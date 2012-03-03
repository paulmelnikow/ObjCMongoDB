//
//  BSONCoder.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
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
