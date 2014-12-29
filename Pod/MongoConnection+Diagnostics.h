//
//  MongoConnection+Diagnostics.h
//  ObjCMongoDB
//
//  Copyright 2013 Paul Melnikow and other contributors
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

#import "ObjCMongoDB.h"

// See http://docs.mongodb.org/manual/reference/command/getLog/#getLog
typedef enum {
    MongoLogFilterOptionGlobal,
    MongoLogFilterOptionReplicaSet,
    MongoLogFilterOptionStartupWarnings
} MongoLogFilterOption;

@interface MongoConnection (Diagnostics)

- (NSString *) serverVersion;
/*! Result is in bytes */
- (NSUInteger) serverMaxBSONObjectSize;
- (NSDictionary *) serverBuildInfo;
- (NSDictionary *) serverReplicationInfo;

- (NSDictionary *) serverStatus;
- (NSArray *) serverLogMessagesWithFilter:(MongoLogFilterOption) filterOption;
- (NSDictionary *) storageStatisticsForDatabaseName:(NSString *) databaseName
                                              scale:(NSUInteger) scale;
- (NSArray *) allDatabases;
- (NSArray *) allCommands;

- (BOOL) pingWithError:(NSError * __autoreleasing *) outError;

@end
