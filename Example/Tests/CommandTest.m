//
//  CommandTest.m
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

#import <XCTest/XCTest.h>
#import "MongoTest.h"
#import "ObjCMongoDB.h"
#import "MongoTests_Helper.h"

@interface CommandTest : MongoTest
@end

@implementation CommandTest

- (void) testBuildInfo {
    NSError *error = nil;
    NSDictionary *result = [self.mongo runCommandWithName:@"buildInfo"
                                           onDatabaseName:@"admin"
                                                    error:&error];
    NSString *version = [result objectForKey:@"version"];
    XCTAssertNotNil(version);
    XCTAssertTrue(version.length > 3);
}

- (void) testCommandDictionary {
    XCTFail(@"TODO");
//    declare_coll_and_error;
//    
//    NSDictionary *testDoc1 = @{@"foo": @1};
//    [coll insertDictionary:testDoc1 writeConcern:nil error:&error];
//    XCTAssertNil(error);
//
//    NSDictionary *testDoc2 = @{@"foo": @2};
//    [coll insertDictionary:testDoc2 writeConcern:nil error:&error];
//    XCTAssertNil(error);
//    
//    MutableOrderedDictionary *command = [MutableOrderedDictionary dictionary];
//    [command setObject:coll.namespaceName forKey:@"distinct"];
//    [command setObject:@"foo" forKey:@"key"];
//    
//    NSDictionary *result = [self.mongo runCommandWithOrderedDictionary:command
//                                                        onDatabaseName:TEST_DATABASE
//                                                                 error:&error];
//    XCTAssertNotNil(result);
//    XCTAssertEqualObjects([result objectForKey:@"ok"], @1);
//    
//    NSArray *values = [result objectForKey:@"values"];
//    XCTAssertTrue([values containsObject:@1]);
//    XCTAssertTrue([values containsObject:@2]);
}

- (void) testServerVersion {
    NSError *error = nil;
    NSDictionary *result = [self.mongo runCommandWithName:@"buildInfo"
                                           onDatabaseName:@"admin"
                                                    error:&error];
    NSString *myVersion = [result objectForKey:@"version"];

    NSString *version = [self.mongo serverVersion];
    
    XCTAssertEqualObjects(myVersion, version);
}

- (void) testMaxBSONSize {
    NSUInteger maxSize = [self.mongo serverMaxBSONObjectSize];
    // Let's make sure it's in a realistic range - 4 MB to 1024 MB
    XCTAssertTrue(maxSize > 4 * 1024 * 1024);
    XCTAssertTrue(maxSize < 1024 * 1024 * 1024);
}

- (void) testStorageStats {
    NSDictionary *result = [self.mongo storageStatisticsForDatabaseName:@"admin" scale:1024];
    XCTAssertEqualObjects([result objectForKey:@"db"], @"admin");
    XCTAssertEqualObjects([result objectForKey:@"ok"], @(1));
}

- (void) testServerLog {
    NSArray *result = [self.mongo serverLogMessagesWithFilter:MongoLogFilterOptionGlobal];
    // There should be some stuff in this result
    XCTAssertTrue(result.count > 10);
}

- (void) testAllDatabases {
    // Create a test collection, to ensure that admin exists
    declare_coll_and_error;
    [coll insertDictionary:[NSDictionary dictionary] writeConcern:nil error:&error];

    NSArray *list = [self.mongo allDatabases];
    XCTAssertTrue([list containsObject:TEST_DATABASE]);
    XCTAssertTrue([list containsObject:@"local"]);
}

- (void) testPing {
    XCTAssertTrue([self.mongo pingWithError:nil]);
}

- (void) testListCommands {
    id commands = [self.mongo allCommands];
    XCTAssertTrue([[commands allKeys] containsObject:@"dropDatabase"]);
    XCTAssertTrue([[commands allKeys] containsObject:@"getLastError"]);
}

- (void) testIsMaster {
    id result = [self.mongo serverReplicationInfo];
    XCTAssertEqualObjects([result objectForKey:@"ok"], @(1));
}

- (void) testServerStatus {
    id result = [self.mongo serverStatus];
    XCTAssertNotNil([result objectForKey:@"version"]);
    XCTAssertNotNil([result objectForKey:@"host"]);
    XCTAssertNotNil([result objectForKey:@"process"]);
}

