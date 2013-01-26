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
#import "MongoConnection.h"
#import "mongo.h"
#import "BSONDocument.h"
#import "BSONEncoder.h"
#import "BSON_Helper.h"
#import "MongoFetchRequest.h"
#import "MongoUpdateRequest.h"
#import "Mongo_PrivateInterfaces.h"
#import "Mongo_Helper.h"

@implementation MongoDBCollection {
    NSString *_name;
}

#pragma mark - Initialization

- (void) dealloc {
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

- (void) setName:(NSString *) value {
#if __has_feature(objc_arc)
    _name = [value copy];
#else
    _name = [[value copy] retain];
#endif
    NSRange firstDot = [value rangeOfString:@"."];
    if (NSNotFound == firstDot.location) {
        id exc = [NSException exceptionWithName:NSInvalidArgumentException
                                         reason:@"Collection name is missing database component (e.g. db.person)"
                                       userInfo:nil];
        @throw exc;
    }
    self.databaseName = [value substringToIndex:firstDot.location];
    self.namespaceName = [value substringFromIndex:1+firstDot.location];
}

#pragma mark - Insert

- (BOOL) insert:(BSONDocument *) document error:(NSError **) error {
    if (MONGO_OK == mongo_insert(self.connection.connValue, self.utf8Name, [document bsonValue]))
        return YES;
    else
        set_error_and_return_NO;
}

- (BOOL) insertDictionary:(NSDictionary *) dictionary error:(NSError **) error {
    BSONDocument *document = [BSONEncoder documentForDictionary:dictionary];
    return [self insert:document error:error];
}

- (BOOL) insertObject:(id) object error:(NSError **) error {
    BSONDocument *document = [BSONEncoder documentForObject:object];
    return [self insert:document error:error];    
}

- (BOOL) insertBatch:(NSArray *) documentArray error:(NSError **) error {
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
    if (MONGO_OK == mongo_insert_batch(self.connection.connValue,
                                       self.utf8Name,
                                       bsonArray,
                                       documentsToInsert))
        return YES;
    else
        set_error_and_return_NO;
}

#pragma mark - Update

- (BOOL) update:(MongoUpdateRequest *) updateRequest error:(NSError **) error {
    if (MONGO_OK == mongo_update(self.connection.connValue,
                                 self.utf8Name,
                                 updateRequest.conditionDocumentValue.bsonValue,
                                 updateRequest.operationDocumentValue.bsonValue,
                                 updateRequest.flags))
        return YES;
    else
        set_error_and_return_NO;
}

#pragma mark - Remove

- (BOOL) removeWithCond:(BSONDocument *) cond error:(NSError **) error {
    int result = mongo_remove(self.connection.connValue, self.utf8Name, cond.bsonValue);
    if (MONGO_OK == result)
        return YES;
    else
        set_error_and_return_NO;
}

- (BOOL) remove:(MongoPredicate *) predicate error:(NSError **) error {
    if (!predicate)
        [NSException raise:NSInvalidArgumentException format:@"For safety, remove with nil predicate is not allowed - use removeAllWithError: instead"];
    return [self removeWithCond:predicate.BSONDocument error:error];
}

- (BOOL) removeAllWithError:(NSError **) error {
    BSONDocument *document = [[BSONDocument alloc] init];
#if !__has_feature(objc_arc)
    [document autorelease];
#endif
    return [self removeWithCond:document error:error];    
}

#pragma mark - Find

- (NSArray *) find:(MongoFetchRequest *) fetchRequest error:(NSError **) error {
    return [[self cursorForFind:fetchRequest error:error] allObjects];
}

- (MongoCursor *) cursorForFind:(MongoFetchRequest *) fetchRequest error:(NSError **) error {
    mongo_cursor *cursor = mongo_find(self.connection.connValue, self.utf8Name,
                                      fetchRequest.queryDocument.bsonValue,
                                      fetchRequest.fieldsDocument.bsonValue,
                                      fetchRequest.limitResults,
                                      fetchRequest.skipResults,
                                      fetchRequest.options);
    if (!cursor) set_error_and_return_nil;
    MongoCursor *result = [[MongoCursor alloc] initWithNativeCursor:cursor];
#if __has_feature(objc_arc)
    return result;
#else
    return [result autorelease];
#endif
}

- (BSONDocument *) findOne:(MongoFetchRequest *) fetchRequest error:(NSError **) error {
    bson *tempBson = malloc(sizeof(bson));
    int result = mongo_find_one(self.connection.connValue, self.utf8Name,
                                fetchRequest.queryDocument.bsonValue,
                                fetchRequest.fieldsDocument.bsonValue,
                                tempBson);
    if (BSON_OK != result) {
        free(tempBson);
        set_error_and_return_nil;
    }
    bson *newBson = malloc(sizeof(bson));
    bson_copy(newBson, tempBson);
    free(tempBson);
    BSONDocument *document = [[BSONDocument alloc] initWithNativeDocument:newBson destroyOnDealloc:YES];
#if __has_feature(objc_arc)
    return document;
#else
    return [document autorelease];
#endif
}

- (NSArray *) findWithPredicate:(MongoPredicate *) predicate error:(NSError **) error {
    return [[self cursorForFindWithPredicate:predicate error:error] allObjects];
}

- (MongoCursor *) cursorForFindWithPredicate:(MongoPredicate *) predicate error:(NSError **) error {
    return [self cursorForFind:[MongoFetchRequest fetchRequestWithPredicate:predicate] error:error];
}

- (BSONDocument *) findOneWithPredicate:(MongoPredicate *) predicate error:(NSError **) error {
    return [self findOne:[MongoFetchRequest fetchRequestWithPredicate:predicate] error:error];    
}

- (NSArray *) findAllWithError:(NSError **) error {
    return [[self cursorForFindAllWithError:error] allObjects];
}

- (MongoCursor *) cursorForFindAllWithError:(NSError **) error {
    return [self cursorForFindWithPredicate:[MongoPredicate predicate] error:error];
}

- (BSONDocument *) findOneWithError:(NSError **) error {
    return [self findOneWithPredicate:[MongoPredicate predicate] error:error];
}

- (NSUInteger) countWithPredicate:(MongoPredicate *) predicate error:(NSError **) error {
    if (!predicate) predicate = [MongoPredicate predicate];
    NSUInteger result = mongo_count(self.connection.connValue,
                                    self.utf8DatabaseName, self.utf8NamespaceName,
                                    predicate.BSONDocument.bsonValue);
    if (BSON_ERROR == result) set_error_and_return_BSON_ERROR;
    return result;
}

#pragma mark - Create indexes

//int mongo_create_index( mongo *conn, const char *ns, bson *key, int options, bson *out );
//bson_bool_t mongo_create_simple_index( mongo *conn, const char *ns, const char *field, int options, bson *out );


#pragma mark - Helper methods

- (BOOL) serverStatusForLastOperation:(NSError **) error { return [self.connection serverStatusForLastOperation:error]; }
- (NSDictionary *) serverStatusAsDictionaryForLastOperation { return [self.connection serverStatusAsDictionaryForLastOperation]; }
- (NSError *) error { return [self.connection error]; }
- (NSError *) serverError { return [self.connection serverError]; }

#pragma mark - Accessors

- (const char *) utf8Name { return BSONStringFromNSString(self.name); }
- (const char *) utf8DatabaseName { return BSONStringFromNSString(self.databaseName); }
- (const char *) utf8NamespaceName { return BSONStringFromNSString(self.namespaceName); }

@end