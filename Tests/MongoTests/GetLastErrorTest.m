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

#import "MongoTest.h"
#import "MongoDBCollection.h"
#import "MongoKeyedPredicate.h"
#import "MongoUpdateRequest.h"
#import "MongoTests_Helper.h"

@interface GetLastErrorTest : MongoTest

@end

@implementation GetLastErrorTest

- (void) testServerStatus {
    declare_coll_and_error;
    
    NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:
                           [BSONObjectID objectID], @"_id",
                           @"test", @"name",
                           nil];
    
    [coll insertDictionary:entry writeConcern:nil error:&error];
    STAssertTrue([coll lastOperationWasSuccessful:&error], @"shouldn't be an error");

    [coll insertDictionary:entry writeConcern:nil error:&error];
    STAssertFalse([coll lastOperationWasSuccessful:&error], @"should be a duplicate key");
}

- (void) testUpdateCount {
    declare_coll_and_error;
    
    BSONObjectID *objectID = [BSONObjectID objectID];
    NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:
                           objectID, @"_id",
                           @"test", @"name",
                           nil];
    
    [coll insertDictionary:entry writeConcern:nil error:&error];
    STAssertTrue([coll lastOperationWasSuccessful:&error], nil);

    MongoKeyedPredicate *matchingPredicate = [MongoKeyedPredicate predicate];
    [matchingPredicate keyPath:@"_id" matches:objectID];
    MongoUpdateRequest *request1 = [MongoUpdateRequest updateRequestWithPredicate:matchingPredicate firstMatchOnly:YES];
    [request1 keyPath:@"addedValue" setValue:@"more test"];
    
    [coll updateWithRequest:request1 error:&error];
    STAssertTrue([coll lastOperationWasSuccessful:&error], nil);
    
    NSDictionary *dict = [coll lastOperationDictionary];
    STAssertNotNil(dict, nil);
    if (dict) {
        STAssertEqualObjects([NSNumber numberWithInt:1], [dict objectForKey:@"n"], nil);
    }
    
    BSONObjectID *noMatchObjectID = [BSONObjectID objectID];
    MongoKeyedPredicate *noMatchPredicate = [MongoKeyedPredicate predicate];
    [noMatchPredicate keyPath:@"_id" matches:noMatchObjectID];
    MongoUpdateRequest *request2 = [MongoUpdateRequest updateRequestWithPredicate:noMatchPredicate firstMatchOnly:YES];
    [request2 keyPath:@"addedValue" setValue:@"more test"];
    
    [coll updateWithRequest:request2 error:&error];
    STAssertTrue([coll lastOperationWasSuccessful:&error], nil);
    
    dict = [coll lastOperationDictionary];
    STAssertNotNil(dict, nil);
    if (dict) {
        STAssertEqualObjects([NSNumber numberWithInt:0], [dict objectForKey:@"n"], nil);
    }
}

@end
