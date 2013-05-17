//
//  GridFSTest.m
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

#import "MongoTest.h"
#import "ObjCMongoDB.h"
#import "MongoTests_Helper.h"

@interface GridFSTest : MongoTest
@end

@implementation GridFSTest

+ (NSData *) randomDataWithLength:(NSUInteger) length {
    void *data = malloc(length);
    if (!data) return nil;

    // This code is from gridfs_test.c in the 10gen C driver
    // Licensed under the Apache 2.0 license, same as the rest of the repository
    int64_t i;
    int random;
    char *letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    int nletters = (int)strlen( letters );
    char *cur;
    
    for ( i = 0, cur = data; i < length; i++, cur++ ) {
        random = rand() % nletters;
        *cur = letters[random];
    }
    
    return [NSData dataWithBytesNoCopy:data length:length freeWhenDone:YES];
}

- (void) testBasic {
    GridFSBucket *bucket = [self.mongo gridFSBucketWithDatabaseName:_coll_name bucketName:nil];
    STAssertNotNil(bucket, nil);
    
    [bucket removeFileWithFilename:@"test-file"];
    [bucket removeFileWithFilename:@"bogus-file"];
    
    NSData *data = [self.class randomDataWithLength:2000*1024];
    STAssertTrue([bucket writeData:data toFilename:@"test-file" MIMEType:@"text/plain"], nil);
    
    GridFileHandle *file = [bucket findWithFilename:@"test-file"];
    STAssertNotNil(file, nil);
    
    GridFileHandle *nonExistentFile = [bucket findWithFilename:@"bogus-file"];
    STAssertNil(nonExistentFile, nil);
    
    STAssertTrue([bucket removeFileWithFilename:@"test-file"], nil);
    STAssertFalse([bucket removeFileWithFilename:@"bogus-file"], nil);
}

@end
