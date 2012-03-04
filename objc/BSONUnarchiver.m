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

@interface BSONUnarchiver (Private)
- (NSArray *) decodeInternalArray;
- (NSDictionary *) decodeInternalDictionary;
- (id) decodeInternalObject;
+ (void) assertIterator:(BSONIterator *) iterator isValueType:(bson_type) type forSelector:(SEL)selector;
+ (NSException *) unsupportedUnkeyedCodingSelector:(SEL)selector;
+ (NSException *) failedWithIteratorType:(bson_type)bsonType selector:(SEL)selector;
@end

@implementation BSONUnarchiver

@synthesize objectForNull;
@synthesize objectForUndefined;

#pragma mark - Initialization

- (BSONUnarchiver *) initWithDocument:(BSONDocument *)document {
    self = [super init];
    if (self) {
        _iterator = [document iterator];
        self.objectForNull = nil;
        self.objectForUndefined = nil;
    }
    return self;
}

+ (BSONUnarchiver *) unarchiverWithDocument:(BSONDocument *)document {
    return [[self alloc] initWithDocument:document];
}

+ (BSONUnarchiver *) unarchiverWithData:(NSData *)data {
    return [[self alloc] initWithDocument:[[BSONDocument alloc] initWithData:data]];
}

- (void) dealloc { }

#pragma mark - NSCoder interface

- (BOOL) allowsKeyedCoding { return YES; }

#pragma mark - Decoding collections

- (NSDictionary *) decodeDictionary {
    return [self decodeInternalDictionary];
}

#pragma mark - Internal methods for decoding objects and collections

- (NSDictionary *) decodeInternalDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    while ([_iterator next]) {
        NSString *key = [_iterator key];
        id obj;
        if ([_iterator isArray]) {
            BSONIterator *pushedIterator = _iterator;
            _iterator = [pushedIterator subIteratorValue];
            obj = [self decodeInternalArray];
            _iterator = pushedIterator;
        } else if ([_iterator isEmbeddedDocument]) {
            BSONIterator *pushedIterator = _iterator;
            _iterator = [pushedIterator subIteratorValue];
            obj = [self decodeDictionary];
            _iterator = pushedIterator;
        } else
            obj = [self decodeInternalObject];
        [dictionary setObject:obj forKey:key];
    }
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

- (NSArray *) decodeInternalArray {
    NSMutableArray *array = [NSMutableArray array];
    while ([_iterator next]) {
        id obj;
        if ([_iterator isArray]) {
            BSONIterator *pushedIterator = _iterator;
            _iterator = [pushedIterator subIteratorValue];
            obj = [self decodeInternalArray];
            _iterator = pushedIterator;
        } else if ([_iterator isEmbeddedDocument]) {
            BSONIterator *pushedIterator = _iterator;
            _iterator = [pushedIterator subIteratorValue];
            obj = [self decodeDictionary];
            _iterator = pushedIterator;
        } else
            obj = [self decodeInternalObject];
        [array addObject:obj];
    }
    return [NSArray arrayWithArray:array];
}

- (id) decodeInternalObject {
    id obj = [_iterator objectValue];
    if ([NSNull null] == obj)
        return self.objectForNull;
    else if ([BSONIterator objectForUndefinedValue] == obj)
        return self.objectForUndefined;
    else
        return obj;
}


- (NSDictionary *)decodeDictionaryForKey:(NSString *)key {
    if (![_iterator containsValueForKey:key]) return nil;
    BSONAssertIteratorIsValueType(_iterator, bson_object);
    
    BSONIterator *pushedIterator = _iterator;
    
    _iterator = [pushedIterator subIteratorValue];
    NSDictionary *result = [self decodeDictionary];
    
    _iterator = pushedIterator;
    return result;
}

- (NSArray *)decodeArrayForKey:(NSString *)key {
    if (![_iterator containsValueForKey:key]) return nil;
    BSONAssertIteratorIsValueType(_iterator, bson_array);

    BSONIterator *pushedIterator = _iterator;
    
    _iterator = [pushedIterator subIteratorValue];
    NSArray *result = [self decodeInternalArray];
    
    _iterator = pushedIterator;
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
    @throw [BSONUnarchiver unsupportedUnkeyedCodingSelector:_cmd];
}
- (NSData *) decodeDataObject {
    @throw [BSONUnarchiver unsupportedUnkeyedCodingSelector:_cmd];
}

#pragma mark - Helper methods

+ (NSException *) unsupportedUnkeyedCodingSelector:(SEL)selector {
    NSString *reason = [NSString stringWithFormat:@"%@ called, but unkeyed decoding methods are not supported. Subclass if unkeyed coding is needed.",
                        NSStringFromSelector(selector)];
    return [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                   reason:reason
                                 userInfo:nil];
}

+ (NSException *) failedWithIteratorType:(bson_type)bsonType selector:(SEL)selector {
    NSString *reason = [NSString stringWithFormat:@"Can't %@ with type %@",
                        NSStringFromSelector(selector),
                        NSStringFromBSONType(bsonType),
                        nil];
    return [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                   reason:reason
                                 userInfo:nil];
}

@end