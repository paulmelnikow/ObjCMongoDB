//
//  MongoConnection.m
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

#import "MongoConnection.h"
#import "mongo.h"
#import "BSONDecoder.h"
#import "BSON_Helper.h"
#import "Mongo_Helper.h"

NSString * const MongoDBErrorDomain = @"MongoDB";
NSString * const MongoDBServerErrorDomain = @"MongoDB_getlasterror";

@implementation MongoConnection {
    mongo *_conn;
}

#pragma mark - Initialization

- (id) init {
    if (self = [super init]) {
        _conn = malloc(sizeof(mongo));
        mongo_init(_conn);
    }
    return self;
}

+ (MongoConnection *) connectionForServer:(NSString *) hostWithPort error:(NSError * __autoreleasing *) error {
    MongoConnection *conn = [[self alloc] init];
    BOOL success = [conn connectToServer:hostWithPort error:error];
    if (!success) {
#if !__has_feature(objc_arc)
        [conn release];
#endif
        return nil;
    }
#if !__has_feature(objc_arc)
    [conn autorelease];
#endif
    return conn;
}

- (void) dealloc {
    mongo_destroy(_conn);
    free(_conn);
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

- (mongo *) connValue { return _conn; }

#pragma mark - Connecting to a single server or a replica set

- (BOOL) connectToServer:(NSString *) hostWithPort
                   error:(NSError * __autoreleasing *) error {
    mongo_host_port host_port;
    mongo_parse_host(BSONStringFromNSString(hostWithPort), &host_port);
    if (MONGO_OK == mongo_connect(_conn, host_port.host, host_port.port))
        return YES;
    else
        set_error_and_return_NO;
}

- (BOOL) connectToReplicaSet:(NSString *) replicaSet
                        seed:(NSArray *) seed
                       error:(NSError * __autoreleasing *) error {
    mongo_replset_init(_conn, BSONStringFromNSString(replicaSet));
    mongo_host_port host_port;
    for (NSString *hostWithPort in seed) {
        mongo_parse_host(BSONStringFromNSString(hostWithPort), &host_port);
        mongo_replset_add_seed(_conn, host_port.host, host_port.port);
    }
    if (MONGO_OK == mongo_replset_connect(_conn))
        return YES;
    else
        set_error_and_return_NO;
}

// FIXME see if this is implemented
// int mongo_set_op_timeout( mongo *conn, int millis );

- (BOOL) checkConnectionWithError:(NSError * __autoreleasing *) error {
    if (MONGO_OK == mongo_check_connection(_conn))
        return YES;
    else
        set_error_and_return_NO;
}

- (BOOL) reconnectWithError:(NSError * __autoreleasing *) error {
    if (MONGO_OK == mongo_reconnect(_conn))
        return YES;
    else
        set_error_and_return_NO;
}

- (void) disconnect { mongo_disconnect(_conn); }

#pragma mark - Collection access

- (MongoDBCollection *) collection:(NSString *) name {
#if __has_feature(objc_arc)
    MongoDBCollection *collection = [[MongoDBCollection alloc] init];
#else
    MongoDBCollection *collection = [[[MongoDBCollection alloc] init] autorelease];
#endif
    collection.connection = self;
    collection.name = name;
    return collection;
}

#pragma mark - Database administration

- (BOOL) dropDatabase:(NSString *) database {
    return mongo_cmd_drop_db(_conn, BSONStringFromNSString(database));
}

//- (BOOL) dropCollection:(id) collection {
//        return mongo_cmd_drop_collection(_conn,
//                                         [database cStringUsingEncoding:NSUTF8StringEncoding],
//                                         [collection cStringUsingEncoding:NSUTF8StringEncoding],
//                                         NULL);
//}
                         
#pragma mark - Error handling

- (BOOL) lastOperationWasSuccessful:(NSError * __autoreleasing *) error {
    int status = mongo_cmd_get_last_error(_conn, "bogusdb", 0);
    if (error) *error = [self serverError];
    if (MONGO_OK == status)
        return YES;
    else
        return NO;
}

- (NSDictionary *) lastOperationDictionary {
    bson *tempBson = bson_create();
    bson_init(tempBson);
    mongo_cmd_get_last_error(_conn, "bogusdb", tempBson);
    if (!bson_size(tempBson)) {
        bson_destroy(tempBson);
        bson_dispose(tempBson);
        return nil;
    }
    
    id result = [BSONDecoder decodeDictionaryWithData:NSDataFromBSON(tempBson, NO)];
    bson_destroy(tempBson);
    bson_dispose(tempBson);
    return result;
}

- (NSError *) error {
    if (!_conn->err) return nil;
    NSString *description = [NSString stringWithFormat:@"%@ [%@]",
                             MongoErrorCodeDescription(_conn->err),
                             NSStringFromMongoErrorCode(_conn->err)];
    if (_conn->errstr) description = [description stringByAppendingFormat:@": %s",
                                      _conn->errstr];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              description, NSLocalizedDescriptionKey,
                              nil];
    return [NSError errorWithDomain:MongoDBErrorDomain
                               code:_conn->err
                           userInfo:userInfo];
}

- (NSError *) serverError {
    if (!_conn->lasterrcode) return nil;
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              NSStringFromBSONString(_conn->lasterrstr), NSLocalizedDescriptionKey,
                              nil];
    return [NSError errorWithDomain:MongoDBServerErrorDomain
                               code:_conn->lasterrcode
                           userInfo:userInfo];
}

@end
