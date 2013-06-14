//
//  BSONTypes.m
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

#import "BSONTypes.h"
#import "BSON_Helper.h"
#import "bson.h"
#import "BSON_PrivateInterfaces.h"

#define bson_type_case(type) case type: name = NSStringize(type); break

__autoreleasing NSString * NSStringFromBSONType (BSONType t) {
    NSString *name = nil;
    switch(t) {
            bson_type_case(BSONTypeEndOfObject);
            bson_type_case(BSONTypeDouble);
            bson_type_case(BSONTypeString);
            bson_type_case(BSONTypeEmbeddedDocument);
            bson_type_case(BSONTypeArray);
            bson_type_case(BSONTypeBinaryData);
            bson_type_case(BSONTypeUndefined);
            bson_type_case(BSONTypeObjectID);
            bson_type_case(BSONTypeBoolean);
            bson_type_case(BSONTypeDate);
            bson_type_case(BSONTypeNull);
            bson_type_case(BSONTypeRegularExpression);
            bson_type_case(BSONTypeDBRef);
            bson_type_case(BSONTypeCode);
            bson_type_case(BSONTypeSymbol);
            bson_type_case(BSONTypeCodeWithScope);
            bson_type_case(BSONTypeInteger);
            bson_type_case(BSONTypeTimestamp);
            bson_type_case(BSONTypeLong);
        default:
            name = [NSString stringWithFormat:@"(%i) ???", t];
    }
    return name;
}

static int (^fuzzGenerator)(void);
static int (^incrementGenerator)(void);
int block_based_fuzz_func(void);
int block_based_fuzz_func(void) { return fuzzGenerator(); }
int block_based_inc_func(void);
int block_based_inc_func(void) { return incrementGenerator(); }

@interface BSONObjectID ()
@property (retain) NSString *privateStringValue;
@end

@implementation BSONObjectID {
    bson_oid_t _oid;
}

#pragma mark - Overriding OID generation

+ (void) generateFuzzUsingBlock:(int (^)(void)) block {
    maybe_release(fuzzGenerator);
    if (block == nil) {
        bson_set_oid_fuzz(NULL);
    } else {
        fuzzGenerator = [block copy];
        bson_set_oid_fuzz(block_based_fuzz_func);
    }
}

+ (void) generateIncrementUsingBlock:(int (^)(void)) block {
    maybe_release(incrementGenerator);
    if (block == nil) {
        bson_set_oid_inc(NULL);
    } else {
        incrementGenerator = [block copy];
        bson_set_oid_inc(block_based_inc_func);
    }
}

#pragma mark - Initialization

- (id) init {
    if (self = [super init]) {
        bson_oid_gen(&_oid);
    }
    return self;
}

- (id) initWithString:(NSString *) s {
    if (s.length != 24) {
        maybe_release(self);
        [NSException raise:NSInvalidArgumentException format:@"String should be 24 characters long"];
    }
    if (self = [super init]) {
        bson_oid_from_string(&_oid, s.bsonString);
    }
    return self;
}

- (id) initWithData:(NSData *) data {
    if ((self = [super init])) {
        if ([data length] != 12) nullify_self_and_return;
        memcpy(_oid.bytes, [data bytes], 12);
    }
    return self;
}

- (id) initWithNativeOID:(const bson_oid_t *) objectIDPointer {
    if (self = [super init]) {
        _oid = *objectIDPointer;
    }
    return self;
}

+ (BSONObjectID *) objectID {
    maybe_autorelease_and_return([[self alloc] init]);
}

+ (BSONObjectID *) objectIDWithString:(NSString *) s {
    if (s.length != 24) return nil;
    maybe_autorelease_and_return([[self alloc] initWithString:s]);
}

+ (BSONObjectID *) objectIDWithData:(NSData *) data {
    maybe_autorelease_and_return([[self alloc] initWithData:data]);
}

+ (BSONObjectID *) objectIDWithNativeOID:(const bson_oid_t *) objectIDPointer {
    maybe_autorelease_and_return([[self alloc] initWithNativeOID:objectIDPointer]);
}

- (id) copyWithZone:(NSZone *) zone {
	return [[BSONObjectID allocWithZone:zone] initWithNativeOID:&_oid];
}

- (const bson_oid_t *) objectIDPointer { return &_oid; }

