//
//  MongoQuery.m
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MongoPredicate.h"
#import "OrderedDictionary.h"

NSString * const MongoRegularExpressionPatternOperator = @"$regex";
NSString * const MongoRegularExpressionOptionsOperator = @"$options";
NSString * const MongoLessThanOperator = @"$lt";
NSString * const MongoLessThanOrEqualOperator = @"$lte";
NSString * const MongoGreaterThanOrEqualOperator = @"$gte";
NSString * const MongoGreaterThanOperator = @"$gt";
NSString * const MongoNotEqualOperator = @"$ne";
NSString * const MongoExistsOperator = @"$exists";
NSString * const MongoInOperator = @"$in";
NSString * const MongoNotInOperator = @"$nin";
NSString * const MongoAllOperator = @"$all";
NSString * const MongoSizeOperator = @"$size";
NSString * const MongoTypeOperator = @"$type";
NSString * const MongoModuloOperator = @"$mod";
NSString * const MongoNearOperator = @"$near";
NSString * const MongoMaxDistanceOperator = @"$maxDistance";
NSString * const MongoWithinOperator = @"$within";
NSString * const MongoWithinBoxOption = @"$box";
NSString * const MongoWithinCircleOption = @"$circle";
NSString * const MongoWhereOperator = @"$where";
NSString * const MongoNotOperator = @"$not";
NSString * const MongoArrayElementMatchOperator = @"$elemMatch";
NSString * const MongoOrOperator = @"$or";

@interface MongoPredicate (Private)
- (void) keyPath:(NSString *) keyPath addOperation:(NSString *) oper object:(id) object;
- (void) keyPath:(NSString *) keyPath addNegationOfOperation:(NSString *) oper object:(id) object;
@end

@implementation MongoPredicate

#pragma mark - Initialization

- (id) init {
    if (self = [super init]) {
        _dict = [OrderedDictionary dictionary];
    }
    return self;
}

- (id) initWithParent:(MongoPredicate *) parent dictionary:(OrderedDictionary *) dictionary {
    if (self = [super init]) {
        _dict = dictionary;
    }
    return self;    
}

+ (MongoPredicate *) predicate {
    MongoPredicate *result = [[self alloc] init];
#if !__has_feature(objc_arc)
    [result autorelease];
#endif
    return result;
}

#pragma mark - Predicate building

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

- (void) keyPath:(NSString *) keyPath matchesRegularExpression:(BSONRegularExpression *) object {
    [self keyPath:keyPath addOperation:MongoRegularExpressionPatternOperator object:object.pattern];
    if (object.options)
        [self keyPath:keyPath addOperation:MongoRegularExpressionOptionsOperator object:object.options];
}

- (void) keyPath:(NSString *) keyPath matchesAnyFromArray:(NSArray *) objects {
    [self keyPath:keyPath addOperation:MongoInOperator object:objects];
}

- (void) keyPath:(NSString *) keyPath doesNotMatchAnyFromArray:(NSArray *) objects {
    [self keyPath:keyPath addOperation:MongoNotInOperator object:objects];
}

- (void) keyPath:(NSString *) keyPath isLessThan:(id) object {
    [self keyPath:keyPath addOperation:MongoLessThanOperator object:object];
}

- (void) keyPath:(NSString *) keyPath isLessThanOrEqualTo:(id) object {
    [self keyPath:keyPath addOperation:MongoLessThanOrEqualOperator object:object];
}

- (void) keyPath:(NSString *) keyPath isGreaterThanOrEqualTo:(id) object {
    [self keyPath:keyPath addOperation:MongoGreaterThanOrEqualOperator object:object];
}

- (void) keyPath:(NSString *) keyPath isGreaterThan:(id) object {
    [self keyPath:keyPath addOperation:MongoGreaterThanOperator object:object];
}

- (void) keyPath:(NSString *) keyPath isNotEqualTo:(id) object {
    [self keyPath:keyPath addOperation:MongoNotEqualOperator object:object];
}

- (void) valueExistsForKeyPath:(NSString *) keyPath {
    [self keyPath:keyPath addOperation:MongoExistsOperator object:[NSNumber numberWithBool:YES]];
}

- (void) valueDoesNotExistForKeyPath:(NSString *) keyPath {
    [self keyPath:keyPath addOperation:MongoExistsOperator object:[NSNumber numberWithBool:NO]];
}

- (void) keyPath:(NSString *) keyPath arrayContainsObject:(id) object {
    return [self keyPath:keyPath matches:object];
}

- (void) keyPath:(NSString *) keyPath arrayContainsAllFromArray:(NSArray *) objects {
    [self keyPath:keyPath addOperation:MongoAllOperator object:objects];
}

- (void) keyPath:(NSString *) keyPath arrayDoesNotContainAllFromArray:(NSArray *) objects {
    [self keyPath:keyPath addNegationOfOperation:MongoAllOperator object:objects];
}

