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
#import "mongo.h"
#import "BSON_Helper.h"
#import "Mongo_PrivateInterfaces.h"
#import "Mongo_Helper.h"

@interface MongoDBCollection ()
@property (copy, nonatomic) NSString * privateFullyQualifiedName;
@end

@implementation MongoDBCollection

#pragma mark - Initialization

- (id) initWithConnection:(MongoConnection *) connectionParam fullyQualifiedName:(NSString *) nameParam {
    if (self = [super init]) {
        self.connection = connectionParam;
        self.fullyQualifiedName = nameParam;
    }
    return self;
}

- (void) dealloc {
    maybe_release(_connection);
    maybe_release(_privateFullyQualifiedName);
    maybe_release(_databaseName);
    maybe_release(_namespaceName);
    super_dealloc;
}

+ (MongoDBCollection *) collectionWithConnection:(MongoConnection *) connection
                              fullyQualifiedName:(NSString *) name {
    MongoDBCollection *result = [[self alloc] initWithConnection:connection fullyQualifiedName:name];
    maybe_autorelease_and_return(result);
}

- (void) setFullyQualifiedName:(NSString *) value {
    self.privateFullyQualifiedName = value;
    NSRange firstDot = [value rangeOfString:@"."];
    
    if (NSNotFound == firstDot.location)
        [NSException raise:NSInvalidArgumentException
                    format:@"Collection name must have a database prefix – mydb.mycollection, or mydb.somecollections.mycollection"];
    
    self.databaseName = [value substringToIndex:firstDot.location];
    self.namespaceName = [value substringFromIndex:1+firstDot.location];
}

- (NSString *) fullyQualifiedName {
    return self.privateFullyQualifiedName;
}

#pragma mark - Insert

- (BOOL) insertDocument:(BSONDocument *) document
           writeConcern:(MongoWriteConcern *) writeConcern
                  error:(NSError * __autoreleasing *) error {
    if (MONGO_OK == mongo_insert(self.connection.connValue,
                                 self.fullyQualifiedName.bsonString,
                                 document.bsonValue,
                                 [[self _coalesceWriteConcern:writeConcern] nativeWriteConcern]))
        return YES;
    else
        set_error_and_return_NO;
}

- (BOOL) insertDictionary:(NSDictionary *) dictionary
             writeConcern:(MongoWriteConcern *) writeConcern
                    error:(NSError * __autoreleasing *) error {
    return [self insertDocument:[dictionary BSONDocument] writeConcern:writeConcern error:error];
}

- (BOOL) insertObject:(id) object
         writeConcern:(MongoWriteConcern *) writeConcern
                error:(NSError * __autoreleasing *) error {
    return [self insertDocument:[BSONEncoder documentForObject:object] writeConcern:writeConcern error:error];
}

- (BOOL) insertDocuments:(NSArray *) documentArray
         continueOnError:(BOOL) continueOnError
            writeConcern:(MongoWriteConcern *) writeConcern
                   error:(NSError * __autoreleasing *) error {
    if (documentArray.count > INT_MAX)
        [NSException raise:NSInvalidArgumentException
                    format:@"That's a lot of documents! Keep it to %i",
         INT_MAX];

    int documentsToInsert = (int) documentArray.count;
    const bson *bsonArray[documentsToInsert];
    const bson **current = bsonArray;
    for (__strong BSONDocument *document in documentArray) {
        if(![document isKindOfClass:[BSONDocument class]]) {
            document = [BSONEncoder documentForObject:document];
        }
        *current++ = document.bsonValue;
    }
    int flags = continueOnError ? MONGO_CONTINUE_ON_ERROR : 0;
    if (MONGO_OK == mongo_insert_batch(self.connection.connValue,
                                       self.fullyQualifiedName.bsonString,
                                       bsonArray,
                                       documentsToInsert,
                                       [[self _coalesceWriteConcern:writeConcern] nativeWriteConcern],
                                       flags))
        return YES;
    else
        set_error_and_return_NO;
}

#pragma mark - Update

