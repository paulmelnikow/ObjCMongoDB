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
#import <mongoc.h>
#import "Helper-private.h"
#import "Interfaces-private.h"
#import <BSONSerializer.h>
#import <BSONDeserializer.h>

NSString * const MongoDBErrorDomain = @"MongoDB";
NSString * const MongoDBServerErrorDomain = @"MongoDB_getlasterror";
NSInteger const MongoCreateIndexError = 101;

@interface MongoConnection ()
// Use this to support implementation of public properties, which need custom setters
@property (copy) MongoWriteConcern *privateWriteConcern;
@end

@implementation MongoConnection {
    mongoc_client_t *_client;
}

#pragma mark - Initialization

- (id) initWithURL:(NSURL *) url {
    if (self = [super init]) {
        _client = mongoc_client_new([[url absoluteString] UTF8String]);
        if (_client == NULL)
            return self = nil;
        self.writeConcern = [MongoWriteConcern writeConcern];
    }
    return self;
}

+ (MongoConnection *) connectionWithURL:(NSURL *) url {
    return [[MongoConnection alloc] initWithURL:url];
}

+ (MongoConnection *) connectionForServer:(NSString *) hostWithPort
                                    error:(NSError * __autoreleasing *) error {
    NSString *urlString = [NSString stringWithFormat:@"mongodb://%@", hostWithPort];
    NSURL *url = [NSURL URLWithString:urlString];
    return [[MongoConnection alloc] initWithURL:url];
}

+ (MongoConnection *) connectionForServer:(NSString *) hostWithPort
                                 username:(NSString *) username
                                 password:(NSString *) password
                               authSource:(NSString *) dbName {
    NSString *urlString = [NSString stringWithFormat:@"mongodb://%@:%@@%@?authSource=%@", username, password, hostWithPort, dbName];
    NSURL *url = [NSURL URLWithString:urlString];
    return [[MongoConnection alloc] initWithURL:url];
}


- (void) dealloc {
    mongoc_client_destroy(_client);
    _client = NULL;
}

- (mongoc_client_t *) clientValue {
    if (_client == NULL)
        [NSException raise:NSInvalidArgumentException format:@"-disconnect was invoked"];
    return _client;
}

#pragma mark - Configuring the connection

- (MongoWriteConcern *) writeConcern { return self.privateWriteConcern; }
- (void) setWriteConcern:(MongoWriteConcern *) writeConcern {
    if (!writeConcern)
        [NSException raise:NSInvalidArgumentException format:@"Nil parameter"];
    self.privateWriteConcern = writeConcern;
    mongoc_client_set_write_concern(_client, self.privateWriteConcern.nativeWriteConcern);
}

//TODO
//mongoc_client_get_uri

- (NSUInteger) maxBSONSize {
    return mongoc_client_get_max_bson_size(_client);
}

- (void) disconnect {
    if (_client) {
        mongoc_client_destroy(_client);
        _client = NULL;
    }
}

#pragma mark - Collection access

- (MongoDBCollection *) collectionWithName:(NSString *) name inDatabase:(NSString *) databaseName {
    mongoc_collection_t *collection =
    mongoc_client_get_collection(_client,
                                 databaseName.UTF8String,
                                 name.UTF8String);
    
    if (collection == NULL) return nil;
    
    return [[MongoDBCollection alloc] initWithConnection:self nativeCollection:collection];
}

- (MongoDBCollection *) collectionWithName:(NSString *) fullyQualifiedName {
    NSRange firstDot = [fullyQualifiedName rangeOfString:@"."];
    
    if (NSNotFound == firstDot.location)
        [NSException raise:NSInvalidArgumentException
                    format:@"Collection name must have a database prefix – mydb.mycollection, or mydb.somecollections.mycollection"];
    
    NSString *databaseName = [fullyQualifiedName substringToIndex:firstDot.location];
    NSString *collectionName = [fullyQualifiedName substringFromIndex:1+firstDot.location];
    
    return [self collectionWithName:collectionName inDatabase:databaseName];
}

#pragma mark - Database administration

// TODO
//- (BOOL) dropDatabaseWithName:(NSString *) database {
//    return mongo_cmd_drop_db(_conn, database.bsonString);
//}

#pragma mark - Run commands

- (NSDictionary *) runCommandWithName:(NSString *) commandName
                       onDatabaseName:(NSString *) databaseName
                                error:(NSError * __autoreleasing *) error {
    return [self runCommandWithName:commandName
                              value:@1
                          arguments:nil
                     onDatabaseName:databaseName
                              error:error];
}

