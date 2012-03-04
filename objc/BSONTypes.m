//
//  BSONObjectID.m
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

#import "BSONObjectID.h"

@implementation BSONObjectID

#pragma mark - Initialization

- (id) init {
    if (self = [super init]) {
        bson_oid_gen(&_oid);
    }
    return self;
}

- (id) initWithString:(NSString *) s {
    if (self = [super init]) {
        bson_oid_from_string(&_oid, [s cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    return self;
}

- (id) initWithData:(NSData *) data {
    if ((self = [super init])) {
        if ([data length] != 12) {
#if !__has_feature(objc_arc)
            [self release];
#endif
            return nil;
        }
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
#if __has_feature(objc_arc)
    return [[self alloc] init];
#else
    return [[[self alloc] init] autorelease];
#endif
}

+ (BSONObjectID *) objectIDWithString:(NSString *) s {
#if __has_feature(objc_arc)
    return [[self alloc] initWithString:s];
#else
    return [[[self alloc] initWithString:s] autorelease];
#endif
}

+ (BSONObjectID *) objectIDWithData:(NSData *) data {
#if __has_feature(objc_arc)
    return [[self alloc] initWithData:data];
#else
    return [[[self alloc] initWithData:data] autorelease];
#endif
}

+ (BSONObjectID *) objectIDWithNativeOID:(const bson_oid_t *) objectIDPointer {
#if __has_feature(objc_arc)
    return [[self alloc] initWithNativeOID:objectIDPointer];
#else
    return [[[self alloc] initWithNativeOID:objectIDPointer] autorelease];
#endif
}

- (id) copyWithZone:(NSZone *) zone {
	return [[BSONObjectID allocWithZone:zone] initWithNativeOID:&_oid];
}

- (const bson_oid_t *) objectIDPointer { return &_oid; }

- (bson_oid_t) oid { return _oid; }


- (NSData *) dataValue {
#if __has_feature(objc_arc)
    return [[NSData alloc] initWithBytes:_oid.bytes length:12];
#else
    return [[[NSData alloc] initWithBytes:_oid.bytes length:12] autorelease];
#endif
}

- (NSUInteger) hash {
	return _oid.ints[0] + _oid.ints[1] + _oid.ints[2];
}

- (NSString *) description {
    return [NSString stringWithFormat:@"bson:ObjectID(\"%@\")", [self stringValue]];
}

- (NSString *) stringValue {
    if (_stringValue) return _stringValue;
    // str must be at least 24 hex chars + null byte
    char buffer[25];
    bson_oid_to_string(&_oid, buffer);
    return _stringValue = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
}

- (NSComparisonResult)compare:(BSONObjectID *) other {
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
    return [self compare:other] == NSOrderedSame;
}

@end