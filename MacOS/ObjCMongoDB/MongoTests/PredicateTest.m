//
//  PredicateTest.m
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PredicateTest.h"
#import "MongoPredicate.h"
#import "MongoKeyedPredicate.h"
#import "BSONTypes.h"

@implementation PredicateTest

-(void) setUp {
    NSError *error = nil;
    _mongo = [MongoConnection connectionForServer:@"127.0.0.1" error:&error];
    STAssertNil(error, error.localizedDescription);
}

- (void) tearDown {
    [_mongo disconnect];
    _mongo = nil;
}

- (void) insertTestDocument:(MongoDBCollection *) collection key:(NSString *) key value: (id) value {
    id dict = [NSDictionary dictionaryWithObject:value forKey:key];
    NSError *error = nil;
    [collection insertDictionary:dict error:&error];
    STAssertNil(error, error.localizedDescription);
}

- (BOOL) collection:(MongoDBCollection *) collection boolForPredicate:(MongoPredicate *) predicate {
    NSError *error = nil;
    NSUInteger result = [collection countWithPredicate:predicate error:&error];
    STAssertNil(error, error.localizedDescription);
    return result > 0;
}

- (void) testGreaterThan {
    NSString *key = @"x";
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.predicate.testGreaterThan"];
    
    [self insertTestDocument:coll key:key value:[NSNumber numberWithInt:0]];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key isGreaterThan:[NSNumber numberWithInt:-1]];
    STAssertTrue([self collection:coll boolForPredicate:pred1], @"");
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key isGreaterThan:[NSNumber numberWithInt:0]];
    STAssertFalse([self collection:coll boolForPredicate:pred2], @"");
}

- (void) testGreaterThanOrEqualTo {
    NSString *key = @"x";
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.predicate.testGreaterThanOrEqualTo"];
    
    [self insertTestDocument:coll key:key value:[NSNumber numberWithInt:0]];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key isGreaterThanOrEqualTo:[NSNumber numberWithInt:0]];
    STAssertTrue([self collection:coll boolForPredicate:pred1], @"");
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key isGreaterThanOrEqualTo:[NSNumber numberWithInt:-1]];
    STAssertTrue([self collection:coll boolForPredicate:pred2], @"");
    
    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key isGreaterThanOrEqualTo:[NSNumber numberWithInt:1]];
    STAssertFalse([self collection:coll boolForPredicate:pred3], @"");    
}

- (void) testLessThan {
    NSString *key = @"x";
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.predicate.testLessThan"];
    
    [self insertTestDocument:coll key:key value:[NSNumber numberWithInt:0]];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key isLessThan:[NSNumber numberWithInt:1]];
    STAssertTrue([self collection:coll boolForPredicate:pred1], @"");
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key isLessThan:[NSNumber numberWithInt:0]];
    STAssertFalse([self collection:coll boolForPredicate:pred2], @"");
}

- (void) testLessThanOrEqualTo {
    NSString *key = @"x";
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.predicate.testLessThanOrEqualTo"];
    
    [self insertTestDocument:coll key:key value:[NSNumber numberWithInt:0]];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key isLessThanOrEqualTo:[NSNumber numberWithInt:1]];
    STAssertTrue([self collection:coll boolForPredicate:pred1], @"");
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key isLessThanOrEqualTo:[NSNumber numberWithInt:0]];
    STAssertTrue([self collection:coll boolForPredicate:pred2], @"");
    
    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key isLessThanOrEqualTo:[NSNumber numberWithInt:-1]];
    STAssertFalse([self collection:coll boolForPredicate:pred3], @"");    
}

- (void) testMatches {
    NSString *key = @"x";
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.predicate.testMatches"];
    
    [self insertTestDocument:coll key:key value:@"test"];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key matches:@"test"];
    STAssertTrue([self collection:coll boolForPredicate:pred1], @"");
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key matches:@"test1"];
    STAssertFalse([self collection:coll boolForPredicate:pred2], @"");

    coll = [_mongo collection:@"objcmongodbtest.predicate.testMatches2"];
    
    id value = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    [self insertTestDocument:coll key:key value:value];
    
    pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key matches:@"c"];
    STAssertTrue([self collection:coll boolForPredicate:pred1], @"");
    
    pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key matches:@"f"];
    STAssertFalse([self collection:coll boolForPredicate:pred2], @"");
}

