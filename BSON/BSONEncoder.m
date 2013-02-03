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

#import "ObjCBSON.h"
#import "BSON_Helper.h"
#import "BSONEncoder.h"
#import "bson.h"
#import "BSON_PrivateInterfaces.h"

@interface BSONBufferWrapper : NSObject
+(BSONBufferWrapper *) wrapperForNativeDocument:(bson *) b;
@property (assign) bson *b;
@end
@implementation BSONBufferWrapper
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

@interface BSONEncoder ()
@property (retain) NSMutableArray *encodingObjectStack;
@property (retain) NSMutableArray *privateKeyPathComponents;
@property (retain) BSONDocument *resultDocument;
@end

@implementation BSONEncoder {
    bson *_bson;
}

#pragma mark - Initialization

- (BSONEncoder *) init {
    return [self initForWriting];
}

- (BSONEncoder *) initForWriting {
    if (self = [super init]) {
        _bson = malloc(sizeof(bson));
        bson_init(_bson);
        self.restrictsKeyNamesForMongoDB = YES;
        self.encodingObjectStack = [NSMutableArray array];
        self.privateKeyPathComponents = [NSMutableArray array];
    }
    return self;
}

- (void) dealloc {
    // In case object is deallocated in the middle of encoding
    bson_destroy(_bson);
    free(_bson);
#if !__has_feature(objc_arc)
    self.resultDocument = nil;
    self.encodingObjectStack = nil;
    self.privateKeyPathComponents = nil;
    self.delegate = nil;
    [super dealloc];
#endif
}

- (bson *) bsonValue { return _bson; }

#pragma mark - Convenience methods

+ (BSONDocument *) documentForObject:(id) obj {
    return [self documentForObject:obj restrictsKeyNamesForMongoDB:YES];
}

+ (BSONDocument *) documentForObject:(id) obj restrictsKeyNamesForMongoDB:(BOOL) restrictsKeyNamesForMongoDB {
    BSONEncoder *encoder = [[self alloc] initForWriting];
    encoder.restrictsKeyNamesForMongoDB = restrictsKeyNamesForMongoDB;
    [encoder encodeObject:obj];
    BSONDocument *result = [encoder BSONDocument];
#if !__has_feature(objc_arc)
    [[result retain] autorelease];
    [encoder release];
#endif
    return result;    
}

+ (BSONDocument *) documentForDictionary:(NSDictionary *) dictionary {
    return [self documentForDictionary:dictionary restrictsKeyNamesForMongoDB:YES];
}

+ (BSONDocument *) documentForDictionary:(NSDictionary *) dictionary restrictsKeyNamesForMongoDB:(BOOL) restrictsKeyNamesForMongoDB {
    BSONEncoder *encoder = [[self alloc] initForWriting];
    encoder.restrictsKeyNamesForMongoDB = restrictsKeyNamesForMongoDB;
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

    if (BSON_ERROR == bson_finish(_bson)) [self _raiseBSONError];
    
    self.resultDocument = [[BSONDocument alloc] initWithNativeDocument:_bson destroyOnDealloc:YES];
    _bson = NULL;

    if ([self.delegate respondsToSelector:@selector(encoderDidFinish:)])
        [self.delegate encoderDidFinish:self];    
}

- (BSONDocument *) BSONDocument {
    if (!self.resultDocument) [self finishEncoding];
    return self.resultDocument;
}

- (NSData *) data {
    if (!self.resultDocument) [self finishEncoding];
    return self.resultDocument.dataValue;
}

#pragma mark - Basic encoding methods

- (void) encodeObject:(id) objv forKey:(NSString *) key {
    [self _encodeObject:objv forKey:key withSubstitutions:YES withObjectIDSubstitution:NO];
}

- (void) encodeObjectIDForObject:(id) objv forKey:(NSString *) key {
    [self _encodeObject:objv forKey:key withSubstitutions:YES withObjectIDSubstitution:YES];
}

