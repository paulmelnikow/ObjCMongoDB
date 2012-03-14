//
//  MongoQuery.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MongoPredicate.h"
#import "bson.h"
#import "BSONTypes.h"
#import "OrderedDictionary.h"

@interface MongoKeyedPredicate : MongoPredicate

- (id) init;
+ (MongoKeyedPredicate *) predicate;

// object or a regex
- (void) keyPath:(NSString *) keyPath matches:(id) object;
- (void) keyPath:(NSString *) keyPath matchesRegularExpression:(BSONRegularExpression *) regex;
- (void) keyPath:(NSString *) keyPath matchesAnyObjects:(id) firstObject, ... NS_REQUIRES_NIL_TERMINATION;
- (void) keyPath:(NSString *) keyPath matchesAnyFromArray:(NSArray *) objects;
- (void) keyPath:(NSString *) keyPath doesNotMatchRegularExpression:(BSONRegularExpression *) regex;
- (void) keyPath:(NSString *) keyPath doesNotMatchAnyObjects:(id) firstObject, ... NS_REQUIRES_NIL_TERMINATION;
- (void) keyPath:(NSString *) keyPath doesNotMatchAnyFromArray:(NSArray *) objects;

- (void) keyPath:(NSString *) keyPath isLessThan:(id) object;
- (void) keyPath:(NSString *) keyPath isLessThanOrEqualTo:(id) object;
- (void) keyPath:(NSString *) keyPath isGreaterThanOrEqualTo:(id) object;
- (void) keyPath:(NSString *) keyPath isGreaterThan:(id) object;
- (void) keyPath:(NSString *) keyPath isNotEqualTo:(id) object;

- (void) valueExistsForKeyPath:(NSString *) keyPath;
- (void) valueDoesNotExistForKeyPath:(NSString *) keyPath;

- (void) keyPath:(NSString *) keyPath arrayContainsAllObjects:(id) firstObject, ... NS_REQUIRES_NIL_TERMINATION;
- (void) keyPath:(NSString *) keyPath arrayContainsAllFromArray:(NSArray *) objects;
- (void) keyPath:(NSString *) keyPath arrayDoesNotContainAllObjects:(id) firstObject, ... NS_REQUIRES_NIL_TERMINATION;
- (void) keyPath:(NSString *) keyPath arrayDoesNotContainAllFromArray:(NSArray *) objects;
- (void) keyPath:(NSString *) keyPath arraySizeIsEqualTo:(NSUInteger) arraySize;
- (void) keyPath:(NSString *) keyPath arraySizeIsNotEqualTo:(NSUInteger) arraySize;

- (void) keyPath:(NSString *) keyPath nativeValueTypeIsEqualTo:(bson_type) nativeValueType;
- (void) keyPath:(NSString *) keyPath nativeValueTypeIsNotEqualTo:(bson_type) nativeValueType;

- (void) keyPath:(NSString *) keyPath isEquivalentTo:(NSUInteger) remainder modulo:(NSUInteger) modulus;
- (void) keyPath:(NSString *) keyPath isNotEquivalentTo:(NSUInteger) remainder modulo:(NSUInteger) modulus;

- (void) keyPath:(NSString *) keyPath isNearPoint:(NSPoint) point;
- (void) keyPath:(NSString *) keyPath isNearPoint:(NSPoint) point maxDistance:(CGFloat) maxDistance;
- (void) keyPath:(NSString *) keyPath isWithinRect:(NSRect) rect;
- (void) keyPath:(NSString *) keyPath isWithinCircleWithCenter:(NSPoint) center radius:(CGFloat) radius;

- (void) keyPath:(NSString *) keyPath isNotNearPoint:(NSPoint) point;
- (void) keyPath:(NSString *) keyPath isNotNearPoint:(NSPoint) point maxDistance:(CGFloat) maxDistance;
- (void) keyPath:(NSString *) keyPath isOutsideRect:(NSRect) rect;
- (void) keyPath:(NSString *) keyPath isOutsideCircleWithCenter:(NSPoint) center radius:(CGFloat) radius;

- (MongoKeyedPredicate *) arrayElementMatchingSubPredicateForKeyPath:(NSString *) keyPath;
- (MongoKeyedPredicate *) arrayElementMatchingSubPredicateForKeyPath:(NSString *) keyPath negated:(BOOL) negated;

- (OrderedDictionary *) dictionaryValueForKeyPath:(NSString *) keyPath;

@end