- (void) keyPath:(NSString *) keyPath arraySizeIsEqualTo:(NSUInteger) arraySize {
    [self keyPath:keyPath addOperation:MongoSizeOperator
           object:[NSNumber numberWithInteger:arraySize]];
}

- (void) keyPath:(NSString *) keyPath arraySizeIsNotEqualTo:(NSUInteger) arraySize {
    [self keyPath:keyPath addNegationOfOperation:MongoSizeOperator
           object:[NSNumber numberWithInteger:arraySize]];
}

- (void) keyPath:(NSString *) keyPath nativeValueTypeEquals:(bson_type) nativeValueType {
    [self keyPath:keyPath addNegationOfOperation:MongoTypeOperator
           object:[NSNumber numberWithInt:nativeValueType]];    
}

- (void) keyPath:(NSString *) keyPath isEquivalentTo:(NSUInteger) remainder modulo:(NSUInteger) modulus {
    NSArray *arguments = [NSArray arrayWithObjects:
                          [NSNumber numberWithInteger:modulus],
                          [NSNumber numberWithInteger:remainder],
                          nil];
    [self keyPath:keyPath addOperation:MongoModuloOperator object:arguments];
}

- (void) keyPath:(NSString *) keyPath isNotEquivalentTo:(NSUInteger) remainder modulo:(NSUInteger) modulus {
    NSArray *arguments = [NSArray arrayWithObjects:
                          [NSNumber numberWithInteger:modulus],
                          [NSNumber numberWithInteger:remainder],
                          nil];
    [self keyPath:keyPath addNegationOfOperation:MongoModuloOperator object:arguments];
}

- (void) keyPath:(NSString *) keyPath isNearPoint:(NSPoint) point {
    NSArray *pointAsArray = [NSArray arrayWithObjects:
                             [NSNumber numberWithDouble:point.x],
                             [NSNumber numberWithDouble:point.y],
                             nil];
    [self keyPath:keyPath addOperation:MongoNearOperator object:pointAsArray];
}
- (void) keyPath:(NSString *) keyPath isNearPoint:(NSPoint) point maxDistance:(CGFloat) maxDistance {
    NSArray *pointAsArray = [NSArray arrayWithObjects:
                             [NSNumber numberWithDouble:point.x],
                             [NSNumber numberWithDouble:point.y],
                             nil];
    [self keyPath:keyPath addOperation:MongoNearOperator object:pointAsArray];
    [self keyPath:keyPath addOperation:MongoMaxDistanceOperator object:[NSNumber numberWithDouble:maxDistance]];
}
- (void) keyPath:(NSString *) keyPath isWithinRect:(NSRect) rect {
    id firstCoord = [NSArray arrayWithObjects:
                           [NSNumber numberWithDouble:NSMinX(rect)],
                           [NSNumber numberWithDouble:NSMinY(rect)],
                           nil];
    id secondCoord = [NSArray arrayWithObjects:
                            [NSNumber numberWithDouble:NSMaxX(rect)],
                            [NSNumber numberWithDouble:NSMaxY(rect)],
                            nil];
    id coordinates = [NSArray arrayWithObjects:firstCoord, secondCoord, nil];
    id arguments = [OrderedDictionary dictionaryWithObject:coordinates forKey:MongoWithinBoxOption];
    [self keyPath:keyPath addOperation:MongoWithinOperator object:arguments];
}
- (void) keyPath:(NSString *) keyPath isWithinCircleWithCenter:(NSPoint) center radius:(CGFloat) radius {
    id centerAsArray = [NSArray arrayWithObjects:
                             [NSNumber numberWithDouble:center.x],
                             [NSNumber numberWithDouble:center.y],
                             nil];
    id centerAndRadius = [NSArray arrayWithObjects:centerAsArray, [NSNumber numberWithDouble:radius], nil];
    id arguments = [OrderedDictionary dictionaryWithObject:centerAndRadius forKey:MongoWithinCircleOption];
    [self keyPath:keyPath addOperation:MongoWithinOperator object:arguments];
}

- (void) where:(BSONCode *) where {
    NSString *keyPath = MongoWhereOperator;
    if ([_dict objectForKey:keyPath]) {
        NSString *reason = [NSString stringWithFormat:@"%@ alreay set", MongoWhereOperator];
        id exc = [NSException exceptionWithName:NSInvalidArgumentException
                                         reason:reason
                                       userInfo:nil];
        @throw exc;
    }
    [_dict setObject:where forKey:keyPath];
}

- (MongoPredicate *) subPredicateForKeyPath:(NSString *) keyPath {
    OrderedDictionary *subPredicate = [self dictionaryValueForKeyPath:keyPath];
    return [[MongoPredicate alloc] initWithParent:self dictionary:subPredicate];
}

