//
//  BSONObjectID.h
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
#import "bson.h"

/**
 Encapsulates an immutable BSON object ID, as a wrapper around a <code>bson_oid_t</code>
 structure.

 Each instance creates a bson_oid_t object during initialization and destoys it on
 deallocation.
 
 @seealso http://www.mongodb.org/display/DOCS/Object+IDs
 */
@interface BSONObjectID : NSObject {
@private
    bson_oid_t _oid;
    NSString *_stringValue;
}

/**
 Creates a new, unique object ID.
 */
+ (BSONObjectID *) objectID;

/*
 Creates an object ID from a hexadecimal string.
 @param A 24-character hexadecimal string for the object ID
 @seealso http://www.mongodb.org/display/DOCS/Object+IDs
 */
+ (BSONObjectID *) objectIDWithString:(NSString *) s;

/**
 Creates a object ID from a data representation.
 @param data A 12-byte data representation for the object ID
 @seealso http://www.mongodb.org/display/DOCS/Object+IDs
 */
+ (BSONObjectID *) objectIDWithData:(NSData *) data;

/**
 Creates a object ID by copying a native <code>bson_oid_t</code> structure.
 @param objectIDPointer A bson_oid_t structure
 */
+ (BSONObjectID *) objectIDWithNativeOID:(const bson_oid_t *) objectIDPointer;


/**
 Returns the 24-digit hexadecimal string value of the receiver.
 @return The hex string value of an object ID.
 */
- (NSString *) stringValue;

/**
 Returns the data representation of the receiver.
 @return The data representation of the receiver.
 */
- (NSData *) dataValue;

/*! Compare two object ID values. */
- (NSComparisonResult)compare:(BSONObjectID *) other;

/*! Test for equality with another object ID. */
- (BOOL)isEqual:(id)other;

@end