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
#import "BSONTypes.h"
#import "bson.h"

typedef enum {
    BSONDoNothingOnNil,
    BSONEncodeNullOnNil,
    BSONRaiseExceptionOnNil
} BSONArchiverBehaviorOnNil;

@class BSONDocument;
@class BSONArchiver;

@protocol BSONArchiverDelegate
@optional

- (BOOL) archiver:(BSONArchiver *) archiver shouldEncodeObject:(id) obj forKeyPath:(NSString *) keyPath;
- (void) archiver:(BSONArchiver *) archiver willReplaceObject:(id) obj withObject:(id) obj forKeyPath:(NSString *) keyPath;
- (void) archiver:(BSONArchiver *) archiverDidEncodeObject;
- (void) archiverDidFinish:(BSONArchiver *) archiver;
- (void) archiverWillFinish:(BSONArchiver *) archiver;

@end

@interface BSONArchiver : NSCoder {
@private
    bson_buffer *_bb;
    NSMutableArray *_stack;
    BSONDocument *_resultDocument;
}

+ (BSONArchiver *) archiver;
- (BSONDocument *) BSONDocument;

- (void) encodeObject:(id) obj;
- (void) encodeDictionary:(NSDictionary *) dictionary;

- (void) encodeObject:(id) objv forKey:(NSString *) key;
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


@property (retain) NSObject<BSONArchiverDelegate> * delegate;
@property (assign) BSONArchiverBehaviorOnNil behaviorOnNil;
@property (assign) BOOL restrictsKeyNamesForMongoDB;

@end