- (NSDictionary *) runCommandWithName:(NSString *) commandName
                                value:(id) value
                            arguments:(NSDictionary *) arguments
                       onDatabaseName:(NSString *) databaseName
                                error:(NSError * __autoreleasing *) error {
    if (!commandName)
        [NSException raise:NSInvalidArgumentException format:@"Nil parameter"];
    
    MutableOrderedDictionary *command = [MutableOrderedDictionary dictionary];
    [command setObject:value forKey:commandName];
    
    for (id key in arguments)
        [command setObject:[arguments objectForKey:key] forKey:key];
    
    return [self runCommandWithOrderedDictionary:command
                                  onDatabaseName:databaseName
                                           error:error];
}

- (NSDictionary *) runCommandWithDictionary:(NSDictionary *) dictionary
                             onDatabaseName:(NSString *) databaseName
                                      error:(NSError * __autoreleasing *) error {
    // MongoDB requires the first key in a command dictionary to contain the command
    // name, so it's important to use an ordered dictionary. This method is deprecated
    // in favor of -runCommandWithName:arguments:onDatabaseName:error.
    return [self runCommandWithOrderedDictionary:(OrderedDictionary *) dictionary
                                  onDatabaseName:databaseName
                                           error:error];
}

- (NSDictionary *) runCommandWithOrderedDictionary:(OrderedDictionary *) orderedDictionary
                                    onDatabaseName:(NSString *) databaseName
                                             error:(NSError * __autoreleasing *) outError {
    BSONSerializer *serializer = [BSONSerializer serializer];
    if (! [serializer serializeDictionary:orderedDictionary error:outError]) return nil;

    bson_t *reply = bson_new();
    bson_error_t error;
    
    bool result = mongoc_client_command_simple(_client,
                                               databaseName.UTF8String,
                                               serializer.document.nativeValue,
                                               NULL,
                                               reply,
                                               &error);
    
    if (! result) {
        bson_destroy(reply);
        // Either the command couldn't be sent or command execution failed.
        // Should return bson_error
        // set outError
        return nil;
    }

    // BSON object is destroyed and deallocated when document is autoreleased
    NSDictionary *ret = [BSONDeserializer dictionaryWithNativeDocument:reply error:outError];
    bson_destroy(reply);
    return ret;
}

#pragma mark - Error handling

// TODO
//- (BOOL) lastOperationWasSuccessful:(NSError * __autoreleasing *) error {
//    int status = mongo_cmd_get_last_error(_conn, "bogusdb", 0);
//    if (error) *error = [self serverError];
//    return MONGO_OK == status;
//}

// TODO
//- (NSDictionary *) lastOperationDictionary {
//    bson *tempBson = bson_alloc();
//    bson_init_empty(tempBson);
//    int emptySize = bson_size(tempBson);
//    mongo_cmd_get_last_error(_conn, "bogusdb", tempBson);
//    if (emptySize == bson_size(tempBson)) {
//        bson_dealloc(tempBson);
//        return nil;
//    }
//    // BSON object is destroyed and deallocated when document is autoreleased
//    return [[BSONDocument documentWithNativeDocument:tempBson dependentOn:nil] dictionaryValue];
//}

// TODO
//- (NSError *) error {
//    if (!_conn->err) return nil;
//    NSString *description = [NSString stringWithFormat:@"%@: %@",
//                             NSStringFromMongoErrorCode(_conn->err),
//                             MongoErrorCodeDescription(_conn->err)];
//    NSString *driverString = [NSString stringWithBSONString:_conn->errstr];
//    if (driverString.length) description = [description stringByAppendingFormat:@": %@",
//                                            driverString];
//    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
//                              description, NSLocalizedDescriptionKey,
//                              nil];
//    return [NSError errorWithDomain:MongoDBErrorDomain
//                               code:_conn->err
//                           userInfo:userInfo];
//}
//
//- (NSError *) serverError {
//    if (!_conn->lasterrcode) return nil;
//    NSString *message = [NSString stringWithBSONString:_conn->lasterrstr];
//    NSDictionary *userInfo = nil;
//    if (message)
//        userInfo = @{ NSLocalizedDescriptionKey : message };
//    return [NSError errorWithDomain:MongoDBServerErrorDomain
//                               code:_conn->lasterrcode
//                           userInfo:userInfo];
//}

@end
