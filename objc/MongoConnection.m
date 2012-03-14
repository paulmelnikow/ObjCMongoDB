//
//  MongoDB.m
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

#import "BSON_Helper.h"
#import "MongoConnection.h"
#import "mongo.h"

NSString * const MongoDBErrorDomain = @"MongoDB";
NSString * const MongoDBObjectIDKey = @"_id";
const char * const MongoDBObjectIDBSONKey = "_id";

@implementation MongoConnection

#pragma mark - Initialization

- (id) init {
    if (self = [super init]) {
        _conn = malloc(sizeof(mongo));
        mongo_init(_conn);
    }
    return self;
}

+ (MongoConnection *) connectionForServer:(NSString *) hostWithPort error:(NSError **) error {
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
}

- (mongo *) connValue { return _conn; }

#pragma mark - Connecting to a single server or a replica set

- (BOOL) connectToServer:(NSString *) hostWithPort error:(NSError **) error {
    mongo_host_port host_port;
    mongo_parse_host(BSONStringFromNSString(hostWithPort), &host_port);
    if (MONGO_OK == mongo_connect(_conn, host_port.host, host_port.port))
        return YES;
    else
        set_error_and_return_NO;
}

- (BOOL) connectToReplicaSet:(NSString *) replicaSet seed:(NSArray *) seed error:(NSError **) error {
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

- (BOOL) checkConnectionWithError:(NSError **) error {
    if (MONGO_OK == mongo_check_connection(_conn))
        return YES;
    else
        set_error_and_return_NO;
}

- (BOOL) reconnectWithError:(NSError **) error {
    if (MONGO_OK == mongo_reconnect(_conn))
        return YES;
    else
        set_error_and_return_NO;
}

- (void) disconnect { mongo_disconnect(_conn); }

#pragma mark - Collection access

- (MongoDBCollection *) collection:(NSString *) name {
    MongoDBCollection *collection = [[MongoDBCollection alloc] init];
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

@end
