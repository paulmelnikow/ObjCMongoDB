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
#import "ObjCMongoDB.h"
#import "mongo.h"
#import "BSON_Helper.h"
#import "Mongo_Helper.h"
#import "Mongo_PrivateInterfaces.h"

NSString * const MongoDBErrorDomain = @"MongoDB";
NSString * const MongoDBServerErrorDomain = @"MongoDB_getlasterror";
NSInteger const CreateIndexError = 101;

@interface MongoConnection ()
// Use this to support implementation of public properties, which need custom setters
@property (copy) MongoWriteConcern *privateWriteConcern;
@property (assign) NSUInteger privateMaxBSONSize;
@end

@implementation MongoConnection {
    mongo *_conn;
}

#pragma mark - Initialization

- (id) init {
    if (self = [super init]) {
        _conn = mongo_alloc();
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
        maybe_release(result);
        return nil;
    }
    maybe_autorelease_and_return(result);
}

- (void) dealloc {
    mongo_destroy(_conn);
    mongo_dealloc(_conn);
    _conn = NULL;
    maybe_release(_privateWriteConcern);
    super_dealloc;
}

- (mongo *) connValue { return _conn; }

#pragma mark - Configuring the connection

- (MongoWriteConcern *) writeConcern { return self.privateWriteConcern; }
- (void) setWriteConcern:(MongoWriteConcern *) writeConcern {
    if (!writeConcern)
        [NSException raise:NSInvalidArgumentException format:@"Nil parameter"];
    self.privateWriteConcern = writeConcern;
    mongo_set_write_concern(_conn, self.privateWriteConcern.nativeWriteConcern);
}

- (NSUInteger) maxBSONSize { return self.privateMaxBSONSize; }
- (void) setMaxBSONSize:(NSUInteger) maxBSONSize {
    if (maxBSONSize > INT_MAX) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Value is larger than what the driver supports. Keep it to %i",
         INT_MAX];
    }
    self.privateMaxBSONSize = (int) maxBSONSize;
    _conn->max_bson_size = (int) maxBSONSize;
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
    if (MONGO_OK == mongo_replica_set_client(_conn))
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
    return [MongoDBCollection collectionWithConnection:self fullyQualifiedName:name];
}

#pragma mark - Database administration

- (BOOL) dropDatabaseWithName:(NSString *) database {
    return mongo_cmd_drop_db(_conn, database.bsonString);
}

#pragma mark - Run commands

- (NSDictionary *) runCommandWithName:(NSString *) commandName
                       onDatabaseName:(NSString *) databaseName
                                error:(NSError * __autoreleasing *) error {
    if (!commandName)
        [NSException raise:NSInvalidArgumentException format:@"Nil parameter"];
    NSDictionary *dictionary = @{ commandName : @(1) };
    return [self runCommandWithDictionary:dictionary onDatabaseName:databaseName error:error];
}

- (NSDictionary *) runCommandWithDictionary:(NSDictionary *) dictionary
                             onDatabaseName:(NSString *) databaseName
                                      error:(NSError * __autoreleasing *) error {
    bson *tempBson = bson_alloc();
    int result = mongo_run_command(self.connValue,
                                   databaseName.bsonString,
                                   [[dictionary BSONDocumentRestrictingKeyNamesForMongoDB:NO] bsonValue],
                                   tempBson);
    if (BSON_OK != result) {
        bson_dealloc(tempBson);
        set_error_and_return_nil;
    }
    // BSON object is destroyed and deallocated when document is autoreleased
    return [[BSONDocument documentWithNativeDocument:tempBson dependentOn:nil] dictionaryValue];
}

#pragma mark - Error handling

- (BOOL) lastOperationWasSuccessful:(NSError * __autoreleasing *) error {
    int status = mongo_cmd_get_last_error(_conn, "bogusdb", 0);
    if (error) *error = [self serverError];
    return MONGO_OK == status;
}

- (NSDictionary *) lastOperationDictionary {
    bson *tempBson = bson_alloc();
    bson_init_empty(tempBson);
    int emptySize = bson_size(tempBson);
    mongo_cmd_get_last_error(_conn, "bogusdb", tempBson);
    if (emptySize == bson_size(tempBson)) {
        bson_dealloc(tempBson);
        return nil;
    }
    // BSON object is destroyed and deallocated when document is autoreleased
    return [[BSONDocument documentWithNativeDocument:tempBson dependentOn:nil] dictionaryValue];
}

- (NSError *) error {
    if (!_conn->err) return nil;
    NSString *description = [NSString stringWithFormat:@"%@: %@",
                             NSStringFromMongoErrorCode(_conn->err),
                             MongoErrorCodeDescription(_conn->err)];
    NSString *driverString = [NSString stringWithBSONString:_conn->errstr];
    if (driverString.length) description = [description stringByAppendingFormat:@": %@",
                                            driverString];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              description, NSLocalizedDescriptionKey,
                              nil];
    return [NSError errorWithDomain:MongoDBErrorDomain
                               code:_conn->err
                           userInfo:userInfo];
}

- (NSError *) serverError {
    if (!_conn->lasterrcode) return nil;
    NSString *message = [NSString stringWithBSONString:_conn->lasterrstr];
    NSDictionary *userInfo = nil;
    if (message)
        userInfo = @{ NSLocalizedDescriptionKey : message };
    return [NSError errorWithDomain:MongoDBServerErrorDomain
                               code:_conn->lasterrcode
                           userInfo:userInfo];
}

@end
