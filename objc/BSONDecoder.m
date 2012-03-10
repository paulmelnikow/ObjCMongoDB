//
//  BSONDecoder.m
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

#import "BSONDecoder.h"
#import "bson.h"

@interface BSONDecoder (Private)
- (id) decodeExposedCustomObjectWithClassOrNil:(Class) classForDecoder;
- (NSDictionary *) decodeExposedDictionaryWithClassOrNil:(Class) classForDecoder;
- (NSArray *) decodeExposedArrayWithClassOrNil:(Class) classForDecoder;
- (id) decodeCurrentObjectWithClassOrNil:(Class) classForDecoder;
+ (NSException *) unsupportedUnkeyedCodingSelector:(SEL)selector;
- (BOOL) decodingHelper:(id*) result;
- (BOOL) decodingHelperForKey:(NSString *) key result:(id*) result;
- (BOOL) decodingHelperForKey:(NSString *) key nativeValueType:(bson_type) nativeValueType result:(id*) result;
- (BOOL) decodingHelperForKey:(NSString *) key nativeValueTypeArray:(bson_type*) nativeValueTypeArray result:(id*) result;
- (id) postDecodingHelper:(id) object keyOrNil:(NSString *) key topLevel:(BOOL) topLevel;

- (NSArray *) keyPathComponentsAddingKeyOrNil:(NSString *) key;
@end

@implementation BSONDecoder

@synthesize delegate, behaviorOnNull, behaviorOnUndefined, objectZone;

#pragma mark - Initialization

- (BSONDecoder *) initWithDocument:(BSONDocument *)document {
    self = [super init];
    if (self) {
#if __has_feature(objc_arc)
        _iterator = [document iterator];
        _iteratorStack = [NSMutableArray array];
        _keyPathComponents = [NSMutableArray array];
#else
        _iterator = [[document iterator] retain];
        _iteratorStack = [[NSMutableArray array] retain];
        _keyPathComponents = [[NSMutableArray array] retain];
#endif
        self.objectZone = NSDefaultMallocZone();
    }
    return self;
}

- (BSONDecoder *) initWithData:(NSData *)data {
    return [self initWithDocument:[[BSONDocument alloc] initWithData:data]];
}

- (void) dealloc {
#if !__has_feature(objc_arc)
    [_keyPathComponents release];
    [_iteratorStack release];
    [_iterator release];
#endif    
}

#pragma mark - Convenience methods

+ (NSDictionary *) decodeDictionaryWithDocument:(BSONDocument *)document {
    return [self decodeDictionaryWithClass:nil document:document];
}

+ (NSDictionary *) decodeDictionaryWithClass:(Class) classForDecoder document:(BSONDocument *) document {
    BSONDecoder *decoder = [[self alloc] initWithDocument:document];
    NSDictionary *result = [decoder decodeDictionaryWithClass:classForDecoder];
#if !__has_feature(objc_arc)
    [[result retain] autorelease];
    [decoder release];
#endif
    return result;
}

+ (NSDictionary *) decodeDictionaryWithData:(NSData *)data {
    return [self decodeDictionaryWithClass:nil data:data];
}

+ (NSDictionary *) decodeDictionaryWithClass:(Class) classForDecoder data:(NSData *) data {
    BSONDecoder *decoder = [[self alloc] initWithData:data];
    NSDictionary *result = [decoder decodeDictionaryWithClass:classForDecoder];
#if !__has_feature(objc_arc)
    [[result retain] autorelease];
    [decoder release];
#endif
    return result;
}

+ (NSDictionary *) decodeObjectWithClass:(Class) classForDecoder document:(BSONDocument *) document {
    BSONDecoder *decoder = [[self alloc] initWithDocument:document];
    NSDictionary *result = [decoder decodeObjectWithClass:classForDecoder];
#if !__has_feature(objc_arc)
    [[result retain] autorelease];
    [decoder release];
#endif
    return result;
}

+ (NSDictionary *) decodeObjectWithClass:(Class) classForDecoder data:(NSData *) data {
    BSONDecoder *decoder = [[self alloc] initWithData:data];
    NSDictionary *result = [decoder decodeObjectWithClass:classForDecoder];
#if !__has_feature(objc_arc)
    [[result retain] autorelease];
    [decoder release];
#endif
    return result;
}

#pragma mark - Decoding top-level objects

