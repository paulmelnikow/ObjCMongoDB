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

- (void) testDropCollection {
    MongoDBCollection *coll = [_mongo collectionWithName:@"objcmongodbtest.CommandTest.testDropCollection"];
    NSError *error = nil;
    NSDictionary *testDoc1 = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"pickles1", @"description",
                              [NSNumber numberWithInt:5], @"quantity",
                              [NSNumber numberWithFloat:2.99], @"price",
                              [NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil], @"ingredients",
                              [NSArray arrayWithObjects:[NSNumber numberWithInt:16], [NSNumber numberWithInt:32], [NSNumber numberWithInt:48], nil], @"sizes",
                              nil];
    [coll insertDictionary:testDoc1 writeConcern:nil error:&error];
    STAssertNil(error, nil);
    
    BSONDocument *resultDoc = [coll findOneWithError:&error];
    STAssertNotNil(resultDoc, nil);
    STAssertNil(error, error.localizedDescription);

    error = nil;
    STAssertTrue([coll dropCollectionWithError:&error], nil);
    STAssertNil(error, error.localizedDescription);
    
    resultDoc = [coll findOneWithError:&error];
    STAssertNil(resultDoc, nil);
    
    error = nil;
    STAssertFalse([coll dropCollectionWithError:&error], @"Shouldn't be able to drop the collection a second time");
    STAssertNotNil(error, error.localizedDescription);
}

@end
