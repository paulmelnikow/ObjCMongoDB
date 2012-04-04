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
#if __has_feature(objc_arc)
    return [[BSONDocument alloc] initWithNativeDocument:mongo_cursor_bson(_cursor) destroyOnDealloc:NO];
#else
    return [[[BSONDocument alloc] initWithNativeDocument:mongo_cursor_bson(_cursor) destroyOnDealloc:NO] autorelease];
#endif
}

- (BSONDocument *) nextObject {
    if (MONGO_OK != mongo_cursor_next(_cursor)) return nil;
    bson *newBson = malloc(sizeof(bson));
    bson_copy(newBson, mongo_cursor_bson(_cursor));
#if __has_feature(objc_arc)
    return [[BSONDocument alloc] initWithNativeDocument:newBson destroyOnDealloc:YES];
#else
    return [[[BSONDocument alloc] initWithNativeDocument:newBson destroyOnDealloc:YES] autorelease];
#endif
}

- (NSArray *) allObjects {
    NSMutableArray *result = [NSMutableArray array];
    BSONDocument *document;
    while (document = [self nextObject]) [result addObject:document];
    return result;
}

@end
