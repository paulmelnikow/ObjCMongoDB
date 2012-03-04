//
//  BSONArchiver.m
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

#import "BSONArchiver.h"
#import "NuMongoDB.h"

@interface BSONArchiver (Private)
+ (NSException *) unsupportedUnkeyedCodingSelector:(SEL)selector;
+ (void) assertNonNil:(id)value withReason:(NSString *)reason;
@end

@implementation BSONArchiver

@synthesize encodesNilAsNull;

#pragma mark - Initialization

- (BSONArchiver *) init {
    if (self = [super init]) {
        _bb = malloc(sizeof(bson_buffer));
        bson_buffer_init(_bb);
    }
    return self;
}

+ (BSONArchiver *) archiver {
    return [[self alloc] init];
}

- (void) dealloc {
    free(_bb);
}

- (bson_buffer *)bsonBufferValue { return _bb; }

#pragma mark - Finishing

- (BSONDocument *) BSONDocument {
#if __has_feature(objc_arc)
    return [[BSONDocument alloc] initWithArchiver:self];
#else
    return [[[BSONDocument alloc] initWithArchiver:self] autorelease];
#endif
}

#pragma mark - Basic encoding methods

- (BOOL) allowsKeyedCoding { return YES; }

- (void) encodeObject:(id) objv forKey:(NSString *) key {
    if (!objv) {
        if (self.encodesNilAsNull) [self encodeNullForKey:key];
        
    } else if ([NSNull null] == objv)
        [self encodeNullForKey:key];
    
    else if ([BSONIterator objectForUndefinedValue] == objv)
        [self encodeUndefinedForKey:key];
    
    else if ([objv isKindOfClass:[BSONObjectID class]])
        [self encodeObjectID:objv forKey:key];

    else if ([objv isKindOfClass:[BSONRegularExpression class]])
        [self encodeRegularExpression:objv forKey:key];
    
    else if ([objv isKindOfClass:[BSONTimestamp class]])
        [self encodeTimestamp:objv forKey:key];
    
    else if ([objv isMemberOfClass:[BSONCode class]])
        [self encodeCode:objv forKey:key];
    
    else if ([objv isMemberOfClass:[BSONCodeWithScope class]])
        [self encodeCodeWithScope:objv forKey:key];
    
    else if ([objv isKindOfClass:[BSONSymbol class]])
        [self encodeSymbol:objv forKey:key];
    
    else if ([objv isKindOfClass:[NSString class]])
        [self encodeString:objv forKey:key];
    
    else if ([objv isKindOfClass:[NSDate class]])
        [self encodeDate:objv forKey:key];
    
    else if ([objv isKindOfClass:[NSImage class]])
        [self encodeImage:objv forKey:key];
    
    else if ([objv isKindOfClass:[NSArray class]])
        [self encodeArray:objv forKey:key];
    
    else if ([objv isKindOfClass:[NSOrderedSet class]])
        [self encodeArray:[(NSOrderedSet *)objv array] forKey:key];
    
    else if ([objv isKindOfClass:[NSData class]])
        [self encodeData:objv forKey:key];
    
    else
        [objv encodeWithCoder:self];
}

#pragma mark - Encoding collections

- (void) encodeArray:(NSArray *) array forKey:(NSString *) key {
    BSONAssertValueNonNil(array);
    BSONAssertKeyNonNil(key);
    
    bson_buffer *pushedBuffer = _bb;
    _bb = bson_append_start_array(pushedBuffer,
                                  BSONStringFromNSString(key));

    for (NSUInteger i = 0; i < array.count; ++i)
        [self encodeObject:[array objectAtIndex:i]
                    forKey:[[NSNumber numberWithInteger:i] stringValue]];
    
    bson_append_finish_object(_bb);    
    _bb = pushedBuffer;
}

- (void) encodeDictionary:(NSDictionary *) dictionary forKey:(NSString *) key {
    BSONAssertValueNonNil(dictionary);
    BSONAssertKeyNonNil(key);
    
    bson_buffer *pushedBuffer = _bb;
    _bb = bson_append_start_object(pushedBuffer,
                                   BSONStringFromNSString(key));
    
    for (id key in [dictionary allKeys])
        [self encodeObject:[dictionary objectForKey:key]
                    forKey:key];
    
    bson_append_finish_object(_bb);    
    _bb = pushedBuffer;
}

#pragma mark - Encoding simple types

- (void) encodeNewObjectID {
    bson_append_new_oid(_bb, MongoDBObjectIDUBSONKey);
}

- (void) encodeObjectID:(BSONObjectID *) objv forKey:(NSString *) key {
    BSONAssertValueNonNil(objv);
    BSONAssertKeyNonNil(key);
    bson_append_oid(_bb, BSONStringFromNSString(key), [objv objectIDPointer]);
}

- (void) encodeInt:(int) intv forKey:(NSString *) key {
    BSONAssertKeyNonNil(key);
    bson_append_int(_bb, BSONStringFromNSString(key), intv);
}

- (void) encodeInt64:(int64_t) intv forKey:(NSString *) key {
    BSONAssertKeyNonNil(key);
    bson_append_long(_bb, BSONStringFromNSString(key), intv);
}

- (void) encodeBool:(BOOL) boolv forKey:(NSString *) key {
    BSONAssertKeyNonNil(key);
    bson_append_bool(_bb, BSONStringFromNSString(key), boolv);
}

- (void) encodeDouble:(double) realv forKey:(NSString *) key {
    BSONAssertKeyNonNil(key);
    bson_append_double(_bb, BSONStringFromNSString(key), realv);
}

