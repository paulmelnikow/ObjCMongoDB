//
//  BSONUnarchiver.m
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

#import "BSONUnarchiver.h"
#import "bson.h"

@interface BSONUnarchiver (Private)
- (NSDictionary *) decodeInternalDictionaryWithClassOrNil:(Class) classForUnarchiver;
- (NSArray *) decodeInternalArrayWithClassOrNil:(Class) classForUnarchiver;;
- (id) decodeInternalObject;
+ (NSException *) unsupportedUnkeyedCodingSelector:(SEL)selector;
- (BOOL) decodingHelperForKey:(NSString *) key result:(id*) result;
- (BOOL) decodingHelperForKey:(NSString *) key nativeValueType:(bson_type) nativeValueType result:(id*) result;
@end

@implementation BSONUnarchiver

@synthesize objectForNull;
@synthesize objectForUndefined;

#pragma mark - Initialization

- (BSONUnarchiver *) initWithDocument:(BSONDocument *)document {
    self = [super init];
    if (self) {
        _iterator = [document iterator];
#if __has_feature(objc_arc)
        _stack = [NSMutableArray array];
#else
        _stack = [[NSMutableArray array] retain];
#endif
        self.objectForNull = nil;
        self.objectForUndefined = [BSONIterator objectForUndefined];
    }
    return self;
}

- (BSONUnarchiver *) initWithData:(NSData *)data {
    return [self initWithDocument:[[BSONDocument alloc] initWithData:data]];
}

+ (NSDictionary *) unarchiveDictionaryWithDocument:(BSONDocument *)document {
    BSONUnarchiver *unarchiver = [[self alloc] initWithDocument:document];
    NSDictionary *result = [unarchiver decodeDictionary];
#if !__has_feature(objc_arc)
    [unarchiver release];
#endif
    return result;
}

+ (NSDictionary *) unarchiveDictionaryWithData:(NSData *)data {
    BSONUnarchiver *unarchiver = [[self alloc] initWithData:data];
    NSDictionary *result = [unarchiver decodeDictionary];
#if !__has_feature(objc_arc)
    [unarchiver release];
#endif
    return result;
}

- (void) dealloc {
#if !__has_feature(objc_arc)
    [_iterator release];
#endif    
}

#pragma mark - NSCoder interface

- (BOOL) allowsKeyedCoding { return YES; }

#pragma mark - Decoding collections

- (NSDictionary *) decodeDictionaryWithClass:(Class) classForUnarchiver {
    return [self decodeInternalDictionaryWithClassOrNil:classForUnarchiver];
}

- (NSDictionary *) decodeDictionary {
    return [self decodeInternalDictionaryWithClassOrNil:nil];
}

#pragma mark - Internal methods for decoding objects and collections

- (void) enterInternalObjectAsArray:(BOOL) asArray { 
    [_stack addObject:_iterator];
    if (asArray)
        _iterator = [_iterator sequentialSubIteratorValue];
    else
        _iterator = [_iterator embeddedDocumentIteratorValue];
}

// FIXME add raise exception if no items left
- (void) leaveInternalObject {
    _iterator = [_stack lastObject];
    [_stack removeLastObject];
}

