//
//  MongoFindRequest.h
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

@class BSONDocument;
@class MongoPredicate;

@interface MongoFindRequest : NSObject

- (id) init;
+ (MongoFindRequest *) findRequest;
+ (MongoFindRequest *) findRequestWithPredicate:(MongoPredicate *) predicate;

// Explain how to use these together
- (void) includeKey:(NSString *) key;
- (void) excludeKey:(NSString *) key;

- (void) includeFirst:(NSUInteger) numElements objectsFromArrayWithKey:(NSString *) key;
- (void) includeLast:(NSUInteger) numElements objectsFromArrayWithKey:(NSString *) key;
- (void) includeRange:(NSRange) range objectsFromArrayWithKey:(NSString *) key;

- (void) sortByKey:(NSString *) key ascending:(BOOL) ascending;

- (void) hintIndexKey:(NSString *) key ascending:(BOOL) ascending;

- (NSString *) description;

@property (retain) MongoPredicate *predicate;
@property (assign) int limitResults;
@property (assign) int skipResults;

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
