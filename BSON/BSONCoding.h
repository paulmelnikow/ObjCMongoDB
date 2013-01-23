//
//  BSONCoding.h
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
#import "BSONEncoder.h"
#import "BSONDecoder.h"
#import "BSONTypes.h"

/**
 Provides an interface for custom objects to encode and decode themselves,
 which <code>BSONEncoder</code> and <code>BSONDecoder</code> can invoke. While custom
 objects are responsible for encoding and decoding themselves, but may use any of the
 keyed coding methods provided by the coders.
 
 Neither <code>BSONEncoder</code> nor <code>BSONDecoder</code> support unkeyed encoding.
 
 When encoding properties and instance variables which conform to <code>BSONCoding</code>
 or support keyed archiving with <code>NSCoder</code>, the parent object can invoke
 <code>-encodeObject:forKey:</code> on the encoder, and the encoder will expose an
 embedded docuemnt where the sub-object can encode itself. However, the encoder doesn't
 encode the specific class information of the child object. At the time of decoding,
 the parent object will need to provide class information to the decoder by calling
 <code>-decodeObjectForKey:withClass:</code>. (Usually parent classes know the classes
 of their instance variables, but if the class may vary, the parent should encode the
 class name along with the object itself.)
 
 To encode custom objects by their BSON object ID, implement the object ID
 substitution methods:
 - <code>-BSONObjectID</code> or <code>-BSONObjectIDForEncoder:</code>
 - <code>+instanceForObjectID:decoder:</code>
 Then the parent object can invoke these coder methods:
 - <code>-[BSONEncoder encodeObjectIDForObject:forKey:]</code>
 - <code>-[BSONDecoder decodeObjectIDForKey:substituteObjectWithClass:]</code>
 
 <code>BSONEncoderDelegate</code> and <code>BSONDecoderDelegate</code> provide powerful
 interfaces for overriding encoding and decoding. If the coding behavior depends on
 context, or on the position of the object being encoded in the document tree,
 consider implementing your custom object's standard coding coding behavior using
 this protocol, and allowing the coders to invoke the delegate to substitute references
 or different values for sub-objects when necessary.
 
 The coders offer control to the delegate upon invocation all the encoding and decoding
 methods, except those using base types like <code>-encodeBool:forKey:</code>. It's easy
 to provide default functionality by implementing this protocol, and allow the delegate
 to replace or ignore it later.
 
 This protocol's design comes from <code>NSCoder</code>. For more information, refer to
 Apple's Archives and Serializations Guide.

 */
@protocol BSONCoding <NSObject>
@optional

/**
 Encodes the receiver with the BSON decoder provided. The receiver may invoke any of the
 encoder's keyed encoding methods to encode its properties and instance variables.
 
 Most of the <code>-encode...:forKey:</code> methods invoke the encoder's delegate,
 which provides a way to customize this behavior at the time of encoding.
 @param encoder The active encoder
 */
- (void) encodeWithBSONEncoder:(BSONEncoder *) encoder;

/**
 Returns an object to encode in place of the receiver. The receiver must implement
 keyed archiving and conform to <code>BSONCoding</code> or <code>NSCoding</code>.
 
 If this method returns <code>nil</code>, the coder adopts its <code>behaviorOnNil</code>.
 
 The encoder invokes this method after <code>BSONEncoderDelegate</code> has a chance
 to substitute an object ID with
 <code>-encoder:shouldSubstituteObjectIDForObject:forKeyPath:</code>, before it invokes
 <code>-encoder:willDecodeObject:forKeyPath:</code> and
 <code>-encoder:willReplaceObject:withObject:forKeyPath:</code>. 
 @param encoder The active encoder
 @return <code>self</code>, <code>nil</code>, or an object to encode in place of the receiver
 */
- (id) replacementObjectForBSONEncoder:(BSONEncoder *) encoder;

/**
 Returns an object initialized using data from the BSON decoder provided. The receiver may
 invoke any of the decoder's keyed decoding methods to decode its properties and
 instance variables. 
 
 Most of the <code>-decode...:forKey:</code> methods invoke the decoder's delegate,
 which provides a way to customize this behavior at the time of decoding.
 @param encoder The active decoder
 @return An initialized object for the decoder to return
 */
- (id) initWithBSONDecoder:(BSONDecoder *) decoder;

/**
 Returns an object for the decoder to return in place of the receiver. This method is
 intended to give objects an opportunity to replace themselves with another object
 after decoding, such for de-duplication purposes. It can also be used to finish
 initialization, as the name suggests.
 
 If this method returns <code>nil</code>, the decoder returns <code>nil</code>.
 
 The decoder invokes this method after <code>BSONDecoderDelegate</code> has a chance
 to provide a substitute class with
 <code>-decoder:classToSubstituteForObjectID:forKeyPath:</code>, before it invokes
 <code>-decoder:didDecodeObject:forKeyPath:</code>.
 @return <code>self</code>, <code>nil</code>, or an object to return in place of the receiver
 */
- (id) awakeAfterUsingBSONDecoder:(BSONDecoder *) decoder __attribute__((ns_consumes_self)) NS_RETURNS_RETAINED;

// Support conveninence method encodeUsingObjectID

/**
 Returns a BSON object ID for the receiver.
 
 This method supports the encoder's object ID substitution functionality:
 - <code>-encodeObjectIDForObject:forKey:</code>
 - <code>-encoder:shouldSubstituteObjectIDForObject:forKeyPath:</code> (delegate method)
 
 <code>+instanceForObjectID:decoder:</code> and either this method or
 <code>-BSONObjectIDForEncoder:</code> are required for substituting object IDs during
 encoding and decoding.
 @return A BSON object ID for the receiver
 */
- (BSONObjectID *) BSONObjectID;

/**
 Returns a BSON object ID for the receiver. Can access the encoder's state (including
 its managed object context or delegate) if necessary for determining the correct
 object ID to use.
 
 This method supports the encoder's object ID substitution functionality:
 - <code>-encodeObjectIDForObject:forKey:</code>
 - <code>-encoder:shouldSubstituteObjectIDForObject:forKeyPath:</code> (delegate method)
 
 <code>+instanceForObjectID:decoder:</code> and either this method or
 <code>-BSONObjectIDForEncoder:</code> are required for substituting object IDs during
 encoding and decoding.
 @param encoder The active encoder
 @return A BSON object ID for the receiver
 */
- (BSONObjectID *) BSONObjectIDForEncoder:(BSONEncoder *) encoder;

/**
 Returns an initialized object identified by the BSON object ID. Can access the decoder's
 state (including its managed object context or delegate) if necessary for determining the
 correct object ID to use.
 
 This method can attempt to locate or create the object and return it. If the object can't
 be found, this method can return a proxy object; the object need not be of the receiver's
 class. The method can also simply return nil, in which case the decoder returns nil, or
 decline to resolve the reference, returning the object ID itself.
 
 This method supports the encoder's object ID substitution functionality:
 - <code>-encodeObjectIDForObject:forKey:</code>
 - <code>-encoder:shouldSubstituteObjectIDForObject:forKeyPath:</code> (delegate method)
 
 <code>+instanceForObjectID:decoder:</code> and either this method or
 <code>-BSONObjectIDForEncoder:</code> are required for substituting object IDs during
 encoding and decoding.
 @param objectID The object ID to locate or create
 @param decoder The active decoder
 @return An initialized object for the decoder to return
 */
+ (id) instanceForObjectID:(BSONObjectID *) __attribute__((ns_consumed)) objectID decoder:(BSONDecoder *) decoder;

@end