- (void) _encodeObject:(id) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions withObjectIDSubstitution:(BOOL) substituteObjectID {
    static Class orderedSetClass;
    if (!orderedSetClass) orderedSetClass = NSClassFromString(@"NSOrderedSet");
    
    if ([self _encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:substituteObjectID]) return;
    
    if ([NSNull null] == objv)
        [self encodeNullForKey:key];
    
    else if ([BSONIterator objectForUndefined] == objv)
        [self encodeUndefinedForKey:key];
    
    else if ([objv isKindOfClass:[BSONObjectID class]])
        [self _encodeObjectID:objv forKey:key withSubstitutions:NO];

    else if ([objv isKindOfClass:[BSONRegularExpression class]])
        [self _encodeRegularExpression:objv forKey:key withSubstitutions:NO];
    
    else if ([objv isKindOfClass:[BSONTimestamp class]])
        [self _encodeTimestamp:objv forKey:key withSubstitutions:NO];
    
    else if ([objv isMemberOfClass:[BSONCode class]])
        [self _encodeCode:objv forKey:key withSubstitutions:NO];
    
    else if ([objv isMemberOfClass:[BSONCodeWithScope class]])
        [self _encodeCodeWithScope:objv forKey:key withSubstitutions:NO];
    
    else if ([objv isKindOfClass:[BSONSymbol class]])
        [self _encodeSymbol:objv forKey:key withSubstitutions:NO];
        
    else if ([objv isKindOfClass:[NSString class]])
        [self _encodeString:objv forKey:key withSubstitutions:NO];
    
    else if ([objv isKindOfClass:[NSNumber class]])
        [self _encodeNumber:objv forKey:key withSubstitutions:NO];
    
    else if ([objv isKindOfClass:[NSDate class]])
        [self _encodeDate:objv forKey:key withSubstitutions:NO];
    
    else if ([objv isKindOfClass:[NSImage class]])
        [self _encodeImage:objv forKey:key withSubstitutions:NO];

    else if ([objv isKindOfClass:[NSData class]])
        [self _encodeData:objv forKey:key withSubstitutions:NO];
    
    else if ([objv isKindOfClass:[BSONDocument class]])
        [self _encodeBSONDocument:objv forKey:key withSubstitutions:NO];
    
    // Use late binding so the package will work at runtime under 10.6 (which lacks NSOrderedSet) as well as 10.7
    else if (orderedSetClass && [objv isKindOfClass:orderedSetClass])
        [self _encodeArray:[(id)objv array] forKey:key withSubstitutions:NO];
    
    else if ([objv isKindOfClass:[NSArray class]])
        [self _encodeArray:objv forKey:key withSubstitutions:NO];
    
    else if ([objv isKindOfClass:[NSDictionary class]])
        [self _encodeDictionary:objv forKey:key withSubstitutions:NO];
    
    else
        [self _encodeCustomObject:objv forKey:key];
}

#pragma mark - Encoding the root object

- (void) encodeObject:(id) objv {
    if ([self _encodingHelper:objv withSubstitutions:YES withObjectIDSubstitution:NO topLevel:YES]) return;
    [self _encodeObject:objv withSubstitutions:NO topLevel:YES];
}

- (void) _encodeObject:(id) objv withSubstitutions:(BOOL) substitutions topLevel:(BOOL)topLevel {
    [self _encodingHelper];
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
        [self _encodeExposedDictionary:objv];
    else
        [self _encodeExposedCustomObject:objv];
    
    [self _postEncodingHelper:objv keyOrNil:nil topLevel:topLevel];
}

- (void) encodeDictionary:(NSDictionary *) objv {
    if ([self _encodingHelper:objv withSubstitutions:YES withObjectIDSubstitution:NO topLevel:YES]) return;
    [self _encodeExposedDictionary:objv];
    [self _postEncodingHelper:objv keyOrNil:nil topLevel:YES];
}

#pragma mark - Exposing internal objects

