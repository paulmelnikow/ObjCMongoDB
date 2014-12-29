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
@class MongoWriteConcern;
@class MongoMutableIndex;

@interface MongoDBCollection : NSObject

- (BOOL) insertDocument:(BSONDocument *) document
           writeConcern:(MongoWriteConcern *) writeConcern
                  error:(NSError * __autoreleasing *) error;
- (BOOL) insertDocuments:(NSArray *) documentArray
         continueOnError:(BOOL) continueOnError
            writeConcern:(MongoWriteConcern *) writeConcern
                   error:(NSError * __autoreleasing *) error;
- (BOOL) insertDictionary:(NSDictionary *) dictionary
             writeConcern:(MongoWriteConcern *) writeConcern
                    error:(NSError * __autoreleasing *) error;

- (BOOL) updateWithRequest:(MongoUpdateRequest *) updateRequest
                     error:(NSError * __autoreleasing *) error;

- (int64_t) countWithPredicate:(MongoPredicate *) predicate
                         error:(NSError * __autoreleasing *) error;

// Returns an array of BSONDocument objects
- (NSArray *) findWithRequest:(MongoFindRequest *) fetchRequest
                        error:(NSError * __autoreleasing *) error;
- (NSArray *) findWithPredicate:(MongoPredicate *) predicate
                          error:(NSError * __autoreleasing *) error;
- (NSArray *) findAllWithError:(NSError * __autoreleasing *) error;

//- (BSONDocument *) findOneWithRequest:(MongoFindRequest *) fetchRequest
//                                error:(NSError * __autoreleasing *) error;
//- (BSONDocument *) findOneWithPredicate:(MongoPredicate *) predicate
//                                  error:(NSError * __autoreleasing *) error;
//- (BSONDocument *) findOneWithError:(NSError * __autoreleasing *) error;

/**
 Designed for high-volume fetches when you don't want to fetch all the documents
 before you start working with them.
 */
- (MongoCursor *) cursorForFindRequest:(MongoFindRequest *) fetchRequest;
- (MongoCursor *) cursorForFindWithPredicate:(MongoPredicate *) predicate;
- (MongoCursor *) cursorForFindAll;

/**
 Note: error is ignored. Examine the cursor to see the error.
 */
- (MongoCursor *) cursorForFindRequest:(MongoFindRequest *) fetchRequest
                                 error:(NSError * __autoreleasing *) error __deprecated_msg("Use -cursorForFindRequest:");
- (MongoCursor *) cursorForFindWithPredicate:(MongoPredicate *) predicate
                                       error:(NSError * __autoreleasing *) error __deprecated_msg("Use -cursorForFindWithPredicate:");
- (MongoCursor *) cursorForFindAllWithError:(NSError * __autoreleasing *) error __deprecated_msg("Use -cursorForFindAll");

- (BOOL) removeWithPredicate:(MongoPredicate *) predicate
                writeConcern:(MongoWriteConcern *) writeConcern
                       error:(NSError * __autoreleasing *) error;
- (BOOL) removeAllWithWriteConcern:(MongoWriteConcern *) writeConcern
                             error:(NSError * __autoreleasing *) error;

// TODO
//- (NSArray *) allIndexesWithError:(NSError * __autoreleasing *) error;
// TODO
//- (BOOL) ensureIndex:(MongoMutableIndex *) index error:(NSError * __autoreleasing *) error;

- (BOOL) dropCollectionWithError:(NSError *__autoreleasing *) outError;

// These are shared across all collections for the connection
// TODO
//- (BOOL) lastOperationWasSuccessful:(NSError * __autoreleasing *) error;
//- (NSDictionary *) lastOperationDictionary;
//- (NSError *) error;
//- (NSError *) serverError;

@end