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
#import "Mongo_PrivateInterfaces.h"

NSString * const MongoDBErrorDomain = @"MongoDB";
NSString * const MongoDBServerErrorDomain = @"MongoDB_getlasterror";

@implementation MongoConnection {
    mongo *_conn;
}

#pragma mark - Initialization

- (id) init {
    if (self = [super init]) {
        _conn = mongo_create();
        mongo_init(_conn);
        self.writeConcern = [MongoWriteConcern writeConcern];
        self.maxBSONSize = MONGO_DEFAULT_MAX_BSON_SIZE;
    }
    return self;
}

+ (MongoConnection *) connectionForServer:(NSString *) hostWithPort error:(NSError * __autoreleasing *) error {
    MongoConnection *result = [[self alloc] init];
    BOOL success = [result connectToServer:hostWithPort error:error];
    if (!success) {
#if !__has_feature(objc_arc)
        [result release];
#endif
        return nil;
    }
    maybe_autorelease_and_return(result);
}

- (void) dealloc {
    mongo_destroy(_conn);
    mongo_dispose(_conn);
    self.writeConcern = nil;
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

- (mongo *) connValue { return _conn; }

#pragma mark - Configuring the connection

- (MongoWriteConcern *) writeConcern { return _writeConcern; }
- (void) setWriteConcern:(MongoWriteConcern *) writeConcern {
#if !__has_feature(objc_arc)
    [_writeConcern release];
#endif
    _writeConcern = [writeConcern copy];
    mongo_set_write_concern(_conn, _writeConcern.nativeWriteConcern);
}

- (NSUInteger) maxBSONSize { return _maxBSONSize; }
- (void) setMaxBSONSize:(NSUInteger) maxBSONSize {
    if (maxBSONSize > INT_MAX) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Value is larger than what the driver supports. Keep it to %i",
         INT_MAX];
    }
    mongo->max_bson_size = _maxBSONSize = maxBSONSize;
}

#pragma mark - Connecting to a single server or a replica set

- (BOOL) connectToServer:(NSString *) hostWithPort
                   error:(NSError * __autoreleasing *) error {
    mongo_host_port host_port;
    mongo_parse_host(hostWithPort.bsonString, &host_port);
    if (MONGO_OK == mongo_client(_conn, host_port.host, host_port.port))
        return YES;
    else
        set_error_and_return_NO;
}

- (BOOL) connectToReplicaSet:(NSString *) replicaSet
                   seedArray:(NSArray *) seedArray
                       error:(NSError * __autoreleasing *) error {
    mongo_replica_set_init(_conn, replicaSet.bsonString);
    mongo_host_port host_port;
    for (NSString *hostWithPort in seedArray) {
        mongo_parse_host(hostWithPort.bsonString, &host_port);
        mongo_replica_set_add_seed(_conn, host_port.host, host_port.port);
    }
    if (MONGO_OK == mongo_replica_set_connect(_conn))
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

- (MongoDBCollection *) collectionWithName:(NSString *) name {
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

- (BOOL) dropDatabaseWithName:(NSString *) database {
    return mongo_cmd_drop_db(_conn, database.bsonString);
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
    
    id result = [BSONDecoder decodeDictionaryWithData:[NSData dataWithNativeBSONObject:tempBson copy:NO]];
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
    NSDictionary *userInfo = @{
                              NSLocalizedDescriptionKey : [NSString stringWithBSONString:_conn->lasterrstr]
                             };
    return [NSError errorWithDomain:MongoDBServerErrorDomain
                               code:_conn->lasterrcode
                           userInfo:userInfo];
}

@end
