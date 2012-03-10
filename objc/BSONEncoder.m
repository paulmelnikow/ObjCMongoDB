//
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

@interface BSONBufferWrapper : NSObject
+(BSONBufferWrapper *) wrapperForNativeDocument:(bson *) b;
@property (assign) bson *b;
@end
@implementation BSONBufferWrapper
@synthesize b;
+(BSONBufferWrapper *) wrapperForNativeDocument:(bson *) b {
    BSONBufferWrapper *result = [[self alloc] init];
    result.b = b;
#if __has_feature(objc_arc)
    return result;
#else
    return [result autorelease];
#endif
}
@end

@interface BSONEncoder (Private)

- (void) encodeCustomObject:(id) obj forKey:(NSString *) key;
- (void) encodeExposedDictionary:(NSDictionary *) dictionary;
- (void) encodeExposedArray:(NSArray *) array;
- (void) encodeExposedCustomObject:(id) obj;
- (void) encodeObject:(id) objv withSubstitutions:(BOOL) substitutions topLevel:(BOOL)topLevel;
- (void) encodeObject:(id) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions withObjectIDSubstitution:(BOOL) substituteObjectID;
- (void) encodeDictionary:(NSDictionary *) dictionary forKey:(NSString *) key withSubstitutions:(BOOL) substitutions;
- (void) encodeArray:(NSArray *) array forKey:(NSString *) key withSubstitutions:(BOOL) substitutions;
- (void) encodeBSONDocument:(BSONDocument *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions;
- (void) encodeObjectID:(BSONObjectID *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions;
- (void) encodeNumber:(NSNumber *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions;
- (void) encodeString:(NSString *)objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions;
- (void) encodeSymbol:(BSONSymbol *)objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions;
- (void) encodeDate:(NSDate *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions;
- (void) encodeImage:(NSImage *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions;
- (void) encodeRegularExpression:(BSONRegularExpression *) regex forKey:(NSString *) key withSubstitutions:(BOOL) substitutions;
- (void) encodeRegularExpressionPattern:(NSString *) pattern options:(NSString *) options forKey:(NSString *) key withSubstitutions:(BOOL) substitutions;
- (void) encodeCode:(BSONCode *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions;
- (void) encodeCodeString:(NSString *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions;
- (void) encodeCodeWithScope:(BSONCodeWithScope *) codeWithScope forKey:(NSString *) key withSubstitutions:(BOOL) substitutions;
- (void) encodeCodeString:(NSString *) code withScope:(BSONDocument *)scope forKey:(NSString *) key withSubstitutions:(BOOL) substitutions;
- (void) encodeData:(NSData *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions;
- (void) encodeTimestamp:(BSONTimestamp *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions;

- (NSArray *) keyPathComponentsAddingKeyOrNil:(NSString *) key;
- (id) substituteForObject:(id) object substituteObjectID:(BOOL) substituteObjectID keyOrNil:(NSString *) key topLevel:(BOOL) topLevel;

- (void) encodingHelper;
- (void) encodingHelperForKey:(NSString *) key;
- (BOOL) encodingHelper:(id) object withSubstitutions:(BOOL) substitutions withObjectIDSubstitution:(BOOL) substituteObjectID topLevel:(BOOL) topLevel;
- (BOOL) encodingHelper:(id) object key:(NSString *) key withSubstitutions:(BOOL) substitutions withObjectIDSubstitution:(BOOL) substituteObjectID;
- (void) postEncodingHelper:(id) object keyOrNil:(NSString *) key topLevel:(BOOL) topLevel;

@end

@implementation BSONEncoder

@synthesize delegate, behaviorOnNil, restrictsKeyNamesForMongoDB;

#pragma mark - Initialization

- (BSONEncoder *) init {
    return [self initForWriting];
}

- (BSONEncoder *) initForWriting {
    if (self = [super init]) {
        _bson = malloc(sizeof(bson));
        bson_init(_bson);
        self.restrictsKeyNamesForMongoDB = YES;
#if __has_feature(objc_arc)
        _encodingObjectStack = [NSMutableArray array];
        _keyPathComponents = [NSMutableArray array];
#else
        _encodingObjectStack = [[NSMutableArray array] retain];
        _keyPathComponents = [[NSMutableArray array] retain];
#endif
    }
    return self;
}

- (void) dealloc {
    // In case object is deallocated in the middle of encoding
    bson_destroy(_bson);
    free(_bson);
#if !__has_feature(objc_arc)
    [_resultDocument release];
    [_encodingObjectStack release];
    [_keyPathComponents release];
#endif
}

- (bson *) bsonValue { return _bson; }

#pragma mark - Convenience methods

+ (BSONDocument *) documentForObject:(id) obj {
    BSONEncoder *encoder = [[self alloc] initForWriting];
    [encoder encodeObject:obj];
    BSONDocument *result = [encoder BSONDocument];
#if !__has_feature(objc_arc)
    [[result retain] autorelease];
    [encoder release];
#endif
    return result;    
}

+ (BSONDocument *) documentForDictionary:(NSDictionary *) dictionary {    
    BSONEncoder *encoder = [[self alloc] initForWriting];
    [encoder encodeDictionary:dictionary];
    BSONDocument *result = [encoder BSONDocument];
#if !__has_feature(objc_arc)
    [[result retain] autorelease];
    [encoder release];
#endif
    return result;
}

#pragma mark - Finishing

- (void) finishEncoding {    
    if ([self.delegate respondsToSelector:@selector(encoderWillFinish:)])
        [self.delegate encoderWillFinish:self];

    bson_finish(_bson);
    
    _resultDocument = [[BSONDocument alloc] initWithNativeDocument:_bson];
    _bson = NULL;

    if ([self.delegate respondsToSelector:@selector(encoderDidFinish:)])
        [self.delegate encoderDidFinish:self];    
}

- (BSONDocument *) BSONDocument {
    if (!_resultDocument) [self finishEncoding];
    return _resultDocument;
}

#pragma mark - Basic encoding methods

- (void) encodeObject:(id) objv forKey:(NSString *) key {
    [self encodeObject:objv forKey:key withSubstitutions:YES withObjectIDSubstitution:NO];
}

- (void) encodeObjectIDForObject:(id) objv forKey:(NSString *) key {
    [self encodeObject:objv forKey:key withSubstitutions:YES withObjectIDSubstitution:YES];
}

- (void) encodeObject:(id) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions withObjectIDSubstitution:(BOOL) substituteObjectID {    
    if ([self encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:substituteObjectID]) return;
    
    if ([NSNull null] == objv)
        [self encodeNullForKey:key];
    
    else if ([BSONIterator objectForUndefined] == objv)
        [self encodeUndefinedForKey:key];
    
    else if ([objv isKindOfClass:[BSONObjectID class]])
        [self encodeObjectID:objv forKey:key withSubstitutions:NO];

    else if ([objv isKindOfClass:[BSONRegularExpression class]])
        [self encodeRegularExpression:objv forKey:key withSubstitutions:NO];
    
    else if ([objv isKindOfClass:[BSONTimestamp class]])
        [self encodeTimestamp:objv forKey:key withSubstitutions:NO];
    
    else if ([objv isMemberOfClass:[BSONCode class]])
        [self encodeCode:objv forKey:key withSubstitutions:NO];
    
    else if ([objv isMemberOfClass:[BSONCodeWithScope class]])
        [self encodeCodeWithScope:objv forKey:key withSubstitutions:NO];
    
    else if ([objv isKindOfClass:[BSONSymbol class]])
        [self encodeSymbol:objv forKey:key withSubstitutions:NO];
        
    else if ([objv isKindOfClass:[NSString class]])
        [self encodeString:objv forKey:key withSubstitutions:NO];
    
    else if ([objv isKindOfClass:[NSNumber class]])
        [self encodeNumber:objv forKey:key withSubstitutions:NO];
    
    else if ([objv isKindOfClass:[NSDate class]])
        [self encodeDate:objv forKey:key withSubstitutions:NO];
    
    else if ([objv isKindOfClass:[NSImage class]])
        [self encodeImage:objv forKey:key withSubstitutions:NO];

    else if ([objv isKindOfClass:[NSData class]])
        [self encodeData:objv forKey:key withSubstitutions:NO];
    
    else if ([objv isKindOfClass:[NSOrderedSet class]])
        [self encodeArray:[(NSOrderedSet *)objv array] forKey:key withSubstitutions:NO];
    
    else if ([objv isKindOfClass:[NSArray class]])
        [self encodeArray:objv forKey:key withSubstitutions:NO];
    
    else if ([objv isKindOfClass:[NSDictionary class]])
        [self encodeDictionary:objv forKey:key withSubstitutions:NO];
    
    else
        [self encodeCustomObject:objv forKey:key];
}

#pragma mark - Encoding top-level objects

- (void) encodeObject:(id) objv {
    if ([self encodingHelper:objv withSubstitutions:YES withObjectIDSubstitution:NO topLevel:YES]) return;
    [self encodeObject:objv withSubstitutions:NO topLevel:YES];
}

- (void) encodeObject:(id) objv withSubstitutions:(BOOL) substitutions topLevel:(BOOL)topLevel {
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
    
    [self postEncodingHelper:objv keyOrNil:nil topLevel:topLevel];
}

- (void) encodeDictionary:(NSDictionary *) objv {
    if ([self encodingHelper:objv withSubstitutions:YES withObjectIDSubstitution:NO topLevel:YES]) return;
    [self encodeExposedDictionary:objv];
    [self postEncodingHelper:objv keyOrNil:nil topLevel:YES];
}

#pragma mark - Exposing internal objects

- (void) exposeKey:(NSString *) key asArray:(BOOL)asArray forObject:(id) object {
    BSONAssertKeyNonNil(key);
    if (self.restrictsKeyNamesForMongoDB) BSONAssertKeyLegalForMongoDB(key);
    
    if ([_encodingObjectStack containsObject:object]) {
        id exc = [NSException exceptionWithName:NSInvalidArchiveOperationException
                                         reason:@"Attempting to encoding objects in a loop"
                                       userInfo:nil];
        @throw exc;
    }
    [_encodingObjectStack addObject:object];
    
    [_keyPathComponents addObject:key];
    if (asArray)
        bson_append_start_array(_bson, BSONStringFromNSString(key));
    else
        bson_append_start_object(_bson, BSONStringFromNSString(key));    
}

- (void) closeKey {
    if (![_keyPathComponents count]) {
        id exc = [NSException exceptionWithName:NSInvalidArchiveOperationException
                                         reason:@"-closeKey called too many times (without matching call to -exposeKey:asArray:forObject:)"
                                       userInfo:nil];
        @throw exc;
    }
    bson_append_finish_object(_bson);
    [_keyPathComponents removeLastObject];
    [_encodingObjectStack removeLastObject];
}

- (void) encodeCustomObject:(id) obj forKey:(NSString *) key {
    if ([self encodingHelper:obj key:key withSubstitutions:NO withObjectIDSubstitution:NO]) return;
    
    [self exposeKey:key asArray:NO forObject:obj];
    [self encodeExposedCustomObject:obj];
    [self closeKey];
    [self postEncodingHelper:obj keyOrNil:key topLevel:NO];
}

- (void) encodeArray:(NSArray *) array forKey:(NSString *) key {
    [self encodeArray:array forKey:key withSubstitutions:YES];
}

- (void) encodeArray:(NSArray *) array forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self encodingHelper:array key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    
    [self exposeKey:key asArray:YES forObject:array];
    [self encodeExposedArray:array];
    [self closeKey];
    [self postEncodingHelper:array keyOrNil:key topLevel:NO];
}

- (void) encodeDictionary:(NSDictionary *) dictionary forKey:(NSString *) key {
    [self encodeDictionary:dictionary forKey:key withSubstitutions:YES];
}

- (void) encodeDictionary:(NSDictionary *) dictionary forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self encodingHelper:dictionary key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    
    [self exposeKey:key asArray:NO forObject:dictionary];
    [self encodeExposedDictionary:dictionary];
    [self closeKey];    
    [self postEncodingHelper:dictionary keyOrNil:key topLevel:NO];
}

#pragma mark - Encoding exposed objects

- (void) encodeExposedCustomObject:(id) obj {
    if ([obj respondsToSelector:@selector(encodeWithBSONEncoder:)])
        [obj encodeWithBSONEncoder:self];
    else
        [obj encodeWithCoder:self];
}

- (void) encodeExposedArray:(NSArray *) array {
    for (NSUInteger i = 0; i < array.count; ++i)
        [self encodeObject:[array objectAtIndex:i]
                    forKey:[[NSNumber numberWithInteger:i] stringValue]
         withSubstitutions:YES
  withObjectIDSubstitution:NO];
}

- (void) encodeExposedDictionary:(NSDictionary *) dictionary {
    for (id key in [dictionary allKeys])
        [self encodeObject:[dictionary objectForKey:key]
                    forKey:key
         withSubstitutions:YES
  withObjectIDSubstitution:NO];
}

#pragma mark - Encoding supported types - trampoline methods

- (void) encodeObjectID:(BSONObjectID *) objv forKey:(NSString *) key {
    [self encodeObjectID:objv forKey:key withSubstitutions:YES];
}
- (void) encodeNumber:(NSNumber *) objv forKey:(NSString *) key {
    [self encodeNumber:objv forKey:key withSubstitutions:YES];
}
- (void) encodeDate:(NSDate *) objv forKey:(NSString *) key {
    [self encodeDate:objv forKey:key withSubstitutions:YES];
}
- (void) encodeTimestamp:(BSONTimestamp *) objv forKey:(NSString *) key {
    [self encodeTimestamp:objv forKey:key withSubstitutions:YES];
}
- (void) encodeImage:(NSImage *) objv forKey:(NSString *) key {
    [self encodeImage:objv forKey:key withSubstitutions:YES];
}
- (void) encodeString:(NSString *) objv forKey:(NSString *) key {
    [self encodeString:objv forKey:key withSubstitutions:YES];
}
- (void) encodeSymbol:(BSONSymbol *)objv forKey:(NSString *) key {
    [self encodeSymbol:objv forKey:key withSubstitutions:YES];
}
- (void) encodeRegularExpression:(BSONRegularExpression *) objv forKey:(NSString *) key {
    [self encodeRegularExpression:objv forKey:key withSubstitutions:YES];
}
- (void) encodeBSONDocument:(BSONDocument *) objv forKey:(NSString *) key {
    [self encodeBSONDocument:objv forKey:key withSubstitutions:YES];
}
- (void) encodeData:(NSData *) objv forKey:(NSString *) key {
    [self encodeData:objv forKey:key withSubstitutions:YES];
}
- (void) encodeCodeString:(NSString *) objv forKey:(NSString *) key {
    [self encodeCodeString:objv forKey:key withSubstitutions:YES];
}
- (void) encodeCode:(BSONCode *) objv forKey:(NSString *) key {
    [self encodeCode:objv forKey:key withSubstitutions:YES];
}
- (void) encodeCodeWithScope:(BSONCodeWithScope *) objv forKey:(NSString *) key {
    [self encodeCodeWithScope:objv forKey:key withSubstitutions:YES];
}

#pragma mark - Encoding supported types

- (void) encodeNewObjectID {
    [self encodingHelper];
    bson_append_new_oid(_bson, MongoDBObjectIDUBSONKey);
}

- (void) encodeObjectID:(BSONObjectID *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    bson_append_oid(_bson, BSONStringFromNSString(key), [objv objectIDPointer]);
    [self postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) encodeInt:(int) intv forKey:(NSString *) key {
    [self encodingHelperForKey:key];
    bson_append_int(_bson, BSONStringFromNSString(key), intv);
}

- (void) encodeInt64:(int64_t) intv forKey:(NSString *) key {
    [self encodingHelperForKey:key];
    bson_append_long(_bson, BSONStringFromNSString(key), intv);
}

- (void) encodeBool:(BOOL) boolv forKey:(NSString *) key {
    [self encodingHelperForKey:key];
    bson_append_bool(_bson, BSONStringFromNSString(key), boolv);
}

- (void) encodeDouble:(double) realv forKey:(NSString *) key {
    [self encodingHelperForKey:key];
    bson_append_double(_bson, BSONStringFromNSString(key), realv);
}

- (void) encodeNullForKey:(NSString *) key {
    [self encodingHelperForKey:key];
    bson_append_null(_bson, BSONStringFromNSString(key));
}

- (void) encodeUndefinedForKey:(NSString *) key {
    [self encodingHelperForKey:key];
    bson_append_undefined(_bson, BSONStringFromNSString(key));
}

- (void) encodeNumber:(NSNumber *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    
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
    [self postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) encodeDate:(NSDate *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    bson_append_date (_bson,
                      BSONStringFromNSString(key),
                      1000.0 * [objv timeIntervalSince1970]);
    [self postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) encodeTimestamp:(BSONTimestamp *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    bson_append_timestamp(_bson, BSONStringFromNSString(key), [objv timestampPointer]);
    [self postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) encodeImage:(NSImage *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    NSData *data = [objv TIFFRepresentationUsingCompression:NSTIFFCompressionLZW
                                                     factor:1.0L];
    [self encodeObject:data forKey:key];
    [self postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) encodeString:(NSString *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    bson_append_string(_bson,
                       BSONStringFromNSString(key),
                       BSONStringFromNSString(objv));
    [self postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) encodeSymbol:(BSONSymbol *)objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    bson_append_symbol(_bson,
                       BSONStringFromNSString(key),
                       BSONStringFromNSString(objv.symbol));
    [self postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) encodeRegularExpressionPattern:(NSString *) pattern options:(NSString *) options forKey:(NSString *) key {
    if (!pattern && !options) {
        [self encodingHelper:nil key:key withSubstitutions:NO withObjectIDSubstitution:NO];
        return;
    } else {
        BSONAssertValueNonNil(pattern);
        BSONAssertValueNonNil(options);
        [self encodingHelperForKey:key];
    }
    bson_append_regex(_bson,
                      BSONStringFromNSString(key),
                      BSONStringFromNSString(pattern),
                      BSONStringFromNSString(options));
}

- (void) encodeRegularExpression:(BSONRegularExpression *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    [self encodeRegularExpressionPattern:objv.pattern options:objv.options forKey:key];
    [self postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) encodeBSONDocument:(BSONDocument *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    bson_append_bson(_bson,
                     BSONStringFromNSString(key),
                     [objv bsonValue]);
    [self postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) encodeData:(NSData *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    bson_append_binary(_bson,
                       BSONStringFromNSString(key),
                       0,
                       objv.bytes,
                       objv.length);
    [self postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) encodeCodeString:(NSString *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    bson_append_code(_bson,
                     BSONStringFromNSString(key),
                     BSONStringFromNSString(objv));
    [self postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) encodeCode:(BSONCode *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    [self encodeCodeString:objv.code forKey:key];
    [self postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) encodeCodeString:(NSString *) code withScope:(BSONDocument *) scope forKey:(NSString *) key {
    if (!code && !scope) {
        [self encodingHelper:nil key:key withSubstitutions:NO withObjectIDSubstitution:NO];
        return;
    }
    BSONAssertValueNonNil(code);
    BSONAssertValueNonNil(scope);
    [self encodingHelperForKey:key];
    bson_append_code_w_scope(_bson,
                             BSONStringFromNSString(key),
                             BSONStringFromNSString(code),
                             [scope bsonValue]);
}

- (void) encodeCodeWithScope:(BSONCodeWithScope *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    [self encodeCodeString:objv.code withScope:objv.scope forKey:key];
    [self postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

// FIXME not implemented:
//bson_buffer * bson_append_element( bson_buffer * b, const char * name_or_null, const bson_iterator* elem);

#pragma mark - Helper methods for -encode... methods

- (void) encodingHelper {
    if (!_bson) {
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

- (BOOL) encodingHelper:(id) object withSubstitutions:(BOOL) substitutions withObjectIDSubstitution:(BOOL) substituteObjectID topLevel:(BOOL) topLevel {
    [self encodingHelper];
    
    if (topLevel) {
        if ([_encodingObjectStack count]) {
            id exc = [NSException exceptionWithName:NSInvalidArchiveOperationException
                                             reason:@"Can only use top-level encoding methods for top-level objects. Use encode...ForKey methods instead."
                                           userInfo:nil];
            @throw exc;
        }
    }
    
    if (substitutions && object) {
        id substituteObject = [self substituteForObject:object substituteObjectID:substituteObjectID keyOrNil:nil topLevel:topLevel];
        if (substituteObject != object) {
            if (topLevel) [_encodingObjectStack addObject:substituteObject];
            [self encodeObject:substituteObject withSubstitutions:NO topLevel:topLevel];
            return YES;
        }
    }
    
    if (topLevel) [_encodingObjectStack addObject:object];    
    return NO;
}

- (BOOL) encodingHelper:(id) object key:(NSString *) key withSubstitutions:(BOOL) substitutions withObjectIDSubstitution:(BOOL) substituteObjectID {
    [self encodingHelperForKey:key];
    
    if (substitutions && object) {
        id substituteObject = [self substituteForObject:object substituteObjectID:substituteObjectID keyOrNil:key topLevel:NO];

        if (substituteObject != object) {
            [self encodeObject:substituteObject forKey:key withSubstitutions:NO withObjectIDSubstitution:NO];
            return YES;
        }
    }
    
    if (!object)
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
    return NO;
}

- (void) postEncodingHelper:(id) object keyOrNil:(NSString *) key topLevel:(BOOL) topLevel {
    if ([self.delegate respondsToSelector:@selector(encoder:didEncodeObject:forKeyPath:)])
        [self.delegate encoder:self didEncodeObject:object forKeyPath:[self keyPathComponentsAddingKeyOrNil:key]];
    if (topLevel) [_encodingObjectStack removeLastObject];
}

#pragma mark - Other helper methods

- (BOOL) allowsKeyedCoding { return YES; }

- (NSArray *) keyPathComponents {
    return [NSArray arrayWithArray:_keyPathComponents];
}

- (NSArray *) keyPathComponentsAddingKeyOrNil:(NSString *) key {
    NSArray *result = [self keyPathComponents];
    if (key) result = [result arrayByAddingObject:key];
    return result.count ? result : nil;
}

- (id) substituteForObject:(id) object substituteObjectID:(BOOL) substituteObjectID keyOrNil:(NSString *) key topLevel:(BOOL) topLevel {
    id originalObject = object;
    
    if (!substituteObjectID
        && !topLevel
        && [self.delegate respondsToSelector:@selector(encoder:shouldSubstituteObjectIDForObject:forKeyPath:)])
        substituteObjectID = [self.delegate encoder:self shouldSubstituteObjectIDForObject:object forKeyPath:[self keyPathComponentsAddingKeyOrNil:key]];

    // Substitute the object ID, if we were asked to
    if (substituteObjectID && object) {
        if ([object respondsToSelector:@selector(BSONObjectIDForEncoder:)])
            object = [object BSONObjectIDForEncoder:self];
        else if ([object respondsToSelector:@selector(BSONObjectID)])
            object = [object BSONObjectID];
        else {
            id exc = [NSException exceptionWithName:NSInvalidArchiveOperationException
                                             reason:@"To encode a custom object by object ID, the object must respond to -BSONObjectID or -BSONObjectIDForEncoder:"
                                           userInfo:nil];
            @throw exc;
        }
        if (!object) {
            id exc = [NSException exceptionWithName:NSInvalidArchiveOperationException
                                             reason:@"Non-nil object provided a nil -BSONObjectID or -BSONObjectIDForEncoder:"
                                           userInfo:nil];
            @throw exc;
        }
    }
    
    // Allow the object to present a substitute object
    if ([object respondsToSelector:@selector(replacementObjectForBSONEncoder:)])
        object = [(id<BSONCoding>)object replacementObjectForBSONEncoder:self];
    else if ([object respondsToSelector:@selector(replacementObjectForCoder:)])
        object = [object replacementObjectForCoder:self];
    
    // Then, allow the delegate to present a substitute object
    if (object && [self.delegate respondsToSelector:@selector(encoder:willEncodeObject:forKeyPath:)])
        object = [self.delegate encoder:self willEncodeObject:object forKeyPath:[self keyPathComponentsAddingKeyOrNil:key]];
    
    // Finally, notify the delegate if a substitution was made
    if (object != originalObject
        && [self.delegate respondsToSelector:@selector(encoder:willReplaceObject:withObject:forKeyPath:)])
        [self.delegate encoder:self willReplaceObject:originalObject withObject:object forKeyPath:[self keyPathComponentsAddingKeyOrNil:key]];
    
    return object;
}

#pragma mark - Unsupported unkeyed encoding methods

+ (void) unsupportedUnkeyedCodingSelector:(SEL) selector {
    NSString *reason = [NSString stringWithFormat:@"%@ called, but unkeyed encoding methods are not supported. Subclass if unkeyed coding is needed.",
                        NSStringFromSelector(selector)];
    id exc = [NSException exceptionWithName:NSInvalidArchiveOperationException
                                     reason:reason
                                   userInfo:nil];
    @throw exc;
}

- (void) encodeArrayOfObjCType:(const char *) itemType count:(NSUInteger) count at:(const void *) address {
    [BSONEncoder unsupportedUnkeyedCodingSelector:_cmd];    
}
- (void) encodeBycopyObject:(id) object {
    [BSONEncoder unsupportedUnkeyedCodingSelector:_cmd];    
}
- (void) encodeByrefObject:(id) object {
    [BSONEncoder unsupportedUnkeyedCodingSelector:_cmd];    
}
- (void) encodeDataObject:(NSData *) data {
    [BSONEncoder unsupportedUnkeyedCodingSelector:_cmd];
}
- (void) encodeRootObject:(id) object {
    [BSONEncoder unsupportedUnkeyedCodingSelector:_cmd];    
}
- (void) encodeValueOfObjCType:(const char *) type at:(const void *) addr {
    [BSONEncoder unsupportedUnkeyedCodingSelector:_cmd];
}
- (void) encodeValuesOfObjCTypes:(const char *) types, ... {
    [BSONEncoder unsupportedUnkeyedCodingSelector:_cmd];    
}
- (void) encodeNXObject:(id) object {
    [BSONEncoder unsupportedUnkeyedCodingSelector:_cmd];    
}

#pragma mark - Unsupported encoding types

+ (void) unsupportedCodingSelector:(SEL) selector {
    NSString *reason = [NSString stringWithFormat:@"%@ is not supported. Subclass if coding this type is needed.",
                        NSStringFromSelector(selector)];
    id exc = [NSException exceptionWithName:NSInvalidArchiveOperationException
                                     reason:reason
                                   userInfo:nil];
    @throw exc;
}

- (void) encodeBytes:(const void *) address length:(NSUInteger) numBytes {
    [BSONEncoder unsupportedCodingSelector:_cmd];    
}
- (void) encodeBytes:(const uint8_t *) bytesp length:(NSUInteger) lenv forKey:(NSString *) key {
    [BSONEncoder unsupportedCodingSelector:_cmd];
}
- (void) encodeConditionalObject:(id) object {
    [BSONEncoder unsupportedCodingSelector:_cmd];
}
- (void) encodeConditionalObject:(id) objv forKey:(NSString *) key {
    [BSONEncoder unsupportedCodingSelector:_cmd];
}
- (void) encodeFloat:(float) realv forKey:(NSString *) key {
    [BSONEncoder unsupportedCodingSelector:_cmd];
}
- (void) encodeInt32:(int32_t) intv forKey:(NSString *) key {
    [BSONEncoder unsupportedCodingSelector:_cmd];
}
- (void) encodeInteger:(NSInteger) intv forKey:(NSString *) key {
    [BSONEncoder unsupportedCodingSelector:_cmd];    
}
- (void) encodePoint:(NSPoint) point {
    [BSONEncoder unsupportedCodingSelector:_cmd];    
}
- (void) encodePoint:(NSPoint) point forKey:(NSString *) key {
    [BSONEncoder unsupportedCodingSelector:_cmd];
}
- (void) encodePropertyList:(id) object {
    [BSONEncoder unsupportedCodingSelector:_cmd];
}
- (void) encodeRect:(NSRect) rect {
    [BSONEncoder unsupportedCodingSelector:_cmd];    
}
- (void) encodeRect:(NSRect) rect forKey:(NSString *) key {
    [BSONEncoder unsupportedCodingSelector:_cmd];
}
- (void) encodeSize:(NSSize) size {
    [BSONEncoder unsupportedCodingSelector:_cmd];    
}
- (void) encodeSize:(NSSize) size forKey:(NSString *) key {
    [BSONEncoder unsupportedCodingSelector:_cmd];
}

@end