- (NSDictionary *) decodeDictionary {
    return [self decodeDictionaryWithClass:nil];
}

- (NSDictionary *) decodeDictionaryWithClass:(Class) classForDecoder {
    id result = [self decodeExposedDictionaryWithClassOrNil:classForDecoder];
    return [self postDecodingHelper:result keyOrNil:nil topLevel:YES];
}

- (id) decodeObjectWithClass:(Class) classForDecoder {
    id result = [self decodeExposedCustomObjectWithClassOrNil:classForDecoder];
    return [self postDecodingHelper:result keyOrNil:nil topLevel:YES];
}

#pragma mark - Exposing internal objects

- (void) exposeKey:(NSString *)key asArray:(BOOL) asArray { 
    [_iteratorStack addObject:_iterator];
#if __has_feature(objc_arc)
    if (asArray)
        _iterator = [_iterator sequentialSubIteratorValue];
    else
        _iterator = [_iterator embeddedDocumentIteratorValue];
#else
    if (asArray)
        _iterator = [[_iterator sequentialSubIteratorValue] retain];
    else
        _iterator = [[_iterator embeddedDocumentIteratorValue] retain];
#endif
    [_keyPathComponents addObject:key];
}

- (void) closeInternalObject {
    if (![_iteratorStack count]) {
        id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                         reason:@"-leaveInternalObject called too many times (without matching call to -enterInternalObjectAsArray:)"
                                       userInfo:nil];
        @throw exc;
    }
#if !__has_feature(objc_arc)
    [_iterator release];
#endif
    _iterator = [_iteratorStack lastObject];
    [_iteratorStack removeLastObject];
    [_keyPathComponents removeLastObject];
}

- (NSDictionary *) decodeDictionaryForKey:(NSString *) key {
    return [self decodeDictionaryForKey:key withClass:nil];
}

- (NSDictionary *) decodeDictionaryForKey:(NSString *) key withClass:(Class) classForDecoder {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:BSON_OBJECT result:&result]) return result;
    
    [self exposeKey:key asArray:NO];
    result = [self decodeExposedDictionaryWithClassOrNil:classForDecoder];
    [self closeInternalObject];
    return [self postDecodingHelper:result keyOrNil:key topLevel:NO];
}

- (NSArray *) decodeArrayForKey:(NSString *) key {
    return [self decodeArrayForKey:key withClass:nil];
}

- (NSArray *) decodeArrayForKey:(NSString *) key withClass:(Class) classForDecoder {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:BSON_ARRAY result:&result]) return result;

    [self exposeKey:key asArray:YES];
    result = [self decodeExposedArrayWithClassOrNil:classForDecoder];
    [self closeInternalObject];
    return [self postDecodingHelper:result keyOrNil:key topLevel:NO];
}

#pragma mark - Decoding exposed internal objects

- (id) decodeExposedCustomObjectWithClassOrNil:(Class) classForDecoder {
    if (classForDecoder)
        return [[classForDecoder allocWithZone:self.objectZone] initWithCoder:self];
    else
        return [self decodeExposedDictionaryWithClassOrNil:nil];
}

