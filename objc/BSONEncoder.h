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
- (BOOL) encoder:(BSONEncoder *) encoder shouldSubstituteObjectIDForObject:(id) obj forKeyPath:(NSArray *) keyPathComponents;
- (id) encoder:(BSONEncoder *) encoder willEncodeObject:(id) obj forKeyPath:(NSArray *) keyPathComponents;
- (void) encoder:(BSONEncoder *) encoder willReplaceObject:(id) obj withObject:(id) replacementObj forKeyPath:(NSArray *) keyPathComponents;
- (void) encoder:(BSONEncoder *) encoder didEncodeObject:(id) obj forKeyPath:(NSArray *) keyPathComponents;
- (void) encoderDidFinish:(BSONEncoder *) encoder;
- (void) encoderWillFinish:(BSONEncoder *) encoder;

@end

/**
 Doesn't support classForCoder. Doesn't make sense for an encoder which doesn't really store class information.
 Detects loops in internal objects.
 Supports replacementObjectForBSONEncoder
 */
@interface BSONEncoder : NSCoder {
@private
    bson_buffer *_bb;
    NSMutableArray *_bufferStack;
    NSMutableArray *_encodingObjectStack;
    NSMutableArray *_keyPathComponents;
    BSONDocument *_resultDocument;
}

- (BSONEncoder *) initForWriting;

+ (BSONDocument *) BSONDocumentForObject:(id) obj;
+ (BSONDocument *) BSONDocumentForDictionary:(NSDictionary *) dictionary;

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