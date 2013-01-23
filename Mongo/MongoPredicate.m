//
//  MongoPredicate.m
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
#import "MongoKeyedPredicate.h"

NSString * const MongoWhereOperatorKey = @"$where";
NSString * const MongoOrOperatorKey = @"$or";
NSString * const MongoNorOperatorKey = @"$nor";
NSString * const MongoAndOperatorKey = @"$and";
NSString * const MongoNotOperatorKey = @"$not";

@implementation MongoPredicate

- (id) init {
    if (self = [super init]) {
        _dict = [OrderedDictionary dictionary];
    }
    return self;
}

- (MongoPredicate *) initWithOperator:(NSString *) operator subPredicates:(NSArray *) subPredicates {
    if (self = [self init]) {
        _operator = operator;
        NSMutableArray *dictionaries = [NSMutableArray array];
        for (MongoPredicate *predicate in subPredicates)
            [dictionaries addObject:predicate.dictionary];
        [_dict setObject:dictionaries forKey:operator];
    }
    return self;
}

+ (MongoPredicate *) predicate {
    id result = [[self alloc] init];
#if !__has_feature(objc_arc)
    [result autorelease];
#endif
    return result;
}

#pragma mark - Getting the result

- (OrderedDictionary *) dictionary {
    return _dict;
}

- (BSONDocument *) BSONDocument {
    return [BSONEncoder documentForDictionary:[self dictionary] restrictsKeyNamesForMongoDB:NO];
}

- (NSString *) description {
    NSString *identifier = [NSString stringWithFormat:@"%@ <%p>\n", [[self class] description], self];
    return [identifier stringByAppendingFormat:@"%@", [self dictionary]];
}

#pragma mark - Or, nor, and predicates - Intitialization

+ (MongoPredicate *) orPredicateWithSubPredicate:(MongoPredicate *) predicate {
    return [self orPredicateWithArray:[NSArray arrayWithObject:predicate]];
}

+ (MongoPredicate *) orPredicateWithSubPredicates:(MongoPredicate *) predicate, ... {
    NSMutableArray *objects = [NSMutableArray array];
    va_addToNSMutableArray(predicate, objects);
    return [self orPredicateWithArray:objects];
}

+ (MongoPredicate *) orPredicateWithArray:(NSArray *) array {
    id result = [[self alloc] initWithOperator:MongoOrOperatorKey subPredicates:array];
#if !__has_feature(objc_arc)
    [result autorelease];
#endif
    return result;
}

+ (MongoPredicate *) norPredicateWithSubPredicate:(MongoPredicate *) predicate {
    return [self norPredicateWithArray:[NSArray arrayWithObject:predicate]];
}

+ (MongoPredicate *) norPredicateWithSubPredicates:(MongoPredicate *) predicate, ... {
    NSMutableArray *objects = [NSMutableArray array];
    va_addToNSMutableArray(predicate, objects);
    return [self norPredicateWithArray:objects];
}

+ (MongoPredicate *) norPredicateWithArray:(NSArray *) array {
    id result = [[self alloc] initWithOperator:MongoNorOperatorKey subPredicates:array];
#if !__has_feature(objc_arc)
    [result autorelease];
#endif
    return result;
}

+ (MongoPredicate *) andPredicateWithSubPredicate:(MongoPredicate *) predicate {
    return [self andPredicateWithArray:[NSArray arrayWithObject:predicate]];
}

+ (MongoPredicate *) andPredicateWithSubPredicates:(MongoPredicate *) predicate, ... {
    NSMutableArray *objects = [NSMutableArray array];
    va_addToNSMutableArray(predicate, objects);
    return [self andPredicateWithArray:objects];
}

+ (MongoPredicate *) andPredicateWithArray:(NSArray *) array {
    id result = [[self alloc] initWithOperator:MongoAndOperatorKey subPredicates:array];
#if !__has_feature(objc_arc)
    [result autorelease];
#endif
    return result;
}

#pragma mark - And and Or predicates - Mutability and convenience

- (void) addSubPredicate:(MongoPredicate *) predicate {
    [(NSMutableArray *) [_dict objectForKey:_operator] addObject:predicate.dictionary];
}

- (MongoKeyedPredicate *) addKeyedSubPredicate {
    id subPredicate = [[MongoKeyedPredicate alloc] init];
    [self addSubPredicate:subPredicate];
#if !__has_feature(objc_arc)
    [subPredicate autorelease];
#endif
    return subPredicate;
}

#pragma mark - Where predicate

- (MongoPredicate *) initWithWhereExpression:(BSONCode *) whereExpression {
    if (self = [self init]) {
        [_dict setObject:whereExpression forKey:MongoWhereOperatorKey];
    }
    return self;
}

+ (MongoPredicate *) wherePredicateWithExpression:(BSONCode *) whereExpression {
    id result = [[self alloc] initWithWhereExpression:whereExpression];
#if !__has_feature(objc_arc)
    [result autorelease];
#endif
    return result;
}

@end

//@implementation MongoOrPredicate
//
//#pragma mark - Initializtion
//
//- (MongoOrPredicate *) initWithSubPredicate:(MongoPredicate *) predicate {
//    return [self initWithArray:[NSMutableArray arrayWithObject:predicate]];
//}
//
//- (MongoOrPredicate *) initWithSubPredicates:(MongoPredicate *) predicate, ... {
//    NSMutableArray *objects = [NSMutableArray array];
//    va_addToNSMutableArray(predicate, objects);
//    return [self initWithArray:objects];
//}
//
//- (MongoOrPredicate *) initWithArray:(NSArray *) array {
//    return self = [super initWithOperator:MongoOrOperatorKey subPredicates:array];
//}
//
//+ (MongoOrPredicate *) orPredicateWithSubPredicate:(MongoPredicate *) predicate {
//    id result = [[self alloc] initWithSubPredicate:predicate];
//#if !__has_feature(objc_arc)
//    [result autorelease];
//#endif
//    return result;
//}
//
//+ (MongoOrPredicate *) orPredicateWithSubPredicates:(MongoPredicate *) predicate, ... {
//    NSMutableArray *objects = [NSMutableArray array];
//    va_addToNSMutableArray(predicate, objects);
//    return [self orPredicateWithArray:objects];
//}
//
//+ (MongoOrPredicate *) orPredicateWithArray:(NSArray *) array {
//    id result = [[self alloc] initWithArray:array];
//#if !__has_feature(objc_arc)
//    [result autorelease];
//#endif
//    return result;
//}
//
//#pragma mark - Mutability
//
//- (void) addSubPredicate:(MongoPredicate *) predicate {
//    [(NSMutableArray *) [_dict objectForKey:MongoOrOperatorKey] addObject:predicate.dictionary];
//}
//
//#pragma mark - Convenience
//
//- (MongoKeyedPredicate *) addKeyedSubPredicate {
//    id subPredicate = [[MongoKeyedPredicate alloc] init];
//    [self addSubPredicate:subPredicate];
//    return subPredicate;
//}
//
//@end
//
