//
//  MongoDBCollection.m
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MongoDBCollection.h"
#import "MongoConnection.h"
#import "mongo.h"
#import "BSONDocument.h"
#import "BSONEncoder.h"
#import "MongoFetchRequest.h"

@implementation MongoDBCollection

@synthesize connection, name;

#pragma mark - Initialization

- (void) dealloc { }

- (void) setName:(NSString *) value {
#if __has_feature(objc_arc)
    name = [value copy];
#else
    name = [[value copy] retain];
#endif
    _utf8Name = BSONStringFromNSString(value);
    NSRange firstDot = [value rangeOfString:@"."];
    if (NSNotFound == firstDot.location) {
        id exc = [NSException exceptionWithName:NSInvalidArgumentException
                                         reason:@"Collection name is missing database component (e.g. db.person)"
                                       userInfo:nil];
        @throw exc;
    }
    _utf8DatabaseName = BSONStringFromNSString([value substringToIndex:firstDot.location]);
    _utf8NamespaceName = BSONStringFromNSString([value substringFromIndex:1+firstDot.location]);
}

#pragma mark - Insert

- (BOOL) insert:(BSONDocument *) document error:(NSError **) error {
    if (MONGO_OK == mongo_insert(connection.connValue, _utf8Name, [document bsonValue]))
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
    if (documentArray.count > INT_MAX) {
        NSString *reason = [NSString stringWithFormat:@"That's a lot of documents! Keep it to %i.",
                            INT_MAX];
        id exc = [NSException exceptionWithName:NSInvalidArgumentException
                                         reason:reason
                                       userInfo:nil];
        @throw exc;
    }
    int documentsToInsert = documentArray.count;
    const bson *bsonArray[documentsToInsert];
    const bson **current = bsonArray;
    for (__strong BSONDocument *document in documentArray) {
        if(![document isKindOfClass:[BSONDocument class]]) {
            document = [BSONEncoder documentForObject:document];
        }
        *current++ = document.bsonValue;
    }
    if (MONGO_OK == mongo_insert_batch(connection.connValue, _utf8Name, bsonArray, documentsToInsert))
        return YES;
    else
        set_error_and_return_NO;
}

#pragma mark - Update

//int mongo_update( mongo *conn, const char *ns, const bson *cond,
//                 const bson *op, int flags );

//- (BOOL) update:(MongoPredicate *) predicate 

#pragma mark - Remove

- (BOOL) removeWithCond:(BSONDocument *) cond error:(NSError **) error {
    int result = mongo_remove(connection.connValue, _utf8Name, cond.bsonValue);
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
    mongo_cursor *cursor = mongo_find(connection.connValue, _utf8Name,
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
    int result = mongo_find_one(connection.connValue, _utf8Name,
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
    NSUInteger result = mongo_count(connection.connValue,
                                    _utf8DatabaseName, _utf8NamespaceName,
                                    predicate.BSONDocument.bsonValue);
    if (BSON_ERROR == result) set_error_and_return_BSON_ERROR;
    return result;
}

#pragma mark - Create indexes

//int mongo_create_index( mongo *conn, const char *ns, bson *key, int options, bson *out );
//bson_bool_t mongo_create_simple_index( mongo *conn, const char *ns, const char *field, int options, bson *out );


#pragma mark - Helper methods

- (BOOL) serverStatusForLastOperation:(NSError **) error { return [connection serverStatusForLastOperation:error]; }
- (NSError *) error { return [connection error]; }
- (NSError *) serverError { return [connection serverError]; }

@end
