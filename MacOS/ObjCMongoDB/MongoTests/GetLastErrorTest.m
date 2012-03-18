//
//  GetLastErrorTest.m
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GetLastErrorTest.h"
#import "MongoDBCollection.h"

@implementation GetLastErrorTest

-(void) setUp {
    NSError *error = nil;
    _mongo = [MongoConnection connectionForServer:@"127.0.0.1" error:&error];
    STAssertNil(error, error.localizedDescription);
}

- (void) tearDown {
    [_mongo disconnect];
    _mongo = nil;
}

- (void) testServerStatus {
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.getlasterror.testServerStatus"];
    
    NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:
                           [BSONObjectID objectID], @"_id",
                           @"test", @"name",
                           nil];
    
    NSError *error = nil;
    [coll insertDictionary:entry error:&error];
    STAssertTrue([coll serverStatusForLastOperation:&error], @"shouldn't be an error");

    [coll insertDictionary:entry error:&error];
    STAssertFalse([coll serverStatusForLastOperation:&error], @"should be a duplicate key");
}

@end
