//
//  PredicateTest.m
//  ObjCMongoDB
//
//  Copyright 2012 Paul Melnikow and other contributors
//  Based on QueryBuilderTest.java from the official Java driver Copyright (c) 2010 10gen Inc.
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
#import "MongoPredicate.h"
#import "MongoKeyedPredicate.h"
#import <BSONTypes.h>
#import "MongoTests_Helper.h"
#import <OrderedDictionary.h>

@interface PredicateTest : MongoTest

@end


@implementation PredicateTest

- (void) insertTestDocument:(MongoDBCollection *) collection key:(NSString *) key value: (id) value {
    id dict = [NSDictionary dictionaryWithObject:value forKey:key];
    NSError *error = nil;
    [collection insertDictionary:dict writeConcern:nil error:&error];
    XCTAssertNil(error);
}

- (BOOL) collectionWithName:(MongoDBCollection *) collection boolForPredicate:(MongoPredicate *) predicate {
    NSError *error = nil;
    NSUInteger result = [collection countWithPredicate:predicate error:&error];
    XCTAssertNil(error);
    return result > 0;
}

- (void) testGreaterThan {
    NSString *key = @"x";
    declare_coll;
    
    [self insertTestDocument:coll key:key value:[NSNumber numberWithInt:0]];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key isGreaterThan:[NSNumber numberWithInt:-1]];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred1]);
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key isGreaterThan:[NSNumber numberWithInt:0]];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred2]);
}

- (void) testGreaterThanOrEqualTo {
    NSString *key = @"x";
    declare_coll;
    
    [self insertTestDocument:coll key:key value:[NSNumber numberWithInt:0]];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key isGreaterThanOrEqualTo:[NSNumber numberWithInt:0]];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred1]);
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key isGreaterThanOrEqualTo:[NSNumber numberWithInt:-1]];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred2]);
    
    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key isGreaterThanOrEqualTo:[NSNumber numberWithInt:1]];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred3]);    
}

- (void) testLessThan {
    NSString *key = @"x";
    declare_coll;
    
    [self insertTestDocument:coll key:key value:[NSNumber numberWithInt:0]];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key isLessThan:[NSNumber numberWithInt:1]];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred1]);
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key isLessThan:[NSNumber numberWithInt:0]];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred2]);
}

- (void) testLessThanOrEqualTo {
    NSString *key = @"x";
    declare_coll;
    
    [self insertTestDocument:coll key:key value:[NSNumber numberWithInt:0]];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key isLessThanOrEqualTo:[NSNumber numberWithInt:1]];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred1]);
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key isLessThanOrEqualTo:[NSNumber numberWithInt:0]];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred2]);
    
    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key isLessThanOrEqualTo:[NSNumber numberWithInt:-1]];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred3]);    
}

- (void) testMatches {
    NSString *key = @"x";
    declare_coll;
    
    [self insertTestDocument:coll key:key value:@"test"];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key matches:@"test"];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred1]);
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key matches:@"test1"];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred2]);
    
    XCTFail(@"TODO");

//    coll = [self.mongo collectionWithName:[NSString stringWithFormat:@"%@2", coll.fullyQualifiedName]];
//    
//    id value = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
//    [self insertTestDocument:coll key:key value:value];
//    
//    pred1 = [MongoKeyedPredicate predicate];
//    [pred1 keyPath:key matches:@"c"];
//    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred1]);
//    
//    pred2 = [MongoKeyedPredicate predicate];
//    [pred2 keyPath:key matches:@"f"];
//    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred2]);
}

- (void) testIsNotEqualTo {
    NSString *key = @"x";
    declare_coll;
    
    [self insertTestDocument:coll key:key value:@"test"];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key isNotEqualTo:@"test1"];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred1]);
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key isNotEqualTo:@"test"];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred2]);
}

- (void) testModulus {
    NSString *key = @"x";
    declare_coll;
    
    [self insertTestDocument:coll key:key value:[NSNumber numberWithInt:9]];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key isEquivalentTo:1 modulo:2];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred1]);
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key isEquivalentTo:0 modulo:2];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred2]);
}

- (void) testMatchesAny {
    NSString *key = @"x";
    declare_coll;
    
    [self insertTestDocument:coll key:key value:@"a"];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key matchesAnyObjects:@"c", @"b", @"a", nil];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred1]);

    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key matchesAnyFromArray:[NSArray arrayWithObjects:@"c", @"b", @"a", nil]];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred2]);
    
    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key matchesAnyObjects:@"d", @"f", @"g", nil];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred3]);

    MongoKeyedPredicate *pred4 = [MongoKeyedPredicate predicate];
    [pred4 keyPath:key matchesAnyFromArray:[NSArray arrayWithObjects:@"d", @"f", @"g", nil]];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred4]);
}

