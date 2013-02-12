//
//  MongoConnection+Diagnostics.m
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

#import "MongoConnection+Diagnostics.h"

@implementation MongoConnection (Diagnostics)

- (NSDictionary *) serverBuildInfo {
    return [self runCommandWithName:@"buildInfo" onDatabaseName:@"admin" error:nil];
}

- (NSString *) serverVersion {
    return [[self serverBuildInfo] objectForKey:@"version"];
}

- (NSUInteger) serverMaxBSONObjectSize {
    return [[[self serverBuildInfo] objectForKey:@"maxBsonObjectSize"] unsignedIntegerValue];
}

- (NSDictionary *) serverReplicationInfo {
    return [self runCommandWithName:@"isMaster" onDatabaseName:@"admin" error:nil];
}

- (NSDictionary *) serverStatus {
    return [self runCommandWithName:@"serverStatus" onDatabaseName:@"admin" error:nil];
}

- (NSDictionary *) storageStatisticsForDatabaseName:(NSString *) databaseName
                                              scale:(NSUInteger) scale {
    NSDictionary *command = @{ @"dbStats" : @(1), @"scale" : @(scale) };
    return [self runCommandWithDictionary:command onDatabaseName:databaseName error:nil];
}

+ (NSString *) _stringForFilterOption:(MongoLogFilterOption) filterOption {
    switch (filterOption) {
        case MongoLogFilterOptionGlobal: return @"global";
        case MongoLogFilterOptionReplicaSet: return @"rs";
        case MongoLogFilterOptionStartupWarnings: return @"startupWarnings";
        default: return nil;
    }
}

- (NSArray *) serverLogMessagesWithFilter:(MongoLogFilterOption) filterOption {
    NSString *filterOptionString = [self.class _stringForFilterOption:filterOption];
    if (!filterOptionString)
        [NSException raise:NSInvalidArgumentException format:@"Invalid filter option"];
    NSDictionary *command = @{ @"getLog" : filterOptionString };
    NSDictionary *response = [self runCommandWithDictionary:command onDatabaseName:@"admin" error:nil];
    return [response objectForKey:@"log"];
}

- (NSArray *) allDatabases {
    NSDictionary *dict = [self runCommandWithName:@"listDatabases" onDatabaseName:@"admin" error:nil];
    NSMutableArray *result = [NSMutableArray array];
    for (NSDictionary *db in [dict objectForKey:@"databases"])
        [result addObject:[db objectForKey:@"name"]];
    return [NSArray arrayWithArray:result];
}

- (NSArray *) allCommands {
    NSDictionary *dict = [self runCommandWithName:@"listCommands" onDatabaseName:@"admin" error:nil];
    return [dict objectForKey:@"commands"];
}

- (BOOL) pingWithError:(NSError * __autoreleasing *) outError {
    NSError *error = nil;
    [self runCommandWithName:@"ping" onDatabaseName:@"admin" error:&error];
    if (outError) *outError = error;
    return error == nil;
}

@end
