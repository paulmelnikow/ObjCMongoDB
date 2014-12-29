//
//  Mongo_PrivateInterfaces.h
//  ObjCMongoDB
//
//  Copyright 2013 Paul Melnikow and other contributors
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


//
// This file is imported internally by classes in the framework to interact with each other. Avoid using it
// in your application. Use the classes' public interfaces instead.
//

#import "NSArray+MongoAdditions.h"
#import "MongoTypes.h"
#import "MongoConnection.h"
#import "MongoFindRequest.h"
#import "MongoUpdateRequest.h"
#import "MongoPredicate.h"
#import "MongoWriteConcern.h"

@class MutableOrderedDictionary;

@interface BSONDocument (Module)
- (const bson_t *) nativeValue;
- (id) initWithNativeValue:(bson_t *) bson;
@end

@interface MongoDBCollection (Project)
- (id) initWithConnection:(MongoConnection *) connection
         nativeCollection:(mongoc_collection_t *) nativeCollection;
@end

@interface MongoIndex (Project)
+ (MongoIndex *) indexWithDictionary:(NSDictionary *) dictionary;
@end

@interface MongoMutableIndex (Projec)
- (mongoc_index_opt_t) options;
@end

@interface MongoConnection (Project)
- (mongoc_client_t *) clientValue NS_RETURNS_INNER_POINTER;
@end

@interface MongoFindRequest (Project)
- (BSONDocument *) fieldsDocument;
- (BSONDocument *) queryDocument;
- (mongoc_query_flags_t) flags;
- (OrderedDictionary *) queryDictionaryValue;
@end

@interface MongoCursor (Project)
+ (MongoCursor *) cursorWithNativeCursor:(mongoc_cursor_t *) cursor;
@end

@interface MongoUpdateRequest (Project)
- (BSONDocument *) conditionDocumentValue;
- (BSONDocument *) operationDocumentValue;
- (mongoc_update_flags_t) flags;
- (OrderedDictionary *) conditionDictionaryValue;
@end

@interface MongoPredicate (Project)
@property (retain) MutableOrderedDictionary *dictionary;
@end

@interface MongoWriteConcern (Project)
- (mongoc_write_concern_t *) nativeWriteConcern NS_RETURNS_INNER_POINTER;
@end
