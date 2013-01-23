//
//  BSONTypes.h
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

/**
 Returns the time the object ID was generated.
 @return the time the object ID was generated
 */
- (NSDate *) dateGenerated;

/*! Compare two object ID values. */
- (NSComparisonResult)compare:(BSONObjectID *) other;

/*! Test for equality with another object ID. */
- (BOOL)isEqual:(id)other;

@end

/**
 A wrapper class encapsulating a BSON regular expression.
 */
@interface BSONRegularExpression : NSObject

+ (BSONRegularExpression *) regularExpressionWithPattern:(NSString *) pattern options:(NSString *) options;

@property (retain) NSString *pattern;
@property (retain) NSString *options;

@end

/**
 A wrapper and convenience encapsulating a BSON timestamp.
 */
@interface BSONTimestamp : NSObject {
    bson_timestamp_t _timestamp;
}

+ (BSONTimestamp *) timestampWithNativeTimestamp:(bson_timestamp_t)timestamp;
+ (BSONTimestamp *) timestampWithIncrement:(int) increment timeInSeconds:(int) time;

@property (assign) int increment;
@property (assign) int timeInSeconds;

@end

@class BSONDocument;

/**
 A wrapper class encapsulating a BSON code object.
 
 When passing an instance of this class to <code>-[BSONEncoder encodeObject:forKey:]</code>,
 the encoder treats it as a code instead of a string.
 <code>-[BSONDecoder decodeObject:forKey:]</code> and <code>-[BSONIterator objectValue]</code>
 return instances of this type, allowing the caller to distinguish a code object from a
 string.
 */
@interface BSONCode : NSObject
+ (BSONCode *) code:(NSString *) code;
@property (retain) NSString * code;
@end

/**
 A wrapper class encapsulating a BSON code with scope object.
 */
@interface BSONCodeWithScope : BSONCode
+ (BSONCodeWithScope *) code:(NSString *) code withScope:(BSONDocument *) scope;
@property (retain) BSONDocument * scope;
@end

/**
 A wrapper class encapsulating a BSON symbol object.
 
 When passing an instance of this class to <code>-[BSONEncoder encodeObject:forKey:]</code>,
 the encoder treats it as a symbol instead of a string.
 <code>-[BSONDecoder decodeObject:forKey:]</code> and <code>-[BSONIterator objectValue]</code>
 return instances of this type, allowing the caller to distinguish a symbol object from a
 string.
 */
@interface BSONSymbol : NSObject 
+ (BSONSymbol *) symbol:(NSString *)symbol;
@property (retain) NSString * symbol;
@end