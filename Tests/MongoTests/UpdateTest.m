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

#import "MongoTest.h"
#import "MongoKeyedPredicate.h"
#import "MongoUpdateRequest.h"
#import "BSONTypes.h"
#import "MongoTests_Helper.h"

@interface UpdateTest : MongoTest

@end

@implementation UpdateTest

- (void) insertTestDocument:(MongoDBCollection *) collection {
    NSDictionary *testDoc =
    @{
      @"description" : @"pickles",
      @"quantity" : @(5),
      @"price" : @(2.99),
      @"ingredients" : @[ @"cucumbers", @"water", @"salt" ],
      @"sizes" : @[ @(16), @(32), @(48) ],
      };
    NSError *error = nil;
    [collection insertDictionary:testDoc writeConcern:nil error:&error];
    STAssertNil(error, error.localizedDescription);
}

- (BOOL) collectionWithName:(MongoDBCollection *) collection boolForPredicate:(MongoPredicate *) predicate {
    NSError *error = nil;
    NSUInteger result = [collection countWithPredicate:predicate error:&error];
    STAssertNil(error, error.localizedDescription);
    return result > 0;
}

- (void) testReplaceDocument {
    declare_coll_and_error;
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"description" matches:@"pickles"];    
    STAssertTrue([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");

    NSDictionary *replacementDoc = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"peaches", @"description",
                             [NSNumber numberWithInt:3], @"quantity",
                             [NSNumber numberWithFloat:.59], @"price",
                             nil];
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req replaceDocumentWithDictionary:replacementDoc];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");

    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"description" matches:@"peaches"];    
    STAssertTrue([self collectionWithName:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testSetValue {
    declare_coll_and_error;
    STAssertTrue([coll removeAllWithWriteConcern:nil error:&error], @"");
    [self insertTestDocument:coll];

    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"quantity" matches:[NSNumber numberWithInt:5]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");

    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req keyPath:@"quantity" setValue:[NSNumber numberWithInt:25]];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");

    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"quantity" matches:[NSNumber numberWithInt:25]];    
    STAssertTrue([self collectionWithName:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testUnsetValue {
    declare_coll_and_error;
    STAssertTrue([coll removeAllWithWriteConcern:nil error:&error], @"");
    [self insertTestDocument:coll];

    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc valueExistsForKeyPath:@"quantity"];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");

    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req unsetValueForKeyPath:@"quantity"];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
}

- (void) testIncrementValue {
    declare_coll_and_error;
    STAssertTrue([coll removeAllWithWriteConcern:nil error:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"quantity" matches:[NSNumber numberWithInt:5]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req incrementValueForKeyPath:@"quantity"];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"quantity" matches:[NSNumber numberWithInt:6]];    
    STAssertTrue([self collectionWithName:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testIncrementByValue {
    declare_coll_and_error;
    STAssertTrue([coll removeAllWithWriteConcern:nil error:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"quantity" matches:[NSNumber numberWithInt:5]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req keyPath:@"quantity" incrementValueBy:[NSNumber numberWithInt:-3]];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"quantity" matches:[NSNumber numberWithInt:2]];    
    STAssertTrue([self collectionWithName:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testBitwiseAnd {
    declare_coll_and_error;
    STAssertTrue([coll removeAllWithWriteConcern:nil error:&error], @"");
    [self insertTestDocument:coll];

    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"quantity" matches:[NSNumber numberWithInt:5]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req keyPath:@"quantity" bitwiseAndWithValue:6];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"quantity" matches:[NSNumber numberWithInt:4]];    
    STAssertTrue([self collectionWithName:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testBitwiseOr {
    declare_coll_and_error;
    STAssertTrue([coll removeAllWithWriteConcern:nil error:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"quantity" matches:[NSNumber numberWithInt:5]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req keyPath:@"quantity" bitwiseOrWithValue:6];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"quantity" matches:[NSNumber numberWithInt:7]];    
    STAssertTrue([self collectionWithName:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testBitwiseCombo {
    declare_coll_and_error;
    STAssertTrue([coll removeAllWithWriteConcern:nil error:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"quantity" matches:[NSNumber numberWithInt:5]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req keyPath:@"quantity" bitwiseOrWithValue:18];
    [req keyPath:@"quantity" bitwiseAndWithValue:28];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"quantity" matches:[NSNumber numberWithInt:20]];    
    STAssertTrue([self collectionWithName:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testAddToSet {
    declare_coll_and_error;
    STAssertTrue([coll removeAllWithWriteConcern:nil error:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req setForKeyPath:@"ingredients" addValue:@"citric acid"];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", @"citric acid", nil]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testAddToSetMulti {
    declare_coll_and_error;
    STAssertTrue([coll removeAllWithWriteConcern:nil error:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req setForKeyPath:@"ingredients" addValuesFromArray:[NSArray arrayWithObjects:@"citric acid", @"monosodium glutamate", @"cucumbers", nil]];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", @"citric acid", @"monosodium glutamate", nil]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testPull {
    declare_coll_and_error;
    STAssertTrue([coll removeAllWithWriteConcern:nil error:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req arrayForKeyPath:@"ingredients" removeItemsMatchingValue:@"cucumbers"];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"water", @"salt", nil]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testPullAll {
    declare_coll_and_error;
    STAssertTrue([coll removeAllWithWriteConcern:nil error:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req arrayForKeyPath:@"ingredients" removeItemsMatchingAnyFromArray:[NSArray arrayWithObjects:@"cucumbers", @"water", nil]];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"salt", nil]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testPullMatching {
    declare_coll_and_error;
    STAssertTrue([coll removeAllWithWriteConcern:nil error:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"sizes" arrayCountIsEqualTo:3];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    MongoKeyedPredicate *predForRemove = [MongoKeyedPredicate predicate];
    [predForRemove keyPath:@"sizes" isLessThan:[NSNumber numberWithInt:20]];
    [req removeMatchingValuesFromArrayUsingKeyedPredicate:predForRemove];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"sizes" matches:[NSArray arrayWithObjects:[NSNumber numberWithInt:32], [NSNumber numberWithInt:48], nil]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testPush {
    declare_coll_and_error;
    STAssertTrue([coll removeAllWithWriteConcern:nil error:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req arrayForKeyPath:@"ingredients" appendValue:@"cucumbers"];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", @"cucumbers", nil]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testPushMulti {
    declare_coll_and_error;
    STAssertTrue([coll removeAllWithWriteConcern:nil error:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req arrayForKeyPath:@"ingredients" appendValuesFromArray:[NSArray arrayWithObjects:@"citric acid", @"monosodium glutamate", nil]];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", @"citric acid", @"monosodium glutamate", nil]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testPopLast {
    declare_coll_and_error;
    STAssertTrue([coll removeAllWithWriteConcern:nil error:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req removeLastValueFromArrayForKeyPath:@"ingredients"];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", nil]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testPopFirst {
    declare_coll_and_error;
    STAssertTrue([coll removeAllWithWriteConcern:nil error:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"cucumbers", @"water", @"salt", nil]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req removeFirstValueFromArrayForKeyPath:@"ingredients"];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"ingredients" matches:[NSArray arrayWithObjects:@"water", @"salt", nil]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testRename {
    declare_coll_and_error;
    STAssertTrue([coll removeAllWithWriteConcern:nil error:&error], @"");
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc valueExistsForKeyPath:@"ingredients"];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req keyPath:@"ingredients" renameToKey:@"contents"];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predForOriginalDoc valueExistsForKeyPath:@"contents"];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testUpdateMulti {
    declare_coll_and_error;
    STAssertTrue([coll removeAllWithWriteConcern:nil error:&error], @"");
    [self insertTestDocument:coll];
    [self insertTestDocument:coll];
    [self insertTestDocument:coll];
    [self insertTestDocument:coll];
    [self insertTestDocument:coll];
    
    MongoKeyedPredicate *predForOriginalDoc = [MongoKeyedPredicate predicate];
    [predForOriginalDoc keyPath:@"quantity" matches:[NSNumber numberWithInt:5]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForOriginalDoc firstMatchOnly:YES];
    [req incrementValueForKeyPath:@"quantity"];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertTrue([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"quantity" matches:[NSNumber numberWithInt:6]];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predAfterUpdate], @"");
    
    req.updatesFirstMatchOnly = NO;
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForOriginalDoc], @"");
    STAssertTrue([self collectionWithName:coll boolForPredicate:predAfterUpdate], @"");
}

- (void) testUpsert {
    declare_coll_and_error;
    STAssertTrue([coll removeAllWithWriteConcern:nil error:&error], @"");
    
    MongoKeyedPredicate *predForTestDoc = [MongoKeyedPredicate predicate];
    [predForTestDoc keyPath:@"quantity" matches:[NSNumber numberWithInt:5]];
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForTestDoc], @"");
    
    MongoUpdateRequest *req = [MongoUpdateRequest updateRequestWithPredicate:predForTestDoc firstMatchOnly:YES];
    [req incrementValueForKeyPath:@"quantity"];
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForTestDoc], @"");
    
    MongoKeyedPredicate *predAfterUpdate = [MongoKeyedPredicate predicate];
    [predAfterUpdate keyPath:@"quantity" matches:[NSNumber numberWithInt:6]];
    STAssertFalse([self collectionWithName:coll boolForPredicate:predAfterUpdate], @"");
    
    req.insertsIfNoMatches = YES;
    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForTestDoc], @"");
    STAssertTrue([self collectionWithName:coll boolForPredicate:predAfterUpdate], @"");

    [self insertTestDocument:coll];
    STAssertTrue([self collectionWithName:coll boolForPredicate:predForTestDoc], @"");

    STAssertTrue([coll updateWithRequest:req error:&error], @"");
    STAssertFalse([self collectionWithName:coll boolForPredicate:predForTestDoc], @"");
    STAssertTrue([self collectionWithName:coll boolForPredicate:predAfterUpdate], @"");
}


@end