- (void) _exposeKey:(NSString *) key asArray:(BOOL)asArray forObject:(id) object {
    BSONAssertKeyNonNil(key);
    if (self.restrictsKeyNamesForMongoDB) BSONAssertKeyLegalForMongoDB(key);
    
    if ([self.encodingObjectStack containsObject:object]) {
        id exc = [NSException exceptionWithName:NSInvalidArchiveOperationException
                                         reason:@"Attempting to encode objects in a loop"
                                       userInfo:nil];
        @throw exc;
    }
    [self.encodingObjectStack addObject:object];
    
    [self.privateKeyPathComponents addObject:key];
    if (asArray)
        bson_append_start_array(_bson, BSONStringFromNSString(key));
    else
        bson_append_start_object(_bson, BSONStringFromNSString(key));    
}

- (void) _closeKey {
    if (![self.privateKeyPathComponents count]) {
        id exc = [NSException exceptionWithName:NSInvalidArchiveOperationException
                                         reason:@"-closeKey called too many times (without matching call to -_exposeKey:asArray:forObject:)"
                                       userInfo:nil];
        @throw exc;
    }
    bson_append_finish_object(_bson);
    [self.privateKeyPathComponents removeLastObject];
    [self.encodingObjectStack removeLastObject];
}

- (void) _encodeCustomObject:(id) obj forKey:(NSString *) key {
    if ([self _encodingHelper:obj key:key withSubstitutions:NO withObjectIDSubstitution:NO]) return;
    
    [self _exposeKey:key asArray:NO forObject:obj];
    [self _encodeExposedCustomObject:obj];
    [self _closeKey];
    [self _postEncodingHelper:obj keyOrNil:key topLevel:NO];
}

- (void) encodeArray:(NSArray *) array forKey:(NSString *) key {
    [self _encodeArray:array forKey:key withSubstitutions:YES];
}

- (void) _encodeArray:(NSArray *) array forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self _encodingHelper:array key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    
    [self _exposeKey:key asArray:YES forObject:array];
    [self _encodeExposedArray:array];
    [self _closeKey];
    [self _postEncodingHelper:array keyOrNil:key topLevel:NO];
}

- (void) encodeDictionary:(NSDictionary *) dictionary forKey:(NSString *) key {
    [self _encodeDictionary:dictionary forKey:key withSubstitutions:YES];
}

- (void) _encodeDictionary:(NSDictionary *) dictionary forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self _encodingHelper:dictionary key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    
    [self _exposeKey:key asArray:NO forObject:dictionary];
    [self _encodeExposedDictionary:dictionary];
    [self _closeKey];
    [self _postEncodingHelper:dictionary keyOrNil:key topLevel:NO];
}

#pragma mark - Encoding exposed objects

- (void) _encodeExposedCustomObject:(id) obj {
    if ([obj respondsToSelector:@selector(encodeWithBSONEncoder:)])
        [obj encodeWithBSONEncoder:self];
    else
        [obj encodeWithCoder:self];
}

- (void) _encodeExposedArray:(NSArray *) array {
    for (NSUInteger i = 0; i < array.count; ++i)
        [self _encodeObject:[array objectAtIndex:i]
                     forKey:[[NSNumber numberWithInteger:i] stringValue]
          withSubstitutions:YES
   withObjectIDSubstitution:NO];
}

- (void) _encodeExposedDictionary:(NSDictionary *) dictionary {
    for (id key in [dictionary allKeys])
        [self _encodeObject:[dictionary objectForKey:key]
                     forKey:key
          withSubstitutions:YES
   withObjectIDSubstitution:NO];
}

#pragma mark - Encoding supported types - trampoline methods

