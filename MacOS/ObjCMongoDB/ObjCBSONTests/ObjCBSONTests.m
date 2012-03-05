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
#import "BSONTypes.h"

@interface Person : NSObject
@property (retain) NSString * name;
@property (retain) NSDate * dob;
@property (assign) NSInteger numberOfVisits;
@property (retain) NSMutableArray * children;
@end
@implementation Person
@synthesize name, dob, numberOfVisits, children;
-(void)encodeWithCoder:(NSCoder *)coder {
    @throw [NSException exceptionWithName:@"encodeWithCoder: was called"
                                   reason:@"encodeWithCoder: was called"
                                 userInfo:nil];
}
-(id)initWithCoder:(NSCoder *)coder {
    @throw [NSException exceptionWithName:@"initWithCoder: was called"
                                   reason:@"initWithCoder: was called"
                                 userInfo:nil];
}
@end
@interface PersonWithCoding : Person <NSCoding>
@end
@implementation PersonWithCoding
-(void)encodeWithCoder:(BSONArchiver *)coder {
    if (![coder isKindOfClass:[BSONArchiver class]])
        @throw [NSException exceptionWithName:@"Needs a BSONArchiver"
                                       reason:@"Needs a BSONArchiver"
                                     userInfo:nil];
    [coder encodeString:self.name forKey:@"name"];
    [coder encodeDate:self.dob forKey:@"dob"];
    [coder encodeInt64:self.numberOfVisits forKey:@"numberOfVisits"];
    [coder encodeArray:self.children forKey:@"children"];
}
-(id)initWithCoder:(NSCoder *)coder {
    @throw [NSException exceptionWithName:@"initWithCoder: was called"
                                   reason:@"initWithCoder: was called"
                                 userInfo:nil];
}
@end

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

- (void)testInvalidMongoDBKeys {
    BSONArchiver *archiver = nil;
    
    NSDictionary *sample = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:1], @"one",
                            [NSNumber numberWithDouble:2.0], @"two",
                            @"3", @"three",
                            [NSArray arrayWithObjects:@"zero", @"one", @"two", @"three", nil], @"four",
                            nil];
    
    archiver = [BSONArchiver archiver];
    
    STAssertThrowsSpecificNamed([sample encodeWithCoder:archiver],
                                NSException,
                                NSInvalidArgumentException,
                                @"Default dictionary encodeWithCoder produces invalid MongoDB keys, but exception wasn't raised");
    
    NSDictionary *badSample1 = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"pickles", @"this.is.a.bad.key",
                                nil];
    archiver = [BSONArchiver archiver];
    STAssertThrowsSpecificNamed([archiver encodeDictionary:badSample1],
                                NSException,
                                NSInvalidArgumentException,
                                @"Exception wasn't raised for invalid MongoDB key containing '.'");
    
    archiver = [BSONArchiver archiver];
    archiver.restrictsKeyNamesForMongoDB = NO;
    STAssertNoThrowSpecificNamed([archiver encodeDictionary:badSample1],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"MongoDB checking disabled, but exception was still raised for invalid key");

    
    NSDictionary *badSample2 = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"pickles", @"bad$key",
                                nil];
    archiver = [BSONArchiver archiver];
    STAssertThrowsSpecificNamed([archiver encodeDictionary:badSample2],
                                NSException,
                                NSInvalidArgumentException,
                                @"Exception wasn't raised for invalid MongoDB key containing '$'");
    
    archiver = [BSONArchiver archiver];
    archiver.restrictsKeyNamesForMongoDB = NO;
    STAssertNoThrowSpecificNamed([archiver encodeDictionary:badSample2],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"MongoDB checking disabled, but exception was still raised for invalid key");
    
}

- (void)testRepeatability {
    NSDictionary *sample = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:1], @"one",
                            [NSNumber numberWithDouble:2.0], @"two",
                            @"3", @"three",
                            [NSArray arrayWithObjects:@"zero", @"one", @"two", @"three", nil], @"four",
                            nil];
    
    BSONArchiver *archiver1 = [BSONArchiver archiver];
    [archiver1 encodeDictionary:sample];

    BSONArchiver *archiver2 = [BSONArchiver archiver];
    [archiver2 encodeDictionary:sample];
    
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
    NSDictionary *sample2 = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInt:1], @"six",
                             [NSNumber numberWithDouble:2.0], @"two",
                             @"3", @"three",
                             [NSArray arrayWithObjects:@"zero", @"one", @"two", @"three", nil], @"four",
                             nil];
    
    BSONArchiver *archiver1 = [BSONArchiver archiver];
    [archiver1 encodeDictionary:sample1];
    
    BSONArchiver *archiver2 = [BSONArchiver archiver];
    [archiver2 encodeDictionary:sample2];
        
    STAssertFalse([[archiver1 BSONDocument] isEqualTo:[archiver2 BSONDocument]],
                  @"Documents had different data and should not be equal");    
}

