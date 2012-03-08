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
- (id) postDecodingHelper:(id) object key:(NSString *) key;

- (NSArray *) keyPathComponentsAddingKeyOrNil:(NSString *) key;
@end

@implementation BSONDecoder

@synthesize delegate, behaviorOnNull, behaviorOnUndefined;

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
    return [self decodeExposedDictionaryWithClassOrNil:classForDecoder];
}

- (id) decodeObjectWithClass:(Class) classForDecoder {
    return [self decodeExposedCustomObjectWithClassOrNil:classForDecoder];
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
}

- (NSDictionary *) decodeDictionaryForKey:(NSString *) key {
    return [self decodeDictionaryForKey:key withClass:nil];
}

- (NSDictionary *) decodeDictionaryForKey:(NSString *) key withClass:(Class) classForDecoder {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:bson_object result:&result]) return result;
    
    [self exposeKey:key asArray:NO];
    result = [self decodeExposedDictionaryWithClassOrNil:classForDecoder];
    [self closeInternalObject];
    return [self postDecodingHelper:result key:key];
}

- (NSArray *) decodeArrayForKey:(NSString *) key {
    return [self decodeArrayForKey:key withClass:nil];
}

- (NSArray *) decodeArrayForKey:(NSString *) key withClass:(Class) classForDecoder {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:bson_array result:&result]) return result;

    [self exposeKey:key asArray:YES];
    result = [self decodeExposedArrayWithClassOrNil:classForDecoder];
    [self closeInternalObject];
    return [self postDecodingHelper:result key:key];
}

#pragma mark - Decoding exposed internal objects

- (id) decodeExposedCustomObjectWithClassOrNil:(Class) classForDecoder {
    if (classForDecoder)
        return [[classForDecoder alloc] initWithCoder:self];
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
    
    return result;
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
    if ([self decodingHelperForKey:key nativeValueType:bson_oid result:&result]) return result;
    return [self postDecodingHelper:[_iterator objectIDValue] key:key];
}

- (int) decodeIntForKey:(NSString *) key {
    bson_type allowedTypes[4];
    allowedTypes[0] = bson_bool;
    allowedTypes[1] = bson_int;
    allowedTypes[2] = bson_long;
    allowedTypes[2] = bson_double;
    
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueTypeArray:allowedTypes result:&result]) return 0;

    return [_iterator intValue];
}
- (int64_t) decodeInt64ForKey:(NSString *) key {
    bson_type allowedTypes[4];
    allowedTypes[0] = bson_bool;
    allowedTypes[1] = bson_int;
    allowedTypes[2] = bson_long;
    allowedTypes[2] = bson_double;
    
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueTypeArray:allowedTypes result:&result]) return 0;

    return [_iterator int64Value];
}
- (BOOL) decodeBoolForKey:(NSString *) key {
    bson_type allowedTypes[3];
    allowedTypes[0] = bson_bool;
    allowedTypes[1] = bson_int;
    allowedTypes[2] = bson_long;
    
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueTypeArray:allowedTypes result:&result]) return 0;

    return [_iterator doubleValue];
}
- (double) decodeDoubleForKey:(NSString *) key {
    bson_type allowedTypes[3];
    allowedTypes[0] = bson_double;
    allowedTypes[1] = bson_int;
    allowedTypes[2] = bson_long;
    
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueTypeArray:allowedTypes result:&result]) return 0;

    return [_iterator doubleValue];
}

- (NSDate *) decodeDateForKey:(NSString *)key {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:bson_date result:&result]) return result;
    return [self postDecodingHelper:[_iterator dateValue] key:key];
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
    allowedTypes[0] = bson_string;
    allowedTypes[1] = bson_code;
    allowedTypes[2] = bson_symbol;
    
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueTypeArray:allowedTypes result:&result]) return result;
    
    return [self postDecodingHelper:[_iterator stringValue] key:key];
}

- (BSONSymbol *) decodeSymbolForKey:(NSString *) key {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:bson_symbol result:&result]) return result;
    return [self postDecodingHelper:[_iterator symbolValue] key:key];
}

- (BSONRegularExpression *) decodeRegularExpressionForKey:(NSString *) key {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:bson_regex result:&result]) return result;
    return [self postDecodingHelper:[_iterator regularExpressionValue] key:key];
}

- (BSONDocument *) decodeBSONDocumentForKey:(NSString *) key {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:bson_object result:&result]) return result;
    return [self postDecodingHelper:[_iterator embeddedDocumentValue] key:key];
}

- (NSData *)decodeDataForKey:(NSString *) key {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:bson_bindata result:&result]) return result;
    return [self postDecodingHelper:[_iterator dataValue] key:key];
}

- (BSONCode *) decodeCodeForKey:(NSString *) key {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:bson_code result:&result]) return result;
    return [self postDecodingHelper:[_iterator codeValue] key:key];
}
- (BSONCodeWithScope *) decodeCodeWithScopeForKey:(NSString *) key {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:bson_codewscope result:&result]) return result;
    return [self postDecodingHelper:[_iterator codeWithScopeValue] key:key];
}

#pragma mark - Helper methods for -decode... methods

- (BOOL) decodingHelper:(id*) result {
    if (bson_null == [_iterator nativeValueType]) {
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
    } else if (bson_undefined == [_iterator nativeValueType]) {
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

- (id) postDecodingHelper:(id) object key:(NSString *) key {
    if ([self.delegate respondsToSelector:@selector(decoder:didDecodeObject:forKeyPath:)])
        return [self.delegate decoder:self didDecodeObject:object forKeyPath:[self keyPathComponentsAddingKeyOrNil:key]];
    
    return object;
}


#pragma mark - Other helper methods

- (BOOL) allowsKeyedCoding { return YES; }

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
    return [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                   reason:reason
                                 userInfo:nil];
}

- (void) decodeValueOfObjCType:(const char *) type at:(void *) data {
    id exc = [BSONDecoder unsupportedUnkeyedCodingSelector:_cmd];
    @throw exc;
}
- (NSData *) decodeDataObject {
    id exc = [BSONDecoder unsupportedUnkeyedCodingSelector:_cmd];
    @throw exc;
}

@end