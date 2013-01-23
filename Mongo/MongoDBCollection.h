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
#import "MongoFetchRequest.h"
#import "MongoUpdateRequest.h"

@class MongoConnection;

@interface MongoDBCollection : NSObject

- (BOOL) insert:(BSONDocument *) document error:(NSError **) error;
- (BOOL) insertDictionary:(NSDictionary *) dictionary error:(NSError **) error;
- (BOOL) insertObject:(id) object error:(NSError **) error;
- (BOOL) insertBatch:(NSArray *) documentArray error:(NSError **) error;

- (BOOL) update:(MongoUpdateRequest *) updateRequest error:(NSError **) error;

- (NSArray *) find:(MongoFetchRequest *) fetchRequest error:(NSError **) error;
- (NSArray *) findWithPredicate:(MongoPredicate *) predicate error:(NSError **) error;
- (NSArray *) findAllWithError:(NSError **) error;

- (MongoCursor *) cursorForFind:(MongoFetchRequest *) fetchRequest error:(NSError **) error;
- (MongoCursor *) cursorForFindWithPredicate:(MongoPredicate *) predicate error:(NSError **) error;
- (MongoCursor *) cursorForFindAllWithError:(NSError **) error;

- (BSONDocument *) findOne:(MongoFetchRequest *) fetchRequest error:(NSError **) error;
- (BSONDocument *) findOneWithPredicate:(MongoPredicate *) predicate error:(NSError **) error;
- (BSONDocument *) findOneWithError:(NSError **) error;

- (NSUInteger) countWithPredicate:(MongoPredicate *) predicate error:(NSError **) error;

- (BOOL) remove:(MongoPredicate *) predicate error:(NSError **) error;
- (BOOL) removeAllWithError:(NSError **) error;

- (BOOL) serverStatusForLastOperation:(NSError **) error;
- (NSDictionary *) serverStatusAsDictionaryForLastOperation;
- (NSError *) error;
- (NSError *) serverError;

@property (retain) MongoConnection * connection;
@property (copy, nonatomic) NSString * name;
@property (copy, nonatomic) NSString * databaseName;
@property (copy, nonatomic) NSString * namespaceName;
@property (readonly, assign) const char * utf8Name;
@property (readonly, assign) const char * utf8DatabaseName;
@property (readonly, assign) const char * utf8NamespaceName;

@end