- (void) testIsNotEqualTo {
    NSString *key = @"x";
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.predicate.testIsNotEqualTo"];
    
    [self insertTestDocument:coll key:key value:@"test"];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key isNotEqualTo:@"test1"];
    STAssertTrue([self collection:coll boolForPredicate:pred1], @"");
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key isNotEqualTo:@"test"];
    STAssertFalse([self collection:coll boolForPredicate:pred2], @"");
}

- (void) testModulus {
    NSString *key = @"x";
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.predicate.testModulus"];
    
    [self insertTestDocument:coll key:key value:[NSNumber numberWithInt:9]];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key isEquivalentTo:1 modulo:2];
    STAssertTrue([self collection:coll boolForPredicate:pred1], @"");
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key isEquivalentTo:0 modulo:2];
    STAssertFalse([self collection:coll boolForPredicate:pred2], @"");
}

- (void) testMatchesAny {
    NSString *key = @"x";
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.predicate.testMatchesAny"];
    
    [self insertTestDocument:coll key:key value:@"a"];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key matchesAnyObjects:@"c", @"b", @"a", nil];
    STAssertTrue([self collection:coll boolForPredicate:pred1], @"");

    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key matchesAnyFromArray:[NSArray arrayWithObjects:@"c", @"b", @"a", nil]];
    STAssertTrue([self collection:coll boolForPredicate:pred2], @"");
    
    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key matchesAnyObjects:@"d", @"f", @"g", nil];
    STAssertFalse([self collection:coll boolForPredicate:pred3], @"");

    MongoKeyedPredicate *pred4 = [MongoKeyedPredicate predicate];
    [pred4 keyPath:key matchesAnyFromArray:[NSArray arrayWithObjects:@"d", @"f", @"g", nil]];
    STAssertFalse([self collection:coll boolForPredicate:pred4], @"");
}

- (void) testDoesNotMatchAny {
    NSString *key = @"x";
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.predicate.testDoesNotMatchAny"];
    
    [self insertTestDocument:coll key:key value:@"a"];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key doesNotMatchAnyObjects:@"c", @"b", @"a", nil];
    STAssertFalse([self collection:coll boolForPredicate:pred1], @"");
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key doesNotMatchAnyFromArray:[NSArray arrayWithObjects:@"c", @"b", @"a", nil]];
    STAssertFalse([self collection:coll boolForPredicate:pred2], @"");
    
    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key doesNotMatchAnyObjects:@"d", @"f", @"g", nil];
    STAssertTrue([self collection:coll boolForPredicate:pred3], @"");
    
    MongoKeyedPredicate *pred4 = [MongoKeyedPredicate predicate];
    [pred4 keyPath:key doesNotMatchAnyFromArray:[NSArray arrayWithObjects:@"d", @"f", @"g", nil]];
    STAssertTrue([self collection:coll boolForPredicate:pred4], @"");
}

- (void) testArrayContainsAll {
    NSString *key = @"x";
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.predicate.testArrayContainsAll"];
    
    id value = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    [self insertTestDocument:coll key:key value:value];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key arrayContainsAllObjects:@"c", @"b", @"a", nil];
    STAssertTrue([self collection:coll boolForPredicate:pred1], @"");
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key arrayContainsAllFromArray:[NSArray arrayWithObjects:@"c", @"b", @"a", nil]];
    STAssertTrue([self collection:coll boolForPredicate:pred2], @"");
    
    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key arrayContainsAllObjects:@"c", @"d", nil];
    STAssertFalse([self collection:coll boolForPredicate:pred3], @"");
    
    MongoKeyedPredicate *pred4 = [MongoKeyedPredicate predicate];
    [pred4 keyPath:key arrayContainsAllFromArray:[NSArray arrayWithObjects:@"c", @"d", nil]];
    STAssertFalse([self collection:coll boolForPredicate:pred4], @"");
}

- (void) testArrayDoesNotContainAll {
    NSString *key = @"x";
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.predicate.testArrayDoesNotContainAll"];
    
    id value = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    [self insertTestDocument:coll key:key value:value];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key arrayDoesNotContainAllObjects:@"c", @"b", @"a", nil];
    STAssertFalse([self collection:coll boolForPredicate:pred1], @"");
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key arrayDoesNotContainAllFromArray:[NSArray arrayWithObjects:@"c", @"b", @"a", nil]];
    STAssertFalse([self collection:coll boolForPredicate:pred2], @"");
    
    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key arrayDoesNotContainAllObjects:@"c", @"d", nil];
    STAssertTrue([self collection:coll boolForPredicate:pred3], @"");
    
    MongoKeyedPredicate *pred4 = [MongoKeyedPredicate predicate];
    [pred4 keyPath:key arrayDoesNotContainAllFromArray:[NSArray arrayWithObjects:@"c", @"d", nil]];
    STAssertTrue([self collection:coll boolForPredicate:pred4], @"");
}

