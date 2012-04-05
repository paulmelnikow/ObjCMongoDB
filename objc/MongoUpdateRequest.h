//
//  MongoUpdateRequest.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 4/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MongoPredicate.h"
#import "OrderedDictionary.h"

@interface MongoUpdateRequest : NSObject {
@private
    BSONDocument *_replacementDocument;
    OrderedDictionary *_operDict;
}

- (id) initForFirstMatchOnly:(BOOL) firstMatchOnly;
+ (MongoUpdateRequest *) updateRequestForFirstMatchOnly:(BOOL) firstMatchOnly;
+ (MongoUpdateRequest *) updateRequestWithPredicate:(MongoPredicate *) predicate firstMatchOnly:(BOOL) firstMatchOnly;

- (void) replaceDocumentWith:(BSONDocument *) replacementDocument;
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

- (NSString *) description;
- (BSONDocument *) conditionDocumentValue;
- (BSONDocument *) operationDocumentValue;
- (int) flags;

- (OrderedDictionary *) conditionDictionaryValue;

@property (retain) MongoPredicate *predicate;
@property (assign) BOOL updatesFirstMatchOnly;
@property (assign) BOOL insertsIfNoMatches;
@property (assign) BOOL blocksDuringMultiUpdates;

@end
