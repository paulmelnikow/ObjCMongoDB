//
//  GetLastErrorTest.m
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

#import "GetLastErrorTest.h"
#import "MongoDBCollection.h"
#import "MongoKeyedPredicate.h"
#import "MongoUpdateRequest.h"

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

- (void) testUpdateCount {
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.getlasterror.testUpdateCount"];
    
    BSONObjectID *objectID = [BSONObjectID objectID];
    NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:
                           objectID, @"_id",
                           @"test", @"name",
                           nil];
    
    NSError *error = nil;
    [coll insertDictionary:entry error:&error];
    STAssertTrue([coll serverStatusForLastOperation:&error], nil);

    MongoKeyedPredicate *matchingPredicate = [MongoKeyedPredicate predicate];
    [matchingPredicate keyPath:@"_id" matches:objectID];
    MongoUpdateRequest *request1 = [MongoUpdateRequest updateRequestWithPredicate:matchingPredicate firstMatchOnly:YES];
    [request1 keyPath:@"addedValue" setValue:@"more test"];
    
    [coll update:request1 error:&error];
    STAssertTrue([coll serverStatusForLastOperation:&error], nil);
    
    NSDictionary *dict = [coll serverStatusAsDictionaryForLastOperation];
    STAssertNotNil(dict, nil);
    if (dict) {
        STAssertEqualObjects([NSNumber numberWithInt:1], [dict objectForKey:@"n"], nil);
    }
    
    BSONObjectID *noMatchObjectID = [BSONObjectID objectID];
    MongoKeyedPredicate *noMatchPredicate = [MongoKeyedPredicate predicate];
    [noMatchPredicate keyPath:@"_id" matches:noMatchObjectID];
    MongoUpdateRequest *request2 = [MongoUpdateRequest updateRequestWithPredicate:noMatchPredicate firstMatchOnly:YES];
    [request2 keyPath:@"addedValue" setValue:@"more test"];
    
    [coll update:request2 error:&error];
    STAssertTrue([coll serverStatusForLastOperation:&error], nil);
    
    dict = [coll serverStatusAsDictionaryForLastOperation];
    STAssertNotNil(dict, nil);
    if (dict) {
        STAssertEqualObjects([NSNumber numberWithInt:0], [dict objectForKey:@"n"], nil);
    }
}

@end
