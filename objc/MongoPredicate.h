//
//  MongoAbstractPredicate.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OrderedDictionary.h"
#import "BSONTypes.h"

extern NSString * const MongoNotOperatorKey;

@class BSONDocument;
@class MongoKeyedPredicate;

@interface MongoPredicate : NSObject {
@protected
    OrderedDictionary *_dict;
    NSString *_operator;
}

- (id) init;
- (id) initWithOperator:(NSString *) operator subPredicates:(NSArray *) subPredicates;
- (MongoPredicate *) initWithWhereExpression:(BSONCode *) whereExpression;

+ (MongoPredicate *) predicate;

+ (MongoPredicate *) orPredicateWithSubPredicate:(MongoPredicate *) predicate;
+ (MongoPredicate *) orPredicateWithSubPredicates:(MongoPredicate *) predicate, ... NS_REQUIRES_NIL_TERMINATION;
+ (MongoPredicate *) orPredicateWithArray:(NSArray *) array;

+ (MongoPredicate *) norPredicateWithSubPredicate:(MongoPredicate *) predicate;
+ (MongoPredicate *) norPredicateWithSubPredicates:(MongoPredicate *) predicate, ... NS_REQUIRES_NIL_TERMINATION;
+ (MongoPredicate *) norPredicateWithArray:(NSArray *) array;

+ (MongoPredicate *) andPredicateWithSubPredicate:(MongoPredicate *) predicate;
+ (MongoPredicate *) andPredicateWithSubPredicates:(MongoPredicate *) predicate, ... NS_REQUIRES_NIL_TERMINATION;
+ (MongoPredicate *) andPredicateWithArray:(NSArray *) array;

+ (MongoPredicate *) wherePredicateWithExpression:(BSONCode *) whereExpression;

// only when initialized wiht operator
- (void) addSubPredicate:(MongoPredicate *) predicate;
- (MongoKeyedPredicate *) addKeyedSubPredicate;

- (OrderedDictionary *) dictionary;
- (BSONDocument *) BSONDocument;
- (NSString *) description;

@end