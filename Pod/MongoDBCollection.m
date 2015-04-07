//
//  MongoDBCollection.m
//  ObjCMongoDB
//
//  Copyright 2012 Paul Melnikow and other contributors
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "MongoDBCollection.h"
#import "ObjCMongoDB.h"
#import <mongoc.h>
#import "Helper-private.h"
#import "Interfaces-private.h"
#import <BSONSerializer.h>

@interface MongoDBCollection ()
@property (strong) MongoConnection *connection;
@end

@implementation MongoDBCollection {
    mongoc_collection_t *_collection;
}

#pragma mark - Initialization

- (id) initWithConnection:(MongoConnection *) connection
         nativeCollection:(mongoc_collection_t *) nativeCollection {
    if (self = [super init]) {
        self.connection = connection;
        _collection = nativeCollection;
    }
    return self;
}

#pragma mark - Insert

- (BOOL) insertDocument:(BSONDocument *) document
           writeConcern:(MongoWriteConcern *) writeConcern
                  error:(NSError * __autoreleasing *) outError {
    
    bson_error_t error;
    
    if (mongoc_collection_insert(_collection,
                                 0,
                                 document.nativeValue,
                                 [[self _coalesceWriteConcern:writeConcern] nativeWriteConcern],
                                 &error))
        return YES;
    else
        // TODO set outError
        return NO;
//        set_error_and_return_NO;
}

- (BOOL) insertDictionary:(NSDictionary *) dictionary
             writeConcern:(MongoWriteConcern *) writeConcern
                    error:(NSError * __autoreleasing *) error {
    BSONSerializer *serializer = [BSONSerializer serializer];
    if (! [serializer serializeDictionary:dictionary error:error])
        return NO;
    return [self insertDocument:[serializer document] writeConcern:writeConcern error:error];
}

- (BOOL) insertDocuments:(NSArray *) documentArray
         continueOnError:(BOOL) continueOnError
            writeConcern:(MongoWriteConcern *) writeConcern
                   error:(NSError * __autoreleasing *) outError {
    if (documentArray.count > UINT32_MAX)
        [NSException raise:NSInvalidArgumentException
                    format:@"That's a lot of documents! Keep it to %i",
         UINT32_MAX];

    int documentCount = (int) documentArray.count;
    const bson_t *bsonArray[documentCount];
    const bson_t **current = bsonArray;
    for (__strong BSONDocument *document in documentArray) {
        if(![document isKindOfClass:[BSONDocument class]]) {
            BSONSerializer *serializer = [BSONSerializer serializer];
            if (![serializer serializeDictionary:(NSDictionary *) document error:outError]) return NO;
            document = [serializer document];
        }
        *current++ = document.nativeValue;
    }
    mongoc_insert_flags_t flags = continueOnError ? MONGOC_INSERT_CONTINUE_ON_ERROR : MONGOC_INSERT_NONE;
    
    bson_error_t error;
    
    if (mongoc_collection_insert_bulk(_collection,
                                      flags,
                                      bsonArray,
                                      documentCount,
                                      [[self _coalesceWriteConcern:writeConcern] nativeWriteConcern],
                                      &error))
        return YES;
    else
        // TODO set outError
//        set_error_and_return_NO;
        return NO;
}

#pragma mark - Update

- (BOOL) updateWithRequest:(MongoUpdateRequest *) updateRequest
                     error:(NSError * __autoreleasing *) outError {
    bson_error_t error;
    
    if (mongoc_collection_update(_collection,
                                 updateRequest.flags,
                                 updateRequest.conditionDocumentValue.nativeValue,
                                 updateRequest.operationDocumentValue.nativeValue,
                                 [[self _coalesceWriteConcern:updateRequest.writeConcern] nativeWriteConcern],
                                 &error))
        return YES;
    else
        // TODO set outError
        //        set_error_and_return_NO;
        return NO;
}

#pragma mark - Remove

- (BOOL) removeWithPredicate:(MongoPredicate *) predicate
                writeConcern:(MongoWriteConcern *) writeConcern
                       error:(NSError * __autoreleasing *) error {
    if (!predicate)
        [NSException raise:NSInvalidArgumentException
                    format:@"For safety, remove with nil predicate is not allowed - use removeAllWithWriteConcern:error: instead"];
    return [self _removeWithCond:predicate.BSONDocument
                    writeConcern:writeConcern
                           error:error];
}

