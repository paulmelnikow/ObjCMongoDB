//
//  UpdateTest.m
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

#import "UpdateTest.h"
#import "MongoKeyedPredicate.h"
#import "MongoUpdateRequest.h"
#import "BSONTypes.h"

@implementation UpdateTest

-(void) setUp {
    NSError *error = nil;
    _mongo = [MongoConnection connectionForServer:@"127.0.0.1" error:&error];
    STAssertNil(error, error.localizedDescription);
}

- (void) tearDown {
    [_mongo disconnect];
    _mongo = nil;
}

- (void) insertTestDocument:(MongoDBCollection *) collection {
    NSDictionary *testDoc = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"pickles", @"description",
                                 [NSNumber numberWithInt:5], @"quantity",
                                 [NSNumber numberWithFloat:2.99], @"price",
                                 [NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil], @"ingredients",
                                 [NSArray arrayWithObjects:[NSNumber numberWithInt:16], [NSNumber numberWithInt:32], [NSNumber numberWithInt:48], nil], @"sizes",
                                 nil];
    NSError *error = nil;
    [collection insertDictionary:testDoc error:&error];
    STAssertNil(error, error.localizedDescription);
}

- (BOOL) collection:(MongoDBCollection *) collection boolForPredicate:(MongoPredicate *) predicate {
    NSError *error = nil;
    NSUInteger result = [collection countWithPredicate:predicate error:&error];
    STAssertNil(error, error.localizedDescription);
    return result > 0;
}

- (void) testReplaceDocument {
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.update.testReplaceDocument"];    
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"description" matches:@"pickles"];    
    STAssertTrue([self collection:coll boolForPredicate:predForOriginalDoc], @"");

    NSDictionary *replacementDoc = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"peaches", @"description",
                             [NSNumber numberWithInt:3], @"quantity",
                             [NSNumber numberWithFloat:.59], @"price",
                             nil];
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req replaceDocumentWithDictionary:replacementDoc];
    NSError *error = nil;
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    STAssertFalse([self collection:coll boolForPredicate:predForOriginalDoc], @"");

    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"description" matches:@"peaches"];    
    STAssertTrue([self collection:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testSetValue {
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.update.testSetValue"];    
    NSError *error = nil;
    STAssertTrue([coll removeAllWithError:&error], @"");
    [self insertTestDocument:coll];

    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"quantity" matches:[NSNumber numberWithInt:5]];
    STAssertTrue([self collection:coll boolForPredicate:predForOriginalDoc], @"");

    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req keyPath:@"quantity" setValue:[NSNumber numberWithInt:25]];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collection:coll boolForPredicate:predForOriginalDoc], @"");

    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"quantity" matches:[NSNumber numberWithInt:25]];    
    STAssertTrue([self collection:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testUnsetValue {
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.update.testUnsetValue"];    
    NSError *error = nil;
    STAssertTrue([coll removeAllWithError:&error], @"");
    [self insertTestDocument:coll];

    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc valueExistsForKeyPath:@"quantity"];
    STAssertTrue([self collection:coll boolForPredicate:predForOriginalDoc], @"");

    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req unsetValueForKeyPath:@"quantity"];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collection:coll boolForPredicate:predForOriginalDoc], @"");
}