- (void) encodeDate:(NSDate *) objv forKey:(NSString *) key {
    BSONAssertValueNonNil(objv);
    BSONAssertKeyNonNil(key);
    bson_append_date (_bb,
                      BSONStringFromNSString(key),
                      1000.0 * [objv timeIntervalSince1970]);
}

- (void) encodeTimestamp:(BSONTimestamp *) objv forKey:(NSString *) key {
    BSONAssertValueNonNil(objv);
    BSONAssertKeyNonNil(key);
    bson_append_timestamp(_bb, BSONStringFromNSString(key), [objv timestampPointer]);
}

- (void) encodeNullForKey:(NSString *) key {
    BSONAssertKeyNonNil(key);
    bson_append_null(_bb, BSONStringFromNSString(key));
}

- (void) encodeUndefinedForKey:(NSString *) key {
    BSONAssertKeyNonNil(key);
    bson_append_undefined(_bb, BSONStringFromNSString(key));
}

- (void) encodeImage:(NSImage *) objv forKey:(NSString *) key {
    BSONAssertValueNonNil(objv);
    BSONAssertKeyNonNil(key);
    NSData *data = [objv TIFFRepresentationUsingCompression:NSTIFFCompressionLZW
                                                     factor:1.0L];
    [self encodeObject:data forKey:key];
}

- (void) encodeString:(NSString *) objv forKey:(NSString *) key {
    BSONAssertValueNonNil(objv);
    BSONAssertKeyNonNil(key);
    bson_append_string(_bb,
                       BSONStringFromNSString(key),
                       BSONStringFromNSString(objv));
}

- (void) encodeSymbol:(NSString *) objv forKey:(NSString *) key {
    BSONAssertValueNonNil(objv);
    BSONAssertKeyNonNil(key);
    bson_append_symbol(_bb,
                       BSONStringFromNSString(key),
                       BSONStringFromNSString(objv));
}

- (void) encodeRegularExpressionPattern:(NSString *) pattern options:(NSString *) options forKey:(NSString *) key {
    BSONAssertValueNonNil(pattern);
    BSONAssertValueNonNil(options);
    BSONAssertKeyNonNil(key);
    bson_append_regex(_bb,
                      BSONStringFromNSString(key),
                      BSONStringFromNSString(pattern),
                      BSONStringFromNSString(options));
}

- (void) encodeRegularExpression:(BSONRegularExpression *) objv forKey:(NSString *) key {
    BSONAssertValueNonNil(objv);
    [self encodeRegularExpressionPattern:objv.pattern options:objv.options forKey:key];
}

- (void) encodeBSONDocument:(BSONDocument *) objv forKey:(NSString *) key {
    BSONAssertValueNonNil(objv);
    BSONAssertKeyNonNil(key);
    bson_append_bson(_bb,
                     BSONStringFromNSString(key),
                     [objv bsonValue]);
}

- (void) encodeData:(NSData *) objv forKey:(NSString *) key {
    BSONAssertValueNonNil(objv);
    BSONAssertKeyNonNil(key);
    bson_append_binary(_bb,
                       BSONStringFromNSString(key),
                       0,
                       objv.bytes,
                       objv.length);
}

- (void) encodeCodeString:(NSString *) objv forKey:(NSString *) key {
    BSONAssertValueNonNil(objv);
    BSONAssertKeyNonNil(key);
    bson_append_code(_bb,
                     BSONStringFromNSString(key),
                     BSONStringFromNSString(objv));
}

- (void) encodeCode:(BSONCode *) objv forKey:(NSString *) key {
    BSONAssertValueNonNil(objv);
    [self encodeCodeString:objv.code forKey:key];
}

- (void) encodeCodeString:(NSString *) code withScope:(BSONDocument *) scope forKey:(NSString *) key {
    BSONAssertValueNonNil(code);
    BSONAssertValueNonNil(scope);
    BSONAssertKeyNonNil(key);
    bson_append_code_w_scope(_bb,
                             BSONStringFromNSString(key),
                             BSONStringFromNSString(code),
                             [scope bsonValue]);
}

- (void) encodeCodeWithScope:(BSONCodeWithScope *) objv forKey:(NSString *) key {
    BSONAssertValueNonNil(objv);
    [self encodeCodeString:objv.code withScope:objv.scope forKey:key];
}

// not implemented:
//bson_buffer * bson_append_element( bson_buffer * b, const char * name_or_null, const bson_iterator* elem);

#pragma mark - Unsupported unkeyed encoding methods

- (void) encodeValueOfObjCType:(const char *) type at:(const void *) addr {
    [BSONArchiver unsupportedUnkeyedCodingSelector:_cmd];
}
- (void) encodeDataObject:(NSData *) data {
    [BSONArchiver unsupportedUnkeyedCodingSelector:_cmd];
}

#pragma mark - Helper methods

+ (void) unsupportedUnkeyedCodingSelector:(SEL) selector {
    NSString *reason = [NSString stringWithFormat:@"%@ called, but unkeyed encoding methods are not supported. Subclass if unkeyed coding is needed.",
                        NSStringFromSelector(selector)];
    @throw [NSException exceptionWithName:NSInvalidArchiveOperationException
                                   reason:reason
                                 userInfo:nil];
}

+ (void) assertNonNil:(id) value withReason:(NSString *) reason {
    if (value) return;
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:reason ? reason : @"Value must not be nil"
                                 userInfo:nil];
}


@end