- (void) encodeObjectID:(BSONObjectID *) objv forKey:(NSString *) key {
    [self _encodeObjectID:objv forKey:key withSubstitutions:YES];
}
- (void) encodeNumber:(NSNumber *) objv forKey:(NSString *) key {
    [self _encodeNumber:objv forKey:key withSubstitutions:YES];
}
- (void) encodeDate:(NSDate *) objv forKey:(NSString *) key {
    [self _encodeDate:objv forKey:key withSubstitutions:YES];
}
- (void) encodeTimestamp:(BSONTimestamp *) objv forKey:(NSString *) key {
    [self _encodeTimestamp:objv forKey:key withSubstitutions:YES];
}
- (void) encodeImage:(NSImage *) objv forKey:(NSString *) key {
    [self _encodeImage:objv forKey:key withSubstitutions:YES];
}
- (void) encodeString:(NSString *) objv forKey:(NSString *) key {
    [self _encodeString:objv forKey:key withSubstitutions:YES];
}
- (void) encodeSymbol:(BSONSymbol *)objv forKey:(NSString *) key {
    [self _encodeSymbol:objv forKey:key withSubstitutions:YES];
}
- (void) encodeRegularExpression:(BSONRegularExpression *) objv forKey:(NSString *) key {
    [self _encodeRegularExpression:objv forKey:key withSubstitutions:YES];
}
- (void) encodeBSONDocument:(BSONDocument *) objv forKey:(NSString *) key {
    [self _encodeBSONDocument:objv forKey:key withSubstitutions:YES];
}
- (void) encodeData:(NSData *) objv forKey:(NSString *) key {
    [self _encodeData:objv forKey:key withSubstitutions:YES];
}
- (void) encodeCodeString:(NSString *) objv forKey:(NSString *) key {
    [self _encodeCodeString:objv forKey:key withSubstitutions:YES];
}
- (void) encodeCode:(BSONCode *) objv forKey:(NSString *) key {
    [self _encodeCode:objv forKey:key withSubstitutions:YES];
}
- (void) encodeCodeWithScope:(BSONCodeWithScope *) objv forKey:(NSString *) key {
    [self _encodeCodeWithScope:objv forKey:key withSubstitutions:YES];
}

#pragma mark - Encoding supported types

- (void) encodeNewObjectID {
    [self _encodingHelper];
    bson_append_new_oid(_bson, MongoDBObjectIDBSONKey);
}

