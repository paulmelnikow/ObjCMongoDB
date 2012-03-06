//  BSONEncoder.m
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

#import "BSONEncoder.h"
#import "NuMongoDB.h"

@interface BSONEncoderStackRecord : NSObject
@property (retain) NSString *pathComponent;
@property (assign) bson_buffer *bb;
@end
@implementation BSONEncoderStackRecord
@synthesize pathComponent, bb;
@end

@interface BSONEncoder (Private)
- (void) encodeCustomObject:(id) obj forKey:(NSString *) key;
- (void) encodeExposedDictionary:(NSDictionary *) dictionary;
- (void) encodeExposedArray:(NSArray *) array;
- (void) encodeExposedCustomObject:(id) obj;
+ (NSException *) unsupportedUnkeyedCodingSelector:(SEL)selector;
- (void) encodingHelper;
- (void) encodingHelperForKey:(NSString *) key;
- (BOOL) encodingHelper:(id) object key:(NSString *) key;
- (void) postEncodingHelper:(id) object key:(NSString *) key;
@end

@implementation BSONEncoder

@synthesize delegate, behaviorOnNil, restrictsKeyNamesForMongoDB;

#pragma mark - Initialization

- (BSONEncoder *) init {
    if (self = [super init]) {
        _bb = malloc(sizeof(bson_buffer));
        bson_buffer_init(_bb);
        self.restrictsKeyNamesForMongoDB = YES;
#if __has_feature(objc_arc)
        _stack = [NSMutableArray array];
        _keyPathComponents = [NSMutableArray array];
#else
        _stack = [[NSMutableArray array] retain];
        _keyPathComponents = [[NSMutableArray array] retain];
#endif
    }
    return self;
}

+ (BSONEncoder *) encoder {
    return [[self alloc] init];
}

- (void) dealloc {
    free(_bb);
#if !__has_feature(objc_arc)
    [_resultDocument release];
#endif
}

- (bson_buffer *)bsonBufferValue { return _bb; }

#pragma mark - Finishing

- (void) finishEncoding {    
    if ([self.delegate respondsToSelector:@selector(encoderWillFinish:)])
        [self.delegate encoderWillFinish:self];

    _resultDocument = [[BSONDocument alloc] initWithEncoder:self];
    _bb = NULL;

    if ([self.delegate respondsToSelector:@selector(encoderDidFinish:)])
        [self.delegate encoderDidFinish:self];    
}

- (BSONDocument *) BSONDocument {
    if (!_resultDocument) [self finishEncoding];
    return _resultDocument;
}

#pragma mark - Basic encoding methods

- (BOOL) allowsKeyedCoding { return YES; }

- (void) encodeObject:(id) objv forKey:(NSString *) key {
    if ([NSNull null] == objv)
        [self encodeNullForKey:key];
    
    else if ([BSONIterator objectForUndefined] == objv)
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
    
    else if ([objv isKindOfClass:[NSNumber class]])
        [self encodeNumber:objv forKey:key];
    
    else if ([objv isKindOfClass:[NSDate class]])
        [self encodeDate:objv forKey:key];
    
    else if ([objv isKindOfClass:[NSImage class]])
        [self encodeImage:objv forKey:key];

    else if ([objv isKindOfClass:[NSData class]])
        [self encodeData:objv forKey:key];
    
    else if ([objv isKindOfClass:[NSOrderedSet class]])
        [self encodeArray:[(NSOrderedSet *)objv array] forKey:key];
    
    else if ([objv isKindOfClass:[NSArray class]])
        [self encodeArray:objv forKey:key];
    
    else if ([objv isKindOfClass:[NSDictionary class]])
        [self encodeDictionary:objv forKey:key];
    
    else
        [self encodeCustomObject:objv forKey:key];
}

#pragma mark - Encoding internal collections

- (void) exposeObjectForKey:(NSString *) key asArray:(BOOL)asArray {
    BSONAssertKeyNonNil(key);
    if (self.restrictsKeyNamesForMongoDB) BSONAssertKeyLegalForMongoDB(key);
    
    BSONEncoderStackRecord *record = [[BSONEncoderStackRecord alloc] init];
    record.pathComponent = key;
    record.bb = _bb;
    [_stack addObject:record];
    [_keyPathComponents addObject:key];
    if (asArray)
        _bb = bson_append_start_array(_bb, BSONStringFromNSString(key));
    else
        _bb = bson_append_start_object(_bb, BSONStringFromNSString(key));    
}

