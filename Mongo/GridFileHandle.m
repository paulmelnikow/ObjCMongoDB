//
//  GridFileHandle.m
//  ObjCMongoDB
//
//  Copyright 2013 Paul Melnikow and other contributors
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

#import "GridFileHandle.h"
#import "BSON_Helper.h"
#import "gridfs.h"

@implementation GridFileHandle {
    gridfile *_gf;
}

#pragma mark - Initialization

- (id) initWithNativeGridFile:(gridfile *) gf {
    if (!gf) nullify_self_and_return;
    if (self = [super init]) {
        _gf = gf;
    }
    return self;
}

- (void) dealloc {
    gridfile_destroy(_gf);
    gridfile_dealloc(_gf);
    _gf = NULL;
    super_dealloc;
}

+ (GridFileHandle *) fileHandleWithNativeGridFile:(gridfile *) gf {
    GridFileHandle *result = [[self alloc] initWithNativeGridFile:gf];
    maybe_autorelease_and_return(result);
}

- (gridfile *) nativeGridFile { return _gf; }

@end