- (BOOL) updateWithRequest:(MongoUpdateRequest *) updateRequest
                     error:(NSError * __autoreleasing *) error {
    if (MONGO_OK == mongo_update(self.connection.connValue,
                                 self.fullyQualifiedName.bsonString,
                                 updateRequest.conditionDocumentValue.bsonValue,
                                 updateRequest.operationDocumentValue.bsonValue,
                                 updateRequest.flags,
                                 [[self _coalesceWriteConcern:updateRequest.writeConcern] nativeWriteConcern]))
        return YES;
    else
        set_error_and_return_NO;
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
                   error:(NSError * __autoreleasing *) error {
    int result = mongo_remove(self.connection.connValue,
                              self.fullyQualifiedName.bsonString,
                              cond.bsonValue,
                              [[self _coalesceWriteConcern:writeConcern] nativeWriteConcern]);
    if (MONGO_OK == result)
        return YES;
    else
        set_error_and_return_NO;
}

#pragma mark - Find

- (NSArray *) findWithRequest:(MongoFindRequest *) findRequest
                        error:(NSError * __autoreleasing *) error {
    return [[self cursorForFindRequest:findRequest error:error] allObjects];
}

- (MongoCursor *) cursorForFindRequest:(MongoFindRequest *) findRequest
                                 error:(NSError * __autoreleasing *) error {
    mongo_cursor *cursor = mongo_find(self.connection.connValue,
                                      self.fullyQualifiedName.bsonString,
                                      findRequest.queryDocument.bsonValue,
                                      findRequest.fieldsDocument.bsonValue,
                                      findRequest.limitResults,
                                      findRequest.skipResults,
                                      findRequest.options);
    if (!cursor) set_error_and_return_nil;
    return [MongoCursor cursorWithNativeCursor:cursor];
}

- (BSONDocument *) findOneWithRequest:(MongoFindRequest *) findRequest
                                error:(NSError * __autoreleasing *) error {
    bson *newBson = bson_alloc();
    int result = mongo_find_one(self.connection.connValue,
                                self.fullyQualifiedName.bsonString,
                                findRequest.queryDocument.bsonValue,
                                findRequest.fieldsDocument.bsonValue,
                                newBson);
    if (BSON_OK != result) {
        bson_dealloc(newBson);
        set_error_and_return_nil;
    }
    // newBson contains a copy of the data
    return [BSONDocument documentWithNativeDocument:newBson dependentOn:nil];
}

- (NSArray *) findWithPredicate:(MongoPredicate *) predicate
                          error:(NSError * __autoreleasing *) error {
    return [[self cursorForFindWithPredicate:predicate error:error] allObjects];
}

- (MongoCursor *) cursorForFindWithPredicate:(MongoPredicate *) predicate
                                       error:(NSError * __autoreleasing *) error {
    return [self cursorForFindRequest:[MongoFindRequest findRequestWithPredicate:predicate] error:error];
}

- (BSONDocument *) findOneWithPredicate:(MongoPredicate *) predicate
                                  error:(NSError * __autoreleasing *) error {
    return [self findOneWithRequest:[MongoFindRequest findRequestWithPredicate:predicate] error:error];
}

- (NSArray *) findAllWithError:(NSError * __autoreleasing *) error {
    return [[self cursorForFindAllWithError:error] allObjects];
}

- (MongoCursor *) cursorForFindAllWithError:(NSError * __autoreleasing *) error {
    return [self cursorForFindWithPredicate:[MongoPredicate predicate] error:error];
}

- (BSONDocument *) findOneWithError:(NSError * __autoreleasing *) error {
    return [self findOneWithPredicate:[MongoPredicate predicate] error:error];
}

- (NSUInteger) countWithPredicate:(MongoPredicate *) predicate
                            error:(NSError * __autoreleasing *) error {
    if (!predicate) predicate = [MongoPredicate predicate];
    NSUInteger result = mongo_count(self.connection.connValue,
                                    self.databaseName.bsonString, self.namespaceName.bsonString,
                                    predicate.BSONDocument.bsonValue);
    if (BSON_ERROR == result) set_error_and_return_BSON_ERROR;
    return result;
}

#pragma mark - Create indexes

- (NSArray *) allIndexesWithError:(NSError * __autoreleasing *) error {
    MongoDBCollection *indexesCollection =
    [self.connection collectionWithName:[self.databaseName stringByAppendingString:@".system.indexes"]];
    MongoKeyedPredicate *predicate = [MongoKeyedPredicate predicate];
    [predicate keyPath:@"ns" matches:self.fullyQualifiedName];
    NSArray *indexDocuments = [indexesCollection findWithPredicate:predicate error:error];
    
    if (indexDocuments) {
        NSMutableArray *result = [NSMutableArray array];
        for (BSONDocument *indexDocument in indexDocuments)
            [result addObject:[MongoIndex indexWithDictionary:[indexDocument dictionaryValue]]];
        return result;
    } else
        return nil;
}

- (BOOL) ensureIndex:(MongoMutableIndex *) index error:(NSError * __autoreleasing *) error {
    NSParameterAssert(index != nil);
    NSParameterAssert(index.fields.allKeys.count > 0);
    bson *tempBson = bson_alloc();
    int result = mongo_create_index(self.connection.connValue,
                                    self.fullyQualifiedName.bsonString,
                                    index.fields.BSONDocument.bsonValue,
                                    index.name ? index.name.bsonString : NULL,
                                    index.options,
                                    tempBson);
    // BSON object is destroyed and deallocated when document is autoreleased
    NSDictionary *resultDict = [[BSONDocument documentWithNativeDocument:tempBson dependentOn:nil] dictionaryValue];
    if (MONGO_OK != result) {
        if (error) {
            NSString *message = [resultDict objectForKey:@"err"];
            *error = [NSError errorWithDomain:MongoDBErrorDomain
                                         code:CreateIndexError
                                     userInfo:message ? @{ NSLocalizedDescriptionKey : message } : nil];
        }
        return NO;
    }
    return YES;
}

#pragma mark - Administration

// Handle commands of the form { "commandName" : "namespace.collection" }
- (NSDictionary *) _runCommandWithName:(NSString *) commandName
                                 error:(NSError * __autoreleasing *) outError {
    if (commandName == nil) [NSException raise:NSInvalidArgumentException format:@"Nil parameter"];
    return [self.connection runCommandWithDictionary:@{ commandName : self.namespaceName }
                                      onDatabaseName:self.databaseName
                                               error:outError];
}

- (BOOL) dropCollectionWithError:(NSError *__autoreleasing *) outError {
    id result = [self _runCommandWithName:@"drop" error:outError];
    return result ? YES : NO;
}

#pragma mark - Helper methods

- (MongoWriteConcern *) _coalesceWriteConcern:(MongoWriteConcern *) writeConcern {
    return writeConcern ? writeConcern : self.connection.writeConcern;
}

- (BOOL) lastOperationWasSuccessful:(NSError * __autoreleasing *) error {
    return [self.connection lastOperationWasSuccessful:error];
}
- (NSDictionary *) lastOperationDictionary {
    return [self.connection lastOperationDictionary];
}
- (NSError *) error {
    return [self.connection error];
}
- (NSError *) serverError {
    return [self.connection serverError];
}

@end