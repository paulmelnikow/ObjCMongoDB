//
//  BSONObjectID.m
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BSONObjectID.h"

@interface BSONObjectID (Private)

- (const bson_oid_t *) objectIDPointer;

@end

@implementation BSONObjectID

- (id) initWithString:(NSString *) s {
    if (self = [super init]) {
        bson_oid_from_string(&oid, [s cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    return self;
}

- (id) initWithObjectIDPointer:(const bson_oid_t *) objectIDPointer {
    if (self = [super init]) {
        oid = *objectIDPointer;
    }
    return self;
}

+ (BSONObjectID *) objectID {
    bson_oid_t oid;
    bson_oid_gen(&oid);
    return [[[self alloc] initWithObjectIDPointer:&oid] autorelease];
}

+ (BSONObjectID *) objectIDWithData:(NSData *) data {
    return [[[self alloc] initWithData:data] autorelease];
}

+ (BSONObjectID *) objectIDWithObjectIDPointer:(const bson_oid_t *) objectIDPointer {
    return [[[self alloc] initWithObjectIDPointer:objectIDPointer] autorelease];
}

- (const bson_oid_t *) objectIDPointer { return &oid; }

- (bson_oid_t) oid { return oid; }

- (id) initWithData:(NSData *) data {
    if ((self = [super init])) {
        if ([data length] == 12) {
            memcpy(oid.bytes, [data bytes], 12);
        }
    }
    return self;
}

- (id) copyWithZone:(NSZone *) zone {
	return [[BSONObjectID allocWithZone:zone] initWithObjectIDPointer:&oid];
}

- (NSUInteger) hash {
	return oid.ints[0] + oid.ints[1] + oid.ints[2];
}

- (NSData *) dataRepresentation {
    return [[[NSData alloc] initWithBytes:oid.bytes length:12] autorelease];
}

- (NSString *) description {
    char buffer[25];                              /* str must be at least 24 hex chars + null byte */
    bson_oid_to_string(&oid, buffer);
    return [NSString stringWithFormat:@"(oid \"%s\")", buffer];
}

- (NSString *) stringValue {
    char buffer[25];                              /* str must be at least 24 hex chars + null byte */
    bson_oid_to_string(&oid, buffer);
    return [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
}

- (NSComparisonResult)compare:(BSONObjectID *) other {
    for (int i = 0; i < 3; i++) {
        int diff = oid.ints[i] - other->oid.ints[i];
        if (diff < 0)
            return NSOrderedAscending;
        else if (diff > 0)
            return NSOrderedDescending;
    }
    return NSOrderedSame;
}

- (BOOL)isEqual:(id)other {
    return ([self compare:other] == 0);
}

@end