- (void) testDoesNotMatchAny {
    NSString *key = @"x";
    declare_coll;
    
    [self insertTestDocument:coll key:key value:@"a"];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key doesNotMatchAnyObjects:@"c", @"b", @"a", nil];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred1]);
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key doesNotMatchAnyFromArray:[NSArray arrayWithObjects:@"c", @"b", @"a", nil]];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred2]);
    
    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key doesNotMatchAnyObjects:@"d", @"f", @"g", nil];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred3]);
    
    MongoKeyedPredicate *pred4 = [MongoKeyedPredicate predicate];
    [pred4 keyPath:key doesNotMatchAnyFromArray:[NSArray arrayWithObjects:@"d", @"f", @"g", nil]];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred4]);
}

- (void) testArrayContainsAll {
    NSString *key = @"x";
    declare_coll;
    
    id value = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    [self insertTestDocument:coll key:key value:value];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key arrayContainsAllObjects:@"c", @"b", @"a", nil];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred1]);
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key arrayContainsAllFromArray:[NSArray arrayWithObjects:@"c", @"b", @"a", nil]];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred2]);
    
    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key arrayContainsAllObjects:@"c", @"d", nil];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred3]);
    
    MongoKeyedPredicate *pred4 = [MongoKeyedPredicate predicate];
    [pred4 keyPath:key arrayContainsAllFromArray:[NSArray arrayWithObjects:@"c", @"d", nil]];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred4]);
}

- (void) testArrayDoesNotContainAll {
    NSString *key = @"x";
    declare_coll;
    
    id value = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    [self insertTestDocument:coll key:key value:value];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key arrayDoesNotContainAllObjects:@"c", @"b", @"a", nil];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred1]);
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key arrayDoesNotContainAllFromArray:[NSArray arrayWithObjects:@"c", @"b", @"a", nil]];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred2]);
    
    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key arrayDoesNotContainAllObjects:@"c", @"d", nil];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred3]);
    
    MongoKeyedPredicate *pred4 = [MongoKeyedPredicate predicate];
    [pred4 keyPath:key arrayDoesNotContainAllFromArray:[NSArray arrayWithObjects:@"c", @"d", nil]];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred4]);
}

- (void) testArraySize {
    NSString *key = @"x";
    declare_coll;
    
    id value = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    [self insertTestDocument:coll key:key value:value];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key arrayCountIsEqualTo:2];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred1]);
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key arrayCountIsEqualTo:3];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred2]);
    
    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key arrayCountIsEqualTo:4];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred3]);
    
    pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key arrayCountIsNotEqualTo:2];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred1]);
    
    pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key arrayCountIsNotEqualTo:3];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred2]);
    
    pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key arrayCountIsNotEqualTo:4];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred3]);
}

- (void) testRegexMatches {
    NSString *key = @"x";
    declare_coll;
    
    [self insertTestDocument:coll key:key value:@"test"];
    
    BSONRegularExpression *matchingRegex = [[BSONRegularExpression alloc] init];
    matchingRegex.pattern = @"\\w*$";

    BSONRegularExpression *noMatchRegex = [[BSONRegularExpression alloc] init];
    noMatchRegex.pattern = @"nomatch";

    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key matchesRegularExpression:matchingRegex];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred1]);
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key matchesRegularExpression:noMatchRegex];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred2]);
    
    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key doesNotMatchRegularExpression:matchingRegex];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred3]);
    
    MongoKeyedPredicate *pred4 = [MongoKeyedPredicate predicate];
    [pred4 keyPath:key doesNotMatchRegularExpression:noMatchRegex];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred4]);
}

- (void) testRange {
    NSString *key = @"x";
    declare_coll;
    
    [self insertTestDocument:coll key:key value:[NSNumber numberWithInt:4]];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key isGreaterThan:[NSNumber numberWithInt:0]];
    [pred1 keyPath:key isLessThan:[NSNumber numberWithInt:5]];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred1]);
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key isGreaterThan:[NSNumber numberWithInt:0]];
    [pred2 keyPath:key isLessThan:[NSNumber numberWithInt:3]];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred2]);    
}

- (void) testMultipleKeys {
    NSString *key1 = @"x";
    NSString *key2 = @"y";
    NSString *value = @"val";
    declare_coll;

    id dict = [NSDictionary dictionaryWithObjectsAndKeys:
               value, key1,
               [NSNumber numberWithInt:9], key2,
               nil];

    NSError *error = nil;
    [coll insertDictionary:dict writeConcern:nil error:&error];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key2 isEquivalentTo:1 modulo:2];
    [pred1 keyPath:key1 matches:value];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred1]);    
}

