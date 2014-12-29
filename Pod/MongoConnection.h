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

@class MongoWriteConcern;

/**
 Encapsulates a Mongo connection object.
 */
@interface MongoConnection : NSObject

- (MongoConnection *) init;
+ (MongoConnection *) connectionForServer:(NSString *) hostWithPort
                                    error:(NSError * __autoreleasing *) error;

- (BOOL) connectToServer:(NSString *) hostWithPort
                   error:(NSError * __autoreleasing *) error;
- (BOOL) connectToReplicaSet:(NSString *) replicaSet
                   seedArray:(NSArray *) seedArray
                       error:(NSError * __autoreleasing *) error;
- (BOOL) checkConnectionWithError:(NSError * __autoreleasing *) error;
- (BOOL) reconnectWithError:(NSError * __autoreleasing *) error;
- (void) disconnect;

// Implement authentication
- (BOOL) authenticate:(NSString *) dbName
             username:(NSString *) username
             password:(NSString *) password
                error:(NSError * __autoreleasing *) error;

/*! Write concern for this connection. May be overridden for each insert, update, or
    delete. The default is acknowledged writes – MongoWriteAcknowledged.
 */
@property (retain) MongoWriteConcern *writeConcern;
/*! Max BSON size for this connection. When attempting to insert a document larger than
    this, the driver will generate an error. */
@property (assign) NSUInteger maxBSONSize;

- (MongoDBCollection *) collectionWithName:(NSString *) name;

- (BOOL) dropDatabaseWithName:(NSString *) database;

// Run the command { commandName: 1 }
- (NSDictionary *) runCommandWithName:(NSString *) commandName
                       onDatabaseName:(NSString *) databaseName
                                error:(NSError * __autoreleasing *) error;
// Run the command { commandName: value }.
// If arguments is non-nil, runs the command
//    { commandName: value, arg1: argv1, arg2: argv2, ... }
- (NSDictionary *) runCommandWithName:(NSString *) commandName
                                value:(id) value
                            arguments:(NSDictionary *) arguments
                       onDatabaseName:(NSString *) databaseName
                                error:(NSError * __autoreleasing *) error;
- (NSDictionary *) runCommandWithOrderedDictionary:(OrderedDictionary *) orderedDictionary
                                    onDatabaseName:(NSString *) databaseName
                                             error:(NSError * __autoreleasing *) error;

// MongoDB requires the first key in a command dictionary to contain the command
// name, so it's important to use an ordered dictionary. This method is deprecated
// in favor of -runCommandWithName:arguments:onDatabaseName:error.
- (NSDictionary *) runCommandWithDictionary:(NSDictionary *) dictionary
                             onDatabaseName:(NSString *) databaseName
                                      error:(NSError * __autoreleasing *) error
    __deprecated_msg("Use -runCommandWithName:arguments:onDatabaseName:error instead");

- (BOOL) lastOperationWasSuccessful:(NSError * __autoreleasing *) error;
- (NSDictionary *) lastOperationDictionary;
- (NSError *) error;
- (NSError *) serverError;

@end