- (void) closeInternalObject {
    if (![_stack count]) {
        id exc = [NSException exceptionWithName:NSInvalidArchiveOperationException
                                         reason:@"-closeInternalObject called too many times (without matching call to -exposeObjectForKey:asArray:)"
                                       userInfo:nil];
        @throw exc;
    }
    bson_append_finish_object(_bb);    
    BSONEncoderStackRecord *record = [_stack lastObject];
    _bb = record.bb;
    [_stack removeLastObject];
    [_keyPathComponents removeLastObject];
}

- (void) encodeObject:(id) objv {
    [self encodingHelper];
    if (!objv) return;
    if ([NSNull null] == objv
        || [BSONIterator objectForUndefined] == objv
        || [objv isKindOfClass:[BSONObjectID class]]
        || [objv isKindOfClass:[BSONRegularExpression class]]
        || [objv isKindOfClass:[BSONTimestamp class]]
        || [objv isMemberOfClass:[BSONCode class]]
        || [objv isMemberOfClass:[BSONCodeWithScope class]]
        || [objv isKindOfClass:[BSONSymbol class]]
        || [objv isKindOfClass:[NSString class]]
        || [objv isKindOfClass:[NSNumber class]]
        || [objv isKindOfClass:[NSDate class]]
        || [objv isKindOfClass:[NSImage class]]
        || [objv isKindOfClass:[NSData class]]
        || [objv isKindOfClass:[NSArray class]]) {
        NSString *reason = [NSString stringWithFormat:@"Encode %@ using encodeObject:forKey: instead", [objv class]];
        id exc = [NSException exceptionWithName:NSInvalidArchiveOperationException
                                         reason:reason
                                       userInfo:nil];
        @throw exc;
    }
    
    if ([objv isKindOfClass:[NSDictionary class]])
        [self encodeExposedDictionary:objv];
    else
        [self encodeExposedCustomObject:objv];
    
    [self postEncodingHelper:objv key:nil];
}

- (void) encodeExposedCustomObject:(id) obj {
    [obj encodeWithCoder:self];
}

- (void) encodeCustomObject:(id) obj forKey:(NSString *) key {
    if ([self encodingHelper:obj key:key]) return;
    
    [self exposeObjectForKey:key asArray:NO];
    [self encodeExposedCustomObject:obj];
    [self closeInternalObject];
    [self postEncodingHelper:obj key:key];
}

- (void) encodeExposedArray:(NSArray *) array {
    for (NSUInteger i = 0; i < array.count; ++i)
        [self encodeObject:[array objectAtIndex:i]
                    forKey:[[NSNumber numberWithInteger:i] stringValue]];
}

- (void) encodeArray:(NSArray *) array forKey:(NSString *) key {
    if ([self encodingHelper:array key:key]) return;
    
    [self exposeObjectForKey:key asArray:YES];
    [self encodeExposedArray:array];
    [self closeInternalObject];
    [self postEncodingHelper:array key:key];
}

- (void) encodeExposedDictionary:(NSDictionary *) dictionary {
    for (id key in [dictionary allKeys])
        [self encodeObject:[dictionary objectForKey:key]
                    forKey:key];
}

- (void) encodeDictionary:(NSDictionary *) dictionary {
    [self encodeExposedDictionary:dictionary];
    [self postEncodingHelper:dictionary key:nil];
}

- (void) encodeDictionary:(NSDictionary *) dictionary forKey:(NSString *) key {
    if ([self encodingHelper:dictionary key:key]) return;

    [self exposeObjectForKey:key asArray:NO];
    [self encodeExposedDictionary:dictionary];
    [self closeInternalObject];    
    [self postEncodingHelper:dictionary key:key];
}

#pragma mark - Encoding simple types

- (void) encodeNewObjectID {
    [self encodingHelper];
    bson_append_new_oid(_bb, MongoDBObjectIDUBSONKey);
}

- (void) encodeObjectID:(BSONObjectID *) objv forKey:(NSString *) key {
    if ([self encodingHelper:objv key:key]) return;
    bson_append_oid(_bb, BSONStringFromNSString(key), [objv objectIDPointer]);
    [self postEncodingHelper:objv key:key];
}

- (void) encodeInt:(int) intv forKey:(NSString *) key {
    [self encodingHelperForKey:key];
    bson_append_int(_bb, BSONStringFromNSString(key), intv);
}

