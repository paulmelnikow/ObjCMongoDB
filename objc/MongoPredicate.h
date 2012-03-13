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
- (void) keyPath:(NSString *) keyPath matchesAnyObjects:(id) firstObject, ... NS_REQUIRES_NIL_TERMINATION;
- (void) keyPath:(NSString *) keyPath matchesAnyFromArray:(NSArray *) objects;
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

- (void) keyPath:(NSString *) keyPath nativeValueTypeEquals:(bson_type) nativeValueType;

- (void) keyPath:(NSString *) keyPath isEquivalentTo:(NSUInteger) remainder modulo:(NSUInteger) modulus;
- (void) keyPath:(NSString *) keyPath isNotEquivalentTo:(NSUInteger) remainder modulo:(NSUInteger) modulus;

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

