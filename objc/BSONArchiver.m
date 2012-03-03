//
//  BSONArchiver.m
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BSONArchiver.h"
#import "NuMongoDB.h"

@interface BSONArchiver (Private)
+ (NSException *) unsupportedUnkeyedCodingSelector:(SEL)selector;
+ (void) assertNonNil:(id)value withReason:(NSString *)reason;
+ (const char *) utf8ForString:(NSString *)key;
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

- (void) encodeObject:(id)objv forKey:(NSString *)key {
    if (!objv) {
        if (self.encodesNilAsNull) [self encodeNullForKey:key];
        
    } else if ([NSNull null] == objv)
        [self encodeNullForKey:key];
    
    else if ([objv isKindOfClass:[BSONObjectID class]])
        [self encodeObjectID:objv forKey:key];
    
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

- (void) encodeArray:(NSArray *)array forKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    
    bson_buffer *pushedBuffer = _bb;
    _bb = bson_append_start_array(pushedBuffer,
                                  [BSONArchiver utf8ForString:key]);

    for (NSUInteger i = 0; i < array.count; ++i)
        [self encodeObject:[array objectAtIndex:i]
                    forKey:[[NSNumber numberWithInteger:i] stringValue]];
    
    bson_append_finish_object(_bb);    
    _bb = pushedBuffer;
}

- (void) encodeDictionary:(NSDictionary *)dictionary forKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    
    bson_buffer *pushedBuffer = _bb;
    _bb = bson_append_start_object(pushedBuffer,
                                   [BSONArchiver utf8ForString:key]);
    
    for (id key in [dictionary allKeys])
        [self encodeObject:[dictionary objectForKey:key]
                    forKey:key];
    
    bson_append_finish_object(_bb);    
    _bb = pushedBuffer;
}

#pragma mark - Encoding simple types

- (void) encodeNewObjectID {
    bson_append_new_oid(_bb, MongoDBObjectIDUTF8Key);
}

- (void) encodeObjectID:(BSONObjectID *)objv forKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_append_oid(_bb, [BSONArchiver utf8ForString:key], [objv objectIDPointer]);
}

- (void) encodeInt:(int)intv forKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_append_int(_bb, [BSONArchiver utf8ForString:key], intv);
}

- (void) encodeInt64:(int64_t)intv forKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_append_long(_bb, [BSONArchiver utf8ForString:key], intv);
}

- (void) encodeBool:(BOOL)boolv forKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_append_bool(_bb, [BSONArchiver utf8ForString:key], boolv);
}

- (void) encodeDouble:(double)realv forKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_append_double(_bb, [BSONArchiver utf8ForString:key], realv);
}

- (void) encodeDate:(NSDate *)objv forKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_append_date (_bb, [BSONArchiver utf8ForString:key], 1000.0 * [objv timeIntervalSince1970]);
}

- (void) encodeNullForKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_append_null(_bb, [BSONArchiver utf8ForString:key]);
}

- (void) encodeImage:(NSImage *)objv forKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    NSData *data = [objv TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:1.0L];
    [self encodeObject:data forKey:key];
}

- (void) encodeString:(NSString *)objv forKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_append_string(_bb,
                       [BSONArchiver utf8ForString:key],
                       [BSONArchiver utf8ForString:objv]);
}

- (void) encodeSymbol:(NSString *)objv forKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_append_symbol(_bb,
                       [BSONArchiver utf8ForString:key],
                       [BSONArchiver utf8ForString:objv]);
}

- (void) encodeRegularExpressionPattern:(NSString *)pattern options:(NSString *)options forKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_append_regex(_bb,
                      [BSONArchiver utf8ForString:key],
                      [BSONArchiver utf8ForString:pattern],
                      [BSONArchiver utf8ForString:options]);
}

- (void) encodeBSONDocument:(BSONDocument *)objv forKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_append_bson(_bb,
                     [BSONArchiver utf8ForString:key],
                     [objv bsonValue]);
}

- (void) encodeData:(NSData *)objv forKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_append_binary(_bb,
                       [BSONArchiver utf8ForString:key],
                       0,
                       [objv bytes],
                       [objv length]);
}

- (void) encodeCode:(NSString *)objv forKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_append_code(_bb,
                     [BSONArchiver utf8ForString:key],
                     [BSONArchiver utf8ForString:objv]);
}

- (void) encodeCode:(NSString *)code withScope:(BSONDocument *)scope forKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_append_code_w_scope(_bb,
                             [BSONArchiver utf8ForString:key],
                             [BSONArchiver utf8ForString:code],
                             [scope bsonValue]);
}

// not implemented:
//bson_buffer * bson_append_element( bson_buffer * b, const char * name_or_null, const bson_iterator* elem);

#pragma mark - Unsupported unkeyed encoding methods

- (void) encodeValueOfObjCType:(const char *)type at:(const void *)addr {
    @throw [BSONArchiver unsupportedUnkeyedCodingSelector:_cmd];
}
- (void) encodeDataObject:(NSData *)data {
    @throw [BSONArchiver unsupportedUnkeyedCodingSelector:_cmd];
}

#pragma mark - Helper methods

+ (NSException *) unsupportedUnkeyedCodingSelector:(SEL)selector {
    NSString *reason = [NSString stringWithFormat:@"%@ called, but unkeyed encoding methods are not supported. Subclass if unkeyed coding is needed.",
                        NSStringFromSelector(selector)];
    return [NSException exceptionWithName:NSInvalidArchiveOperationException
                                   reason:reason
                                 userInfo:nil];
}

+ (void) assertNonNil:(id)value withReason:(NSString *)reason {
    if (value) return;
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:reason ? reason : @"Value must not be nil"
                                 userInfo:nil];
}

+ (const char *) utf8ForString:(NSString *)key {
    return [key cStringUsingEncoding:NSUTF8StringEncoding];
}

@end