- (void) encodeInt64:(int64_t) intv forKey:(NSString *) key {
    [self encodingHelperForKey:key];
    bson_append_long(_bb, BSONStringFromNSString(key), intv);
}

- (void) encodeBool:(BOOL) boolv forKey:(NSString *) key {
    [self encodingHelperForKey:key];
    bson_append_bool(_bb, BSONStringFromNSString(key), boolv);
}

- (void) encodeDouble:(double) realv forKey:(NSString *) key {
    [self encodingHelperForKey:key];
    bson_append_double(_bb, BSONStringFromNSString(key), realv);
}

- (void) encodeNullForKey:(NSString *) key {
    [self encodingHelperForKey:key];
    bson_append_null(_bb, BSONStringFromNSString(key));
}

- (void) encodeUndefinedForKey:(NSString *) key {
    [self encodingHelperForKey:key];
    bson_append_undefined(_bb, BSONStringFromNSString(key));
}

- (void) encodeNumber:(NSNumber *) objv forKey:(NSString *) key {
    if ([self encodingHelper:objv key:key]) return;
    
    switch (*(objv.objCType)) {
        case 'd':
        case 'f':
            [self encodeDouble:objv.doubleValue forKey:key];
            break;
        case 'l':
        case 'L':
//            [self encodeInt64:objv.longValue forKey:key];
//            break;
        case 'q':
        case 'Q':
            [self encodeInt64:objv.longLongValue forKey:key];
            break;
        case 'B': // C++/C99 bool
        case 'c': // ObjC BOOL
            [self encodeBool:objv.boolValue forKey:key];
            break;
        case 'C':
        case 's':
        case 'S':
        case 'i':
        case 'I':
        default:
            [self encodeInt:objv.intValue forKey:key];
            break;
    }
    [self postEncodingHelper:objv key:key];
}

- (void) encodeDate:(NSDate *) objv forKey:(NSString *) key {
    if ([self encodingHelper:objv key:key]) return;
    bson_append_date (_bb,
                      BSONStringFromNSString(key),
                      1000.0 * [objv timeIntervalSince1970]);
    [self postEncodingHelper:objv key:key];
}

- (void) encodeTimestamp:(BSONTimestamp *) objv forKey:(NSString *) key {
    if ([self encodingHelper:objv key:key]) return;
    bson_append_timestamp(_bb, BSONStringFromNSString(key), [objv timestampPointer]);
    [self postEncodingHelper:objv key:key];
}

- (void) encodeImage:(NSImage *) objv forKey:(NSString *) key {
    if ([self encodingHelper:objv key:key]) return;
    NSData *data = [objv TIFFRepresentationUsingCompression:NSTIFFCompressionLZW
                                                     factor:1.0L];
    [self encodeObject:data forKey:key];
    [self postEncodingHelper:objv key:key];
}

- (void) encodeString:(NSString *) objv forKey:(NSString *) key {
    if ([self encodingHelper:objv key:key]) return;
    bson_append_string(_bb,
                       BSONStringFromNSString(key),
                       BSONStringFromNSString(objv));
    [self postEncodingHelper:objv key:key];
}

- (void) encodeSymbol:(BSONSymbol *)objv forKey:(NSString *) key {
    if ([self encodingHelper:objv key:key]) return;
    bson_append_symbol(_bb,
                       BSONStringFromNSString(key),
                       BSONStringFromNSString(objv.symbol));
    [self postEncodingHelper:objv key:key];
}

- (void) encodeRegularExpressionPattern:(NSString *) pattern options:(NSString *) options forKey:(NSString *) key {
    if (!pattern && !options) {
        [self encodingHelper:nil key:key];
        return;
    } else {
        BSONAssertValueNonNil(pattern);
        BSONAssertValueNonNil(options);
        [self encodingHelperForKey:key];
    }
    bson_append_regex(_bb,
                      BSONStringFromNSString(key),
                      BSONStringFromNSString(pattern),
                      BSONStringFromNSString(options));
}

- (void) encodeRegularExpression:(BSONRegularExpression *) objv forKey:(NSString *) key {
    if ([self encodingHelper:objv key:key]) return;
    [self encodeRegularExpressionPattern:objv.pattern options:objv.options forKey:key];
    [self postEncodingHelper:objv key:key];
}

- (void) encodeBSONDocument:(BSONDocument *) objv forKey:(NSString *) key {
    if ([self encodingHelper:objv key:key]) return;
    bson_append_bson(_bb,
                     BSONStringFromNSString(key),
                     [objv bsonValue]);
    [self postEncodingHelper:objv key:key];
}

