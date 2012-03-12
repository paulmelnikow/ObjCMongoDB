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
    utf8Name = BSONStringFromNSString(value);
}

#pragma mark - Insert

- (BOOL) insert:(BSONDocument *) document error:(NSError **) error {
    if (MONGO_OK == mongo_insert(connection.connValue, utf8Name, [document bsonValue]))
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
    bson *bsonArray[documentsToInsert];
    bson **current = bsonArray;
    for (BSONDocument *document in documentArray) {
        if(![document isKindOfClass:[BSONDocument class]]) {
            document = [BSONEncoder documentForObject:document];
        }
        *current++ = document.bsonValue;
    }
    if (MONGO_OK == mongo_insert_batch(connection.connValue, utf8Name, bsonArray, documentsToInsert))
        return YES;
    else
        set_error_and_return_NO;
}

#pragma mark - Update

//int mongo_update( mongo *conn, const char *ns, const bson *cond,
//                 const bson *op, int flags );

#pragma mark - Remove

//int mongo_remove( mongo *conn, const char *ns, const bson *cond );


#pragma mark - Find


//mongo_cursor *mongo_find( mongo *conn, const char *ns, bson *query,
//                         bson *fields, int limit, int skip, int options );

//bson_bool_t mongo_find_one( mongo *conn, const char *ns, bson *query,
//                           bson *fields, bson *out );

//int64_t mongo_count( mongo *conn, const char *db, const char *coll,
//                    bson *query );

#pragma mark - Create indexes

//int mongo_create_index( mongo *conn, const char *ns, bson *key, int options, bson *out );
//bson_bool_t mongo_create_simple_index( mongo *conn, const char *ns, const char *field, int options, bson *out );


#pragma mark - Helper methods

- (NSError *) error { return [connection error]; }

@end
