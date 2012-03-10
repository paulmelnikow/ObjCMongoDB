//
//  BSONEncoder.h
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
#import <AppKit/AppKit.h>
#import "BSONTypes.h"
#import "bson.h"

typedef enum {
    BSONDoNothingOnNil,
    BSONEncodeNullOnNil,
    BSONRaiseExceptionOnNil
} BSONEncoderBehaviorOnNil;

@class BSONDocument;
@class BSONEncoder;

@protocol BSONEncoderDelegate
@optional
// never called on the root object
- (BOOL) encoder:(BSONEncoder *) encoder shouldSubstituteObjectIDForObject:(id) obj forKeyPath:(NSArray *) keyPathComponents;
- (id) encoder:(BSONEncoder *) encoder willEncodeObject:(id) obj forKeyPath:(NSArray *) keyPathComponents;
- (void) encoder:(BSONEncoder *) encoder willReplaceObject:(id) obj withObject:(id) replacementObj forKeyPath:(NSArray *) keyPathComponents;
- (void) encoder:(BSONEncoder *) encoder didEncodeObject:(id) obj forKeyPath:(NSArray *) keyPathComponents;
- (void) encoderDidFinish:(BSONEncoder *) encoder;
- (void) encoderWillFinish:(BSONEncoder *) encoder;

@end

/**
 Provides a high-level interface for creating a BSON document from a top-level object.
 <code>BSONEncoder</code> handles BSON-supported types, arrays and dictionaries, and custom objects
 which conform to <code>NSCoding</code> and support keyed archiving.
 
 Invoke <code>BSONDocument</code> to finish encoding and return the encoded document. To encode another
 top-level object, instantiate another encoder.

 <code>BSONEncoder</code> follows the design of <code>NSCoder</code> as much as possible. For more
 details, refer to Apple's Objects and Serializations Guide.
  
 Important differences from <code>NSKeyedArchiver</code>:
 
 - <code>BSONEncoder</code> provides its own encoding implementation for:
     - <code>NSString</code>
     - <code>NSNumber</code>
     - <code>NSDate</code>
     - <code>NSData</code>
     - <code>NSImage</code>
     - <code>NSDictionary</code>
     - <code>NSArray</code>
     - <code>BSONObjectID</code> and the other classes defined in <code>BSONTypes.h</code>
 - <code>BSONEncoder</code> does not store class information. While BSON documents include enough
 type information to decode to appropriate Objective-C object types, <code>BSONDecoder</code> relies
 on subclasses to encode themselves.
 - <code>BSONEncoder</code> does not store version information.
 - <code>BSONEncoder</code> does not support unkeyed coding. (If your custom objects can't implement
 unkeyed coding, you can implement unkeyed coding by subclassing <code>BSONEncoder</code> and
 overriding the unkeyed methods to automatically generate pre-defined, sequential key names, and
 subclassing <code>BSONDecoder</code> to override the decoding methods to use these pre-defined key
 names in the same sequence.)
 - BSON documents may contain only one top-level object. Encoding multiple objects by encapsulating
 them in an parent object, or by creating a separate BSON document for each one. (Each document
 inserted into a MongoDB collection needs its own BSON document.)
 - In MongoDB, key names may not contain <code>$</code> or <code.</code> characters. By default,
 <code>BSONEncoder</code> throws an exception on illegal keys. You can control this behavior by
 setting <code>restrictsKeyNamesForMongoDB</code> to <code>NO</code>. (Note that implementations
 of <code>-encodeWithCoder:</code> in some Foundation classes may generate illegal keys. If this is
 a problem, consider subclassing to mangle the keys so they're safe for MongoDB.)
 - <code>BSONEncoder</code> does not allow objects to override their encoding with
 <code>classForCoder</code>. Use <code>-encodeWithCoder:</code> (from <code>NSCoding</code>),
 <code>-replacementObjectForCoder:</code> (from <code>NSObject</code>),
 <code>-encodeWithBSONEncoder:</code>, or <code>-replacementObjectForBSONEncoder:</code> (both from
 <code>BSONCoding</code>) instead.
 - <code>BSONEncoder</code> does not automatically encode objects by reference, even duplicate objects.
 (BSON's object ID type is useful for identifying a reference to another document in a MongoDB collection,
 but unlike an Objective-C pointer, it can't be used to refer to a sub-object. A BSON object ID only
 gets meaning in the context of a MongoDB collection. It has no meaning within a single document.) To
 encode an object by reference, either the object or the delegate needs to substitute another object.
 (See Encoding by Reference below.)
 - To avoid infinite loops, <code>BSONEncoder</code> throws an exception if an object attempts to encode
 its parent object or its direct ancestors. This check is done after object and delegate substitution,
 and isn't triggered when, for example, an object ID is substituted in place of a parent object.
 - <code>BSONEncoderDelegate</code> provides a similar interface to <code>NSKeyedArchiver</code>, but
 conveys additional state information in the encoder's key path, and provides an additional delegate
 method for substituing object IDs during encoding.
  
 Encoding by Reference
 
 While by default <code>BSONEncoder</code> encodes child objects essentially by copying, it provides
 a mechanism for substituting BSON object IDs for child objects. If an object should <i>always</i>
 encode a child as an object ID, its <code>-encodeWithCoder:</code> can invoke
 <code>-encodeObjectIDForObject:forKey:</code>. If the appropriate behavior depends on context or
 other factors, have the delegate implement
 <code>-encoder:shouldSubstituteObjectIDForObject:forKeyPath:</code>, and consider the key path,
 key path depth, the object, or the delegate's own state.
 
 For either of these to work, the child object must be able to generate an object ID by implementing
 <code>BSONObjectID</code> or <code>BSONObjectIDForEncoder:</code> (defined in <code>BSONCoding</code>).
 
 To encode some other reference structure, use one of the substitution methods of the object or delegate.
 
 Controlling encoding of sub-objects
 
 Objects may control their encoding by implementing one of these methods:
 - <code>-encodeWithCoder:</code>
 - <code>-encodeWithBSONEncoder:</code>
 - <code>-replacementObjectForCoder:</code>
 - <code>-replacementObjectForBSONEncoder:</code>
 
 In addition, a delegate may control encoding by implementing one of these methods:
 - <code>-encoder:shouldSubstituteObjectIDForObject:forKeyPath:</code>
 - <code>-encoder:willEncodeObject:forKeyPath:</code>
 */
