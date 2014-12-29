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

#import "MongoTest.h"
#import "MongoKeyedPredicate.h"
#import "MongoFindRequest.h"
#import "MongoTests_Helper.h"

@interface FindTest : MongoTest
@end

@implementation FindTest

- (void) insertTestDocument:(MongoDBCollection *) collection {
    NSDictionary *testDoc =
    @{
      @"description" : @"pickles",
      @"quantity" : @(5),
      @"price" : @(2.99),
      @"ingredients" : @[ @"cucumbers", @"water", @"salt" ],
      @"sizes" : @[ @(16), @(32), @(48) ],
      };
    NSError *error = nil;
    [collection insertDictionary:testDoc writeConcern:nil error:&error];
    XCTAssertNil(error);
}

- (void) testFindOne {
    // Test basic instance of -findOneWithError:, -findOneWithPredicate:error:, and -findOne:error:
    BSONDocument *resultDoc = nil; NSDictionary *resultDict = nil;
    
    declare_coll_and_error;
    NSDictionary *testDoc1 = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"pickles1", @"description",
                             [NSNumber numberWithInt:5], @"quantity",
                             [NSNumber numberWithFloat:2.99], @"price",
                             [NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil], @"ingredients",
                             [NSArray arrayWithObjects:[NSNumber numberWithInt:16], [NSNumber numberWithInt:32], [NSNumber numberWithInt:48], nil], @"sizes",
                             nil];
    [coll insertDictionary:testDoc1 writeConcern:nil error:&error];
    XCTAssertNil(error);
    
    error = nil;
    NSDictionary *testDoc2 = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"pickles2", @"description",
                             [NSNumber numberWithInt:5], @"quantity",
                             [NSNumber numberWithFloat:2.99], @"price",
                             [NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil], @"ingredients",
                             [NSArray arrayWithObjects:[NSNumber numberWithInt:16], [NSNumber numberWithInt:32], [NSNumber numberWithInt:48], nil], @"sizes",
                             nil];
    [coll insertDictionary:testDoc2 writeConcern:nil error:&error];
    XCTAssertNil(error);

    error = nil;
    NSDictionary *testDoc3 = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"pickles3", @"description",
                              [NSNumber numberWithInt:5], @"quantity",
                              [NSNumber numberWithFloat:2.99], @"price",
                              [NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil], @"ingredients",
                              [NSArray arrayWithObjects:[NSNumber numberWithInt:16], [NSNumber numberWithInt:32], [NSNumber numberWithInt:48], nil], @"sizes",
                              nil];
    [coll insertDictionary:testDoc3 writeConcern:nil error:&error];
    XCTAssertNil(error);
    
    XCTFail(@"TODO");
//    error = nil;
//    resultDoc = [coll findOneWithError:&error];
//    XCTAssertNotNil(resultDoc); XCTAssertNil(error);
//    resultDict = [resultDoc dictionaryValue];
//    XCTAssertEqualObjects([NSNumber numberWithInt:5], [resultDict objectForKey:@"quantity"]);
//
//    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
//    [pred1 keyPath:@"description" matches:@"pickles2"];
//    error = nil;
//    resultDoc = [coll findOneWithPredicate:pred1 error:&error];
//    XCTAssertNotNil(resultDoc); XCTAssertNil(error);
//    resultDict = [resultDoc dictionaryValue];
//    XCTAssertEqualObjects(@"pickles2", [resultDict objectForKey:@"description"]);
//    XCTAssertEqualObjects([NSNumber numberWithInt:5], [resultDict objectForKey:@"quantity"]);
//    
//    MongoFindRequest *req1 = [MongoFindRequest findRequestWithPredicate:pred1];
//    [req1 includeKey:@"description"];
//    [req1 includeKey:@"price"];
//    error = nil;
//    resultDoc = [coll findOneWithRequest:req1 error:&error];
//    XCTAssertNotNil(resultDoc); XCTAssertNil(error);
//    resultDict = [resultDoc dictionaryValue];
//    XCTAssertEqualObjects(@"pickles2", [resultDict objectForKey:@"description"]);
//    XCTAssertEqualObjects([NSNumber numberWithFloat:2.99], [resultDict objectForKey:@"price"]);
//    XCTAssertNil([resultDict objectForKey:@"quantity"]);
}

@end
