//
//  MongoKeyedPredicate.h
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

#import "MongoPredicate.h"
#import "bson.h"
#import "BSONTypes.h"

@interface MongoKeyedPredicate : MongoPredicate

- (id) init;
+ (MongoKeyedPredicate *) predicate;

- (void) objectIDMatches:(BSONObjectID *) objectID;

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
- (void) keyPath:(NSString *) keyPath arrayCountIsEqualTo:(NSUInteger) arrayCount;
- (void) keyPath:(NSString *) keyPath arrayCountIsNotEqualTo:(NSUInteger) arrayCount;

- (void) keyPath:(NSString *) keyPath nativeValueTypeIsEqualTo:(bson_type) nativeValueType;
- (void) keyPath:(NSString *) keyPath nativeValueTypeIsNotEqualTo:(bson_type) nativeValueType;

- (void) keyPath:(NSString *) keyPath isEquivalentTo:(NSUInteger) remainder modulo:(NSUInteger) modulus;
- (void) keyPath:(NSString *) keyPath isNotEquivalentTo:(NSUInteger) remainder modulo:(NSUInteger) modulus;

- (void) keyPath:(NSString *) keyPath isNearPoint:(CGPoint) point;
- (void) keyPath:(NSString *) keyPath isNearPoint:(CGPoint) point maxDistance:(CGFloat) maxDistance;
- (void) keyPath:(NSString *) keyPath isWithinRect:(CGRect) rect;
- (void) keyPath:(NSString *) keyPath isWithinCircleWithCenter:(CGPoint) center radius:(CGFloat) radius;

- (void) keyPath:(NSString *) keyPath isNotNearPoint:(CGPoint) point;
- (void) keyPath:(NSString *) keyPath isNotNearPoint:(CGPoint) point maxDistance:(CGFloat) maxDistance;
- (void) keyPath:(NSString *) keyPath isOutsideRect:(CGRect) rect;
- (void) keyPath:(NSString *) keyPath isOutsideCircleWithCenter:(CGPoint) center radius:(CGFloat) radius;

- (MongoKeyedPredicate *) arrayElementMatchingSubPredicateForKeyPath:(NSString *) keyPath;
- (MongoKeyedPredicate *) arrayElementMatchingSubPredicateForKeyPath:(NSString *) keyPath negated:(BOOL) negated;

@end