- (BOOL) removeAllWithWriteConcern:(MongoWriteConcern *) writeConcern
                             error:(NSError * __autoreleasing *) error {
    return [self _removeWithCond:[BSONDocument document]
                    writeConcern:writeConcern
                           error:error];
}

- (BOOL) _removeWithCond:(BSONDocument *) cond
            writeConcern:(MongoWriteConcern *) writeConcern
                   error:(NSError * __autoreleasing *) outError {
    bson_error_t error;
    
    if (mongoc_collection_remove(_collection,
                                 0, // TODO MONGOC_REMOVE_SINGLE_REMOVE
                                 cond.nativeValue,
                                 [[self _coalesceWriteConcern:writeConcern] nativeWriteConcern],
                                 &error))
        return YES;
    else
        // TODO set outError
//        set_error_and_return_NO;
        return NO;
}

#pragma mark - Find

- (NSArray *) findWithRequest:(MongoFindRequest *) findRequest
                        error:(NSError * __autoreleasing *) error {
    return [[self cursorForFindRequest:findRequest error:error] allObjects];
}

- (MongoCursor *) cursorForFindRequest:(MongoFindRequest *) findRequest {
    mongoc_cursor_t *cursor = mongoc_collection_find(_collection,
                                                     findRequest.flags,
                                                     findRequest.skipResults,
                                                     findRequest.limitResults,
                                                     20, // TODO batch_size
                                                     findRequest.queryDocument.nativeValue,
                                                     findRequest.fieldsDocument.nativeValue,
                                                     0); // TODO read_prefs
                                                    
    return [MongoCursor cursorWithNativeCursor:cursor];
}

- (MongoCursor *) cursorForFindRequest:(MongoFindRequest *) findRequest
                                 error:(NSError * __autoreleasing *) error {
    return [self cursorForFindRequest:findRequest];
}

// TODO
//- (BSONDocument *) findOneWithRequest:(MongoFindRequest *) findRequest
//                                error:(NSError * __autoreleasing *) error {
//    bson *newBson = bson_alloc();
//    int result = mongo_find_one(self.connection.connValue,
//                                self.fullyQualifiedName.bsonString,
//                                findRequest.queryDocument.bsonValue,
//                                findRequest.fieldsDocument.bsonValue,
//                                newBson);
//    if (BSON_OK != result) {
//        bson_dealloc(newBson);
//        set_error_and_return_nil;
//    }
//    // newBson contains a copy of the data
//    return [BSONDocument documentWithNativeDocument:newBson dependentOn:nil];
//}

- (NSArray *) findWithPredicate:(MongoPredicate *) predicate
                          error:(NSError * __autoreleasing *) error {
    return [[self cursorForFindWithPredicate:predicate error:error] allObjects];
}

- (MongoCursor *) cursorForFindWithPredicate:(MongoPredicate *) predicate {
    return [self cursorForFindRequest:[MongoFindRequest findRequestWithPredicate:predicate]];
}

- (MongoCursor *) cursorForFindWithPredicate:(MongoPredicate *) predicate
                                       error:(NSError * __autoreleasing *) error {
    return [self cursorForFindRequest:[MongoFindRequest findRequestWithPredicate:predicate]];
}

//TODO
//- (BSONDocument *) findOneWithPredicate:(MongoPredicate *) predicate
//                                  error:(NSError * __autoreleasing *) error {
//    return [self findOneWithRequest:[MongoFindRequest findRequestWithPredicate:predicate] error:error];
//}

- (NSArray *) findAllWithError:(NSError * __autoreleasing *) error {
    return [[self cursorForFindAllWithError:error] allObjects];
}

- (MongoCursor *) cursorForFindAll {
    return [self cursorForFindWithPredicate:[MongoPredicate predicate]];
}

- (MongoCursor *) cursorForFindAllWithError:(NSError * __autoreleasing *) error {
    return [self cursorForFindWithPredicate:[MongoPredicate predicate]];
}

// TODO
//- (BSONDocument *) findOneWithError:(NSError * __autoreleasing *) error {
//    return [self findOneWithPredicate:[MongoPredicate predicate] error:error];
//}

