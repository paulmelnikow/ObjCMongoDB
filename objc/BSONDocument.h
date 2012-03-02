//
//  BSONDocument.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "bson.h"

@class BSONArchiver;

@interface BSONDocument : NSObject {
    id _source;
@public
    bson bsonValue;
}

-(BSONDocument *)init;
-(BSONDocument *)initWithData:(NSData *)data;
//- (void) dump;
- (NSData *) dataValue;

@end
