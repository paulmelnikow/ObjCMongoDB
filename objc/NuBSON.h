/*!
@header NuBSON.h
@discussion Declarations for the NuBSON component.
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

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#import <Foundation/Foundation.h>
#import "bson.h"

/*!
   @class NuBSON
   @abstract A BSON serializer and deserializer.
   @discussion BSON is the wire format used to communicate with MongoDB.
 */
@interface NuBSON : NSObject
{
    @public
    bson bsonValue;
}
/*! Create a BSON representation from serialized NSData. */
+ (NuBSON *) bsonWithData:(NSData *) data;
/*! Create an array of BSON objects from serialized NSData. */
+ (NSMutableArray *) bsonArrayWithData:(NSData *) data;

/*! Create a BSON representation of a dictionary object. */
+ (NuBSON *) bsonWithDictionary:(NSDictionary *) dict;
/*! Create a BSON representation from a Nu list. */
+ (NuBSON *) bsonWithList:(id) cell;

/*! Create a BSON representation from serialized NSData. */
- (NuBSON *) initWithData:(NSData *) data;
/*! Create a BSON representation of a dictionary object. */
- (NuBSON *) initWithDictionary:(NSDictionary *) dict;
/*! Create a BSON representation from a Nu list. */
- (NuBSON *) initWithList:(id) cell;

/*! Return an NSData representation of the BSON object. */
- (NSData *) dataRepresentation;
/*! Return a dictionary equivalent of a BSON object. */
- (NSMutableDictionary *) dictionaryValue;

/*! Return an array containing all the top-level keys in the BSON object. */
- (NSArray *) allKeys;

/*! Return a named top-level element of the BSON object. */
- (id) objectForKey:(NSString *) key;
/*! Return a named element of the BSON object. */
- (id) objectForKeyPath:(NSString *) keypath;
@end

@interface NuBSONObjectID : NSObject
{
    @public
    bson_oid_t oid;
}

/*! Create a new and unique object ID. */
+ (NuBSONObjectID *) objectID;
/*! Create an object ID from a 12-byte data representation. */
+ (NuBSONObjectID *) objectIDWithData:(NSData *) data;
/*! Create an object ID wrapper from a bson_oid_t native structure. */
+ (NuBSONObjectID *) objectIDWithObjectIDPointer:(const bson_oid_t *) objectIDPointer;
/*! Create an object ID from a hex string. */
- (id) initWithString:(NSString *) s;
/*! Get the hex string value of an object ID. */
- (NSString *) stringValue;
/*! Create an object ID from an NSData representation. */
- (id) initWithData:(NSData *) data;
/*! Get the NSData representation of an object ID. */
- (NSData *) dataRepresentation;
/*! Compare two object ID values. */
- (NSComparisonResult)compare:(NuBSONObjectID *) other;
/*! Test for equality with another object ID. */
- (BOOL)isEqual:(id)other;
/*! Raw object id */
- (bson_oid_t) oid;
@end

@interface NuBSONBuffer : NSObject 
{
	bson_buffer bb;	
}

- (id) init;
- (NuBSON *) bsonValue;
- (void) addObject:(id) object withKey:(id) key;
@end

bson *bson_for_object(id object); // used in NuMongoDB

@interface NuBSONComparator : NSObject
{
    NuBSON *specification;
}
/*! Create a new and comparator for the given BSON specification. */
+ (NuBSONComparator *) comparatorWithBSONSpecification:(NuBSON *) s;
/*! Compare BSON data using the associated specification. */
- (int) compareDataAtAddress:(const void *) aptr withSize:(int) asiz withDataAtAddress:(const void *) bptr withSize:(int) bsiz;

@end


// deprecated convenience categories
@interface NSData (NuBSON)
- (NSMutableDictionary *) BSONValue;
@end

@interface NSDictionary (NuBSON)
- (NSData *) BSONRepresentation;
@end