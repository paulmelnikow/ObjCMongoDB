//
//  CommandTest.m
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 2/11/13.
//
//

#import "CommandTest.h"
#import "ObjCMongoDB.h"

@implementation CommandTest {
    MongoConnection *_mongo;
}

-(void) setUp {
    NSError *error = nil;
    _mongo = [MongoConnection connectionForServer:@"127.0.0.1" error:&error];
    STAssertNil(error, error.localizedDescription);
}

- (void) tearDown {
    [_mongo disconnect];
    _mongo = nil;
}

- (void) testBuildInfo {
    NSError *error = nil;
    NSDictionary *result = [_mongo runCommandWithName:@"buildInfo"
                                       onDatabaseName:@"admin"
                                                error:&error];
    NSString *version = [result objectForKey:@"version"];
    STAssertNotNil(version, nil);
    STAssertTrue(version.length > 3, nil);
}

- (void) testServerVersion {
    NSError *error = nil;
    NSDictionary *result = [_mongo runCommandWithName:@"buildInfo"
                                       onDatabaseName:@"admin"
                                                error:&error];
    NSString *myVersion = [result objectForKey:@"version"];

    NSString *version = [_mongo serverVersion];
    
    STAssertEqualObjects(myVersion, version, nil);
}

- (void) testMaxBSONSize {
    NSUInteger maxSize = [_mongo serverMaxBSONObjectSize];
    // Let's make sure it's in a realistic range - 4 MB to 1024 MB
    STAssertTrue(maxSize > 4 * 1024 * 1024, nil);
    STAssertTrue(maxSize < 1024 * 1024 * 1024, nil);
}

- (void) testStorageStats {
    NSDictionary *result = [_mongo storageStatisticsForDatabaseName:@"admin" scale:1024];
    STAssertEqualObjects([result objectForKey:@"db"], @"admin", nil);
    STAssertEqualObjects([result objectForKey:@"ok"], @(1), nil);    
}

- (void) testServerLog {
    NSArray *result = [_mongo serverLogMessagesWithFilter:MongoLogFilterOptionGlobal];
    // There should be some stuff in this result
    STAssertTrue(result.count > 10, nil);
}

- (void) testAllDatabases {
    NSArray *list = [_mongo allDatabases];
    STAssertTrue([list containsObject:@"admin"], nil);
    STAssertTrue([list containsObject:@"local"], nil);
}

- (void) testPing {
    STAssertTrue([_mongo pingWithError:nil], nil);
}

- (void) testListCommands {
    id commands = [_mongo allCommands];
    STAssertTrue([[commands allKeys] containsObject:@"dropDatabase"], nil);
    STAssertTrue([[commands allKeys] containsObject:@"getLastError"], nil);
}

- (void) testIsMaster {
    id result = [_mongo serverReplicationInfo];
    STAssertEqualObjects([result objectForKey:@"ok"], @(1), nil);
}

- (void) testServerStatus {
    id result = [_mongo serverStatus];
    STAssertNotNil([result objectForKey:@"version"], nil);
    STAssertNotNil([result objectForKey:@"host"], nil);
    STAssertNotNil([result objectForKey:@"process"], nil);
}

@end
