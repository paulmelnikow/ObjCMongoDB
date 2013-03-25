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
#import "BSON_Helper.h"
#import "Mongo_Helper.h"
#import "BSON_PrivateInterfaces.h"

@implementation MongoCursor {
    mongo_cursor *_cursor;
}

#pragma mark - Initialization

- (id) initWithNativeCursor:(mongo_cursor *) cursor {
    if (self = [super init]) {
        _cursor = cursor;
    }
    return self;
}

+ (MongoCursor *) cursorWithNativeCursor:(mongo_cursor *) cursor {
    MongoCursor *result = [[self alloc] initWithNativeCursor:cursor];
    maybe_autorelease_and_return(result);
}

- (void) dealloc {
    mongo_cursor_destroy(_cursor);
    _cursor = NULL;
    super_dealloc;
}

#pragma mark - Enumeration

- (BSONDocument *) nextObjectNoCopy {
    if (MONGO_OK != mongo_cursor_next(_cursor)) return nil;
    bson *newBson = bson_alloc();
    // ownsData = 0 means this is effectively const
    bson_init_finished_data(newBson, (char *) mongo_cursor_data(_cursor), 0);
    return [BSONDocument documentWithNativeDocument:newBson dependentOn:nil];
}

- (BSONDocument *) nextObject {
    if (MONGO_OK != mongo_cursor_next(_cursor)) return nil;
    bson *newBson = bson_alloc();
    bson_copy(newBson, mongo_cursor_bson(_cursor));
    return [BSONDocument documentWithNativeDocument:newBson dependentOn:nil];
}

- (NSArray *) allObjects {
    NSMutableArray *result = [NSMutableArray array];
    BSONDocument *document;
    while (document = [self nextObject]) [result addObject:document];
    return result;
}

@end