- (bson_oid_t) oid { return _oid; }

- (NSData *) dataValue {
    return [NSData dataWithBytes:_oid.bytes length:12];
}

- (NSDate *) dateGenerated {
    return [NSDate dateWithTimeIntervalSince1970:bson_oid_generated_time(&_oid)];
}

- (NSUInteger) hash {
	return _oid.ints[0] + _oid.ints[1] + _oid.ints[2];
}

- (NSString *) description {
    return [self stringValue];
}

- (NSString *) stringValue {
    if (self.privateStringValue) return self.privateStringValue;
    // str must be at least 24 hex chars + null byte
    char buffer[25];
    bson_oid_to_string(&_oid, buffer);
    return self.privateStringValue = [NSString stringWithBSONString:buffer];
}

- (NSComparisonResult)compare:(BSONObjectID *) other {
    if (!other) [NSException raise:NSInvalidArgumentException format:@"Nil argument"];
    for (int i = 0; i < 3; i++) {
        int diff = _oid.ints[i] - other->_oid.ints[i];
        if (diff < 0)
            return NSOrderedAscending;
        else if (diff > 0)
            return NSOrderedDescending;
    }
    return NSOrderedSame;
}

- (BOOL)isEqual:(id)other {
    if (![other isKindOfClass:[BSONObjectID class]]) return NO;
    return [self compare:other] == NSOrderedSame;
}

@end

@implementation BSONRegularExpression

- (void) dealloc {
    maybe_release(_pattern);
    maybe_release(_options);
    super_dealloc;
}

+ (BSONRegularExpression *) regularExpressionWithPattern:(NSString *) pattern options:(NSString *) options {
    BSONRegularExpression *obj = [[self alloc] init];
    obj.pattern = pattern;
    obj.options = options;
    maybe_autorelease_and_return(obj);
}

@end

@implementation  BSONTimestamp {
    bson_timestamp_t _timestamp;
}

- (BSONTimestamp *) initWithNativeTimestamp:(bson_timestamp_t) timestamp {
    if (self = [super init]) {
        _timestamp = timestamp;
    }
    return self;
}

+ (BSONTimestamp *) timestampWithNativeTimestamp:(bson_timestamp_t) timestamp {
    maybe_autorelease_and_return([[self alloc] initWithNativeTimestamp:timestamp]);
}

+ (BSONTimestamp *) timestampWithIncrement:(int) increment timeInSeconds:(int) time {
    BSONTimestamp *obj = [[self alloc] init];
    obj.increment = increment;
    obj.timeInSeconds = time;
    maybe_autorelease_and_return(obj);
}

- (bson_timestamp_t *) timestampPointer {
    return &_timestamp;
}

- (int) increment { return _timestamp.i; }
- (void) setIncrement:(int) increment {
    [self willChangeValueForKey:@"increment"];
    _timestamp.i = increment;
    [self didChangeValueForKey:@"increment"];
}
- (int) timeInSeconds { return _timestamp.t; }
- (void) setTimeInSeconds:(int) timeInSeconds {
    [self willChangeValueForKey:@"timeInSeconds"];
    _timestamp.t = timeInSeconds;
    [self didChangeValueForKey:@"timeInSeconds"];
}

@end

@implementation BSONCode

- (void) dealloc {
    maybe_release(_code);
    super_dealloc;
}

+ (BSONCode *) code:(NSString *) code {
    BSONCode *obj = [[self alloc] init];
    obj.code = code;
    maybe_autorelease_and_return(obj);
}

@end

@implementation BSONCodeWithScope

- (void) dealloc {
    maybe_release(_scope);
    super_dealloc;
}

+ (BSONCodeWithScope *) code:(NSString *) code withScope:(BSONDocument *) scope {
    BSONCodeWithScope *obj = [[self alloc] init];
    obj.code = code;
    obj.scope = scope;
    maybe_autorelease_and_return(obj);
}

@end

@implementation BSONSymbol

- (void) dealloc {
    maybe_release(_symbol);
    super_dealloc;
}

+ (BSONSymbol *) symbol:(NSString *)symbol {
    BSONSymbol *obj = [[self alloc] init];
    obj.symbol = symbol;
    maybe_autorelease_and_return(obj);
}

@end