- (void) testEncodeAfterFinishedEncoding {
    NSDictionary *sample1 = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInt:1], @"one",
                             [NSNumber numberWithDouble:2.0], @"two",
                             @"3", @"three",
                             [NSArray arrayWithObjects:@"zero", @"one", @"two", @"three", nil], @"four",
                             nil];

    BSONArchiver *archiver = [BSONArchiver archiver];
    [archiver encodeDictionary:sample1];
    [archiver BSONDocument];
    STAssertThrowsSpecificNamed([archiver encodeBool:NO forKey:@"testKey"],
                                NSException,
                                NSInvalidArchiveOperationException,
                                @"Attempted encoding after finishEncoding but didn't throw exception");
}

- (void) testEncodeNilKeys {
    BSONArchiver *archiver = [BSONArchiver archiver];
    NSString *reason = @"Nil key should throw an exception";
    STAssertThrows([archiver encodeObject:@"test" forKey:nil], reason);
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"asdf", @"asdf", nil];
    STAssertThrows([archiver encodeDictionary:dict forKey:nil], reason);
    STAssertThrows([archiver encodeArray:[NSArray arrayWithObject:@"test"] forKey:nil], reason);
    STAssertThrows([archiver encodeBSONDocument:[[BSONDocument alloc] init] forKey:nil], reason);
    STAssertThrows([archiver encodeNullForKey:nil], reason);
    STAssertThrows([archiver encodeUndefinedForKey:nil], reason);
    STAssertThrows([archiver encodeObjectID:[[BSONObjectID alloc] init] forKey:nil], reason);
    STAssertThrows([archiver encodeInt:1 forKey:nil], reason);
    STAssertThrows([archiver encodeInt64:1 forKey:nil], reason);
    STAssertThrows([archiver encodeBool:YES forKey:nil], reason);
    STAssertThrows([archiver encodeDouble:3.25 forKey:nil], reason);
    STAssertThrows([archiver encodeNumber:[NSNumber numberWithInt:3] forKey:nil], reason);
    STAssertThrows([archiver encodeString:@"test" forKey:nil], reason);
    STAssertThrows([archiver encodeSymbol:[BSONSymbol symbol:@"test"] forKey:nil], reason);
    STAssertThrows([archiver encodeDate:[NSDate date] forKey:nil], reason);
    STAssertThrows([archiver encodeImage:[NSImage imageNamed:NSImageNameBonjour] forKey:nil], reason);
    STAssertThrows([archiver encodeRegularExpressionPattern:@"test" options:@"test" forKey:nil], reason);
    STAssertThrows([archiver encodeRegularExpression:[BSONRegularExpression regularExpressionWithPattern:@"test" options:@"test"]
                                              forKey:nil], reason);
    STAssertThrows([archiver encodeCode:[BSONCode code:@"test"] forKey:nil], reason);
    STAssertThrows([archiver encodeCodeString:@"test" forKey:nil], reason);
    STAssertThrows([archiver encodeCodeWithScope:[BSONCodeWithScope code:@"test" withScope:[[BSONDocument alloc] init]]
                                          forKey:nil], reason);
    STAssertThrows([archiver encodeCodeString:@"test" withScope:[[BSONDocument alloc] init]
                                          forKey:nil], reason);
    STAssertThrows([archiver encodeData:[NSData data] forKey:nil], reason);
    STAssertThrows([archiver encodeTimestamp:[BSONTimestamp timestampWithIncrement:10 timeInSeconds:10]
                                      forKey:nil], reason);
}

