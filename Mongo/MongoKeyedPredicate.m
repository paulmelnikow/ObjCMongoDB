//
//  MongoKeyedPredicate.m
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

#import "MongoKeyedPredicate.h"
#import "OrderedDictionary.h"
#import "Mongo_Helper.h"
#import "ObjCBSON.h"
#import "OrderedDictionary.h"
#import "Mongo_PrivateInterfaces.h"
#import "BSON_Helper.h"

@implementation MongoKeyedPredicate

#pragma mark - Initialization

- (id) init {
    return [super init];
}

+ (MongoKeyedPredicate *) predicate {
    id result = [[self alloc] init];
    maybe_autorelease_and_return(result);
}

#pragma mark - Predicate building

- (void) objectIDMatches:(BSONObjectID *) objectID {
    [self keyPath:MongoDBObjectIDKey matches:objectID];
}

- (void) keyPath:(NSString *) keyPath matches:(id) object {
    if ([self.dictionary objectForKey:keyPath])
        [NSException raise:NSInvalidArgumentException
                    format:@"Criteria alreay set for key path %@", keyPath];

    [self.dictionary setObject:object forKey:keyPath];
}

- (void) keyPath:(NSString *) keyPath matchesRegularExpression:(BSONRegularExpression *) regex {
    [self _keyPath:keyPath addOperation:@"$regex" object:regex.pattern];
    if (regex.options)
        [self _keyPath:keyPath addOperation:@"$options" object:regex.options];
}

- (void) keyPath:(NSString *) keyPath doesNotMatchRegularExpression:(BSONRegularExpression *) regex {
    [self _keyPath:keyPath addOperation:@"$not" object:regex];
}

- (void) keyPath:(NSString *) keyPath matchesAnyFromArray:(NSArray *) objects {
    [self _keyPath:keyPath addOperation:@"$in" object:objects];
}

- (void) keyPath:(NSString *) keyPath doesNotMatchAnyFromArray:(NSArray *) objects {
    [self _keyPath:keyPath addOperation:@"$nin" object:objects];
}

- (void) keyPath:(NSString *) keyPath isLessThan:(id) object {
    [self _keyPath:keyPath addOperation:@"$lt" object:object];
}

- (void) keyPath:(NSString *) keyPath isLessThanOrEqualTo:(id) object {
    [self _keyPath:keyPath addOperation:@"$lte" object:object];
}

- (void) keyPath:(NSString *) keyPath isGreaterThanOrEqualTo:(id) object {
    [self _keyPath:keyPath addOperation:@"$gte" object:object];
}

- (void) keyPath:(NSString *) keyPath isGreaterThan:(id) object {
    [self _keyPath:keyPath addOperation:@"$gt" object:object];
}

- (void) keyPath:(NSString *) keyPath isNotEqualTo:(id) object {
    [self _keyPath:keyPath addOperation:@"$ne" object:object];
}

- (void) valueExistsForKeyPath:(NSString *) keyPath {
    [self _keyPath:keyPath addOperation:@"$exists" object:[NSNumber numberWithBool:YES]];
}

- (void) valueDoesNotExistForKeyPath:(NSString *) keyPath {
    [self _keyPath:keyPath addOperation:@"$exists" object:[NSNumber numberWithBool:NO]];
}

- (void) keyPath:(NSString *) keyPath arrayContainsObject:(id) object {
    return [self keyPath:keyPath matches:object];
}

- (void) keyPath:(NSString *) keyPath arrayContainsAllFromArray:(NSArray *) objects negated:(BOOL) negated {
    [self _keyPath:keyPath addOperation:@"$all" object:objects negated:negated];
}

- (void) keyPath:(NSString *) keyPath arrayCountIsEqualTo:(NSUInteger) arrayCount negated:(BOOL) negated {
    [self _keyPath:keyPath addOperation:@"$size" object:@(arrayCount) negated:negated];
}

- (void) keyPath:(NSString *) keyPath nativeValueTypeIsEqualTo:(bson_type) nativeValueType negated:(BOOL) negated {
    [self _keyPath:keyPath addOperation:@"$type" object:@(nativeValueType) negated:negated];
}

- (void) keyPath:(NSString *) keyPath isEquivalentTo:(NSUInteger) remainder modulo:(NSUInteger) modulus negated:(BOOL) negated {
    NSArray *arguments = @[ @(modulus), @(remainder) ];
    [self _keyPath:keyPath addOperation:@"$mod" object:arguments negated:negated];
}