- (void) testArrayMultiCond {
    NSString *key = @"x";
    declare_coll;
    
    id value = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    [self insertTestDocument:coll key:key value:value];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key arrayContainsAllObjects:@"c", @"b", @"a", nil];
    [pred1 keyPath:key arrayCountIsEqualTo:3];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred1]);
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key arrayContainsAllObjects:@"c", @"b", @"a", nil];
    [pred2 keyPath:key arrayCountIsEqualTo:4];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred2]);

    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key arrayContainsAllObjects:@"d", @"b", @"a", nil];
    [pred3 keyPath:key arrayCountIsEqualTo:3];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred2]);
}

- (void) testArrayElemMatch {
    NSString *key = @"x";
    declare_coll;
    
    id dict1 = [OrderedDictionary dictionaryWithObjectsAndKeys:
               @"apple", @"item",
               [NSNumber numberWithInt:3], @"count",
               nil];
    id dict2 = [OrderedDictionary dictionaryWithObjectsAndKeys:
                @"orange", @"item",
                [NSNumber numberWithInt:6], @"count",
                nil];

    [self insertTestDocument:coll key:key value:[NSArray arrayWithObjects:dict1, dict2, nil]];

    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    MongoKeyedPredicate *pred1a = [pred1 arrayElementMatchingSubPredicateForKeyPath:key];
    [pred1a keyPath:@"item" matches:@"apple"];
    [pred1a keyPath:@"count" isGreaterThan:[NSNumber numberWithInt:4]];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred1]);
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    MongoKeyedPredicate *pred2a = [pred2 arrayElementMatchingSubPredicateForKeyPath:key];
    [pred2a keyPath:@"item" matches:@"apple"];
    [pred2a keyPath:@"count" isGreaterThan:[NSNumber numberWithInt:1]];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred2]);

    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    MongoKeyedPredicate *pred3a = [pred3 arrayElementMatchingSubPredicateForKeyPath:key];
    [pred3a keyPath:@"item" matches:@"orange"];
    [pred3a keyPath:@"count" isGreaterThan:[NSNumber numberWithInt:4]];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred3]);
    
    MongoKeyedPredicate *pred4 = [MongoKeyedPredicate predicate];
    MongoKeyedPredicate *pred4a = [pred4 arrayElementMatchingSubPredicateForKeyPath:key negated:YES];
    [pred4a keyPath:@"item" matches:@"apple"];
    [pred4a keyPath:@"count" isGreaterThan:[NSNumber numberWithInt:4]];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred4]);
    
    MongoKeyedPredicate *pred5 = [MongoKeyedPredicate predicate];
    MongoKeyedPredicate *pred5a = [pred5 arrayElementMatchingSubPredicateForKeyPath:key negated:YES];
    [pred5a keyPath:@"item" matches:@"apple"];
    [pred5a keyPath:@"count" isGreaterThan:[NSNumber numberWithInt:1]];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred5]);
    
    MongoKeyedPredicate *pred6 = [MongoKeyedPredicate predicate];
    MongoKeyedPredicate *pred6a = [pred6 arrayElementMatchingSubPredicateForKeyPath:key negated:YES];
    [pred6a keyPath:@"item" matches:@"orange"];
    [pred6a keyPath:@"count" isGreaterThan:[NSNumber numberWithInt:4]];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred6]);    
}

- (void) testType {
    NSString *key = @"x";
    declare_coll;
    
    [self insertTestDocument:coll key:key value:@"test"];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key nativeValueTypeIsEqualTo:BSON_TYPE_UTF8];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred1]);
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key nativeValueTypeIsEqualTo:BSON_TYPE_INT32];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred2]);

    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key nativeValueTypeIsNotEqualTo:BSON_TYPE_UTF8];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred3]);
    
    MongoKeyedPredicate *pred4 = [MongoKeyedPredicate predicate];
    [pred4 keyPath:key nativeValueTypeIsNotEqualTo:BSON_TYPE_INT32];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred4]);
}

