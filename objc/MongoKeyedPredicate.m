//
//  MongoQuery.m
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MongoKeyedPredicate.h"
#import "OrderedDictionary.h"
#import "Mongo_Helper.h"
#import "ObjCBSON.h"

NSString * const MongoRegularExpressionPatternOperatorKey = @"$regex";
NSString * const MongoRegularExpressionOptionsOperatorKey = @"$options";
NSString * const MongoLessThanOperatorKey = @"$lt";
NSString * const MongoLessThanOrEqualOperatorKey = @"$lte";
NSString * const MongoGreaterThanOrEqualOperatorKey = @"$gte";
NSString * const MongoGreaterThanOperatorKey = @"$gt";
NSString * const MongoNotEqualOperatorKey = @"$ne";
NSString * const MongoExistsOperatorKey = @"$exists";
NSString * const MongoInOperatorKey = @"$in";
NSString * const MongoNotInOperatorKey = @"$nin";
NSString * const MongoAllOperatorKey = @"$all";
NSString * const MongoSizeOperatorKey = @"$size";
NSString * const MongoTypeOperatorKey = @"$type";
NSString * const MongoModuloOperatorKey = @"$mod";
NSString * const MongoNearOperatorKey = @"$near";
NSString * const MongoMaxDistanceOperatorKey = @"$maxDistance";
NSString * const MongoWithinOperatorKey = @"$within";
NSString * const MongoWithinBoxOptionKey = @"$box";
NSString * const MongoWithinCircleOptionKey = @"$circle";
NSString * const MongoArrayElementMatchOperatorKey = @"$elemMatch";

@interface MongoKeyedPredicate (Private)
- (void) keyPath:(NSString *) keyPath addOperation:(NSString *) oper object:(id) object;
- (void) keyPath:(NSString *) keyPath addOperation:(NSString *) oper object:(id) object negated:(BOOL) negated;
@end

@implementation MongoKeyedPredicate

#pragma mark - Initialization

- (id) init {
    return [super init];
}

//- (id) initWithParent:(MongoPredicate *) parent dictionary:(OrderedDictionary *) dictionary {
//    if (self = [super init]) {
//        _dict = dictionary;
//    }
//    return self;    
//}
//
+ (MongoKeyedPredicate *) predicate {
    id result = [[self alloc] init];
#if !__has_feature(objc_arc)
    [result autorelease];
#endif
    return result;
}

#pragma mark - Predicate building

- (void) objectIDMatches:(BSONObjectID *) objectID {
    [self keyPath:MongoDBObjectIDKey matches:objectID];
}

- (void) keyPath:(NSString *) keyPath matches:(id) object {
    if ([_dict objectForKey:keyPath]) {
        NSString *reason = [NSString stringWithFormat:@"Criteria alreay set for key path %@", keyPath];
        id exc = [NSException exceptionWithName:NSInvalidArgumentException
                                         reason:reason
                                       userInfo:nil];
        @throw exc;
    }
    [_dict setObject:object forKey:keyPath];
}

- (void) keyPath:(NSString *) keyPath matchesRegularExpression:(BSONRegularExpression *) regex {
    [self keyPath:keyPath addOperation:MongoRegularExpressionPatternOperatorKey object:regex.pattern];
    if (regex.options)
        [self keyPath:keyPath addOperation:MongoRegularExpressionOptionsOperatorKey object:regex.options];
}

- (void) keyPath:(NSString *) keyPath doesNotMatchRegularExpression:(BSONRegularExpression *) regex {
    [self keyPath:keyPath addOperation:MongoNotOperatorKey object:regex];
}

- (void) keyPath:(NSString *) keyPath matchesAnyFromArray:(NSArray *) objects {
    [self keyPath:keyPath addOperation:MongoInOperatorKey object:objects];
}

- (void) keyPath:(NSString *) keyPath doesNotMatchAnyFromArray:(NSArray *) objects {
    [self keyPath:keyPath addOperation:MongoNotInOperatorKey object:objects];
}

