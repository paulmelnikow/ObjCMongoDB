//
//  GridFSBucket.h
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

#import <Foundation/Foundation.h>
#import "GridFileHandle.h"

@class MongoConnection;
@class MongoPredicate;
@class GridFileWriter;

@interface GridFSBucket : NSObject

- (GridFileHandle *) findWithFilename:(NSString *) filename;
/* Queries the bucket's "files" collection */
- (GridFileHandle *) findOneWithPredicate:(MongoPredicate *) predicate;

- (BOOL) writeData:(NSData *) data toFilename:(NSString *) filename MIMEType:(NSString *) MIMEType;
- (GridFileWriter *) writerWithFilename:(NSString *) filename MIMEType:(NSString *) MIMEType;

- (BOOL) removeFileWithFilename:(NSString *) filename;

/* The default is YES. When NO, the driver will store the original filename but for indexing purposes
 will use uppercase filenames. */
@property (assign) BOOL usesCaseSensitiveFilenames;

@property (retain) MongoConnection * connection;
@property (copy, nonatomic) NSString * databaseName;
@property (copy, nonatomic) NSString * bucketName;

@end
