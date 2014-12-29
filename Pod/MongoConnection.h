//
//  MongoConnection.h
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

#import <Foundation/Foundation.h>
#import "MongoDBCollection.h"

FOUNDATION_EXPORT NSString * const MongoDBErrorDomain;
FOUNDATION_EXPORT NSString * const MongoDBServerErrorDomain;
FOUNDATION_EXPORT NSInteger const MongoCreateIndexError;

@class OrderedDictionary;
@class MongoWriteConcern;

/**
 Encapsulates a Mongo connection object.
 */
@interface MongoConnection : NSObject

/**
 Connect using the given URL string.
 */
+ (MongoConnection *) connectionWithURL:(NSURL *) url;

/**
 Connect using the given host:port string.
 
 The error parameter is ignored.
 */
+ (MongoConnection *) connectionForServer:(NSString *) hostWithPort
                                    error:(NSError * __autoreleasing *) error __deprecated_msg("Use +connectionWithURL with a connection string URI: http://docs.mongodb.org/manual/reference/connection-string/");

/**
 Convenience method to connect using basic authentication using a
 signature similar to the old -authenticate method.
 */
+ (MongoConnection *) connectionForServer:(NSString *) hostWithPort
                                 username:(NSString *) username
                                 password:(NSString *) password
                               authSource:(NSString *) dbName __deprecated_msg("Use +connectionWithURL with a connection string URI: http://docs.mongodb.org/manual/reference/connection-string/");

/**
 Disconnect this connection and invalidate it. Further attemps to use it or
 its collections will raise an exception
 */
- (void) disconnect;

/**
 Write concern for this connection. May be overridden for each insert, update, or
 delete. The default is acknowledged writes – MongoWriteAcknowledged.
 */
@property (retain) MongoWriteConcern *writeConcern;

/**
 Max BSON size for this connection. When attempting to insert a document larger
 than this, the driver will generate an error.
 */
@property (assign, readonly) NSUInteger maxBSONSize;

/**
 Get the collection with the given name in the given database.
 
 The collection name can be namespaced, e.g. collection or
 namespace.collection.
 */
- (MongoDBCollection *) collectionWithName:(NSString *) name inDatabase:(NSString *) databaseName;

/**
 Get the collection with the given fully-qualified name.
 e.g. database.collection or database.namespace.collection
 */
- (MongoDBCollection *) collectionWithName:(NSString *) fullyQualifiedName __deprecated_msg("Use -collectionWithName:inDatabase:");

// TODO
//- (BOOL) dropDatabaseWithName:(NSString *) database;

/**
 Run the command { commandName: 1 }
 */
- (NSDictionary *) runCommandWithName:(NSString *) commandName
                       onDatabaseName:(NSString *) databaseName
                                error:(NSError * __autoreleasing *) error;
/**
 Run the command { commandName: value }. If arguments is non-nil, run the
 command { commandName: value, arg1: argv1, arg2: argv2, ... }
 */
- (NSDictionary *) runCommandWithName:(NSString *) commandName
                                value:(id) value
                            arguments:(NSDictionary *) arguments
                       onDatabaseName:(NSString *) databaseName
                                error:(NSError * __autoreleasing *) error;
- (NSDictionary *) runCommandWithOrderedDictionary:(OrderedDictionary *) orderedDictionary
                                    onDatabaseName:(NSString *) databaseName
                                             error:(NSError * __autoreleasing *) error;

/**
 MongoDB requires the first key in a command dictionary to contain the command
 name, so it's important to use an ordered dictionary. This method is deprecated
 in favor of -runCommandWithName:arguments:onDatabaseName:error.
 */
- (NSDictionary *) runCommandWithDictionary:(NSDictionary *) dictionary
                             onDatabaseName:(NSString *) databaseName
                                      error:(NSError * __autoreleasing *) error
    __deprecated_msg("Use -runCommandWithName:arguments:onDatabaseName:error instead");

// TODO
//- (BOOL) lastOperationWasSuccessful:(NSError * __autoreleasing *) error;
// TODO
//- (NSDictionary *) lastOperationDictionary;
// TODO
//- (NSError *) error;
//- (NSError *) serverError;

@end
