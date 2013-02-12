//
//  MongoConnection+Commands.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 2/11/13.
//
//

#import <ObjCMongoDB/ObjCMongoDB.h>

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