- (void) testOr {
    NSString *key1 = @"x";
    NSString *key2 = @"y";
    declare_coll;
    
    id dict = [NSDictionary dictionaryWithObjectsAndKeys:
               [NSNumber numberWithInt:5], key1,
               [NSNumber numberWithInt:10], key2,
               nil];
    NSError *error = nil;
    [coll insertDictionary:dict writeConcern:nil error:&error];

    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key1 matches:[NSNumber numberWithInt:5]];
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key2 matches:[NSNumber numberWithInt:10]];
    
    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key1 matches:[NSNumber numberWithInt:7]];
    MongoKeyedPredicate *pred4 = [MongoKeyedPredicate predicate];
    [pred4 keyPath:key2 matches:[NSNumber numberWithInt:7]];

    MongoPredicate *predTrueTrue = [MongoPredicate orPredicateWithSubPredicates:pred1, pred2, nil];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:predTrueTrue]);
    
    MongoPredicate *predTrueFalse = [MongoPredicate orPredicateWithSubPredicates:pred1, pred4, nil];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:predTrueFalse]);

    MongoPredicate *predFalseTrue = [MongoPredicate orPredicateWithSubPredicates:pred3, pred2, nil];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:predFalseTrue]);

    MongoPredicate *predFalseFalse = [MongoPredicate orPredicateWithSubPredicates:pred3, pred4, nil];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:predFalseFalse]);
}

- (void) testNor {
    NSString *key1 = @"x";
    NSString *key2 = @"y";
    declare_coll;
    
    id dict = [NSDictionary dictionaryWithObjectsAndKeys:
               [NSNumber numberWithInt:5], key1,
               [NSNumber numberWithInt:10], key2,
               nil];
    NSError *error = nil;
    [coll insertDictionary:dict writeConcern:nil error:&error];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key1 matches:[NSNumber numberWithInt:5]];
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key2 matches:[NSNumber numberWithInt:10]];
    
    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key1 matches:[NSNumber numberWithInt:7]];
    MongoKeyedPredicate *pred4 = [MongoKeyedPredicate predicate];
    [pred4 keyPath:key2 matches:[NSNumber numberWithInt:7]];
    
    MongoPredicate *predTrueTrue = [MongoPredicate norPredicateWithSubPredicates:pred1, pred2, nil];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:predTrueTrue]);
    
    MongoPredicate *predTrueFalse = [MongoPredicate norPredicateWithSubPredicates:pred1, pred4, nil];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:predTrueFalse]);
    
    MongoPredicate *predFalseTrue = [MongoPredicate norPredicateWithSubPredicates:pred3, pred2, nil];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:predFalseTrue]);
    
    MongoPredicate *predFalseFalse = [MongoPredicate norPredicateWithSubPredicates:pred3, pred4, nil];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:predFalseFalse]);
}

- (void) testAnd {
    NSString *key1 = @"x";
    NSString *key2 = @"y";
    declare_coll;
    
    id dict = [NSDictionary dictionaryWithObjectsAndKeys:
               [NSNumber numberWithInt:5], key1,
               [NSNumber numberWithInt:10], key2,
               nil];
    NSError *error = nil;
    [coll insertDictionary:dict writeConcern:nil error:&error];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key1 matches:[NSNumber numberWithInt:5]];
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key2 matches:[NSNumber numberWithInt:10]];
    
    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key1 matches:[NSNumber numberWithInt:7]];
    MongoKeyedPredicate *pred4 = [MongoKeyedPredicate predicate];
    [pred4 keyPath:key2 matches:[NSNumber numberWithInt:7]];
    
    MongoPredicate *predTrueTrue = [MongoPredicate andPredicateWithSubPredicates:pred1, pred2, nil];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:predTrueTrue]);
    
    MongoPredicate *predTrueFalse = [MongoPredicate andPredicateWithSubPredicates:pred1, pred4, nil];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:predTrueFalse]);
    
    MongoPredicate *predFalseTrue = [MongoPredicate andPredicateWithSubPredicates:pred3, pred2, nil];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:predFalseTrue]);
    
    MongoPredicate *predFalseFalse = [MongoPredicate andPredicateWithSubPredicates:pred3, pred4, nil];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:predFalseFalse]);
}

- (void) testWhere {
    NSString *key1 = @"x";
    NSString *key2 = @"y";
    declare_coll;
    
    id dict = [NSDictionary dictionaryWithObjectsAndKeys:
               [NSNumber numberWithInt:5], key1,
               [NSNumber numberWithInt:4], key2,
               nil];
    NSError *error = nil;
    [coll insertDictionary:dict writeConcern:nil error:&error];
    
    BSONCode *code1 = [[BSONCode alloc] init];
    code1.code = @"this.x + this.y == 9";
    MongoPredicate *pred1 = [MongoPredicate wherePredicateWithExpression:code1];
    XCTAssertTrue([self collectionWithName:coll boolForPredicate:pred1]);

    BSONCode *code2 = [[BSONCode alloc] init];
    code2.code = @"this.x + this.y == 10";
    MongoPredicate *pred2 = [MongoPredicate wherePredicateWithExpression:code2];
    XCTAssertFalse([self collectionWithName:coll boolForPredicate:pred2]);
}

- (void) testObjectIDMatches {
    // FIXME
}

@end