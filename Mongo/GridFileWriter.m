//
//  GridFileWriter.m
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

#import "GridFileWriter.h"
#import "BSON_Helper.h"
#import "Mongo_PrivateInterfaces.h"
#import "gridfs.h"

@interface GridFileWriter ()
@property (nonatomic, assign, readwrite) BOOL finished;
@end

@implementation GridFileWriter

+ (GridFileWriter *) writerWithNativeGridFile:(gridfile *) gf {
    GridFileWriter *result = [[self alloc] initWithNativeGridFile:gf];
    maybe_autorelease_and_return(result);
}

- (void) dealloc {
    if (!self.finished)
        NSLog(@"Warning: GridFileWriter was deallocated without being finished");
    super_dealloc;
}

- (void) writeData:(NSData *) data {
    if (self.finished)
        [NSException raise:NSInvalidArgumentException format:@"Writer is already finished"];
    gridfile_write_buffer(self.nativeGridFile,
                          data.bytes,
                          data.length);
}

- (BOOL) finish {
    if (self.finished)
        [NSException raise:NSInvalidArgumentException format:@"Writer is already finished"];
    int result = gridfile_writer_done(self.nativeGridFile);
    if (result == MONGO_OK)
        return self.finished = YES;
    else
        return NO;
}

@end