- (void) keyPath:(NSString *) keyPath isNearPoint:(CGPoint) point negated:(BOOL) negated {
    [self _keyPath:keyPath addOperation:@"$near"
            object:[NSArray arrayWithPoint:point]
           negated:negated];
}
- (void) keyPath:(NSString *) keyPath isNearPoint:(CGPoint) point maxDistance:(CGFloat) maxDistance negated:(BOOL) negated {
    [self _keyPath:keyPath addOperation:@"$near"
            object:[NSArray arrayWithPoint:point]
           negated:negated];
    [self _keyPath:keyPath addOperation:@"$maxDistance"
            object:@(maxDistance)];
}
- (void) keyPath:(NSString *) keyPath isWithinRect:(CGRect) rect
         negated:(BOOL) negated {
    id arguments = [OrderedDictionary dictionaryWithObject:[NSArray arrayWithRect:rect]
                                                    forKey:@"$box"];
    [self _keyPath:keyPath addOperation:@"$within" object:arguments negated:negated];
}
- (void) keyPath:(NSString *) keyPath isWithinCircleWithCenter:(CGPoint) center
          radius:(CGFloat) radius
         negated:(BOOL) negated {
    id centerAndRadius = @[ [NSArray arrayWithPoint:center], @(radius) ];
    id arguments = [OrderedDictionary dictionaryWithObject:centerAndRadius forKey:@"$circle"];
    [self _keyPath:keyPath addOperation:@"$within" object:arguments negated:negated];
}

// Useful for matching a subdocuments which meet multiple criteria which are *inside arrays*
- (MongoKeyedPredicate *) arrayElementMatchingSubPredicateForKeyPath:(NSString *) keyPath negated:(BOOL) negated {
    MongoKeyedPredicate *subPredicate = [MongoKeyedPredicate predicate];
    [self _keyPath:keyPath addOperation:@"$elemMatch" object:subPredicate.dictionary negated:negated];
    return subPredicate;
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

- (void) keyPath:(NSString *) keyPath isNearPoint:(CGPoint) point {
    [self keyPath:keyPath isNearPoint:point negated:NO];
}

- (void) keyPath:(NSString *) keyPath isNotNearPoint:(CGPoint) point {
    [self keyPath:keyPath isNearPoint:point negated:YES];
}

- (void) keyPath:(NSString *) keyPath isNearPoint:(CGPoint) point maxDistance:(CGFloat) maxDistance {
    [self keyPath:keyPath isNearPoint:point maxDistance:maxDistance negated:NO];
}

- (void) keyPath:(NSString *) keyPath isNotNearPoint:(CGPoint) point maxDistance:(CGFloat) maxDistance {
    [self keyPath:keyPath isNearPoint:point maxDistance:maxDistance negated:YES];
}

- (void) keyPath:(NSString *) keyPath isWithinRect:(CGRect) rect {
    [self keyPath:keyPath isWithinRect:rect negated:NO];
}

- (void) keyPath:(NSString *) keyPath isOutsideRect:(CGRect) rect {
    [self keyPath:keyPath isWithinRect:rect negated:YES];
}

- (void) keyPath:(NSString *) keyPath isWithinCircleWithCenter:(CGPoint) center radius:(CGFloat) radius {
    [self keyPath:keyPath isWithinCircleWithCenter:center radius:radius negated:NO];
}

- (void) keyPath:(NSString *) keyPath isOutsideCircleWithCenter:(CGPoint) center radius:(CGFloat) radius {
    [self keyPath:keyPath isWithinCircleWithCenter:center radius:radius negated:YES];
}

- (MongoKeyedPredicate *) arrayElementMatchingSubPredicateForKeyPath:(NSString *) keyPath {
    return [self arrayElementMatchingSubPredicateForKeyPath:keyPath negated:NO];
}

#pragma mark - Helper methods

- (void) _keyPath:(NSString *) keyPath addOperation:(NSString *) oper object:(id) object {
    [self _keyPath:keyPath addOperation:oper object:object negated:NO];
}

- (void) _keyPath:(NSString *) keyPath addOperation:(NSString *) oper object:(id) object negated:(BOOL) negated {
    OrderedDictionary *dictForKeyPath = [self.dictionary objectForKey:keyPath];
    if (!dictForKeyPath) {
        dictForKeyPath = [OrderedDictionary dictionary];
        [self.dictionary setObject:dictForKeyPath forKey:keyPath];
    } else if (![dictForKeyPath isKindOfClass:[OrderedDictionary class]])
        [NSException raise:NSInvalidArgumentException
                    format:@"Match object alreay set for key path %@", keyPath];
    
    if (negated)
        [dictForKeyPath setObject:[OrderedDictionary dictionaryWithObject:object forKey:oper] forKey:@"$not"];
    else
        [dictForKeyPath setObject:object forKey:oper];
}

@end