- (NSDictionary *) decodeInternalDictionaryWithClassOrNil:(Class) classForUnarchiver {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    while ([_iterator next]) {
        NSString *key = [_iterator key];
        id obj;
        if ([_iterator isArray]) {
            [self enterInternalObjectAsArray:YES];
            obj = [self decodeInternalArrayWithClassOrNil:nil];
            [self leaveInternalObject];
        } else if ([_iterator isEmbeddedDocument]) {
            [self enterInternalObjectAsArray:NO];
            if (classForUnarchiver) {
                obj = [[classForUnarchiver alloc] initWithCoder:self];
            } else {
                obj = [self decodeInternalDictionaryWithClassOrNil:nil];
            }
            [self leaveInternalObject];
        } else {
            obj = [self decodeInternalObject];
        }
        [dictionary setObject:obj forKey:key];
    }
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

- (NSArray *) decodeInternalArrayWithClassOrNil:(Class) classForUnarchiver {
    NSMutableArray *array = [NSMutableArray array];
    while ([_iterator next]) {
        id obj;
        if ([_iterator isArray]) {
            [self enterInternalObjectAsArray:YES];
            obj = [self decodeInternalArrayWithClassOrNil:nil];
            [self leaveInternalObject];
        } else if ([_iterator isEmbeddedDocument]) {
            [self enterInternalObjectAsArray:NO];
            if (classForUnarchiver) {
                obj = [[classForUnarchiver alloc] initWithCoder:self];
            } else {
                obj = [self decodeInternalDictionaryWithClassOrNil:nil];
            }
            [self leaveInternalObject];
        } else {
            obj = [self decodeInternalObject];
        }
        [array addObject:obj];
    }
    return [NSArray arrayWithArray:array];
}

- (id) decodeInternalObject {
    id obj = [_iterator objectValue];
    if ([NSNull null] == obj)
        return self.objectForNull;
    else if ([BSONIterator objectForUndefined] == obj)
        return self.objectForUndefined;
    else
        return obj;
}

- (NSDictionary *)decodeDictionaryForKey:(NSString *)key {
    return [self decodeDictionaryForKey:key withClass:nil];
}

- (NSDictionary *) decodeDictionaryForKey:(NSString *) key withClass:(Class)classForUnarchiver {
    if (![_iterator containsValueForKey:key]) return nil;
    BSONAssertIteratorIsValueType(_iterator, bson_object);
    [self enterInternalObjectAsArray:NO];
    NSDictionary *result = [self decodeInternalDictionaryWithClassOrNil:classForUnarchiver];
    [self leaveInternalObject];
    return result;
}

- (NSArray *)decodeArrayForKey:(NSString *)key {
    return [self decodeArrayForKey:key withClass:nil];
}

- (NSArray *) decodeArrayForKey:(NSString *) key withClass:(Class)classForUnarchiver {
    id result = nil;
    if ([self decodingHelperForKey:key nativeValueType:bson_array result:&result]) return result;

    [self enterInternalObjectAsArray:YES];
    result = [self decodeInternalArrayWithClassOrNil:classForUnarchiver];
    [self leaveInternalObject];
    return result;
}

#pragma mark - Decoding basic types

- (id) decodeObjectForKey:(NSString *)key {
    if (![_iterator containsValueForKey:key]) return nil;
    return [self decodeInternalObject];
}

- (BSONObjectID *) decodeObjectIDForKey:(NSString *)key {
    if (![_iterator containsValueForKey:key]) return nil;
    BSONAssertIteratorIsValueType(_iterator, bson_oid);
    return [_iterator objectIDValue];
}

- (int) decodeIntForKey:(NSString *)key {
    if (![_iterator containsValueForKey:key]) return 0;
    
    bson_type allowedTypes[4];
    allowedTypes[0] = bson_bool;
    allowedTypes[1] = bson_int;
    allowedTypes[2] = bson_long;
    allowedTypes[2] = bson_double;

    BSONAssertIteratorIsInValueTypeArray(_iterator, allowedTypes);
    return [_iterator intValue];
}
- (int64_t) decodeInt64ForKey:(NSString *)key {
    if (![_iterator containsValueForKey:key]) return 0;
    
    bson_type allowedTypes[4];
    allowedTypes[0] = bson_bool;
    allowedTypes[1] = bson_int;
    allowedTypes[2] = bson_long;
    allowedTypes[2] = bson_double;
    
    BSONAssertIteratorIsInValueTypeArray(_iterator, allowedTypes);
    return [_iterator int64Value];
}
- (BOOL) decodeBoolForKey:(NSString *)key {
    if (![_iterator containsValueForKey:key]) return 0;
    
    bson_type allowedTypes[3];
    allowedTypes[0] = bson_bool;
    allowedTypes[1] = bson_int;
    allowedTypes[2] = bson_long;
    
    BSONAssertIteratorIsInValueTypeArray(_iterator, allowedTypes);
    return [_iterator doubleValue];
}
- (double) decodeDoubleForKey:(NSString *)key {
    if (![_iterator containsValueForKey:key]) return 0;
    
    bson_type allowedTypes[3];
    allowedTypes[0] = bson_double;
    allowedTypes[1] = bson_int;
    allowedTypes[2] = bson_long;
    
    BSONAssertIteratorIsInValueTypeArray(_iterator, allowedTypes);
    return [_iterator doubleValue];
}

- (NSDate *) decodeDateForKey:(NSString *)key {
    if (![_iterator containsValueForKey:key]) return nil;
    BSONAssertIteratorIsValueType(_iterator, bson_date);
    return [_iterator dateValue];
}
- (NSImage *) decodeImageForKey:(NSString *)key {
    NSData *data = [self decodeDataForKey:key];
    if (data)
        return [[NSImage alloc] initWithData:data];
    else
        return nil;
}

- (NSString *) decodeStringForKey:(NSString *)key {
    if (![_iterator containsValueForKey:key]) return nil;
    
    bson_type allowedTypes[3];
    allowedTypes[0] = bson_string;
    allowedTypes[1] = bson_code;
    allowedTypes[2] = bson_symbol;
    
    BSONAssertIteratorIsInValueTypeArray(_iterator, allowedTypes);
    return [_iterator stringValue];
}

- (BSONSymbol *) decodeSymbolForKey:(NSString *)key {
    if (![_iterator containsValueForKey:key]) return nil;
    BSONAssertIteratorIsValueType(_iterator, bson_symbol);
    return [_iterator symbolValue];
}

- (BSONRegularExpression *) decodeRegularExpressionForKey:(NSString *)key {
    if (![_iterator containsValueForKey:key]) return nil;
    BSONAssertIteratorIsValueType(_iterator, bson_regex);
    return [_iterator regularExpressionValue];
}

- (BSONDocument *) decodeBSONDocumentForKey:(NSString *)key {
    if (![_iterator containsValueForKey:key]) return nil;
    BSONAssertIteratorIsValueType(_iterator, bson_object);
    return [_iterator embeddedDocumentValue];
}

- (NSData *)decodeDataForKey:(NSString *)key {
    if (![_iterator containsValueForKey:key]) return nil;
    BSONAssertIteratorIsValueType(_iterator, bson_bindata);
    return [_iterator dataValue];
    
}

- (id) decodeCodeForKey:(NSString *)key {
    if (![_iterator containsValueForKey:key]) return nil;
    BSONAssertIteratorIsValueType(_iterator, bson_code);
    return [_iterator codeValue];
}
- (id) decodeCodeWithScopeForKey:(NSString *)key {
    if (![_iterator containsValueForKey:key]) return nil;
    BSONAssertIteratorIsValueType(_iterator, bson_codewscope);
    return [_iterator codeWithScopeValue];
}

#pragma mark - Unsupported unkeyed encoding methods

- (void) decodeValueOfObjCType:(const char *)type at:(void *)data {
    id exc = [BSONUnarchiver unsupportedUnkeyedCodingSelector:_cmd];
    @throw exc;
}
- (NSData *) decodeDataObject {
    id exc = [BSONUnarchiver unsupportedUnkeyedCodingSelector:_cmd];
    @throw exc;
}

#pragma mark - Helper methods

- (BOOL) decodingHelperForKey:(NSString *) key result:(id*) result {
    BSONAssertKeyNonNil(key);
    if (![_iterator containsValueForKey:key]) {
        result = nil; return YES;
    }
    if (bson_null == [_iterator nativeValueType]) {
        *result = self.objectForNull; return YES;
    }    
    if (bson_undefined == [_iterator nativeValueType]) {
        *result = self.objectForUndefined; return YES;
    }
    return NO;
}

- (BOOL) decodingHelperForKey:(NSString *) key nativeValueType:(bson_type) nativeValueType result:(id*) result {
    if ([self decodingHelperForKey:key result:result]) return YES;
    BSONAssertIteratorIsValueType(_iterator, nativeValueType);
    return NO;
}


+ (NSException *) unsupportedUnkeyedCodingSelector:(SEL)selector {
    NSString *reason = [NSString stringWithFormat:@"%@ called, but unkeyed decoding methods are not supported. Subclass if unkeyed coding is needed.",
                        NSStringFromSelector(selector)];
    return [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                   reason:reason
                                 userInfo:nil];
}

@end