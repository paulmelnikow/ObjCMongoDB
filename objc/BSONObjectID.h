//
//  BSONObjectID.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "bson.h"

@interface BSONObjectID : NSObject {
@public
    bson_oid_t oid;
}

/*! Create a new and unique object ID. */
+ (BSONObjectID *) objectID;
/*! Create an object ID from a 12-byte data representation. */
+ (BSONObjectID *) objectIDWithData:(NSData *) data;
/*! Create an object ID wrapper from a bson_oid_t native structure. */
+ (BSONObjectID *) objectIDWithObjectIDPointer:(const bson_oid_t *) objectIDPointer;
/*! Create an object ID from a hex string. */
- (id) initWithString:(NSString *) s;
/*! Get the hex string value of an object ID. */
- (NSString *) stringValue;
/*! Create an object ID from an NSData representation. */
- (id) initWithData:(NSData *) data;
/*! Get the NSData representation of an object ID. */
- (NSData *) dataRepresentation;
/*! Compare two object ID values. */
- (NSComparisonResult)compare:(BSONObjectID *) other;
/*! Test for equality with another object ID. */
- (BOOL)isEqual:(id)other;
/*! Raw object id */
- (bson_oid_t) oid;
@end