- (MongoPredicate *) negationSubPredicateForKeyPath:(NSString *) keyPath {
    id subPredicate = [OrderedDictionary dictionary];
    OrderedDictionary *dict = [self dictionaryValueForKeyPath:keyPath];
    [dict setObject:subPredicate forKey:MongoNotOperator];
    return [[MongoPredicate alloc] initWithParent:self dictionary:subPredicate];
}

- (MongoPredicate *) arrayElementSubPredicateForKeyPath:(NSString *) keyPath {
    id subPredicate = [OrderedDictionary dictionary];
    OrderedDictionary *dict = [self dictionaryValueForKeyPath:keyPath];
    [dict setObject:subPredicate forKey:MongoArrayElementMatchOperator];
    return [[MongoPredicate alloc] initWithParent:self dictionary:subPredicate];
}

- (MongoPredicate *) orSubPredicate {
    if (!_orPredicates) _orPredicates = [NSMutableArray arrayWithObject:_dict];
    OrderedDictionary *subPredicate = [OrderedDictionary dictionary];
    [_orPredicates addObject:subPredicate];
    return [[MongoPredicate alloc] initWithParent:self dictionary:subPredicate];
}

#pragma mark - Trampoline methods

- (void) keyPath:(NSString *) keyPath matchesAnyObjects:(id) firstObject, ... {
    NSMutableArray *objects = [NSMutableArray array];
    va_list args;
    va_start(args, firstObject);
    for (id obj = firstObject; obj != nil; obj = va_arg(args, id))
        [objects addObject:obj];
    va_end(args);
    [self keyPath:keyPath matchesAnyFromArray:objects];
}

- (void) keyPath:(NSString *) keyPath doesNotMatchAnyObjects:(id) firstObject, ... {
    NSMutableArray *objects = [NSMutableArray array];
    va_list args;
    va_start(args, firstObject);
    for (id obj = firstObject; obj != nil; obj = va_arg(args, id))
        [objects addObject:obj];
    va_end(args);
    [self keyPath:keyPath doesNotMatchAnyFromArray:objects];    
}

- (void) keyPath:(NSString *) keyPath arrayContainsAllObjects:(id) firstObject, ... {
    NSMutableArray *objects = [NSMutableArray array];
    va_list args;
    va_start(args, firstObject);
    for (id obj = firstObject; obj != nil; obj = va_arg(args, id))
        [objects addObject:obj];
    va_end(args);
    [self keyPath:keyPath arrayContainsAllFromArray:objects];
}

- (void) keyPath:(NSString *) keyPath arrayDoesNotContainAllObjects:(id) firstObject, ... {
    NSMutableArray *objects = [NSMutableArray array];
    va_list args;
    va_start(args, firstObject);
    for (id obj = firstObject; obj != nil; obj = va_arg(args, id))
        [objects addObject:obj];
    va_end(args);
    [self keyPath:keyPath arrayDoesNotContainAllFromArray:objects];
}

#pragma mark - Getting the result

- (OrderedDictionary *) dictionaryValue {
    if (_orPredicates)
        return [OrderedDictionary dictionaryWithObject:_orPredicates forKey:MongoOrOperator];
    else
        return _dict;
}

- (BSONDocument *) BSONDocument {
    return [BSONEncoder documentForDictionary:[self dictionaryValue] restrictsKeyNamesForMongoDB:NO];
}

- (NSString *) description {
    NSString *identifier = [NSString stringWithFormat:@"%@ <%p>\n", [[self class] description], self];
    return [identifier stringByAppendingFormat:@"%@", [self dictionaryValue]];
}

#pragma mark - Helper methods

- (void) keyPath:(NSString *) keyPath addOperation:(NSString *) oper object:(id) object {
    OrderedDictionary *dict = [self dictionaryValueForKeyPath:keyPath];
    [dict setObject:object forKey:oper];
}

- (void) keyPath:(NSString *) keyPath addNegationOfOperation:(NSString *) oper object:(id) object {
    id subPredicate = [OrderedDictionary dictionaryWithObject:object forKey:oper];
    OrderedDictionary *dict = [self dictionaryValueForKeyPath:keyPath];
    [dict setObject:subPredicate forKey:MongoNotOperator];
}

- (OrderedDictionary *) dictionaryValueForKeyPath:(NSString *) keyPath {
    OrderedDictionary *result = [_dict objectForKey:keyPath];
    if (!result) {
        result = [OrderedDictionary dictionary];
        [_dict setObject:result forKey:keyPath];
    } else if (![result isKindOfClass:[OrderedDictionary class]]) {
        NSString *reason = [NSString stringWithFormat:@"Match object alreay set for key path %@", keyPath];
        id exc = [NSException exceptionWithName:NSInvalidArgumentException
                                         reason:reason
                                       userInfo:nil];
        @throw exc;
    }
    return result;
}

@end