- (void) encodeData:(NSData *) objv forKey:(NSString *) key {
    if ([self encodingHelper:objv key:key]) return;
    bson_append_binary(_bb,
                       BSONStringFromNSString(key),
                       0,
                       objv.bytes,
                       objv.length);
    [self postEncodingHelper:objv key:key];
}

- (void) encodeCodeString:(NSString *) objv forKey:(NSString *) key {
    if ([self encodingHelper:objv key:key]) return;
    bson_append_code(_bb,
                     BSONStringFromNSString(key),
                     BSONStringFromNSString(objv));
    [self postEncodingHelper:objv key:key];
}

- (void) encodeCode:(BSONCode *) objv forKey:(NSString *) key {
    if ([self encodingHelper:objv key:key]) return;
    [self encodeCodeString:objv.code forKey:key];
    [self postEncodingHelper:objv key:key];
}

- (void) encodeCodeString:(NSString *) code withScope:(BSONDocument *) scope forKey:(NSString *) key {
    if (!code && !scope) {
        [self encodingHelper:nil key:key];
        return;
    }
    BSONAssertValueNonNil(code);
    BSONAssertValueNonNil(scope);
    [self encodingHelperForKey:key];
    bson_append_code_w_scope(_bb,
                             BSONStringFromNSString(key),
                             BSONStringFromNSString(code),
                             [scope bsonValue]);
}

- (void) encodeCodeWithScope:(BSONCodeWithScope *) objv forKey:(NSString *) key {
    if ([self encodingHelper:objv key:key]) return;
    [self encodeCodeString:objv.code withScope:objv.scope forKey:key];
    [self postEncodingHelper:objv key:key];
}

// FIXME not implemented:
//bson_buffer * bson_append_element( bson_buffer * b, const char * name_or_null, const bson_iterator* elem);

#pragma mark - Unsupported unkeyed encoding methods

- (void) encodeValueOfObjCType:(const char *) type at:(const void *) addr {
    [BSONEncoder unsupportedUnkeyedCodingSelector:_cmd];
}
- (void) encodeDataObject:(NSData *) data {
    [BSONEncoder unsupportedUnkeyedCodingSelector:_cmd];
}

#pragma mark - Helper methods

+ (void) unsupportedUnkeyedCodingSelector:(SEL) selector {
    NSString *reason = [NSString stringWithFormat:@"%@ called, but unkeyed encoding methods are not supported. Subclass if unkeyed coding is needed.",
                        NSStringFromSelector(selector)];
    id exc = [NSException exceptionWithName:NSInvalidArchiveOperationException
                                   reason:reason
                                 userInfo:nil];
    @throw exc;
}

- (void) encodingHelper {
    if (!_bb) {
        id exc = [NSException exceptionWithName:NSInvalidArchiveOperationException
                                       reason:@"Can't continue to encode after finishEncoding called"
                                                      userInfo:nil];
        @throw exc;
    }
}

- (void) encodingHelperForKey:(NSString *) key {
    [self encodingHelper];
    BSONAssertKeyNonNil(key);
    if (self.restrictsKeyNamesForMongoDB) BSONAssertKeyLegalForMongoDB(key);
}

- (BOOL) encodingHelper:(id) object key:(NSString *) key {
    [self encodingHelperForKey:key];
    
    if (object) return NO;
    
    switch(self.behaviorOnNil) {
        case BSONDoNothingOnNil:
            return YES;
        case BSONEncodeNullOnNil:
            [self encodeNullForKey:key];
            return YES;
        case BSONRaiseExceptionOnNil:
            @throw [NSException exceptionWithName:NSInvalidArchiveOperationException
                                           reason:@"Can't encode nil value with BSONRaiseExceptionOnNil set"
                                         userInfo:nil];
    }
}

- (NSArray *) keyPathComponents {
    return [NSArray arrayWithArray:_keyPathComponents];
}

- (void) postEncodingHelper:(id) object key:(NSString *) key {
    if ([self.delegate respondsToSelector:@selector(encoder:didEncodeObject:forKeyPath:)]) {
        NSArray *keyPathComponents = [self keyPathComponents];
        if (key) keyPathComponents = [keyPathComponents arrayByAddingObject:key];
        if (!keyPathComponents.count) keyPathComponents = nil;
        [self.delegate encoder:self didEncodeObject:object forKeyPath:keyPathComponents];
    }
}

@end