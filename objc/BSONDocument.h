//
//  BSONDocument.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "bson.h"

@class BSONArchiver;

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
-(BSONDocument *)init;

/**
 Initializes a BSON document.
 
 If <i>data</i> is mutable, it retains a copy instead. Otherwise it retains the
 object itself and accesses its buffer directly.
 @param data An instance of <code>NSData</code> with the binary data for the new
 document.
 */
-(BSONDocument *)initWithData:(NSData *)data;

/**
 Initializes a BSON document by copying data from an archiver's buffer after encoding
 is finished.
 
 There's usually no need to invoke this directly. Instead, call the
 <code>BSONDocument<code> method on the <code>BSONArchiver</code>.
 @param archiver An archiver which has finished encoding a BSON document
 */
- (BSONDocument *) initWithArchiver:(BSONArchiver *)archiver;

/**
 Initializes a BSON document by copying data from a BSON buffer. This allows you to
 create a bson_buffer directly and then bridge it into the framework, but there's
 usually no need to call this directly.
 @param bb A pointer to a <code>bson_buffer</code> structure.
 */
- (BSONDocument *) initWithNativeBuffer:(bson_buffer *)bb;

/**
 Returns an immutable <code>NSData</code> object pointing to the BSON data buffer.
 @returns An immutable <code>NSData</code> object pointing to the BSON data buffer.
 */
- (NSData *) dataValue;

/**
 Returns a Boolean value that indicates whether the receiver is equal to another BSON document.
 @param object The object with which to compare the receiver
 @returns <code>YES</code> if <i>object</i> is a <code>BSONDocument</code> with an equal <code>@link dataValue @/link</code> or
 is an <code>NSData</code> equal to the receiver's <i>dataValue</i>, and <code>NO</code> for any other object.
 */
- (BOOL) isEqual:(id)object;

@end