- (void) testIncrementValue {
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.update.testIncrementValue"];    
    NSError *error = nil;
    STAssertTrue([coll removeAllWithError:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"quantity" matches:[NSNumber numberWithInt:5]];
    STAssertTrue([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req incrementValueForKeyPath:@"quantity"];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"quantity" matches:[NSNumber numberWithInt:6]];    
    STAssertTrue([self collection:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testIncrementByValue {
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.update.testIncrementByValue"];    
    NSError *error = nil;
    STAssertTrue([coll removeAllWithError:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"quantity" matches:[NSNumber numberWithInt:5]];
    STAssertTrue([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req keyPath:@"quantity" incrementValueBy:[NSNumber numberWithInt:-3]];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"quantity" matches:[NSNumber numberWithInt:2]];    
    STAssertTrue([self collection:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testBitwiseAnd {
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.update.testBitwiseAnd"];    
    NSError *error = nil;
    STAssertTrue([coll removeAllWithError:&error], @"");
    [self insertTestDocument:coll];

    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"quantity" matches:[NSNumber numberWithInt:5]];
    STAssertTrue([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req keyPath:@"quantity" bitwiseAndWithValue:6];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"quantity" matches:[NSNumber numberWithInt:4]];    
    STAssertTrue([self collection:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testBitwiseOr {
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.update.testBitwiseOr"];    
    NSError *error = nil;
    STAssertTrue([coll removeAllWithError:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"quantity" matches:[NSNumber numberWithInt:5]];
    STAssertTrue([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req keyPath:@"quantity" bitwiseOrWithValue:6];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"quantity" matches:[NSNumber numberWithInt:7]];    
    STAssertTrue([self collection:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testBitwiseCombo {
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.update.testBitwiseCombo"];    
    NSError *error = nil;
    STAssertTrue([coll removeAllWithError:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"quantity" matches:[NSNumber numberWithInt:5]];
    STAssertTrue([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req keyPath:@"quantity" bitwiseOrWithValue:18];
    [req keyPath:@"quantity" bitwiseAndWithValue:28];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"quantity" matches:[NSNumber numberWithInt:20]];    
    STAssertTrue([self collection:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testAddToSet {
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.update.testAddToSet"];    
    NSError *error = nil;
    STAssertTrue([coll removeAllWithError:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil]];
    STAssertTrue([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req setForKeyPath:@"ingredients" addValue:@"citric acid"];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", @"citric acid", nil]];
    STAssertTrue([self collection:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testAddToSetMulti {
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.update.testAddToSetMulti"];    
    NSError *error = nil;
    STAssertTrue([coll removeAllWithError:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil]];
    STAssertTrue([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req setForKeyPath:@"ingredients" addValuesFromArray:[NSArray arrayWithObjects:@"citric acid", @"monosodium glutamate", @"cucumbers", nil]];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", @"citric acid", @"monosodium glutamate", nil]];
    STAssertTrue([self collection:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testPull {
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.update.testPull"];    
    NSError *error = nil;
    STAssertTrue([coll removeAllWithError:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil]];
    STAssertTrue([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req arrayForKeyPath:@"ingredients" removeItemsMatchingValue:@"cucumbers"];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"water", @"salt", nil]];
    STAssertTrue([self collection:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testPullAll {
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.update.testPullAll"];    
    NSError *error = nil;
    STAssertTrue([coll removeAllWithError:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil]];
    STAssertTrue([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req arrayForKeyPath:@"ingredients" removeItemsMatchingAnyFromArray:[NSArray arrayWithObjects:@"cucumbers", @"water", nil]];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"salt", nil]];
    STAssertTrue([self collection:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testPullMatching {
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.update.testPullMatching"];    
    NSError *error = nil;
    STAssertTrue([coll removeAllWithError:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"sizes" arrayCountIsEqualTo:3];
    STAssertTrue([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    MongoKeyedPredicate *predForRemove = [MongoKeyedPredicate predicate];
    [predForRemove keyPath:@"sizes" isLessThan:[NSNumber numberWithInt:20]];
    [req removeMatchingValuesFromArrayUsingKeyedPredicate:predForRemove];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"sizes" matches:[NSArray arrayWithObjects:[NSNumber numberWithInt:32], [NSNumber numberWithInt:48], nil]];
    STAssertTrue([self collection:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testPush {
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.update.testPush"];    
    NSError *error = nil;
    STAssertTrue([coll removeAllWithError:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil]];
    STAssertTrue([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req arrayForKeyPath:@"ingredients" appendValue:@"cucumbers"];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", @"cucumbers", nil]];
    STAssertTrue([self collection:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testPushMulti {
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.update.testPushMulti"];    
    NSError *error = nil;
    STAssertTrue([coll removeAllWithError:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil]];
    STAssertTrue([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req arrayForKeyPath:@"ingredients" appendValuesFromArray:[NSArray arrayWithObjects:@"citric acid", @"monosodium glutamate", nil]];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", @"citric acid", @"monosodium glutamate", nil]];
    STAssertTrue([self collection:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testPopLast {
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.update.testPopLast"];    
    NSError *error = nil;
    STAssertTrue([coll removeAllWithError:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil]];
    STAssertTrue([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req removeLastValueFromArrayForKeyPath:@"ingredients"];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", nil]];
    STAssertTrue([self collection:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testPopFirst {
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.update.testPopFirst"];    
    NSError *error = nil;
    STAssertTrue([coll removeAllWithError:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil]];
    STAssertTrue([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req removeFirstValueFromArrayForKeyPath:@"ingredients"];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"water", @"salt", nil]];
    STAssertTrue([self collection:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testRename {
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.update.testRename"];    
    NSError *error = nil;
    STAssertTrue([coll removeAllWithError:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc valueExistsForKeyPath:@"ingredients"];
    STAssertTrue([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req keyPath:@"ingredients" renameToKey:@"contents"];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predForOriginalDoc valueExistsForKeyPath:@"contents"];
    STAssertTrue([self collection:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testUpdateMulti {
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.update.testUpdateMulti"];    
    NSError *error = nil;
    STAssertTrue([coll removeAllWithError:&error], @"");
    [self insertTestDocument:coll];
    [self insertTestDocument:coll];
    [self insertTestDocument:coll];
    [self insertTestDocument:coll];
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"quantity" matches:[NSNumber numberWithInt:5]];
    STAssertTrue([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req incrementValueForKeyPath:@"quantity"];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertTrue([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"quantity" matches:[NSNumber numberWithInt:6]];
    STAssertTrue([self collection:coll boolForPredicate:predAfterUpdate], @"");
    
    req.updatesFirstMatchOnly = NO;
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collection:coll boolForPredicate:predForOriginalDoc], @"");
    STAssertTrue([self collection:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testUpsert {
    MongoDBCollection *coll = [_mongo collection:@"objcmongodbtest.update.testUpsert"];    
    NSError *error = nil;
    STAssertTrue([coll removeAllWithError:&error], @"");
    
    MongoKeyedPredicate *predForTestDoc = [MongoKeyedPredicate predicate];
    [predForTestDoc keyPath:@"quantity" matches:[NSNumber numberWithInt:5]];
    STAssertFalse([self collection:coll boolForPredicate:predForTestDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForTestDoc firstMatchOnly:YES];
    [req incrementValueForKeyPath:@"quantity"];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collection:coll boolForPredicate:predForTestDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"quantity" matches:[NSNumber numberWithInt:6]];
    STAssertFalse([self collection:coll boolForPredicate:predAfterUpdate], @"");
    
    req.insertsIfNoMatches = YES;
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    STAssertFalse([self collection:coll boolForPredicate:predForTestDoc], @"");
    STAssertTrue([self collection:coll boolForPredicate:predAfterUpdate], @"");

    [self insertTestDocument:coll];
    STAssertTrue([self collection:coll boolForPredicate:predForTestDoc], @"");

    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    STAssertFalse([self collection:coll boolForPredicate:predForTestDoc], @"");
    STAssertTrue([self collection:coll boolForPredicate:predAfterUpdate], @"");
}


@end