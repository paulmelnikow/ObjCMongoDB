//
//  MongoCursor.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "mongo.h"
#import "BSONDocument.h"

@interface MongoCursor : NSEnumerator {
@private
    mongo_cursor *_cursor;
}

- (id) initWithNativeCursor:(mongo_cursor *) cursor;

- (BSONDocument *) nextObject;
- (BSONDocument *) nextObjectNoCopy;
- (NSArray *) allObjects;

@end
