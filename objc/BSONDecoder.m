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
- (NSDictionary *) decodeInternalDictionaryWithClassOrNil:(Class) classForDecoder;
- (NSArray *) decodeInternalArrayWithClassOrNil:(Class) classForDecoder;
- (id) decodeInternalObjectWithClassOrNil:(Class) classForDecoder;
+ (NSException *) unsupportedUnkeyedCodingSelector:(SEL)selector;
- (BOOL) decodingHelper:(id*) result;
- (BOOL) decodingHelperForKey:(NSString *) key result:(id*) result;
- (BOOL) decodingHelperForKey:(NSString *) key nativeValueType:(bson_type) nativeValueType result:(id*) result;
- (BOOL) decodingHelperForKey:(NSString *) key nativeValueTypeArray:(bson_type*) nativeValueTypeArray result:(id*) result;
@end

@implementation BSONDecoder

@synthesize behaviorOnNull, behaviorOnUndefined;

#pragma mark - Initialization

- (BSONDecoder *) initWithDocument:(BSONDocument *)document {
    self = [super init];
    if (self) {
        _iterator = [document iterator];
#if __has_feature(objc_arc)
        _stack = [NSMutableArray array];
#else
        _stack = [[NSMutableArray array] retain];
#endif
    }
    return self;
}

- (BSONDecoder *) initWithData:(NSData *)data {
    return [self initWithDocument:[[BSONDocument alloc] initWithData:data]];
}

- (void) dealloc {
#if !__has_feature(objc_arc)
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

- (NSDictionary *) decodeDictionaryWithClass:(Class) classForDecoder {
    return [self decodeInternalDictionaryWithClassOrNil:classForDecoder];
}

- (NSDictionary *) decodeDictionary {
    return [self decodeDictionaryWithClass:nil];
}

- (id) decodeObjectWithClass:(Class) classForDecoder {
    return [self decodeInternalObjectWithClassOrNil:classForDecoder];
}

#pragma mark - Exposing internal objects

- (void) exposeObjectAsArray:(BOOL) asArray { 
    [_stack addObject:_iterator];
    if (asArray)
        _iterator = [_iterator sequentialSubIteratorValue];
    else
        _iterator = [_iterator embeddedDocumentIteratorValue];
}

- (void) closeInternalObject {
    if (![_stack count]) {
        id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                         reason:@"-leaveInternalObject called too many times (without matching call to -enterInternalObjectAsArray:)"
                                       userInfo:nil];
        @throw exc;
    }
    _iterator = [_stack lastObject];
    [_stack removeLastObject];
}

- (NSDictionary *) decodeDictionaryForKey:(NSString *) key {
    return [self decodeDictionaryForKey:key withClass:nil];
}

- (NSDictionary *) decodeDictionaryForKey:(NSString *) key withClass:(Class) classForDecoder {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:bson_object result:&result]) return result;
    
    [self exposeObjectAsArray:NO];
    result = [self decodeInternalDictionaryWithClassOrNil:classForDecoder];
    [self closeInternalObject];
    return result;
}

- (NSArray *) decodeArrayForKey:(NSString *) key {
    return [self decodeArrayForKey:key withClass:nil];
}

- (NSArray *) decodeArrayForKey:(NSString *) key withClass:(Class) classForDecoder {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:bson_array result:&result]) return result;

    [self exposeObjectAsArray:YES];
    result = [self decodeInternalArrayWithClassOrNil:classForDecoder];
    [self closeInternalObject];
    return result;
}

#pragma mark - Decoding exposed internal objects

- (NSDictionary *) decodeInternalDictionaryWithClassOrNil:(Class) classForDecoder {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    while ([_iterator next])
        [dictionary setObject:[self decodeInternalObjectWithClassOrNil:classForDecoder]
                       forKey:[_iterator key]];
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

- (NSArray *) decodeInternalArrayWithClassOrNil:(Class) classForDecoder {
    NSMutableArray *array = [NSMutableArray array];
    while ([_iterator next])
        [array addObject:[self decodeInternalObjectWithClassOrNil:classForDecoder]];
    return [NSArray arrayWithArray:array];
}

- (id) decodeInternalObjectWithClassOrNil:(Class) classForDecoder {
    id result = nil;
    if ([self decodingHelper:&result]) return result;
    
    if ([_iterator isArray]) {
        [self exposeObjectAsArray:YES];
        result = [self decodeInternalArrayWithClassOrNil:nil];
        [self closeInternalObject];
        
    } else if ([_iterator isEmbeddedDocument]) {
        [self exposeObjectAsArray:NO];
        if (classForDecoder) {
            result = [[classForDecoder alloc] initWithCoder:self];
        } else {
            result = [self decodeInternalDictionaryWithClassOrNil:nil];
        }
        [self closeInternalObject];
        
    } else {
        result = [_iterator objectValue];
    }
    
    return result;
}

#pragma mark - Decoding supported types

- (id) decodeObjectForKey:(NSString *) key withClass:(Class) classForDecoder {
    id result = nil;
    if ([self decodingHelperForKey:key result:&result]) return result;
    return [self decodeInternalObjectWithClassOrNil:classForDecoder];    
}

- (id) decodeObjectForKey:(NSString *) key {
    return [self decodeObjectForKey:key withClass:nil];
}

- (BSONObjectID *) decodeObjectIDForKey:(NSString *) key {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:bson_oid result:&result]) return result;
    return [_iterator objectIDValue];
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
    return [_iterator dateValue];
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
    
    return [_iterator stringValue];
}

- (BSONSymbol *) decodeSymbolForKey:(NSString *) key {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:bson_symbol result:&result]) return result;
    return [_iterator symbolValue];
}

- (BSONRegularExpression *) decodeRegularExpressionForKey:(NSString *) key {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:bson_regex result:&result]) return result;
    return [_iterator regularExpressionValue];
}

- (BSONDocument *) decodeBSONDocumentForKey:(NSString *) key {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:bson_object result:&result]) return result;
    return [_iterator embeddedDocumentValue];
}

- (NSData *)decodeDataForKey:(NSString *) key {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:bson_bindata result:&result]) return result;
    return [_iterator dataValue];
    
}

- (id) decodeCodeForKey:(NSString *) key {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:bson_code result:&result]) return result;
    return [_iterator codeValue];
}
- (id) decodeCodeWithScopeForKey:(NSString *) key {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:bson_codewscope result:&result]) return result;
    return [_iterator codeWithScopeValue];
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

#pragma mark - Other helper methods

- (BOOL) allowsKeyedCoding { return YES; }

+ (id) objectForUndefined {
    return [BSONIterator objectForUndefined];
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