- (void) testArraySize {
    NSString *key = @"x";
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.predicate.testArraySize"];
    
    id value = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    [self insertTestDocument:coll key:key value:value];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key arraySizeIsEqualTo:2];
    STAssertFalse([self collection:coll boolForPredicate:pred1], @"");
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key arraySizeIsEqualTo:3];
    STAssertTrue([self collection:coll boolForPredicate:pred2], @"");
    
    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key arraySizeIsEqualTo:4];
    STAssertFalse([self collection:coll boolForPredicate:pred3], @"");
    
    pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key arraySizeIsNotEqualTo:2];
    STAssertTrue([self collection:coll boolForPredicate:pred1], @"");
    
    pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key arraySizeIsNotEqualTo:3];
    STAssertFalse([self collection:coll boolForPredicate:pred2], @"");
    
    pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key arraySizeIsNotEqualTo:4];
    STAssertTrue([self collection:coll boolForPredicate:pred3], @"");
}

- (void) testRegexMatches {
    NSString *key = @"x";
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.predicate.testRegexMatches"];
    
    [self insertTestDocument:coll key:key value:@"test"];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key matchesRegularExpression:[BSONRegularExpression regularExpressionWithPattern:@"\\w*$" options:nil]];
    STAssertTrue([self collection:coll boolForPredicate:pred1], @"");
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key matchesRegularExpression:[BSONRegularExpression regularExpressionWithPattern:@"nomatch" options:nil]];
    STAssertFalse([self collection:coll boolForPredicate:pred2], @"");
    
    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key doesNotMatchRegularExpression:[BSONRegularExpression regularExpressionWithPattern:@"\\w*$" options:nil]];
    STAssertFalse([self collection:coll boolForPredicate:pred3], @"");
    
    MongoKeyedPredicate *pred4 = [MongoKeyedPredicate predicate];
    [pred4 keyPath:key doesNotMatchRegularExpression:[BSONRegularExpression regularExpressionWithPattern:@"nomatch" options:nil]];
    STAssertTrue([self collection:coll boolForPredicate:pred4], @"");
}

- (void) testRange {
    NSString *key = @"x";
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.predicate.testRange"];
    
    [self insertTestDocument:coll key:key value:[NSNumber numberWithInt:4]];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key isGreaterThan:[NSNumber numberWithInt:0]];
    [pred1 keyPath:key isLessThan:[NSNumber numberWithInt:5]];
    STAssertTrue([self collection:coll boolForPredicate:pred1], @"");
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key isGreaterThan:[NSNumber numberWithInt:0]];
    [pred2 keyPath:key isLessThan:[NSNumber numberWithInt:3]];
    STAssertFalse([self collection:coll boolForPredicate:pred2], @"");    
}

- (void) testMultipleKeys {
    NSString *key1 = @"x";
    NSString *key2 = @"y";
    NSString *value = @"val";
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.predicate.testMultipleKeys"];

    id dict = [NSDictionary dictionaryWithObjectsAndKeys:
               value, key1,
               [NSNumber numberWithInt:9], key2,
               nil];

    NSError *error = nil;
    [coll insertDictionary:dict error:&error];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key2 isEquivalentTo:1 modulo:2];
    [pred1 keyPath:key1 matches:value];
    STAssertTrue([self collection:coll boolForPredicate:pred1], @"");    
}

- (void) testArrayMultiCond {
    NSString *key = @"x";
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.predicate.testArrayMultiCond"];
    
    id value = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    [self insertTestDocument:coll key:key value:value];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key arrayContainsAllObjects:@"c", @"b", @"a", nil];
    [pred1 keyPath:key arraySizeIsEqualTo:3];
    STAssertTrue([self collection:coll boolForPredicate:pred1], @"");
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key arrayContainsAllObjects:@"c", @"b", @"a", nil];
    [pred2 keyPath:key arraySizeIsEqualTo:4];
    STAssertFalse([self collection:coll boolForPredicate:pred2], @"");

    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key arrayContainsAllObjects:@"d", @"b", @"a", nil];
    [pred3 keyPath:key arraySizeIsEqualTo:3];
    STAssertFalse([self collection:coll boolForPredicate:pred2], @"");
}

