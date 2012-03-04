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
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    while ([_iterator next]) {
        NSString *key = [_iterator key];
        id obj;
        if ([_iterator isArray]) {
            BSONIterator *pushedIterator = _iterator;
            _iterator = [pushedIterator subIteratorValue];
            obj = [self decodeArray];
            _iterator = pushedIterator;
        } else if ([_iterator isSubDocument]) {
            BSONIterator *pushedIterator = _iterator;
            _iterator = [pushedIterator subIteratorValue];
            obj = [self decodeDictionary];
            _iterator = pushedIterator;
        } else
            obj = [_iterator objectValue];
        [dictionary setObject:obj forKey:key];
    }
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

- (NSArray *) decodeArray {
    NSMutableArray *array = [NSMutableArray array];
    while ([_iterator next]) {
        id obj;
        if ([_iterator isArray]) {
            BSONIterator *pushedIterator = _iterator;
            _iterator = [pushedIterator subIteratorValue];
            obj = [self decodeArray];
            _iterator = pushedIterator;
        } else if ([_iterator isSubDocument]) {
            BSONIterator *pushedIterator = _iterator;
            _iterator = [pushedIterator subIteratorValue];
            obj = [self decodeDictionary];
            _iterator = pushedIterator;
        } else
            obj = [_iterator objectValue];
        [array addObject:obj];
    }
    return [NSArray arrayWithArray:array];
}

- (NSDictionary *)decodeDictionaryForKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_type type = [_iterator findKey:key];
    switch (type) {
        case bson_eoo: return nil;
        case bson_object: break;
        default: @throw [BSONUnarchiver failedWithIteratorType:type selector:_cmd];
    }
    BSONIterator *pushedIterator = _iterator;
    _iterator = [pushedIterator subIteratorValue];
    NSDictionary *result = [self decodeDictionary];
    _iterator = pushedIterator;
    return result;
}

- (NSArray *)decodeArrayForKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_type type = [_iterator findKey:key];
    switch (type) {
        case bson_eoo: return nil;
        case bson_array: break;
        default: @throw [BSONUnarchiver failedWithIteratorType:type selector:_cmd];
    }
    BSONIterator *pushedIterator = _iterator;
    _iterator = [pushedIterator subIteratorValue];
    NSArray *result = [self decodeArray];
    _iterator = pushedIterator;
    return result;
}

- (id) decodeObjectForKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    [_iterator findKey:key];
    return [_iterator objectValue];
}

#pragma mark - Decoding basic types

- (BSONObjectID *) decodeObjectIDForKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_type type = [_iterator findKey:key];
    switch (type) {
        case bson_eoo: return nil;
        case bson_oid: return [_iterator objectIDValue];
        default: @throw [BSONUnarchiver failedWithIteratorType:type selector:_cmd];
    }
}

- (int) decodeIntForKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_type type = [_iterator findKey:key];
    switch (type) {
        case bson_eoo: return 0;
        case bson_bool:
        case bson_int:
        case bson_long:
        case bson_double: return [_iterator intValue];
        default: @throw [BSONUnarchiver failedWithIteratorType:type selector:_cmd];
    }
}
- (int64_t) decodeInt64ForKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_type type = [_iterator findKey:key];
    switch (type) {
        case bson_eoo: return 0;
        case bson_bool:
        case bson_int:
        case bson_long:
        case bson_double: return [_iterator int64Value];
        default: @throw [BSONUnarchiver failedWithIteratorType:type selector:_cmd];
    }
}
- (BOOL) decodeBoolForKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_type type = [_iterator findKey:key];
    switch (type) {
        case bson_eoo: return 0;
        case bson_bool:
        case bson_int:
        case bson_long:
        case bson_double: return [_iterator boolValue];
        default: @throw [BSONUnarchiver failedWithIteratorType:type selector:_cmd];
    }
}
- (double) decodeDoubleForKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_type type = [_iterator findKey:key];
    switch (type) {
        case bson_eoo: return 0;
        case bson_bool:
        case bson_int:
        case bson_long:
        case bson_double: return [_iterator doubleValue];
        default: @throw [BSONUnarchiver failedWithIteratorType:type selector:_cmd];
    }
}

- (NSDate *) decodeDateForKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_type type = [_iterator findKey:key];
    switch (type) {
        case bson_eoo: return 0;
        case bson_date: return [_iterator dateValue];
        default: @throw [BSONUnarchiver failedWithIteratorType:type selector:_cmd];
    }
}
- (NSImage *) decodeImageForKey:(NSString *)key {
    NSData *data = [self decodeDataForKey:key];
    if (data)
        return [[NSImage alloc] initWithData:data];
    else
        return nil;
}

- (NSString *) decodeStringForKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_type type = [_iterator findKey:key];
    switch (type) {
        case bson_eoo: return 0;
        case bson_string:
        case bson_code:
        case bson_symbol: return [_iterator stringValue];
        default: @throw [BSONUnarchiver failedWithIteratorType:type selector:_cmd];
    }    
}

- (id) decodeSymbolForKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_type type = [_iterator findKey:key];
    switch (type) {
        case bson_eoo: return 0;
        case bson_symbol: return [_iterator stringValue];
        default: @throw [BSONUnarchiver failedWithIteratorType:type selector:_cmd];
    }
}

- (id) decodeRegularExpressionForKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_type type = [_iterator findKey:key];
    switch (type) {
        case bson_eoo: return 0;
        case bson_regex: return [_iterator regularExpressionValue];
        default: @throw [BSONUnarchiver failedWithIteratorType:type selector:_cmd];
    }
}

- (BSONDocument *) decodeBSONDocumentForKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_type type = [_iterator findKey:key];
    switch (type) {
        case bson_eoo: return 0;
        case bson_object: return [_iterator subDocumentValue];
        default: @throw [BSONUnarchiver failedWithIteratorType:type selector:_cmd];
    }
}

- (NSData *)decodeDataForKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_type type = [_iterator findKey:key];
    switch (type) {
        case bson_eoo: return 0;
        case bson_bindata: return [_iterator dataValue];
        default: @throw [BSONUnarchiver failedWithIteratorType:type selector:_cmd];
    }
}

- (id) decodeCodeForKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_type type = [_iterator findKey:key];
    switch (type) {
        case bson_eoo: return 0;
        case bson_code: return [_iterator codeValue];
        default: @throw [BSONUnarchiver failedWithIteratorType:type selector:_cmd];
    }
}
- (id) decodeCodeWithScopeForKey:(NSString *)key {
    [BSONArchiver assertNonNil:key withReason:KeyMustNotBeNil];
    bson_type type = [_iterator findKey:key];
    switch (type) {
        case bson_eoo: return 0;
        case bson_codewscope: return [_iterator codeWithScopeValue];
        default: @throw [BSONUnarchiver failedWithIteratorType:type selector:_cmd];
    }
}

#pragma mark - Unsupported unkeyed encoding methods

- (void) decodeValueOfObjCType:(const char *)type at:(void *)data {
    @throw [BSONUnarchiver unsupportedUnkeyedCodingSelector:_cmd];
}
-(NSData *)decodeDataObject {
    @throw [BSONUnarchiver unsupportedUnkeyedCodingSelector:_cmd];
}

#pragma mark - Helper methods

+ (NSException *) unsupportedUnkeyedCodingSelector:(SEL)selector {
    NSString *reason = [NSString stringWithFormat:@"%@ called, but unkeyed decoding methods are not supported. Subclass if unkeyed coding is needed.",
                        NSStringFromSelector(selector)];
    return [NSException exceptionWithName:NSInvalidArchiveOperationException
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