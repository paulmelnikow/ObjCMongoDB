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
#import "bson.h"

@class BSONEncoder;

/**
 Encapsulates an immutable BSON document, as a wrapper around a <code>bson</code>
 structure.
 
 Each instance creates a bson object during initialization and destoys it on
 deallocation.
 */
@interface BSONDocument : NSObject {
@private
    id _source;
    /**
     The <code>bson</code> structure.
     */
    bson _bson;
}

/**
 Initializes an empty BSON document.
 */
- (BSONDocument *)init;

/**
 Initializes an empty BSON document which retains parent until deallocation.
 
 Used internally to initialize embedded BSON documents, which depend on the root BSONDocument
 for their data storage.
 */
- (BSONDocument *)initWithParentOrNil:(id) parent;

/**
 Initializes a BSON document.
 
 If <i>data</i> is mutable, it retains a copy instead. Otherwise it retains the
 object itself and accesses its buffer directly.
 @param data An instance of <code>NSData</code> with the binary data for the new
 document.
 */
-(BSONDocument *)initWithData:(NSData *) data;

/**
 Initializes a BSON document by ending encoding and taking ownership of a BSON encoder's
 buffer after encoding is finished.
 
 There's usually no need to invoke this directly. Instead, call the
 <code>BSONDocument<code> method on the <code>BSONEncoder</code>.
 @param encoder A BSON encoder which has finished encoding a BSON document
 */
- (BSONDocument *) initWithEncoder:(BSONEncoder *) encoder;

/**
 Initializes a BSON document by taking ownership of an existing BSON buffer. This allows
 you to create a bson_buffer directly and then bridge it into the ObjCMongoDB framework,
 but there's usually no need to do this directly.
 @param bb A pointer to a <code>bson_buffer</code> structure.
 */
- (BSONDocument *) initWithNativeBuffer:(bson_buffer *) bb;

/**
 Returns an immutable <code>NSData</code> object pointing to the document's BSON data buffer. Does not make
 a copy of the buffer, and will stop working if the document is deallocated.
 @returns An immutable <code>NSData</code> object pointing to the BSON data buffer.
 */
- (NSData *) dataValue;

/**
 Returns a new BSON iterator initialized for the document.
 
 The iterator retains the document.
 @returns A BSON iterator initialized for the document with its retain count set to 1.
 */
- (BSONIterator *) iterator;

/**
 Returns a Boolean value that indicates whether the receiver is equal to another BSON document.
 @param object The object with which to compare the receiver
 @returns <code>YES</code> if <i>object</i> is a <code>BSONDocument</code> with an equal <code>@link dataValue @/link</code> or
 is an <code>NSData</code> equal to the receiver's <i>dataValue</i>, and <code>NO</code> for any other object.
 */
- (BOOL) isEqual:(id)object;

@end
