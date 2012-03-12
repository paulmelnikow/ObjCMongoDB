//
//  MongoQuery.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "bson.h"
#import "BSONTypes.h"
#import "OrderedDictionary.h"

@interface MongoPredicate : NSObject {
@private
    OrderedDictionary *_dict;
    NSMutableArray *_orPredicates;
}

- (id) init;
+ (MongoPredicate *) predicate;

// object or a regex
- (void) keyPath:(NSString *) keyPath matches:(id) object;
- (void) keyPath:(NSString *) keyPath matchesRegularExpression:(BSONRegularExpression *) object;
- (void) keyPath:(NSString *) keyPath isLessThan:(id) object;
- (void) keyPath:(NSString *) keyPath isLessThanOrEqualTo:(id) object;
- (void) keyPath:(NSString *) keyPath isGreaterThanOrEqualTo:(id) object;
- (void) keyPath:(NSString *) keyPath isGreaterThan:(id) object;
- (void) keyPath:(NSString *) keyPath isNotEqualTo:(id) object;

- (void) keyPathExists:(NSString *) keyPath;
- (void) keyPathDoesNotExist:(NSString *) keyPath;

- (void) keyPath:(NSString *) keyPath arrayContains:(id) object;
- (void) keyPath:(NSString *) keyPath arrayContainsAny:(id) firstObject, ... NS_REQUIRES_NIL_TERMINATION;
- (void) keyPath:(NSString *) keyPath arrayContainsAnyInArray:(NSArray *) objects;
- (void) keyPath:(NSString *) keyPath arrayContainsAll:(id) firstObject, ... NS_REQUIRES_NIL_TERMINATION;
- (void) keyPath:(NSString *) keyPath arrayContainsAllInArray:(NSArray *) objects;

- (void) keyPath:(NSString *) keyPath arrayDoesNotContainAny:(id) firstObject, ... NS_REQUIRES_NIL_TERMINATION;
- (void) keyPath:(NSString *) keyPath arrayDoesNotContainAnyInArray:(NSArray *) objects;
- (void) keyPath:(NSString *) keyPath arrayDoesNotContainAll:(id) firstObject, ... NS_REQUIRES_NIL_TERMINATION;
- (void) keyPath:(NSString *) keyPath arrayDoesNotContainAllInArray:(NSArray *) objects;

- (void) keyPath:(NSString *) keyPath arraySizeEquals:(NSUInteger) arraySize;
- (void) keyPath:(NSString *) keyPath arraySizeDoesNotEqual:(NSUInteger) arraySize;

- (void) keyPath:(NSString *) keyPath nativeValueTypeEquals:(bson_type) nativeValueType;

- (void) keyPath:(NSString *) keyPath isEquivalentTo:(NSUInteger) remainder mod:(NSUInteger) modulus;
- (void) keyPath:(NSString *) keyPath isNotEquivalentTo:(NSUInteger) remainder mod:(NSUInteger) modulus;

- (void) keyPath:(NSString *) keyPath isNearPoint:(NSPoint) point;
- (void) keyPath:(NSString *) keyPath isNearPoint:(NSPoint) point maxDistance:(CGFloat) maxDistance;
- (void) keyPath:(NSString *) keyPath isWithinRect:(NSRect) rect;
- (void) keyPath:(NSString *) keyPath isWithinCircleWithCenter:(NSPoint) center radius:(CGFloat) radius;

- (void) where:(BSONCode *) where;

- (MongoPredicate *) subPredicateForKeyPath:(NSString *) keyPath;
- (MongoPredicate *) negationSubPredicateForKeyPath:(NSString *) keyPath;
- (MongoPredicate *) arrayElementSubPredicateForKeyPath:(NSString *) keyPath;
- (MongoPredicate *) orSubPredicate;

- (OrderedDictionary *) dictionaryValue;
- (OrderedDictionary *) dictionaryValueForKeyPath:(NSString *) keyPath;
- (BSONDocument *) BSONDocument;
- (NSString *) description;

@end

