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
#import "Helper-private.h"
#import "Interfaces-private.h"

@implementation MongoCursor {
    mongoc_cursor_t *_cursor;
}

#pragma mark - Initialization

- (id) initWithNativeCursor:(mongoc_cursor_t *) cursor {
    if (self = [super init]) {
        _cursor = cursor;
    }
    return self;
}

+ (MongoCursor *) cursorWithNativeCursor:(mongoc_cursor_t *) cursor {
    return [[self alloc] initWithNativeCursor:cursor];
}

- (void) dealloc {
    mongoc_cursor_destroy(_cursor);
    _cursor = NULL;
}

#pragma mark - Enumeration

- (BSONDocument *) nextObjectNoCopy {
    // TODO check this
    const bson_t *next = NULL;
    if (! mongoc_cursor_next(_cursor, &next)) return nil;
    return [[BSONDocument alloc] initWithNativeValue:(bson_t *)next];
}

- (BSONDocument *) nextObject {
    // TODO check this
    const bson_t *next = NULL;
    if (! mongoc_cursor_next(_cursor, &next)) return nil;
    bson_t *copy = bson_copy(next);
    return [[BSONDocument alloc] initWithNativeValue:(bson_t *)copy];
}

- (NSArray *) allObjects {
    NSMutableArray *result = [NSMutableArray array];
    BSONDocument *document;
    while (document = [self nextObject]) [result addObject:document];
    return result;
}

// TODO
//mongoc_cursor_error
//mongoc_cursor_get_id

@end