- (void) testArrayElemMatch {
    NSString *key = @"x";
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.predicate.testArrayElemMatch"];
    
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
    STAssertFalse([self collection:coll boolForPredicate:pred1], @"");
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    MongoKeyedPredicate *pred2a = [pred2 arrayElementMatchingSubPredicateForKeyPath:key];
    [pred2a keyPath:@"item" matches:@"apple"];
    [pred2a keyPath:@"count" isGreaterThan:[NSNumber numberWithInt:1]];
    STAssertTrue([self collection:coll boolForPredicate:pred2], @"");

    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    MongoKeyedPredicate *pred3a = [pred3 arrayElementMatchingSubPredicateForKeyPath:key];
    [pred3a keyPath:@"item" matches:@"orange"];
    [pred3a keyPath:@"count" isGreaterThan:[NSNumber numberWithInt:4]];
    STAssertTrue([self collection:coll boolForPredicate:pred3], @"");
    
    MongoKeyedPredicate *pred4 = [MongoKeyedPredicate predicate];
    MongoKeyedPredicate *pred4a = [pred4 arrayElementMatchingSubPredicateForKeyPath:key negated:YES];
    [pred4a keyPath:@"item" matches:@"apple"];
    [pred4a keyPath:@"count" isGreaterThan:[NSNumber numberWithInt:4]];
    STAssertTrue([self collection:coll boolForPredicate:pred4], @"");
    
    MongoKeyedPredicate *pred5 = [MongoKeyedPredicate predicate];
    MongoKeyedPredicate *pred5a = [pred5 arrayElementMatchingSubPredicateForKeyPath:key negated:YES];
    [pred5a keyPath:@"item" matches:@"apple"];
    [pred5a keyPath:@"count" isGreaterThan:[NSNumber numberWithInt:1]];
    STAssertFalse([self collection:coll boolForPredicate:pred5], @"");
    
    MongoKeyedPredicate *pred6 = [MongoKeyedPredicate predicate];
    MongoKeyedPredicate *pred6a = [pred6 arrayElementMatchingSubPredicateForKeyPath:key negated:YES];
    [pred6a keyPath:@"item" matches:@"orange"];
    [pred6a keyPath:@"count" isGreaterThan:[NSNumber numberWithInt:4]];
    STAssertFalse([self collection:coll boolForPredicate:pred6], @"");    
}

- (void) testType {
    NSString *key = @"x";
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.predicate.testType"];
    
    [self insertTestDocument:coll key:key value:@"test"];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key nativeValueTypeIsEqualTo:BSON_STRING];
    STAssertTrue([self collection:coll boolForPredicate:pred1], @"");
    
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key nativeValueTypeIsEqualTo:BSON_INT];
    STAssertFalse([self collection:coll boolForPredicate:pred2], @"");

    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key nativeValueTypeIsNotEqualTo:BSON_STRING];
    STAssertFalse([self collection:coll boolForPredicate:pred3], @"");
    
    MongoKeyedPredicate *pred4 = [MongoKeyedPredicate predicate];
    [pred4 keyPath:key nativeValueTypeIsNotEqualTo:BSON_INT];
    STAssertTrue([self collection:coll boolForPredicate:pred4], @"");
}

- (void) testOr {
    NSString *key1 = @"x";
    NSString *key2 = @"y";
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.predicate.testOr"];
    
    id dict = [NSDictionary dictionaryWithObjectsAndKeys:
               [NSNumber numberWithInt:5], key1,
               [NSNumber numberWithInt:10], key2,
               nil];
    NSError *error = nil;
    [coll insertDictionary:dict error:&error];

    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key1 matches:[NSNumber numberWithInt:5]];
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key2 matches:[NSNumber numberWithInt:10]];
    
    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key1 matches:[NSNumber numberWithInt:7]];
    MongoKeyedPredicate *pred4 = [MongoKeyedPredicate predicate];
    [pred4 keyPath:key2 matches:[NSNumber numberWithInt:7]];

    MongoPredicate *predTrueTrue = [MongoPredicate orPredicateWithSubPredicates:pred1, pred2, nil];
    STAssertTrue([self collection:coll boolForPredicate:predTrueTrue], @"");
    
    MongoPredicate *predTrueFalse = [MongoPredicate orPredicateWithSubPredicates:pred1, pred4, nil];
    STAssertTrue([self collection:coll boolForPredicate:predTrueFalse], @"");

    MongoPredicate *predFalseTrue = [MongoPredicate orPredicateWithSubPredicates:pred3, pred2, nil];
    STAssertTrue([self collection:coll boolForPredicate:predFalseTrue], @"");

    MongoPredicate *predFalseFalse = [MongoPredicate orPredicateWithSubPredicates:pred3, pred4, nil];
    STAssertFalse([self collection:coll boolForPredicate:predFalseFalse], @"");
}

