//
//  BSONDocument.h
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
#import "BSONIterator.h"

@class BSONEncoder;

/**
 Encapsulates a finished, immutable BSON document, as a wrapper around a
 <code>bson</code> structure.
 
 Each instance creates or takes ownership of a bson object during
 initialization and destoys it on deallocation.
 
 For a mutable document, instantiate a BSONEncoder.
 */
@interface BSONDocument : NSObject

/**
 Returns an empty BSON document.
 */
+ (BSONDocument *) document;

/**
 Returns an empty BSON document created using the given data block, which it
 retains and accesses directly.
 
 If <i>data</i> is mutable, it retains a copy instead.
 
 @param data An instance of <code>NSData</code> with the binary data for the new
 document.
 */
+ (BSONDocument *) documentWithData:(NSData *) data;

/**
 Returns an immutable <code>NSData</code> object with the contents of the document's
 BSON data buffer.
 
 The NSData object is guaranteed to remain valid even if the receiver is deallocated.
 
 @returns An immutable <code>NSData</code> object pointing to the BSON data buffer.
 */
- (NSData *) dataValue;

/**
 Returns a new BSON iterator initialized for the document.
 
 The iterator retains the document.
 @returns An autoreleased BSON iterator initialized for the document
 */
- (BSONIterator *) iterator;

/**
 Convenience method which decodes the document to a dictionary value using the default options. This
 method invokes <code>[+BSONDecoder decodeDictionaryWithDocument:]</code> and returns the result.
 
 For more complex decoding, instantiate a <code>BSONDecoder</code> and invoke
 <code>-decodeDictionary:</code> directly.
 @returns The decoded document in dictionary form
 */
- (NSDictionary *) dictionaryValue;

/**
 Returns a Boolean value that indicates whether the receiver is equal to another BSON document.
 @param object The object with which to compare the receiver
 @returns <code>YES</code> if <i>object</i> is a <code>BSONDocument</code> with an equal <code>@link dataValue @/link</code> or
 is an <code>NSData</code> equal to the receiver's <i>dataValue</i>, and <code>NO</code> for any other object.
 */
- (BOOL) isEqual:(id)object;

/**
 Returns a string representation of the BSON document for debugging purposes. This uses the driver's
 printing code and requires synchronization. Be aware it's somewhat expensive.
 @returns A string representation of the BSON document.
 */
- (NSString *) description;

@end