- (void) keyPath:(NSString *) keyPath isLessThan:(id) object {
    [self keyPath:keyPath addOperation:MongoLessThanOperatorKey object:object];
}

- (void) keyPath:(NSString *) keyPath isLessThanOrEqualTo:(id) object {
    [self keyPath:keyPath addOperation:MongoLessThanOrEqualOperatorKey object:object];
}

- (void) keyPath:(NSString *) keyPath isGreaterThanOrEqualTo:(id) object {
    [self keyPath:keyPath addOperation:MongoGreaterThanOrEqualOperatorKey object:object];
}

- (void) keyPath:(NSString *) keyPath isGreaterThan:(id) object {
    [self keyPath:keyPath addOperation:MongoGreaterThanOperatorKey object:object];
}

- (void) keyPath:(NSString *) keyPath isNotEqualTo:(id) object {
    [self keyPath:keyPath addOperation:MongoNotEqualOperatorKey object:object];
}

- (void) valueExistsForKeyPath:(NSString *) keyPath {
    [self keyPath:keyPath addOperation:MongoExistsOperatorKey object:[NSNumber numberWithBool:YES]];
}

- (void) valueDoesNotExistForKeyPath:(NSString *) keyPath {
    [self keyPath:keyPath addOperation:MongoExistsOperatorKey object:[NSNumber numberWithBool:NO]];
}

- (void) keyPath:(NSString *) keyPath arrayContainsObject:(id) object {
    return [self keyPath:keyPath matches:object];
}

- (void) keyPath:(NSString *) keyPath arrayContainsAllFromArray:(NSArray *) objects negated:(BOOL) negated {
    [self keyPath:keyPath addOperation:MongoAllOperatorKey object:objects negated:negated];
}

- (void) keyPath:(NSString *) keyPath arrayCountIsEqualTo:(NSUInteger) arrayCount negated:(BOOL) negated {
    [self keyPath:keyPath addOperation:MongoSizeOperatorKey
           object:[NSNumber numberWithInteger:arrayCount]
          negated:negated];
}

- (void) keyPath:(NSString *) keyPath nativeValueTypeIsEqualTo:(bson_type) nativeValueType negated:(BOOL) negated {
    [self keyPath:keyPath addOperation:MongoTypeOperatorKey
           object:[NSNumber numberWithInt:nativeValueType]
          negated:negated];
}

- (void) keyPath:(NSString *) keyPath isEquivalentTo:(NSUInteger) remainder modulo:(NSUInteger) modulus negated:(BOOL) negated {
    NSArray *arguments = [NSArray arrayWithObjects:
                          [NSNumber numberWithInteger:modulus],
                          [NSNumber numberWithInteger:remainder],
                          nil];
    [self keyPath:keyPath addOperation:MongoModuloOperatorKey object:arguments negated:negated];
}

