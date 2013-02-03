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

/*! Default write concern for this connection. May be overridden for each insert, update,
    or delete. Don't mutate the writeConcern after setting it, else your changes won't
    propagate to the driver. Create and pass in a new one instead.
 */
@property (copy) MongoWriteConcern *writeConcern;

- (MongoDBCollection *) collectionWithName:(NSString *) name;

- (BOOL) dropDatabaseWithName:(NSString *) database;
//- (BOOL) dropCollection:(MongoDBNamespace *) collection;

- (BOOL) lastOperationWasSuccessful:(NSError * __autoreleasing *) error;
- (NSDictionary *) lastOperationDictionary;
- (NSError *) error;
- (NSError *) serverError;

@end