- (NSDictionary *) decodeExposedDictionaryWithClassOrNil:(Class) classForDecoder {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    while ([_iterator next])
        [dictionary setObject:[self decodeCurrentObjectWithClassOrNil:classForDecoder]
                       forKey:[_iterator key]];
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

- (NSArray *) decodeExposedArrayWithClassOrNil:(Class) classForDecoder {
    NSMutableArray *array = [NSMutableArray array];
    while ([_iterator next])
        [array addObject:[self decodeCurrentObjectWithClassOrNil:classForDecoder]];
    return [NSArray arrayWithArray:array];
}

- (id) decodeCurrentObjectWithClassOrNil:(Class) classForDecoder {
    id result = nil;
    if ([self decodingHelper:&result]) return result;
    
    if (![_iterator isArray] && ![_iterator isEmbeddedDocument]) {
        result = [_iterator objectValue];
        
    } else if (classForDecoder) {
        [self exposeKey:[_iterator key] asArray:NO];
        result = [self decodeExposedCustomObjectWithClassOrNil:classForDecoder];
        [self closeInternalObject];
        
    } else if ([_iterator isEmbeddedDocument]) {
        [self exposeKey:[_iterator key] asArray:NO];
        result = [self decodeExposedDictionaryWithClassOrNil:nil];
        [self closeInternalObject];        
        
    } else {
        [self exposeKey:[_iterator key] asArray:YES];
        result = [self decodeExposedArrayWithClassOrNil:nil];
        [self closeInternalObject];        
    }
    
    return [self postDecodingHelper:result keyOrNil:[_iterator key] topLevel:NO];
}


#pragma mark - Basic decoding methods

- (id) decodeObjectForKey:(NSString *) key {
    return [self decodeObjectForKey:key withClass:nil];
}

- (id) decodeObjectForKey:(NSString *) key withClass:(Class) classForDecoder {
    id result = nil;
    if ([self decodingHelperForKey:key result:&result]) return result;

    if (![_iterator isArray] && ![_iterator isEmbeddedDocument]) {
        result = [_iterator objectValue];

    } else if (classForDecoder) {
        [self exposeKey:key asArray:NO];
        result = [self decodeExposedCustomObjectWithClassOrNil:classForDecoder];
        [self closeInternalObject];

    } else if ([_iterator isEmbeddedDocument]) {
        [self exposeKey:key asArray:NO];
        result = [self decodeExposedDictionaryWithClassOrNil:nil];
        [self closeInternalObject];        

    } else {
        [self exposeKey:key asArray:YES];
        result = [self decodeExposedArrayWithClassOrNil:nil];
        [self closeInternalObject];        
    }
    
    return result;
}

#pragma mark - Decoding supported types

- (BSONObjectID *) decodeObjectIDForKey:(NSString *) key {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:BSON_OID result:&result]) return result;
    return [self postDecodingHelper:[_iterator objectIDValue] keyOrNil:key topLevel:NO];
}

- (int) decodeIntForKey:(NSString *) key {
    bson_type allowedTypes[3];
    allowedTypes[0] = BSON_INT;
    allowedTypes[1] = BSON_LONG;
    allowedTypes[2] = BSON_DOUBLE;
    
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueTypeArray:allowedTypes result:&result]) return 0;

    return [_iterator intValue];
}
- (int64_t) decodeInt64ForKey:(NSString *) key {
    bson_type allowedTypes[3];
    allowedTypes[0] = BSON_INT;
    allowedTypes[1] = BSON_LONG;
    allowedTypes[2] = BSON_DOUBLE;
    
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueTypeArray:allowedTypes result:&result]) return 0;

    return [_iterator int64Value];
}
- (BOOL) decodeBoolForKey:(NSString *) key {
    bson_type allowedTypes[4];
    allowedTypes[0] = BSON_BOOL;
    allowedTypes[1] = BSON_INT;
    allowedTypes[2] = BSON_LONG;
    allowedTypes[3] = BSON_DOUBLE;
    
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueTypeArray:allowedTypes result:&result]) return 0;

    return [_iterator doubleValue];
}
- (double) decodeDoubleForKey:(NSString *) key {
    bson_type allowedTypes[3];
    allowedTypes[0] = BSON_INT;
    allowedTypes[1] = BSON_LONG;
    allowedTypes[2] = BSON_DOUBLE;
    
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueTypeArray:allowedTypes result:&result]) return 0;

    return [_iterator doubleValue];
}

- (NSDate *) decodeDateForKey:(NSString *)key {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:BSON_DATE result:&result]) return result;
    return [self postDecodingHelper:[_iterator dateValue] keyOrNil:key topLevel:NO];
}
- (NSImage *) decodeImageForKey:(NSString *) key {
    NSData *data = [self decodeDataForKey:key];
    if (data)
        return [[NSImage alloc] initWithData:data];
    else
        return nil;
}

- (NSString *) decodeStringForKey:(NSString *) key {
    bson_type allowedTypes[3];
    allowedTypes[0] = BSON_STRING;
    allowedTypes[1] = BSON_CODE;
    allowedTypes[2] = BSON_SYMBOL;
    
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueTypeArray:allowedTypes result:&result]) return result;
    
    return [self postDecodingHelper:[_iterator stringValue] keyOrNil:key topLevel:NO];
}

- (BSONSymbol *) decodeSymbolForKey:(NSString *) key {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:BSON_SYMBOL result:&result]) return result;
    return [self postDecodingHelper:[_iterator symbolValue] keyOrNil:key topLevel:NO];
}