- (void) keyPath:(NSString *) keyPath isNearPoint:(NSPoint) point negated:(BOOL) negated {
    NSArray *pointAsArray = [NSArray arrayWithObjects:
                             [NSNumber numberWithDouble:point.x],
                             [NSNumber numberWithDouble:point.y],
                             nil];
    [self keyPath:keyPath addOperation:MongoNearOperatorKey object:pointAsArray negated:negated];
}
- (void) keyPath:(NSString *) keyPath isNearPoint:(NSPoint) point maxDistance:(CGFloat) maxDistance negated:(BOOL) negated {
    NSArray *pointAsArray = [NSArray arrayWithObjects:
                             [NSNumber numberWithDouble:point.x],
                             [NSNumber numberWithDouble:point.y],
                             nil];
    [self keyPath:keyPath addOperation:MongoNearOperatorKey object:pointAsArray negated:negated];
    [self keyPath:keyPath addOperation:MongoMaxDistanceOperatorKey object:[NSNumber numberWithDouble:maxDistance]];
}
- (void) keyPath:(NSString *) keyPath isWithinRect:(NSRect) rect negated:(BOOL) negated {
    id firstCoord = [NSArray arrayWithObjects:
                           [NSNumber numberWithDouble:NSMinX(rect)],
                           [NSNumber numberWithDouble:NSMinY(rect)],
                           nil];
    id secondCoord = [NSArray arrayWithObjects:
                            [NSNumber numberWithDouble:NSMaxX(rect)],
                            [NSNumber numberWithDouble:NSMaxY(rect)],
                            nil];
    id coordinates = [NSArray arrayWithObjects:firstCoord, secondCoord, nil];
    id arguments = [OrderedDictionary dictionaryWithObject:coordinates forKey:MongoWithinBoxOptionKey];
    [self keyPath:keyPath addOperation:MongoWithinOperatorKey object:arguments negated:negated];
}
- (void) keyPath:(NSString *) keyPath isWithinCircleWithCenter:(NSPoint) center radius:(CGFloat) radius negated:(BOOL) negated {
    id centerAsArray = [NSArray arrayWithObjects:
                             [NSNumber numberWithDouble:center.x],
                             [NSNumber numberWithDouble:center.y],
                             nil];
    id centerAndRadius = [NSArray arrayWithObjects:centerAsArray, [NSNumber numberWithDouble:radius], nil];
    id arguments = [OrderedDictionary dictionaryWithObject:centerAndRadius forKey:MongoWithinCircleOptionKey];
    [self keyPath:keyPath addOperation:MongoWithinOperatorKey object:arguments negated:negated];
}

// Useful for matching a subdocuments which meet multiple criteria which are *inside arrays*
// $elemMatch
- (MongoKeyedPredicate *) arrayElementMatchingSubPredicateForKeyPath:(NSString *) keyPath negated:(BOOL) negated {
    MongoKeyedPredicate *subPredicate = [[MongoKeyedPredicate alloc] init];
    [self keyPath:keyPath addOperation:MongoArrayElementMatchOperatorKey object:subPredicate.dictionary negated:negated];
    return [subPredicate autorelease];
}

#pragma mark - Trampoline methods

- (void) keyPath:(NSString *) keyPath matchesAnyObjects:(id) firstObject, ... {
    NSMutableArray *objects = [NSMutableArray array];
    va_addToNSMutableArray(firstObject, objects);
    [self keyPath:keyPath matchesAnyFromArray:objects];
}

- (void) keyPath:(NSString *) keyPath doesNotMatchAnyObjects:(id) firstObject, ... {
    NSMutableArray *objects = [NSMutableArray array];
    va_addToNSMutableArray(firstObject, objects);
    [self keyPath:keyPath doesNotMatchAnyFromArray:objects];    
}

- (void) keyPath:(NSString *) keyPath arrayContainsAllObjects:(id) firstObject, ... {
    NSMutableArray *objects = [NSMutableArray array];
    va_addToNSMutableArray(firstObject, objects);
    [self keyPath:keyPath arrayContainsAllFromArray:objects];
}

- (void) keyPath:(NSString *) keyPath arrayDoesNotContainAllObjects:(id) firstObject, ... {
    NSMutableArray *objects = [NSMutableArray array];
    va_addToNSMutableArray(firstObject, objects);
    [self keyPath:keyPath arrayDoesNotContainAllFromArray:objects];
}

- (void) keyPath:(NSString *) keyPath arrayContainsAllFromArray:(NSArray *) objects {
    [self keyPath:keyPath arrayContainsAllFromArray:objects negated:NO];
}

- (void) keyPath:(NSString *) keyPath arrayDoesNotContainAllFromArray:(NSArray *) objects {
    [self keyPath:keyPath arrayContainsAllFromArray:objects negated:YES];
}

- (void) keyPath:(NSString *) keyPath arrayCountIsEqualTo:(NSUInteger) arraySize {
    [self keyPath:keyPath arrayCountIsEqualTo:arraySize negated:NO];
}

- (void) keyPath:(NSString *) keyPath arrayCountIsNotEqualTo:(NSUInteger) arraySize {
    [self keyPath:keyPath arrayCountIsEqualTo:arraySize negated:YES];
}