- (void) testEncodeNilValues {
    BSONArchiver *archiver = [BSONArchiver archiver];
    
    NSString *reason = nil;
    
    reason = @"Half-nil values should throw an exception";
    STAssertThrows([archiver encodeRegularExpressionPattern:nil options:@"test" forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeRegularExpressionPattern:@"test" options:nil forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeCodeString:nil withScope:[[BSONDocument alloc] init] forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeCodeString:@"test" withScope:nil forKey:@"testKey"], reason);
    
    reason = @"With default behavior DoNothingOnNil, no exception should be raised for nil values";
    STAssertNoThrow([archiver encodeObject:nil forKey:@"testKey"], reason);
    STAssertNoThrow([archiver encodeDictionary:nil forKey:@"testKey"], reason);
    STAssertNoThrow([archiver encodeArray:nil forKey:@"testKey"], reason);
    STAssertNoThrow([archiver encodeBSONDocument:nil forKey:@"testKey"], reason);
    STAssertNoThrow([archiver encodeObjectID:nil forKey:@"testKey"], reason);
    STAssertNoThrow([archiver encodeNumber:nil forKey:@"testKey"], reason);
    STAssertNoThrow([archiver encodeString:nil forKey:@"testKey"], reason);
    STAssertNoThrow([archiver encodeSymbol:nil forKey:@"testKey"], reason);
    STAssertNoThrow([archiver encodeDate:nil forKey:@"testKey"], reason);
    STAssertNoThrow([archiver encodeImage:nil forKey:@"testKey"], reason);
    STAssertNoThrow([archiver encodeRegularExpression:nil forKey:@"testKey"], reason);
    STAssertNoThrow([archiver encodeCode:nil forKey:@"testKey"], reason);
    STAssertNoThrow([archiver encodeCodeString:nil forKey:@"testKey"], reason);
    STAssertNoThrow([archiver encodeCodeWithScope:nil forKey:@"testKey"], reason);
    STAssertNoThrow([archiver encodeData:nil forKey:@"testKey"], reason);
    STAssertNoThrow([archiver encodeTimestamp:nil forKey:@"testKey"], reason);
    
    STAssertEqualObjects([archiver BSONDocument],
                         [[BSONDocument alloc] init],
                         @"With default behavior, encoding nil values should result in an empty document");
    
    archiver = [BSONArchiver archiver];
    
    reason = @"Zero value on primitive types should not throw an exception";
    STAssertNoThrow([archiver encodeInt:0 forKey:@"testKey"], reason);
    STAssertNoThrow([archiver encodeInt64:0 forKey:@"testKey"], reason);
    STAssertNoThrow([archiver encodeDouble:0 forKey:@"testKey"], reason);
    STAssertNoThrow([archiver encodeBool:NO forKey:@"testKey"], reason);
    
    STAssertFalse([[archiver BSONDocument] isEqualTo:[[BSONDocument alloc] init]],
                         @"With default behavior, encoding zero-value primitives should fill up the document");
    
    archiver = [BSONArchiver archiver];
    archiver.behaviorOnNil = BSONRaiseExceptionOnNil;
    
    reason = @"Half-nil values should throw an exception";
    STAssertThrows([archiver encodeRegularExpressionPattern:nil options:@"test" forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeRegularExpressionPattern:@"test" options:nil forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeCodeString:nil withScope:[[BSONDocument alloc] init] forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeCodeString:@"test" withScope:nil forKey:@"testKey"], reason);
 
    reason = @"Nil value should throw an exception";
    STAssertThrows([archiver encodeObject:nil forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeDictionary:nil forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeArray:nil forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeBSONDocument:nil forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeObjectID:nil forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeNumber:nil forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeString:nil forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeSymbol:nil forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeDate:nil forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeImage:nil forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeRegularExpressionPattern:nil options:@"test" forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeRegularExpressionPattern:@"test" options:nil forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeRegularExpression:nil forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeCode:nil forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeCodeString:nil forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeCodeWithScope:nil forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeCodeString:nil withScope:[[BSONDocument alloc] init] forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeCodeString:@"test" withScope:nil forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeData:nil forKey:@"testKey"], reason);
    STAssertThrows([archiver encodeTimestamp:nil forKey:@"testKey"], reason);
    
    reason = @"Zero value on primitive types should not throw an exception";
    STAssertNoThrow([archiver encodeInt:0 forKey:@"testKey"], reason);
    STAssertNoThrow([archiver encodeInt64:0 forKey:@"testKey"], reason);
    STAssertNoThrow([archiver encodeDouble:0 forKey:@"testKey"], reason);
    STAssertNoThrow([archiver encodeBool:NO forKey:@"testKey"], reason);
    
    archiver = [BSONArchiver archiver];
    archiver.behaviorOnNil = BSONEncodeNullOnNil;
    
    // FIXME test encoding of nil as null
    [archiver encodeObject:nil forKey:@"testKey"];
    reason = @"Inserted nil and should have encoded null, but did not";
    STAssertEquals([archiver.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    STAssertThrows([archiver encodeDictionary:nil forKey:@"testKey"], @"Encoding finished");
    
    archiver = [BSONArchiver archiver];
    archiver.behaviorOnNil = BSONEncodeNullOnNil;
    [archiver encodeDictionary:nil forKey:@"testKey"];
    STAssertEquals([archiver.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    archiver = [BSONArchiver archiver];
    archiver.behaviorOnNil = BSONEncodeNullOnNil;
    [archiver encodeArray:nil forKey:@"testKey"];
    STAssertEquals([archiver.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);

    archiver = [BSONArchiver archiver];
    archiver.behaviorOnNil = BSONEncodeNullOnNil;
    [archiver encodeBSONDocument:nil forKey:@"testKey"];
    STAssertEquals([archiver.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    archiver = [BSONArchiver archiver];
    archiver.behaviorOnNil = BSONEncodeNullOnNil;
    [archiver encodeObjectID:nil forKey:@"testKey"];
    STAssertEquals([archiver.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    archiver = [BSONArchiver archiver];
    archiver.behaviorOnNil = BSONEncodeNullOnNil;
    [archiver encodeNumber:nil forKey:@"testKey"];
    STAssertEquals([archiver.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    archiver = [BSONArchiver archiver];
    archiver.behaviorOnNil = BSONEncodeNullOnNil;
    [archiver encodeString:nil forKey:@"testKey"];
    STAssertEquals([archiver.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    archiver = [BSONArchiver archiver];
    archiver.behaviorOnNil = BSONEncodeNullOnNil;
    [archiver encodeSymbol:nil forKey:@"testKey"];
    STAssertEquals([archiver.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    archiver = [BSONArchiver archiver];
    archiver.behaviorOnNil = BSONEncodeNullOnNil;
    [archiver encodeDate:nil forKey:@"testKey"];
    STAssertEquals([archiver.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    archiver = [BSONArchiver archiver];
    archiver.behaviorOnNil = BSONEncodeNullOnNil;
    [archiver encodeImage:nil forKey:@"testKey"];
    STAssertEquals([archiver.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    archiver = [BSONArchiver archiver];
    archiver.behaviorOnNil = BSONEncodeNullOnNil;
    [archiver encodeRegularExpressionPattern:nil options:nil forKey:@"testKey"];
    STAssertEquals([archiver.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    archiver = [BSONArchiver archiver];
    archiver.behaviorOnNil = BSONEncodeNullOnNil;
    [archiver encodeRegularExpression:nil forKey:@"testKey"];
    STAssertEquals([archiver.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    archiver = [BSONArchiver archiver];
    archiver.behaviorOnNil = BSONEncodeNullOnNil;
    [archiver encodeCode:nil forKey:@"testKey"];
    STAssertEquals([archiver.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    archiver = [BSONArchiver archiver];
    archiver.behaviorOnNil = BSONEncodeNullOnNil;
    [archiver encodeCodeString:nil forKey:@"testKey"];
    STAssertEquals([archiver.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    archiver = [BSONArchiver archiver];
    archiver.behaviorOnNil = BSONEncodeNullOnNil;
    [archiver encodeCodeWithScope:nil forKey:@"testKey"];
    STAssertEquals([archiver.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    archiver = [BSONArchiver archiver];
    archiver.behaviorOnNil = BSONEncodeNullOnNil;
    [archiver encodeCodeString:nil withScope:nil forKey:@"testKey"];
    STAssertEquals([archiver.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    archiver = [BSONArchiver archiver];
    archiver.behaviorOnNil = BSONEncodeNullOnNil;
    [archiver encodeData:nil forKey:@"testKey"];
    STAssertEquals([archiver.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    archiver = [BSONArchiver archiver];
    archiver.behaviorOnNil = BSONEncodeNullOnNil;
    [archiver encodeTimestamp:nil forKey:@"testKey"];
    STAssertEquals([archiver.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
}

- (void) testEncodeCustomObjectWithRecursiveChildren {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    BSONArchiver *archiver = nil;
        
    Person *lucy = [[Person alloc] init];
    lucy.name = @"Lucy Ricardo";
    lucy.dob = [df dateFromString:@"1920-01-01"];
    lucy.numberOfVisits = 75;
    lucy.children = [NSMutableArray array];
    
    archiver = [BSONArchiver archiver];
    STAssertThrows([archiver encodeObject:lucy],
                   @"Should have called our bogus encodeWithCoder: and raised an exception, but didn't");

    lucy = [[PersonWithCoding alloc] init];
    lucy.name = @"Lucy Ricardo";
    lucy.dob = [df dateFromString:@"1920-01-01"];
    lucy.numberOfVisits = 75;
    lucy.children = [NSMutableArray array];

    PersonWithCoding *littleRicky = [[PersonWithCoding alloc] init];
    littleRicky.name = @"Ricky Ricardo, Jr.";
    littleRicky.dob = [df dateFromString:@"1953-01-19"];
    littleRicky.numberOfVisits = 15;
    
    [lucy.children addObject:littleRicky];
    
    archiver = [BSONArchiver archiver];
    STAssertThrows([archiver encodeObject:lucy],
                   @"Should have called our functional encodeWithCoder:, no exception");
    
    
}


@end
