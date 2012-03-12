//
//  MongoFetchRequest.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OrderedDictionary.h"

@interface MongoFetchRequest : NSObject {
@private
    OrderedDictionary *_fields;
    OrderedDictionary *_sort;
    OrderedDictionary *_hint;
}

- (id) init;
+ (MongoFetchRequest *) fetchRequest;

- (void) includeKey:(NSString *) key;
- (void) excludeKey:(NSString *) key;

- (void) includeFirst:(NSUInteger) numElements objectsFromArrayWithKey:(NSString *) key;
- (void) includeLast:(NSUInteger) numElements objectsFromArrayWithKey:(NSString *) key;
- (void) includeRange:(NSRange) range objectsFromArrayWithKey:(NSString *) key;

- (void) sortByKey:(NSString *) key ascending:(BOOL) ascending;

- (void) hintIndexKey:(NSString *) key ascending:(BOOL) ascending;

- (BSONDocument *) fieldsDocument;
- (OrderedDictionary *) queryDictionaryValue;
- (BSONDocument *) queryDocument;
- (int) options;
- (NSString *) description;

@property (retain) MongoPredicate *predicate;
@property (assign) NSUInteger *limitResults;
@property (assign) NSUInteger *skipResults;

@property (assign) BOOL fetchAllResultsImmediately;
@property (assign) BOOL timeoutEnabled;
@property (assign) BOOL tailable;
@property (assign) BOOL tailableQueryBlocksAwaitingData;
@property (assign) BOOL allowQueryOfNonPrimaryServer;
@property (assign) BOOL allowPartialResults;

@property (assign) BOOL includeIndexKeyOnly;
@property (assign) BOOL explain;
@property (assign) BOOL snapshotMode;
@property (assign) BOOL showDiskLocation;
@property (assign) NSString *comment;
@property (assign) NSInteger maximumDocumentsToScan;
@property (retain) MongoPredicate *lowerIndexBound;
@property (retain) MongoPredicate *upperIndexBound;

@end