- (int64_t) countWithPredicate:(MongoPredicate *) predicate
                         error:(NSError * __autoreleasing *) error {
    if (!predicate) predicate = [MongoPredicate predicate];
    
    bson_error_t bsonError;
    
    int64_t result = mongoc_collection_count(_collection,
                                             0, // TODO flags
                                             predicate.BSONDocument.nativeValue,
                                             0, // TODO skip
                                             0, // TODO limit
                                             0, // TODO read_prefs
                                             &bsonError);
    
    if (-1 == result); // TODO set error

    return result;
}

#pragma mark - Create indexes

// TODO
//- (NSArray *) allIndexesWithError:(NSError * __autoreleasing *) error {
//    MongoDBCollection *indexesCollection =
//    [self.connection collectionWithName:[self.databaseName stringByAppendingString:@".system.indexes"]];
//    MongoKeyedPredicate *predicate = [MongoKeyedPredicate predicate];
//    [predicate keyPath:@"ns" matches:self.fullyQualifiedName];
//    NSArray *indexDocuments = [indexesCollection findWithPredicate:predicate error:error];
//    
//    if (indexDocuments) {
//        NSMutableArray *result = [NSMutableArray array];
//        for (BSONDocument *indexDocument in indexDocuments)
//            [result addObject:[MongoIndex indexWithDictionary:[indexDocument dictionaryValue]]];
//        return result;
//    } else
//        return nil;
//}

// TODO
//- (BOOL) ensureIndex:(MongoMutableIndex *) index error:(NSError * __autoreleasing *) error {
//    if (!index) [NSException raise:NSInvalidArgumentException format:@"Nil parameter"];
//    if (!index.fields.allKeys.count) [NSException raise:NSInvalidArgumentException format:@"No fields in index"];
//    bson *tempBson = bson_alloc();
//    int result = mongo_create_index(self.connection.connValue,
//                                    self.fullyQualifiedName.bsonString,
//                                    index.fields.BSONDocument.bsonValue,
//                                    index.name ? index.name.bsonString : NULL,
//                                    index.options,
//                                    -1,
//                                    tempBson);
//    // BSON object is destroyed and deallocated when document is autoreleased
//    NSDictionary *resultDict = [[BSONDocument documentWithNativeDocument:tempBson dependentOn:nil] dictionaryValue];
//    if (MONGO_OK != result) {
//        if (error) {
//            NSString *message = [resultDict objectForKey:@"err"];
//            *error = [NSError errorWithDomain:MongoDBErrorDomain
//                                         code:MongoCreateIndexError
//                                     userInfo:message ? @{ NSLocalizedDescriptionKey : message } : nil];
//        }
//        return NO;
//    }
//    return YES;
//}

#pragma mark - Administration

// TODO
// Handle commands of the form { "commandName" : "namespace.collection" }
//- (NSDictionary *) _runCommandWithName:(NSString *) commandName
//                                 error:(NSError * __autoreleasing *) outError {
//    if (commandName == nil) [NSException raise:NSInvalidArgumentException format:@"Nil parameter"];
//    return [self.connection runCommandWithName:commandName
//                                         value:self.namespaceName
//                                     arguments:nil
//                                onDatabaseName:self.databaseName
//                                         error:outError];
//}

- (BOOL) dropCollectionWithError:(NSError *__autoreleasing *) outError {
    bson_error_t bsonError;
    
    if (mongoc_collection_drop(_collection, &bsonError)) {
        return YES;
    } else {
        // TODO set error
        return NO;
    }
}

#pragma mark - Helper methods

- (MongoWriteConcern *) _coalesceWriteConcern:(MongoWriteConcern *) writeConcern {
    return writeConcern ? writeConcern : self.connection.writeConcern;
}

// TODO
//- (BOOL) lastOperationWasSuccessful:(NSError * __autoreleasing *) error {
//    return [self.connection lastOperationWasSuccessful:error];
//}
//- (NSDictionary *) lastOperationDictionary {
//    return [self.connection lastOperationDictionary];
//}
//- (NSError *) error {
//    return [self.connection error];
//}
//- (NSError *) serverError {
//    return [self.connection serverError];
//}

@end