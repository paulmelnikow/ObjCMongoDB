//
//  ObjCBSONTests.m
//  ObjCBSONTests
//
//  Created by Paul Melnikow on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ObjCBSONTests.h"
#import "BSONArchiver.h"
#import "BSONDocument.h"

@implementation ObjCBSONTests

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

- (void)testRepeatability
{
    NSDictionary *sample = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:1], @"one",
                            [NSNumber numberWithDouble:2.0], @"two",
                            @"3", @"three",
                            [NSArray arrayWithObjects:@"zero", @"one", @"two", @"three", nil], @"four",
                            nil];
    
    BSONArchiver *archiver1 = [BSONArchiver archiver];
    [sample encodeWithCoder:archiver1];

    BSONArchiver *archiver2 = [BSONArchiver archiver];
    [sample encodeWithCoder:archiver2];

    STAssertEqualObjects([[archiver1 BSONDocument] dataValue],
                         [[archiver2 BSONDocument] dataValue],
                         @"Encoded same dictionary but got different data values.");

    STAssertEqualObjects([archiver1 BSONDocument],
                         [archiver2 BSONDocument],
                         @"Encoded same dictionary but documents were not equal.");
}

- (void) testUnequal {
    NSDictionary *sample1 = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:1], @"one",
                            [NSNumber numberWithDouble:2.0], @"two",
                            @"3", @"three",
                            [NSArray arrayWithObjects:@"zero", @"one", @"two", @"three", nil], @"four",
                            nil];
    
    BSONArchiver *archiver1 = [BSONArchiver archiver];
    [sample1 encodeWithCoder:archiver1];
        
    NSDictionary *sample2 = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInt:1], @"six",
                             [NSNumber numberWithDouble:2.0], @"two",
                             @"3", @"three",
                             [NSArray arrayWithObjects:@"zero", @"one", @"two", @"three", nil], @"four",
                             nil];
    
    BSONArchiver *archiver2 = [BSONArchiver archiver];
    [sample2 encodeWithCoder:archiver2];

    STAssertFalse([[archiver1 BSONDocument] isEqualTo:[archiver2 BSONDocument]],
                  @"Documents had different data and should not be equal");
}

@end
