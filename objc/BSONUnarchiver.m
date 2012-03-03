//
//  BSONUnarchiver.m
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BSONUnarchiver.h"

@interface BSONUnarchiver (Private)
+ (NSException *) failedWithIteratorType:(bson_type)bsonType selector:(SEL)selector;
@end

@implementation BSONUnarchiver

@synthesize objectForNull;
@synthesize objectForUndefined;

#pragma mark - Initialization

- (BSONUnarchiver *) initWithDocument:(BSONDocument *)document {
    self = [super init];
    if (self) {
        _iterator = [BSONIterator iteratorWithDocument:document];
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

#pragma mark - Helper methods

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