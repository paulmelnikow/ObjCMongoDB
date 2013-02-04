//
//  NSData+BSONAdditions.h
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

#import <Foundation/Foundation.h>
#import "bson.h"

@interface NSData (BSONAdditions)

/**
 Returns an autoreleased NSData object which provides access to the BSON object.
 
 If <code>copy</code> is <code>YES</code>, the NSData object allocates a new buffer and
 copies the contents.
 
 If <code>NO</code>, the NSData object simply points to data buffer of the native BSON
 object, without copying or transferring ownership. The returned object will stop working
 if the BSON object is deallocated or subsequently modified. This option is intended for
 temporary use.
 
 @param b A pointer to a native BSON struct
 @param copy A BOOL indicating whether to copy the document's data buffer
 @return An NSData instance which provides access to the BSON document's data buffer or
 a copy of that data buffer
 */
+ (NSData *) dataWithNativeBSONObject:(const bson *) bson copy:(BOOL) copy;

@end