@interface BSONEncoder : NSCoder {
@private
    bson *_bson;
    NSMutableArray *_bufferStack;
    NSMutableArray *_encodingObjectStack;
    NSMutableArray *_keyPathComponents;
    BSONDocument *_resultDocument;
}

- (BSONEncoder *) initForWriting;

+ (BSONDocument *) documentForObject:(id) obj;
+ (BSONDocument *) documentForDictionary:(NSDictionary *) dictionary;

- (BSONDocument *) BSONDocument;

- (void) encodeObject:(id) obj;
- (void) encodeDictionary:(NSDictionary *) dictionary;

- (void) encodeObject:(id) objv forKey:(NSString *) key;

// objectid is substituted before other methods, eg delegate, are called
// objv must implement -BSONObjectID or -BSONObjectIDForEncoder: method
- (void) encodeObjectIDForObject:(id) objv forKey:(NSString *) key;
- (void) encodeDictionary:(NSDictionary *) dictionary forKey:(NSString *) key;
- (void) encodeArray:(NSArray *) array forKey:(NSString *) key;
- (void) encodeBSONDocument:(BSONDocument *) objv forKey:(NSString *) key;

- (void) encodeNullForKey:(NSString *) key;
- (void) encodeUndefinedForKey:(NSString *) key;

- (void) encodeNewObjectID;
- (void) encodeObjectID:(BSONObjectID *)objv forKey:(NSString *) key;

- (void) encodeInt:(int) intv forKey:(NSString *) key;
- (void) encodeInt64:(int64_t) intv forKey:(NSString *) key;
- (void) encodeBool:(BOOL) boolv forKey:(NSString *) key;
- (void) encodeDouble:(double) realv forKey:(NSString *) key;
- (void) encodeNumber:(NSNumber *) objv forKey:(NSString *) key;

- (void) encodeString:(NSString *)objv forKey:(NSString *) key;
- (void) encodeSymbol:(BSONSymbol *)objv forKey:(NSString *) key;

- (void) encodeDate:(NSDate *) objv forKey:(NSString *) key;
- (void) encodeImage:(NSImage *) objv forKey:(NSString *) key;

- (void) encodeRegularExpression:(BSONRegularExpression *) regex forKey:(NSString *) key;
- (void) encodeRegularExpressionPattern:(NSString *) pattern options:(NSString *) options forKey:(NSString *) key;
- (void) encodeCode:(BSONCode *) objv forKey:(NSString *) key;
- (void) encodeCodeString:(NSString *) objv forKey:(NSString *) key;
- (void) encodeCodeWithScope:(BSONCodeWithScope *) codeWithScope forKey:(NSString *) key;
- (void) encodeCodeString:(NSString *) code withScope:(BSONDocument *)scope forKey:(NSString *) key;

- (void) encodeData:(NSData *) objv forKey:(NSString *) key;

- (void) encodeTimestamp:(BSONTimestamp *) objv forKey:(NSString *) key;

- (NSArray *) keyPathComponents;

@property (retain) NSObject<BSONEncoderDelegate> * delegate;
@property (assign) BSONEncoderBehaviorOnNil behaviorOnNil;
@property (assign) BOOL restrictsKeyNamesForMongoDB;

@end