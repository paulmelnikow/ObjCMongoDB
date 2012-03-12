//
//  MongoTests.m
//  MongoTests
//
//  Created by Paul Melnikow on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MongoTests.h"
#import "MongoPredicate.h"
#import "MongoFetchRequest.h"

@implementation MongoTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testExample {
    
    MongoPredicate *predicate = [MongoPredicate predicate];
    [predicate keyPath:@"age" isGreaterThanOrEqualTo:[NSNumber numberWithInteger:18]];
    [predicate keyPath:@"age" isLessThanOrEqualTo:[NSNumber numberWithInteger:30]];
    [predicate keyPath:@"username" isNotEqualTo:@"joe"];

    NSLog(@"%@", predicate);

    MongoFetchRequest *request = [MongoFetchRequest fetchRequest];
    request.predicate = predicate;
    [request includeKey:@"username"];
    [request excludeKey:@"_id"];

    NSLog(@"%@", request);

    NSLog(@"\n");
}

@end