- (void) _encodeObjectID:(BSONObjectID *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self _encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    if (BSON_ERROR == bson_append_oid(_bson, BSONStringFromNSString(key), [objv objectIDPointer]))
        [self _raiseBSONError];
    [self _postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) encodeInt:(int) intv forKey:(NSString *) key {
    [self _encodingHelperForKey:key];
    if (BSON_ERROR == bson_append_int(_bson, BSONStringFromNSString(key), intv))
        [self _raiseBSONError];
}

- (void) encodeInt64:(int64_t) intv forKey:(NSString *) key {
    [self _encodingHelperForKey:key];
    if (BSON_ERROR == bson_append_long(_bson, BSONStringFromNSString(key), intv))
        [self _raiseBSONError];
}

- (void) encodeBool:(BOOL) boolv forKey:(NSString *) key {
    [self _encodingHelperForKey:key];
    if (BSON_ERROR == bson_append_bool(_bson, BSONStringFromNSString(key), boolv))
        [self _raiseBSONError];
}

- (void) encodeDouble:(double) realv forKey:(NSString *) key {
    [self _encodingHelperForKey:key];
    if (BSON_ERROR == bson_append_double(_bson, BSONStringFromNSString(key), realv))
        [self _raiseBSONError];
}

- (void) encodeNullForKey:(NSString *) key {
    [self _encodingHelperForKey:key];
    if (BSON_ERROR == bson_append_null(_bson, BSONStringFromNSString(key)))
        [self _raiseBSONError];
}

- (void) encodeUndefinedForKey:(NSString *) key {
    [self _encodingHelperForKey:key];
    if (BSON_ERROR == bson_append_undefined(_bson, BSONStringFromNSString(key)))
        [self _raiseBSONError];
}

- (void) _encodeNumber:(NSNumber *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self _encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    
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
    [self _postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) _encodeDate:(NSDate *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self _encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    if (BSON_ERROR == bson_append_date (_bson,
                                        BSONStringFromNSString(key),
                                        1000.0 * [objv timeIntervalSince1970]))
        [self _raiseBSONError];
    [self _postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) _encodeTimestamp:(BSONTimestamp *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self _encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    if (BSON_ERROR == bson_append_timestamp(_bson, BSONStringFromNSString(key), [objv timestampPointer]))
        [self _raiseBSONError];
    [self _postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) _encodeImage:(NSImage *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self _encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    NSData *data = [objv TIFFRepresentationUsingCompression:NSTIFFCompressionLZW
                                                     factor:1.0L];
    [self encodeObject:data forKey:key];
    [self _postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) _encodeString:(NSString *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self _encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    if (BSON_ERROR == bson_append_string(_bson,
                                         BSONStringFromNSString(key),
                                         BSONStringFromNSString(objv)))
        [self _raiseBSONError];
    [self _postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) _encodeSymbol:(BSONSymbol *)objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self _encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    if (BSON_ERROR == bson_append_symbol(_bson,
                                         BSONStringFromNSString(key),
                                         BSONStringFromNSString(objv.symbol)))
        [self _raiseBSONError];
    [self _postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) encodeRegularExpressionPattern:(NSString *) pattern options:(NSString *) options forKey:(NSString *) key {
    if (!pattern && !options) {
        [self _encodingHelper:nil key:key withSubstitutions:NO withObjectIDSubstitution:NO];
        return;
    } else {
        BSONAssertValueNonNil(pattern);
        [self _encodingHelperForKey:key];
    }
    if (BSON_ERROR == bson_append_regex(_bson,
                                        BSONStringFromNSString(key),
                                        BSONStringFromNSString(pattern),
                                        options ? BSONStringFromNSString(options) : ""))
        [self _raiseBSONError];
}

- (void) _encodeRegularExpression:(BSONRegularExpression *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self _encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    [self encodeRegularExpressionPattern:objv.pattern options:objv.options forKey:key];
    [self _postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) _encodeBSONDocument:(BSONDocument *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self _encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    if (BSON_ERROR == bson_append_bson(_bson,
                                       BSONStringFromNSString(key),
                                       [objv bsonValue]))
        [self _raiseBSONError];
    [self _postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) _encodeData:(NSData *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self _encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    if (objv.length > INT_MAX)
        [NSException raise:NSInvalidArgumentException format:@"Data length is out of range"];
    if (BSON_ERROR == bson_append_binary(_bson,
                                         BSONStringFromNSString(key),
                                         0,
                                         objv.bytes,
                                         (int) objv.length))
        [self _raiseBSONError];
    [self _postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) _encodeCodeString:(NSString *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self _encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    if (BSON_ERROR == bson_append_code(_bson,
                                       BSONStringFromNSString(key),
                                       BSONStringFromNSString(objv)))
        [self _raiseBSONError];
    [self _postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) _encodeCode:(BSONCode *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self _encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    [self encodeCodeString:objv.code forKey:key];
    [self _postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

- (void) encodeCodeString:(NSString *) code withScope:(BSONDocument *) scope forKey:(NSString *) key {
    if (!code && !scope) {
        [self _encodingHelper:nil key:key withSubstitutions:NO withObjectIDSubstitution:NO];
        return;
    }
    BSONAssertValueNonNil(code);
    BSONAssertValueNonNil(scope);
    [self _encodingHelperForKey:key];
    if (BSON_ERROR == bson_append_code_w_scope(_bson,
                                               BSONStringFromNSString(key),
                                               BSONStringFromNSString(code),
                                               [scope bsonValue]))
        [self _raiseBSONError];
}

- (void) _encodeCodeWithScope:(BSONCodeWithScope *) objv forKey:(NSString *) key withSubstitutions:(BOOL) substitutions {
    if ([self _encodingHelper:objv key:key withSubstitutions:substitutions withObjectIDSubstitution:NO]) return;
    [self encodeCodeString:objv.code withScope:objv.scope forKey:key];
    [self _postEncodingHelper:objv keyOrNil:key topLevel:NO];
}

#pragma mark - Helper methods for -encode... methods

- (void) _encodingHelper {
    if (!_bson) {
        id exc = [NSException exceptionWithName:NSInvalidArchiveOperationException
                                         reason:@"Can't continue to encode after finishEncoding called"
                                       userInfo:nil];
        @throw exc;
    }
}

- (void) _encodingHelperForKey:(NSString *) key {
    [self _encodingHelper];
    BSONAssertKeyNonNil(key);
    if (self.restrictsKeyNamesForMongoDB) BSONAssertKeyLegalForMongoDB(key);
}

- (BOOL) _encodingHelper:(id) object withSubstitutions:(BOOL) substitutions withObjectIDSubstitution:(BOOL) substituteObjectID topLevel:(BOOL) topLevel {
    [self _encodingHelper];
    
    if (topLevel) {
        if ([self.encodingObjectStack count]) {
            id exc = [NSException exceptionWithName:NSInvalidArchiveOperationException
                                             reason:@"Can only use root object encoding methods for the root object. Use encode...:forKey: methods instead."
                                           userInfo:nil];
            @throw exc;
        }
    }
    
    if (substitutions && object) {
        id substituteObject = [self _substituteForObject:object substituteObjectID:substituteObjectID keyOrNil:nil topLevel:topLevel];
        if (substituteObject != object) {
            if (topLevel) [self.encodingObjectStack addObject:substituteObject];
            [self _encodeObject:substituteObject withSubstitutions:NO topLevel:topLevel];
            return YES;
        }
    }
    
    if (topLevel) [self.encodingObjectStack addObject:object];
    return NO;
}

- (BOOL) _encodingHelper:(id) object key:(NSString *) key withSubstitutions:(BOOL) substitutions withObjectIDSubstitution:(BOOL) substituteObjectID {
    [self _encodingHelperForKey:key];
    
    if (substitutions && object) {
        id substituteObject = [self _substituteForObject:object substituteObjectID:substituteObjectID keyOrNil:key topLevel:NO];

        if (substituteObject != object) {
            [self _encodeObject:substituteObject forKey:key withSubstitutions:NO withObjectIDSubstitution:NO];
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

- (void) _postEncodingHelper:(id) object keyOrNil:(NSString *) key topLevel:(BOOL) topLevel {
    if ([self.delegate respondsToSelector:@selector(encoder:didEncodeObject:forKeyPath:)])
        [self.delegate encoder:self didEncodeObject:object forKeyPath:[self _keyPathComponentsAddingKeyOrNil:key]];
    if (topLevel) [self.encodingObjectStack removeLastObject];
}

#pragma mark - Other helper methods

- (BOOL) allowsKeyedCoding { return YES; }

- (NSArray *) keyPathComponents {
    return [self.privateKeyPathComponents copy];
}

- (NSArray *) _keyPathComponentsAddingKeyOrNil:(NSString *) key {
    NSArray *result = [self keyPathComponents];
    if (key) result = [result arrayByAddingObject:key];
    return result.count ? result : nil;
}

- (id) _substituteForObject:(id) object substituteObjectID:(BOOL) substituteObjectID keyOrNil:(NSString *) key topLevel:(BOOL) topLevel {
    id originalObject = object;
    
    if (!substituteObjectID
        && !topLevel
        && [self.delegate respondsToSelector:@selector(encoder:shouldSubstituteObjectIDForObject:forKeyPath:)])
        substituteObjectID = [self.delegate encoder:self shouldSubstituteObjectIDForObject:object forKeyPath:[self _keyPathComponentsAddingKeyOrNil:key]];

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
        object = [self.delegate encoder:self willEncodeObject:object forKeyPath:[self _keyPathComponentsAddingKeyOrNil:key]];
    
    // Finally, notify the delegate if a substitution was made
    if (object != originalObject
        && [self.delegate respondsToSelector:@selector(encoder:willReplaceObject:withObject:forKeyPath:)])
        [self.delegate encoder:self willReplaceObject:originalObject withObject:object forKeyPath:[self _keyPathComponentsAddingKeyOrNil:key]];
    
    return object;
}

- (void) _raiseBSONError {
    id exc = [NSException exceptionWithName:NSInvalidArchiveOperationException
                                     reason:NSStringFromBSONError(_bson->err)
                                   userInfo:nil];
    @throw exc;
}

#pragma mark - Unsupported unkeyed encoding methods

+ (void) _unsupportedUnkeyedCodingSelector:(SEL) selector {
    NSString *reason = [NSString stringWithFormat:@"%@ called, but unkeyed encoding methods are not supported. Subclass if unkeyed coding is needed.",
                        NSStringFromSelector(selector)];
    id exc = [NSException exceptionWithName:NSInvalidArchiveOperationException
                                     reason:reason
                                   userInfo:nil];
    @throw exc;
}

- (void) encodeArrayOfObjCType:(const char *) itemType count:(NSUInteger) count at:(const void *) address {
    [BSONEncoder _unsupportedUnkeyedCodingSelector:_cmd];
}
- (void) encodeBycopyObject:(id) object {
    [BSONEncoder _unsupportedUnkeyedCodingSelector:_cmd];
}
- (void) encodeByrefObject:(id) object {
    [BSONEncoder _unsupportedUnkeyedCodingSelector:_cmd];
}
- (void) encodeDataObject:(NSData *) data {
    [BSONEncoder _unsupportedUnkeyedCodingSelector:_cmd];
}
- (void) encodeRootObject:(id) object {
    [BSONEncoder _unsupportedUnkeyedCodingSelector:_cmd];
}
- (void) encodeValueOfObjCType:(const char *) type at:(const void *) addr {
    [BSONEncoder _unsupportedUnkeyedCodingSelector:_cmd];
}
- (void) encodeValuesOfObjCTypes:(const char *) types, ... {
    [BSONEncoder _unsupportedUnkeyedCodingSelector:_cmd];
}

#pragma mark - Unsupported encoding types

+ (void) _unsupportedCodingSelector:(SEL) selector {
    NSString *reason = [NSString stringWithFormat:@"%@ is not supported. Subclass if coding this type is needed.",
                        NSStringFromSelector(selector)];
    id exc = [NSException exceptionWithName:NSInvalidArchiveOperationException
                                     reason:reason
                                   userInfo:nil];
    @throw exc;
}

- (void) encodeBytes:(const void *) address length:(NSUInteger) numBytes {
    [BSONEncoder _unsupportedCodingSelector:_cmd];    
}
- (void) encodeBytes:(const uint8_t *) bytesp length:(NSUInteger) lenv forKey:(NSString *) key {
    [BSONEncoder _unsupportedCodingSelector:_cmd];
}
- (void) encodeConditionalObject:(id) object {
    [BSONEncoder _unsupportedCodingSelector:_cmd];
}
- (void) encodeConditionalObject:(id) objv forKey:(NSString *) key {
    [BSONEncoder _unsupportedCodingSelector:_cmd];
}
- (void) encodeFloat:(float) realv forKey:(NSString *) key {
    [BSONEncoder _unsupportedCodingSelector:_cmd];
}
- (void) encodeInt32:(int32_t) intv forKey:(NSString *) key {
    [BSONEncoder _unsupportedCodingSelector:_cmd];
}
- (void) encodeInteger:(NSInteger) intv forKey:(NSString *) key {
    [BSONEncoder _unsupportedCodingSelector:_cmd];    
}
- (void) encodePoint:(NSPoint) point {
    [BSONEncoder _unsupportedCodingSelector:_cmd];    
}
- (void) encodePoint:(NSPoint) point forKey:(NSString *) key {
    [BSONEncoder _unsupportedCodingSelector:_cmd];
}
- (void) encodePropertyList:(id) object {
    [BSONEncoder _unsupportedCodingSelector:_cmd];
}
- (void) encodeRect:(NSRect) rect {
    [BSONEncoder _unsupportedCodingSelector:_cmd];    
}
- (void) encodeRect:(NSRect) rect forKey:(NSString *) key {
    [BSONEncoder _unsupportedCodingSelector:_cmd];
}
- (void) encodeSize:(NSSize) size {
    [BSONEncoder _unsupportedCodingSelector:_cmd];    
}
- (void) encodeSize:(NSSize) size forKey:(NSString *) key {
    [BSONEncoder _unsupportedCodingSelector:_cmd];
}

@end