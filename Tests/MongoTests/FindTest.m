//
//  DBCollectionTest.m
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

#import "FindTest.h"
#import "MongoKeyedPredicate.h"
#import "MongoFindRequest.h"

@implementation FindTest

- (void) setUp {
    NSError *error = nil;
    _mongo = [MongoConnection connectionForServer:@"127.0.0.1" error:&error];
    STAssertNil(error, error.localizedDescription);
}

- (void) tearDown {
    [_mongo disconnect];
    _mongo = nil;
}

- (void) insertTestDocument:(MongoDBCollection *) collection {
    NSDictionary *testDoc = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"pickles", @"description",
                             [NSNumber numberWithInt:5], @"quantity",
                             [NSNumber numberWithFloat:2.99], @"price",
                             [NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil], @"ingredients",
                             [NSArray arrayWithObjects:[NSNumber numberWithInt:16], [NSNumber numberWithInt:32], [NSNumber numberWithInt:48], nil], @"sizes",
                             nil];
    NSError *error = nil;
    [collection insertDictionary:testDoc error:&error];
    STAssertNil(error, error.localizedDescription);
}

- (void) testFindOne {
    // Test basic instance of -findOneWithError:, -findOneWithPredicate:error:, and -findOne:error:
    NSError *error = nil; BSONDocument *resultDoc = nil; NSDictionary *resultDict = nil;
    
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.DBCollection.testFindOne"];    
    NSDictionary *testDoc1 = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"pickles1", @"description",
                             [NSNumber numberWithInt:5], @"quantity",
                             [NSNumber numberWithFloat:2.99], @"price",
                             [NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil], @"ingredients",
                             [NSArray arrayWithObjects:[NSNumber numberWithInt:16], [NSNumber numberWithInt:32], [NSNumber numberWithInt:48], nil], @"sizes",
                             nil];
    [coll insertDictionary:testDoc1 error:&error];
    STAssertNil(error, error.localizedDescription);
    
    error = nil;
    NSDictionary *testDoc2 = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"pickles2", @"description",
                             [NSNumber numberWithInt:5], @"quantity",
                             [NSNumber numberWithFloat:2.99], @"price",
                             [NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil], @"ingredients",
                             [NSArray arrayWithObjects:[NSNumber numberWithInt:16], [NSNumber numberWithInt:32], [NSNumber numberWithInt:48], nil], @"sizes",
                             nil];
    [coll insertDictionary:testDoc2 error:&error];
    STAssertNil(error, error.localizedDescription);

    error = nil;
    NSDictionary *testDoc3 = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"pickles3", @"description",
                              [NSNumber numberWithInt:5], @"quantity",
                              [NSNumber numberWithFloat:2.99], @"price",
                              [NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil], @"ingredients",
                              [NSArray arrayWithObjects:[NSNumber numberWithInt:16], [NSNumber numberWithInt:32], [NSNumber numberWithInt:48], nil], @"sizes",
                              nil];
    [coll insertDictionary:testDoc3 error:&error];
    STAssertNil(error, error.localizedDescription);
    
    error = nil;
    resultDoc = [coll findOneWithError:&error];
    STAssertNotNil(resultDoc, nil); STAssertNil(error, error.localizedDescription);
    resultDict = [resultDoc dictionaryValue];
    STAssertEqualObjects([NSNumber numberWithInt:5], [resultDict objectForKey:@"quantity"], nil);

    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:@"description" matches:@"pickles2"];
    error = nil;
    resultDoc = [coll findOneWithPredicate:pred1 error:&error];
    STAssertNotNil(resultDoc, nil); STAssertNil(error, error.localizedDescription);
    resultDict = [resultDoc dictionaryValue];
    STAssertEqualObjects(@"pickles2", [resultDict objectForKey:@"description"], nil);
    STAssertEqualObjects([NSNumber numberWithInt:5], [resultDict objectForKey:@"quantity"], nil);
    
    MongoFindRequest *req1 = [MongoFindRequest findRequestWithPredicate:pred1];
    [req1 includeKey:@"description"];
    [req1 includeKey:@"price"];
    error = nil;
    resultDoc = [coll findOneWithRequest:req1 error:&error];
    STAssertNotNil(resultDoc, nil); STAssertNil(error, error.localizedDescription);
    resultDict = [resultDoc dictionaryValue];
    STAssertEqualObjects(@"pickles2", [resultDict objectForKey:@"description"], nil);
    STAssertEqualObjects([NSNumber numberWithFloat:2.99], [resultDict objectForKey:@"price"], nil);
    STAssertNil([resultDict objectForKey:@"quantity"], nil);
}

@end