- (BSONRegularExpression *) decodeRegularExpressionForKey:(NSString *) key {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:BSON_REGEX result:&result]) return result;
    return [self postDecodingHelper:[_iterator regularExpressionValue] keyOrNil:key topLevel:NO];
}

- (BSONDocument *) decodeBSONDocumentForKey:(NSString *) key {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:BSON_OBJECT result:&result]) return result;
    return [self postDecodingHelper:[_iterator embeddedDocumentValue] keyOrNil:key topLevel:NO];
}

- (NSData *)decodeDataForKey:(NSString *) key {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:BSON_BINDATA result:&result]) return result;
    return [self postDecodingHelper:[_iterator dataValue] keyOrNil:key topLevel:NO];
}

- (BSONCode *) decodeCodeForKey:(NSString *) key {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:BSON_CODE result:&result]) return result;
    return [self postDecodingHelper:[_iterator codeValue] keyOrNil:key topLevel:NO];
}
- (BSONCodeWithScope *) decodeCodeWithScopeForKey:(NSString *) key {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:BSON_CODEWSCOPE result:&result]) return result;
    return [self postDecodingHelper:[_iterator codeWithScopeValue] keyOrNil:key topLevel:NO];
}

#pragma mark - Helper methods for -decode... methods

- (BOOL) decodingHelper:(id*) result {
    if (BSON_NULL == [_iterator nativeValueType]) {
        switch(self.behaviorOnNull) {
            case BSONReturnNSNull:
                *result = [NSNull null]; return YES;
            case BSONReturnNilForNull:
                *result = nil; return YES;
            case BSONRaiseExceptionOnNull:
                @throw [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                               reason:@"Tried to decode null value with BSONRaiseExceptionOnNull set"
                                             userInfo:nil];
        }
    } else if (BSON_UNDEFINED == [_iterator nativeValueType]) {
        switch(self.behaviorOnUndefined) {
            case BSONReturnBSONUndefined:
                *result = [BSONDecoder objectForUndefined]; return YES;
            case BSONReturnNSNullForUndefined:
                *result = [NSNull null]; return YES;
            case BSONReturnNilForUndefined:
                *result = nil; return YES;
            case BSONRaiseExceptionOnUndefined:
                @throw [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                               reason:@"Tried to decode undefined value with BSONRaiseExceptionOnUndefined set"
                                             userInfo:nil];
        }
    }
    return NO;
}

- (BOOL) decodingHelperForKey:(NSString *) key result:(id*) result {
    BSONAssertKeyNonNil(key);
    if (![_iterator containsValueForKey:key]) {
        result = nil; return YES;
    }
    return [self decodingHelper:result];
}

- (BOOL) decodingHelperForKey:(NSString *) key nativeValueType:(bson_type) nativeValueType result:(id*) result {
    if ([self decodingHelperForKey:key result:result]) return YES;
    BSONAssertIteratorIsValueType(_iterator, nativeValueType);
    return NO;
}

- (BOOL) decodingHelperForKey:(NSString *) key nativeValueTypeArray:(bson_type*) nativeValueTypeArray result:(id*) result {
    if ([self decodingHelperForKey:key result:result]) return YES;
    BSONAssertIteratorIsInValueTypeArray(_iterator, nativeValueTypeArray);
    return NO;
}

- (id) postDecodingHelper:(id) object keyOrNil:(NSString *) key topLevel:(BOOL) topLevel {
    id originalObject = object;
    
    if ([object respondsToSelector:@selector(awakeAfterUsingBSONDecoder:)])
        object = [object awakeAfterUsingBSONDecoder:self];
    else if ([object respondsToSelector:@selector(awakeAfterUsingCoder:)])
        object = [object awakeAfterUsingCoder:self];

    if ([self.delegate respondsToSelector:@selector(decoder:didDecodeObject:forKeyPath:)])
        object = [self.delegate decoder:self didDecodeObject:object forKeyPath:[self keyPathComponentsAddingKeyOrNil:key]];
    
    if (originalObject != object
        && [self.delegate respondsToSelector:@selector(decoder:willReplaceObject:withObject:forKeyPath:)])
        [self.delegate decoder:self willReplaceObject:originalObject withObject:object forKeyPath:[self keyPathComponentsAddingKeyOrNil:key]];
    
    if (topLevel && [self.delegate respondsToSelector:@selector(decoderWillFinish:)])
        [self.delegate decoderWillFinish:self];
            
    return object;
}

