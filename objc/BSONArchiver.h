//
//  BSONArchiver.h
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
#import "bson.h"

#define KeyMustNotBeNil @"Key must not be nil"

@class BSONDocument;
@class BSONObjectID;

@interface BSONArchiver : NSCoder {
@private
    bson_buffer *_bb;
}

+ (BSONArchiver *) archiver;
- (BSONDocument *) BSONDocument;

- (void) encodeObject:(id)objv forKey:(NSString *)key;
- (void) encodeArray:(NSArray *)array forKey:(NSString *)key;
- (void) encodeBSONDocument:(BSONDocument *)objv forKey:(NSString *)key;

- (void) encodeNullForKey:(NSString *)key;

- (void) encodeNewObjectID;
- (void) encodeObjectID:(BSONObjectID *)objv forKey:(NSString *)key;

- (void) encodeInt:(int)intv forKey:(NSString *)key;
- (void) encodeInt64:(int64_t)intv forKey:(NSString *)key;
- (void) encodeBool:(BOOL)boolv forKey:(NSString *)key;
- (void) encodeDouble:(double)realv forKey:(NSString *)key;

- (void) encodeString:(NSString *)objv forKey:(NSString *)key;
- (void) encodeSymbol:(NSString *)objv forKey:(NSString *)key;

- (void) encodeDate:(NSDate *)objv forKey:(NSString *)key;
- (void) encodeImage:(NSImage *)objv forKey:(NSString *)key;

- (void) encodeRegularExpressionPattern:(NSString *)pattern options:(NSString *)options forKey:(NSString *)key;
- (void) encodeCode:(NSString *)objv forKey:(NSString *)key;
- (void) encodeCode:(NSString *)code withScope:(BSONDocument *)scope forKey:(NSString *)key;

- (void) encodeData:(NSData *)objv forKey:(NSString *)key;

+ (void) assertNonNil:(id)value withReason:(NSString *)reason;
+ (const char *) utf8ForString:(NSString *)key;

@property (assign) BOOL encodesNilAsNull;

@end