- (void) testNor {
    NSString *key1 = @"x";
    NSString *key2 = @"y";
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.predicate.testNor"];
    
    id dict = [NSDictionary dictionaryWithObjectsAndKeys:
               [NSNumber numberWithInt:5], key1,
               [NSNumber numberWithInt:10], key2,
               nil];
    NSError *error = nil;
    [coll insertDictionary:dict error:&error];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key1 matches:[NSNumber numberWithInt:5]];
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key2 matches:[NSNumber numberWithInt:10]];
    
    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key1 matches:[NSNumber numberWithInt:7]];
    MongoKeyedPredicate *pred4 = [MongoKeyedPredicate predicate];
    [pred4 keyPath:key2 matches:[NSNumber numberWithInt:7]];
    
    MongoPredicate *predTrueTrue = [MongoPredicate norPredicateWithSubPredicates:pred1, pred2, nil];
    STAssertFalse([self collection:coll boolForPredicate:predTrueTrue], @"");
    
    MongoPredicate *predTrueFalse = [MongoPredicate norPredicateWithSubPredicates:pred1, pred4, nil];
    STAssertFalse([self collection:coll boolForPredicate:predTrueFalse], @"");
    
    MongoPredicate *predFalseTrue = [MongoPredicate norPredicateWithSubPredicates:pred3, pred2, nil];
    STAssertFalse([self collection:coll boolForPredicate:predFalseTrue], @"");
    
    MongoPredicate *predFalseFalse = [MongoPredicate norPredicateWithSubPredicates:pred3, pred4, nil];
    STAssertTrue([self collection:coll boolForPredicate:predFalseFalse], @"");
}

- (void) testAnd {
    NSString *key1 = @"x";
    NSString *key2 = @"y";
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.predicate.testAnd"];
    
    id dict = [NSDictionary dictionaryWithObjectsAndKeys:
               [NSNumber numberWithInt:5], key1,
               [NSNumber numberWithInt:10], key2,
               nil];
    NSError *error = nil;
    [coll insertDictionary:dict error:&error];
    
    MongoKeyedPredicate *pred1 = [MongoKeyedPredicate predicate];
    [pred1 keyPath:key1 matches:[NSNumber numberWithInt:5]];
    MongoKeyedPredicate *pred2 = [MongoKeyedPredicate predicate];
    [pred2 keyPath:key2 matches:[NSNumber numberWithInt:10]];
    
    MongoKeyedPredicate *pred3 = [MongoKeyedPredicate predicate];
    [pred3 keyPath:key1 matches:[NSNumber numberWithInt:7]];
    MongoKeyedPredicate *pred4 = [MongoKeyedPredicate predicate];
    [pred4 keyPath:key2 matches:[NSNumber numberWithInt:7]];
    
    MongoPredicate *predTrueTrue = [MongoPredicate andPredicateWithSubPredicates:pred1, pred2, nil];
    STAssertTrue([self collection:coll boolForPredicate:predTrueTrue], @"");
    
    MongoPredicate *predTrueFalse = [MongoPredicate andPredicateWithSubPredicates:pred1, pred4, nil];
    STAssertFalse([self collection:coll boolForPredicate:predTrueFalse], @"");
    
    MongoPredicate *predFalseTrue = [MongoPredicate andPredicateWithSubPredicates:pred3, pred2, nil];
    STAssertFalse([self collection:coll boolForPredicate:predFalseTrue], @"");
    
    MongoPredicate *predFalseFalse = [MongoPredicate andPredicateWithSubPredicates:pred3, pred4, nil];
    STAssertFalse([self collection:coll boolForPredicate:predFalseFalse], @"");
}

- (void) testWhere {
    NSString *key1 = @"x";
    NSString *key2 = @"y";
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.predicate.testWhere"];
    
    id dict = [NSDictionary dictionaryWithObjectsAndKeys:
               [NSNumber numberWithInt:5], key1,
               [NSNumber numberWithInt:4], key2,
               nil];
    NSError *error = nil;
    [coll insertDictionary:dict error:&error];
    
    MongoPredicate *pred1 = [MongoPredicate wherePredicateWithExpression:[BSONCode code:@"this.x + this.y == 9"]];
    STAssertTrue([self collection:coll boolForPredicate:pred1], @"");

    MongoPredicate *pred2 = [MongoPredicate wherePredicateWithExpression:[BSONCode code:@"this.x + this.y == 10"]];
    STAssertFalse([self collection:coll boolForPredicate:pred2], @"");
}

@end