/*!
@header NuMongoDB.h
@discussion Declarations for the NuMongoDB component.
@copyright Copyright (c) 2010 Radtastical, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#import <Foundation/Foundation.h>
#import "mongo.h"
#import "BSONTypes.h"

@class NuBSON;

/*!
   @class NuMongoDBCursor
   @abstract A cursor used to iterate results returned by MongoDB database queries.
   @discussion We typically receive cursors when we use the MongoDB find command.
   Cursors are recommended for iterating over large result sets.
 */
@interface NuMongoDBCursor : NSObject
{
    mongo_cursor *cursor;
}

/*! Step the cursor to the next object. */
- (BOOL) next;
/*! Get the NuBSON representation of the current object. */
- (NuBSON *) currentBSON;
/*! Get the native representation of the current object. */
- (NSDictionary *) currentObject;
/*! Return the remaining elements in an array. */
- (NSMutableArray *) arrayValue;

@end

/*!
   @class NuMongoDB
   @abstract A connection to a MongoDB database.
   @discussion NuMongoDB instances are used to connect to, update, and query MongoDB databases.
 */
@interface NuMongoDB : NSObject
{
    mongo_connection conn[1];
    mongo_connection_options opts;
}

/*! Connect to a MongoDB database. Options can include @"host" and @"port". */
- (int) connectWithOptions:(NSDictionary *) options;
/*! Connect to a local MongoDB database on the default port (27017). */
- (int) connect;
/*! Add user to named database. */
- (void) addUser:(NSString *) user withPassword:(NSString *) password forDatabase:(NSString *) database;
/*! Authenticate to named database. */
- (BOOL) authenticateUser:(NSString *) user withPassword:(NSString *) password forDatabase:(NSString *) database;
/*! Convenience method for database searches. Query should be a dictionary. */
- (NuMongoDBCursor *) find:(id) query inCollection:(NSString *) collection;
/*! Main search method. Query and fields specifiers are dictionaries or nil. */
- (NuMongoDBCursor *) find:(id) query inCollection:(NSString *) collection returningFields:(id) fields numberToReturn:(int) nToReturn numberToSkip:(int) nToSkip;
/*! Convenience method that returns search results as an array. */
- (NSMutableArray *) findArray:(id) query inCollection:(NSString *) collection;
/*! Convenience method that returns search results as an array.  */
- (NSMutableArray *) findArray:(id) query inCollection:(NSString *) collection returningFields:(id) fields numberToReturn:(int) nToReturn numberToSkip:(int) nToSkip;
/*! Convenience method that can be used to atomically modify a document (at most one) and return it.  */
- (NSMutableDictionary *) findAndModify:(id)collection options:(NSDictionary *)options inDatabase:(NSString *)database;
/*! Convenience method that returns search results as a single object.  */
- (NSMutableDictionary *) findOne:(id) query inCollection:(NSString *) collection;
/*! Add an object to a collection, returning the _id of the new object. */
- (id) insertObject:(id) insert intoCollection:(NSString *) collection;
/*! Add an array of objects to a collection */
- (void) insertObjects:(NSArray *)array intoCollection:(NSString *) collection;
/*! Update an object in a collection. insertIfNecessary triggers an "upsert". */
- (void) updateObject:(id) update inCollection:(NSString *) collection withCondition:(id) condition insertIfNecessary:(BOOL) insertIfNecessary updateMultipleEntries:(BOOL) updateMultipleEntries;
/*! Remove an object or objects matching a specified condition. */
- (void) removeWithCondition:(id) condition fromCollection:(NSString *) collection;
/*! Count objects with a specified condition. */
- (long long) countWithCondition:(id) condition inCollection:(NSString *) collection inDatabase:(NSString *) database;
/*! Run an arbitrary database command. */
- (id) runCommand:(id) command inDatabase:(NSString *) database;
/*! Get the names of the collections in a database. */
- (id) collectionNamesInDatabase:(NSString *) database;
/*! Convenience method to list all the databases on the connected server. */
- (id) listDatabases;
/*! Remove a database. */
- (BOOL) dropDatabase:(NSString *) database;
/*! Remove a collection. */
- (BOOL) dropCollection:(NSString *) collection inDatabase:(NSString *) database;
/*! Create a collection if it doesn't already exist. */
- (BOOL) ensureCollection:(NSString *) collection hasIndex:(NSObject *) key withOptions:(int) options;
/*! Close a database connection. */
- (void) close;
/*! GridFS write file */
- (NSMutableDictionary *) writeFile:(NSString *)filePath withMIMEType:(NSString *)type inCollection:(NSString *) collection inDatabase:(NSString *) database;
- (NSMutableDictionary *) writeData:(NSData *)data named:(NSString *)file withMIMEType:(NSString *)type inCollection:(NSString *) collection inDatabase:(NSString *) database;
- (NSData *) retrieveDataforGridFSFile:(NSString *) filePath inCollection:(NSString *) collection inDatabase:(NSString *) database;
-(BOOL) removeFile:(NSString *)filePath inCollection:(NSString *) collection inDatabase:(NSString *) database;
/*! Automatically record update times by inserting an _up NSDate with each update. */
+ (void) setEnableUpdateTimestamps:(BOOL) enable;
@end
