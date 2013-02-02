//
//  MongoPredicate.h
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

#import <Foundation/Foundation.h>
#import "BSONTypes.h"

@class BSONDocument;
@class MongoKeyedPredicate;

@interface MongoPredicate : NSObject

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

- (BSONDocument *) BSONDocument;
- (NSString *) description;

@end