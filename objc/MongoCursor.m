//
//  MongoCursor.m
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MongoCursor.h"

@implementation MongoCursor

#pragma mark - Initialization

- (id) initWithNativeCursor:(mongo_cursor *) cursor {
    if (self = [super init]) {
        _cursor = cursor;
    }
    return self;
}

- (void) dealloc {
    mongo_cursor_destroy(_cursor);
}

#pragma mark - Enumeration

- (BSONDocument *) nextObjectNoCopy {
    return [[BSONDocument alloc] initWithNativeDocument:mongo_cursor_bson(_cursor) destroyOnDealloc:NO];
}

- (BSONDocument *) nextObject {
    bson *newBson = malloc(sizeof(bson));
    bson_copy_basic(newBson, mongo_cursor_bson(_cursor));
    return [[BSONDocument alloc] initWithNativeDocument:newBson destroyOnDealloc:YES];
}

- (NSArray *) allObjects {
    NSMutableArray *result = [NSMutableArray array];
    BSONDocument *document;
    while (document = [self nextObject]) [result addObject:document];
    return result;
}

@end
