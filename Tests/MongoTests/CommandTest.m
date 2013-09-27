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

#import <SenTestingKit/SenTestingKit.h>
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
    STAssertNotNil(version, nil);
    STAssertTrue(version.length > 3, nil);
}

- (void) testServerVersion {
    NSError *error = nil;
    NSDictionary *result = [self.mongo runCommandWithName:@"buildInfo"
                                           onDatabaseName:@"admin"
                                                    error:&error];
    NSString *myVersion = [result objectForKey:@"version"];

    NSString *version = [self.mongo serverVersion];
    
    STAssertEqualObjects(myVersion, version, nil);
}

- (void) testMaxBSONSize {
    NSUInteger maxSize = [self.mongo serverMaxBSONObjectSize];
    // Let's make sure it's in a realistic range - 4 MB to 1024 MB
    STAssertTrue(maxSize > 4 * 1024 * 1024, nil);
    STAssertTrue(maxSize < 1024 * 1024 * 1024, nil);
}

- (void) testStorageStats {
    NSDictionary *result = [self.mongo storageStatisticsForDatabaseName:@"admin" scale:1024];
    STAssertEqualObjects([result objectForKey:@"db"], @"admin", nil);
    STAssertEqualObjects([result objectForKey:@"ok"], @(1), nil);    
}

- (void) testServerLog {
    NSArray *result = [self.mongo serverLogMessagesWithFilter:MongoLogFilterOptionGlobal];
    // There should be some stuff in this result
    STAssertTrue(result.count > 10, nil);
}

- (void) testAllDatabases {
    // Create a test collection, to ensure that admin exists
    declare_coll_and_error;
    [coll insertDictionary:[NSDictionary dictionary] writeConcern:nil error:&error];

    NSArray *list = [self.mongo allDatabases];
    STAssertTrue([list containsObject:@"admin"], nil);
    STAssertTrue([list containsObject:@"local"], nil);
}

- (void) testPing {
    STAssertTrue([self.mongo pingWithError:nil], nil);
}

- (void) testListCommands {
    id commands = [self.mongo allCommands];
    STAssertTrue([[commands allKeys] containsObject:@"dropDatabase"], nil);
    STAssertTrue([[commands allKeys] containsObject:@"getLastError"], nil);
}

- (void) testIsMaster {
    id result = [self.mongo serverReplicationInfo];
    STAssertEqualObjects([result objectForKey:@"ok"], @(1), nil);
}

- (void) testServerStatus {
    id result = [self.mongo serverStatus];
    STAssertNotNil([result objectForKey:@"version"], nil);
    STAssertNotNil([result objectForKey:@"host"], nil);
    STAssertNotNil([result objectForKey:@"process"], nil);
}

- (void) testDropCollection {
    declare_coll_and_error;
    NSDictionary *testDoc =
    @{
      @"description" : @"pickles",
      @"quantity" : @(5),
      @"price" : @(2.99),
      @"ingredients" : @[ @"cucumbers", @"water", @"salt" ],
      @"sizes" : @[ @(16), @(32), @(48) ],
      };
    [coll insertDictionary:testDoc writeConcern:nil error:&error];
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

- (void) testGetIndexes {
    declare_coll_and_error;
    [coll dropCollectionWithError:nil];
    
    NSDictionary *testDoc =
    @{
      @"description" : @"pickles",
      @"quantity" : @(5),
      @"price" : @(2.99),
      @"ingredients" : @[ @"cucumbers", @"water", @"salt" ],
      @"sizes" : @[ @(16), @(32), @(48) ],
      };
    [coll insertDictionary:testDoc writeConcern:nil error:&error];
    STAssertNil(error, nil);
    
    NSArray *indexes = [coll allIndexesWithError:&error];
    STAssertEquals([indexes count], (NSUInteger)1, nil);
    
    MongoMutableIndex *index = [MongoMutableIndex mutableIndex];
    [index addField:@"foo" ascending:YES];
    STAssertTrue([coll ensureIndex:index error:&error], nil);
    STAssertNil(error, nil);
    
    indexes = [coll allIndexesWithError:&error];
    STAssertEquals([indexes count], (NSUInteger)2, nil);
}

- (void) testEnsureIndex {
    declare_coll_and_error;
    [coll dropCollectionWithError:nil];

    NSDictionary *testDoc =
    @{
      @"description" : @"pickles",
      @"quantity" : @(5),
      @"price" : @(2.99),
      @"ingredients" : @[ @"cucumbers", @"water", @"salt" ],
      @"sizes" : @[ @(16), @(32), @(48) ],
      };
    [coll insertDictionary:testDoc writeConcern:nil error:&error];
    STAssertNil(error, nil);

    MongoMutableIndex *index = [MongoMutableIndex mutableIndex];
    index.name = @"desc";
    [index addField:@"description" ascending:YES];
    STAssertTrue([coll ensureIndex:index error:&error], nil);
    STAssertNil(error, nil);

    NSArray *indexes = [coll allIndexesWithError:&error];
    STAssertEquals([indexes count], (NSUInteger)2, nil);
    BOOL ok = NO;
    for (MongoIndex *item in indexes) {
        if ([@"_id_" isEqual:item.name] &&
            1 == item.fields.allKeys.count &&
            [@(1) isEqual:[item.fields objectForKey:@"_id"]]) {
            ok = YES;
            break;
        }
    }
    STAssertTrue(ok, nil);
    ok = NO;
    for (MongoIndex *item in indexes) {
        if ([@"desc" isEqual:item.name] &&
            1 == item.fields.allKeys.count &&
            [@(1) isEqual:[item.fields objectForKey:@"description"]]) {
            ok = YES;
            break;
        }
    }
    STAssertTrue(ok, nil);
}

- (void) testEnsureIndexFailure {
    declare_coll_and_error;
    [coll dropCollectionWithError:nil];

    MongoMutableIndex *nullIndex = [MongoMutableIndex mutableIndex];
    STAssertThrows([coll ensureIndex:nullIndex error:&error], nil);
    
    // Attempt to create 64 indexes, which should cause the database to throw an error, since indexes are limited
    // to 64 per collection. They start with one on _id.
    for (NSUInteger i = 1; i<=64; ++i) {
        MongoMutableIndex *index = [MongoMutableIndex mutableIndex];
        [index addField:[NSString stringWithFormat:@"field%lu", (unsigned long) i] ascending:YES];
        if (i < 64)
            STAssertTrue([coll ensureIndex:index error:&error], nil);
        else {
            error = nil;
            STAssertFalse([coll ensureIndex:index error:&error], nil);
            STAssertNotNil(error, nil);
        }
    }
}

@end
