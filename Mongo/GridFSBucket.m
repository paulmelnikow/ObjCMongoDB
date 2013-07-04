//
//  GridFSBucket.m
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

#import "GridFSBucket.h"
#import "GridFileHandle.h"
#import "GridFileWriter.h"
#import "BSON_Helper.h"
#import "Mongo_PrivateInterfaces.h"
#import "gridfs.h"

@interface GridFSBucket ()
@property (assign) BOOL privateUsesCaseSensitiveFilenames;
@end

@implementation GridFSBucket {
    gridfs *_gfs;
}

#pragma mark - Initialization

- (id) initWithConnection:(MongoConnection *) connectionParam
             databaseName:(NSString *) databaseNameParam
               bucketName:(NSString *) bucketNameParam {
    if (self = [super init]) {
        self.connection = connectionParam;
        self.databaseName = databaseNameParam;
        self.bucketName = bucketNameParam;
        gridfs *gfs = gridfs_alloc();
        if (MONGO_OK != gridfs_init(self.connection.connValue,
                                    databaseNameParam.bsonString,
                                    bucketNameParam.bsonString,
                                    gfs)) {
            gridfs_dealloc(gfs);
            nullify_self_and_return;
        }
        _gfs = gfs;
        self.usesCaseSensitiveFilenames = YES;
    }
    return self;
}

+ (GridFSBucket *) bucketWithConnection:(MongoConnection *) connection
                           databaseName:(NSString *) databaseName
                             bucketName:(NSString *) bucketName {
    GridFSBucket *result = [[self alloc] initWithConnection:connection
                                               databaseName:databaseName
                                                 bucketName:bucketName];
    maybe_autorelease_and_return(result);
}

- (void) dealloc {
    gridfs_destroy(_gfs);
    gridfs_dealloc(_gfs);
    _gfs = NULL;
    maybe_release(_connection);
    maybe_release(_databaseName);
    maybe_release(_bucketName);
    super_dealloc;
}

- (void) setUsesCaseSensitiveFilenames:(BOOL) usesCaseSensitiveFilenames {
    self.privateUsesCaseSensitiveFilenames = usesCaseSensitiveFilenames;
    gridfs_set_caseInsensitive(_gfs, !usesCaseSensitiveFilenames);
}

- (BOOL) usesCaseSensitiveFilenames {
    return self.privateUsesCaseSensitiveFilenames;
}

#pragma mark - Finding files

- (GridFileHandle *) findWithFilename:(NSString *) filename {
    NSParameterAssert(filename != nil);
    gridfile *gf = gridfile_create();
    if (MONGO_OK != gridfs_find_filename(_gfs,
                                         filename.bsonString,
                                         gf)) {
        gridfile_destroy(gf);
        gridfile_dealloc(gf);
        return nil;
    }
    return [GridFileHandle fileHandleWithNativeGridFile:gf];
}

- (GridFileHandle *) findOneWithPredicate:(MongoPredicate *) predicate {
    NSParameterAssert(predicate != nil);
    gridfile *gf = gridfile_create();
    if (MONGO_OK != gridfs_find_query(_gfs,
                                      predicate.BSONDocument.bsonValue,
                                      gf)) {
        gridfile_destroy(gf);
        gridfile_dealloc(gf);
        return nil;
    }
    return [GridFileHandle fileHandleWithNativeGridFile:gf];
}

#pragma mark - Storing files

- (BOOL) writeData:(NSData *) data toFilename:(NSString *) filename MIMEType:(NSString *) MIMEType {
    NSParameterAssert(data != nil);
    NSParameterAssert(filename != nil);
    return MONGO_OK == gridfs_store_buffer(_gfs,
                                           data.bytes,
                                           data.length,
                                           filename.bsonString,
                                           MIMEType.bsonString,
                                           GRIDFILE_NOMD5);
//                                           GRIDFILE_DEFAULT);
}

- (GridFileWriter *) writerWithFilename:(NSString *) filename MIMEType:(NSString *) MIMEType {
    NSParameterAssert(filename != nil);
    gridfile *gf = gridfile_create();
    if (MONGO_OK != gridfile_writer_init(gf,
                                         _gfs,
                                         filename.bsonString,
                                         MIMEType.bsonString,
                                         GRIDFILE_DEFAULT)) {
        gridfile_destroy(gf);
        gridfile_dealloc(gf);
        return nil;
    }
    return [GridFileWriter writerWithNativeGridFile:gf];
}

#pragma mark - Deleting files

- (BOOL) removeFileWithFilename:(NSString *) filename {
    NSParameterAssert(filename != nil);
    return MONGO_OK == gridfs_remove_filename(_gfs, filename.bsonString);
}

@end
