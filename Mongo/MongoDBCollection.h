//
//  MongoDBCollection.h
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
#import "MongoCursor.h"
#import "MongoFindRequest.h"
#import "MongoUpdateRequest.h"

@class MongoConnection;

@interface MongoDBCollection : NSObject

- (BOOL) insertDocument:(BSONDocument *) document error:(NSError * __autoreleasing *) error;
- (BOOL) insertDocuments:(NSArray *) documentArray error:(NSError * __autoreleasing *) error;
- (BOOL) insertDictionary:(NSDictionary *) dictionary error:(NSError * __autoreleasing *) error;
- (BOOL) insertObject:(id) object error:(NSError * __autoreleasing *) error;

- (BOOL) updateWithRequest:(MongoUpdateRequest *) updateRequest error:(NSError * __autoreleasing *) error;

- (NSUInteger) countWithPredicate:(MongoPredicate *) predicate error:(NSError * __autoreleasing *) error;

// Returns an array of BSONDocument objects
- (NSArray *) findWithRequest:(MongoFindRequest *) fetchRequest error:(NSError * __autoreleasing *) error;
- (NSArray *) findWithPredicate:(MongoPredicate *) predicate error:(NSError * __autoreleasing *) error;
- (NSArray *) findAllWithError:(NSError * __autoreleasing *) error;

- (BSONDocument *) findOneWithRequest:(MongoFindRequest *) fetchRequest error:(NSError * __autoreleasing *) error;
- (BSONDocument *) findOneWithPredicate:(MongoPredicate *) predicate error:(NSError * __autoreleasing *) error;
- (BSONDocument *) findOneWithError:(NSError * __autoreleasing *) error;

// Designed for high-volume fetches when you don't want to fetch all the documents before you start
// working with them.
- (MongoCursor *) cursorForFindRequest:(MongoFindRequest *) fetchRequest error:(NSError * __autoreleasing *) error;
- (MongoCursor *) cursorForFindWithPredicate:(MongoPredicate *) predicate error:(NSError * __autoreleasing *) error;
- (MongoCursor *) cursorForFindAllWithError:(NSError * __autoreleasing *) error;

- (BOOL) removeWithPredicate:(MongoPredicate *) predicate error:(NSError * __autoreleasing *) error;
- (BOOL) removeAllWithError:(NSError * __autoreleasing *) error;

// These are shared across all collections for the connection
- (BOOL) lastOperationWasSuccessful:(NSError * __autoreleasing *) error;
- (NSDictionary *) lastOperationDictionary;
- (NSError *) error;
- (NSError *) serverError;

@property (retain) MongoConnection * connection;
@property (copy, nonatomic) NSString * name;
@property (copy, nonatomic) NSString * databaseName;
@property (copy, nonatomic) NSString * namespaceName;

@end