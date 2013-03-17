//
//  MongoUpdateRequest.h
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
#import "MongoPredicate.h"
#import "OrderedDictionary.h"

@class MongoWriteConcern;

@interface MongoUpdateRequest : NSObject

- (id) initForFirstMatchOnly:(BOOL) firstMatchOnly;
+ (MongoUpdateRequest *) updateRequestForFirstMatchOnly:(BOOL) firstMatchOnly;
+ (MongoUpdateRequest *) updateRequestWithPredicate:(MongoPredicate *) predicate
                                     firstMatchOnly:(BOOL) firstMatchOnly;

- (void) replaceDocumentWithDocument:(BSONDocument *) replacementDocument;
- (void) replaceDocumentWithDictionary:(NSDictionary *) replacementDictionary;

- (void) keyPath:(NSString *) keyPath setValue:(id) value;
- (void) unsetValueForKeyPath:(NSString *) keyPath;

- (void) incrementValueForKeyPath:(NSString *) keyPath;
- (void) keyPath:(NSString *) keyPath incrementValueBy:(NSNumber *) increment;
- (void) keyPath:(NSString *) keyPath bitwiseAndWithValue:(NSInteger) value;
- (void) keyPath:(NSString *) keyPath bitwiseOrWithValue:(NSInteger) value;

- (void) setForKeyPath:(NSString *) keyPath addValue:(NSString *) value;
- (void) setForKeyPath:(NSString *) keyPath addValuesFromArray:(NSArray *) values;
- (void) arrayForKeyPath:(NSString *) keyPath removeItemsMatchingValue:(id) value;
- (void) arrayForKeyPath:(NSString *) keyPath removeItemsMatchingAnyFromArray:(NSArray *) array;
- (void) removeMatchingValuesFromArrayUsingKeyedPredicate:(MongoKeyedPredicate *) keyedPredicate;

- (void) arrayForKeyPath:(NSString *) keyPath appendValue:(id) value;
- (void) arrayForKeyPath:(NSString *) keyPath appendValuesFromArray:(NSArray *) values;
- (void) removeLastValueFromArrayForKeyPath:(NSString *) keyPath;
- (void) removeFirstValueFromArrayForKeyPath:(NSString *) keyPath;

- (void) keyPath:(NSString *) oldKey renameToKey:(NSString *) newKey;

@property (retain) MongoPredicate *predicate;
@property (assign) BOOL updatesFirstMatchOnly;
@property (assign) BOOL insertsIfNoMatches; // This is upsert
@property (assign) BOOL blocksDuringMultiUpdates;
@property (retain) MongoWriteConcern *writeConcern;

@end