- (void) keyPath:(NSString *) keyPath nativeValueTypeIsEqualTo:(bson_type) nativeValueType {
    [self keyPath:keyPath nativeValueTypeIsEqualTo:nativeValueType negated:NO];
}

- (void) keyPath:(NSString *) keyPath nativeValueTypeIsNotEqualTo:(bson_type) nativeValueType {
    [self keyPath:keyPath nativeValueTypeIsEqualTo:nativeValueType negated:YES];
}

- (void) keyPath:(NSString *) keyPath isEquivalentTo:(NSUInteger) remainder modulo:(NSUInteger) modulus {
    [self keyPath:keyPath isEquivalentTo:remainder modulo:modulus negated:NO];
}

- (void) keyPath:(NSString *) keyPath isNotEquivalentTo:(NSUInteger) remainder modulo:(NSUInteger) modulus {
    [self keyPath:keyPath isEquivalentTo:remainder modulo:modulus negated:YES];
}

- (void) keyPath:(NSString *) keyPath isNearPoint:(NSPoint) point {
    [self keyPath:keyPath isNearPoint:point negated:NO];
}

- (void) keyPath:(NSString *) keyPath isNotNearPoint:(NSPoint) point {
    [self keyPath:keyPath isNearPoint:point negated:YES];
}

- (void) keyPath:(NSString *) keyPath isNearPoint:(NSPoint) point maxDistance:(CGFloat) maxDistance {
    [self keyPath:keyPath isNearPoint:point maxDistance:maxDistance negated:NO];
}

- (void) keyPath:(NSString *) keyPath isNotNearPoint:(NSPoint) point maxDistance:(CGFloat) maxDistance {
    [self keyPath:keyPath isNearPoint:point maxDistance:maxDistance negated:YES];
}

- (void) keyPath:(NSString *) keyPath isWithinRect:(NSRect) rect {
    [self keyPath:keyPath isWithinRect:rect negated:NO];
}

- (void) keyPath:(NSString *) keyPath isOutsideRect:(NSRect) rect {
    [self keyPath:keyPath isWithinRect:rect negated:YES];
}

- (void) keyPath:(NSString *) keyPath isWithinCircleWithCenter:(NSPoint) center radius:(CGFloat) radius {
    [self keyPath:keyPath isWithinCircleWithCenter:center radius:radius negated:NO];
}

- (void) keyPath:(NSString *) keyPath isOutsideCircleWithCenter:(NSPoint) center radius:(CGFloat) radius {
    [self keyPath:keyPath isWithinCircleWithCenter:center radius:radius negated:YES];
}

- (MongoKeyedPredicate *) arrayElementMatchingSubPredicateForKeyPath:(NSString *) keyPath {
    return [self arrayElementMatchingSubPredicateForKeyPath:keyPath negated:NO];
}

#pragma mark - Helper methods

- (void) keyPath:(NSString *) keyPath addOperation:(NSString *) oper object:(id) object {
    [self keyPath:keyPath addOperation:oper object:object negated:NO];
}

- (void) keyPath:(NSString *) keyPath addOperation:(NSString *) oper object:(id) object negated:(BOOL) negated {
    OrderedDictionary *dictForKeyPath = [_dict objectForKey:keyPath];
    if (!dictForKeyPath) {
        dictForKeyPath = [OrderedDictionary dictionary];
        [_dict setObject:dictForKeyPath forKey:keyPath];
    } else if (![dictForKeyPath isKindOfClass:[OrderedDictionary class]]) {
        NSString *reason = [NSString stringWithFormat:@"Match object alreay set for key path %@", keyPath];
        id exc = [NSException exceptionWithName:NSInvalidArgumentException
                                         reason:reason
                                       userInfo:nil];
        @throw exc;
    }
    
    if (negated)
        [dictForKeyPath setObject:[OrderedDictionary dictionaryWithObject:object forKey:oper] forKey:MongoNotOperatorKey];
    else
        [dictForKeyPath setObject:object forKey:oper];
}

@end
