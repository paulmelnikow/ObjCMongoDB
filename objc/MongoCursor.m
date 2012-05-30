//
//  MongoCursor.m
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