#pragma mark - Other helper methods

- (BOOL) allowsKeyedCoding { return YES; }

- (BOOL) containsValueForKey:(NSString *) key {
    return [_iterator containsValueForKey:key];
}

+ (id) objectForUndefined {
    return [BSONIterator objectForUndefined];
}

- (NSArray *) keyPathComponents {
    return [NSArray arrayWithArray:_keyPathComponents];
}

- (NSArray *) keyPathComponentsAddingKeyOrNil:(NSString *) key {
    NSArray *result = [self keyPathComponents];
    if (key) result = [result arrayByAddingObject:key];
    return result.count ? result : nil;
}

#pragma mark - Unsupported unkeyed encoding methods

+ (NSException *) unsupportedUnkeyedCodingSelector:(SEL)selector {
    NSString *reason = [NSString stringWithFormat:@"%@ called, but unkeyed decoding methods are not supported. Subclass if unkeyed coding is needed.",
                        NSStringFromSelector(selector)];
    id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                   reason:reason
                                 userInfo:nil];
    @throw exc;
}

- (void) decodeArrayOfObjCType:(const char *) itemType count:(NSUInteger) count at:(void *) array {
    [BSONDecoder unsupportedUnkeyedCodingSelector:_cmd];
}
- (NSData *) decodeDataObject {
    [BSONDecoder unsupportedUnkeyedCodingSelector:_cmd];
    return nil;
}
- (void) decodeValueOfObjCType:(const char *) type at:(void *) data {
    [BSONDecoder unsupportedUnkeyedCodingSelector:_cmd];
}
- (void) decodeValuesOfObjCTypes:(const char *)types, ... {
    [BSONDecoder unsupportedUnkeyedCodingSelector:_cmd];    
}
- (id) decodeNXObject {
    [BSONDecoder unsupportedUnkeyedCodingSelector:_cmd];
    return nil;
}

#pragma mark - Unsupported decoding types

+ (void) unsupportedCodingSelector:(SEL) selector {
    NSString *reason = [NSString stringWithFormat:@"%@ is not supported. Subclass if coding this type is needed.",
                        NSStringFromSelector(selector)];
    id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                     reason:reason
                                   userInfo:nil];
    @throw exc;
}

- (const uint8_t *) decodeBytesForKey:(NSString *) key returnedLength:(NSUInteger *)lengthp {
    [BSONDecoder unsupportedCodingSelector:_cmd];
    return NULL;
}
- (void *) decodeBytesWithReturnedLength:(NSUInteger *) lengthp {
    [BSONDecoder unsupportedCodingSelector:_cmd];
    return NULL;
}
- (float) decodeFloatForKey:(NSString *) key {
    [BSONDecoder unsupportedCodingSelector:_cmd];
    return 0;
}
- (int32_t) decodeInt32ForKey:(NSString *) key {
    [BSONDecoder unsupportedCodingSelector:_cmd];
    return 0;
}
- (NSInteger) decodeIntegerForKey:(NSString *) key {
    [BSONDecoder unsupportedCodingSelector:_cmd];
    return 0;
}
- (id)decodeObject {
    id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                     reason:@"Use -decodeObjectWithClass: instead."
                                   userInfo:nil];
    @throw exc;
}
-(NSPoint)decodePoint {
    [BSONDecoder unsupportedCodingSelector:_cmd];
    return NSZeroPoint;
}
-(NSPoint)decodePointForKey:(NSString *)key {
    [BSONDecoder unsupportedCodingSelector:_cmd];
    return NSZeroPoint;
}
-(id)decodePropertyList {
    [BSONDecoder unsupportedCodingSelector:_cmd];
    return nil;
}
-(NSRect)decodeRect {
    [BSONDecoder unsupportedCodingSelector:_cmd];
    return NSZeroRect;    
}
-(NSRect)decodeRectForKey:(NSString *)key {
    [BSONDecoder unsupportedCodingSelector:_cmd];
    return NSZeroRect;    
}
-(NSSize)decodeSize {
    [BSONDecoder unsupportedCodingSelector:_cmd];
    return NSZeroSize;    
}
-(NSSize)decodeSizeForKey:(NSString *)key {
    [BSONDecoder unsupportedCodingSelector:_cmd];
    return NSZeroSize;    
}

@end