- (void) testDropCollection {
    XCTFail(@"TODO");
//    declare_coll_and_error;
//    NSDictionary *testDoc =
//    @{
//      @"description" : @"pickles",
//      @"quantity" : @(5),
//      @"price" : @(2.99),
//      @"ingredients" : @[ @"cucumbers", @"water", @"salt" ],
//      @"sizes" : @[ @(16), @(32), @(48) ],
//      };
//    [coll insertDictionary:testDoc writeConcern:nil error:&error];
//    XCTAssertNil(error);
//    
//    BSONDocument *resultDoc = [coll findOneWithError:&error];
//    XCTAssertNotNil(resultDoc);
//    XCTAssertNil(error);
//
//    error = nil;
//    XCTAssertTrue([coll dropCollectionWithError:&error]);
//    XCTAssertNil(error);
//    
//    resultDoc = [coll findOneWithError:&error];
//    XCTAssertNil(resultDoc);
//    
//    error = nil;
//    XCTAssertFalse([coll dropCollectionWithError:&error], @"Shouldn't be able to drop the collection a second time");
//    XCTAssertNotNil(error);
}

- (void) testGetIndexes {
    XCTFail(@"TODO");
//    declare_coll_and_error;
//    [coll dropCollectionWithError:nil];
//    
//    NSDictionary *testDoc =
//    @{
//      @"description" : @"pickles",
//      @"quantity" : @(5),
//      @"price" : @(2.99),
//      @"ingredients" : @[ @"cucumbers", @"water", @"salt" ],
//      @"sizes" : @[ @(16), @(32), @(48) ],
//      };
//    [coll insertDictionary:testDoc writeConcern:nil error:&error];
//    XCTAssertNil(error);
//    
//    NSArray *indexes = [coll allIndexesWithError:&error];
//    XCTAssertEqual([indexes count], (NSUInteger)1);
//    
//    MongoMutableIndex *index = [MongoMutableIndex mutableIndex];
//    [index addField:@"foo" ascending:YES];
//    XCTAssertTrue([coll ensureIndex:index error:&error]);
//    XCTAssertNil(error);
//    
//    indexes = [coll allIndexesWithError:&error];
//    XCTAssertEqual([indexes count], (NSUInteger)2);
}

- (void) testEnsureIndex {
    XCTFail(@"TODO");
//    declare_coll_and_error;
//    [coll dropCollectionWithError:nil];
//
//    NSDictionary *testDoc =
//    @{
//      @"description" : @"pickles",
//      @"quantity" : @(5),
//      @"price" : @(2.99),
//      @"ingredients" : @[ @"cucumbers", @"water", @"salt" ],
//      @"sizes" : @[ @(16), @(32), @(48) ],
//      };
//    [coll insertDictionary:testDoc writeConcern:nil error:&error];
//    XCTAssertNil(error);
//
//    MongoMutableIndex *index = [MongoMutableIndex mutableIndex];
//    index.name = @"desc";
//    [index addField:@"description" ascending:YES];
//    XCTAssertTrue([coll ensureIndex:index error:&error]);
//    XCTAssertNil(error);
//
//    NSArray *indexes = [coll allIndexesWithError:&error];
//    XCTAssertEqual([indexes count], (NSUInteger)2);
//    BOOL ok = NO;
//    for (MongoIndex *item in indexes) {
//        if ([@"_id_" isEqual:item.name] &&
//            1 == item.fields.allKeys.count &&
//            [@(1) isEqual:[item.fields objectForKey:@"_id"]]) {
//            ok = YES;
//            break;
//        }
//    }
//    XCTAssertTrue(ok);
//    ok = NO;
//    for (MongoIndex *item in indexes) {
//        if ([@"desc" isEqual:item.name] &&
//            1 == item.fields.allKeys.count &&
//            [@(1) isEqual:[item.fields objectForKey:@"description"]]) {
//            ok = YES;
//            break;
//        }
//    }
//    XCTAssertTrue(ok);
}

- (void) testEnsureIndexFailure {
    XCTFail(@"TODO");
//    declare_coll_and_error;
//    [coll dropCollectionWithError:nil];
//
//    MongoMutableIndex *nullIndex = [MongoMutableIndex mutableIndex];
//    XCTAssertThrows([coll ensureIndex:nullIndex error:&error]);
//    
//    // Attempt to create 64 indexes, which should cause the database to throw an error, since indexes are limited
//    // to 64 per collection. They start with one on _id.
//    for (NSUInteger i = 1; i<=64; ++i) {
//        MongoMutableIndex *index = [MongoMutableIndex mutableIndex];
//        [index addField:[NSString stringWithFormat:@"field%lu", (unsigned long) i] ascending:YES];
//        if (i < 64)
//            XCTAssertTrue([coll ensureIndex:index error:&error]);
//        else {
//            error = nil;
//            XCTAssertFalse([coll ensureIndex:index error:&error]);
//            XCTAssertNotNil(error);
//        }
//    }
}

@end
