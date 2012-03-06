//
//  ObjCBSONTests.m
//  ObjCBSONTests
//
//  Created by Paul Melnikow on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ObjCBSONTests.h"
#import "BSONEncoder.h"
#import "BSONDecoder.h"
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
    id exc = [NSException exceptionWithName:@"encodeWithCoder: was called"
                                   reason:@"encodeWithCoder: was called"
                                 userInfo:nil];
    @throw exc;
}
-(id)initWithCoder:(NSCoder *)coder {
    id exc = [NSException exceptionWithName:@"initWithCoder: was called"
                                   reason:@"initWithCoder: was called"
                                 userInfo:nil];
    @throw exc;
}
-(NSString *)description {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setTimeStyle:NSDateFormatterNoStyle];
    [df setDateStyle:NSDateFormatterShortStyle];
    
    NSMutableString *string = [NSMutableString stringWithFormat:@"<%@: %p>", [[self class] description], self];
    [string appendFormat:@"  name: %@", self.name];
    [string appendFormat:@"  dob: %@", [df stringFromDate:self.dob]];
    [string appendFormat:@"  numberOfVisits: %ld", (long)numberOfVisits];
    [string appendFormat:@"  children: %@", (long)children];
    return string;
}
-(BOOL)isEqual:(Person *) obj {
    if (![obj isKindOfClass:[Person class]]) return NO;
    return ((!self.name && !obj.name) || [self.name isEqualTo:obj.name])
    && ((!self.dob && !obj.dob) || [self.dob isEqualTo:obj.dob])
    && self.numberOfVisits == obj.numberOfVisits
    && ((!self.children && !obj.children) || [self.children isEqualTo:obj.children]);
}
@end
@interface PersonWithCoding : Person <NSCoding>
@end
@implementation PersonWithCoding
-(void)encodeWithCoder:(BSONEncoder *)coder {
    if (![coder isKindOfClass:[BSONEncoder class]]) {
        id exc = [NSException exceptionWithName:@"Needs a BSONEncoder"
                                       reason:@"Needs a BSONEncoder"
                                     userInfo:nil];
        @throw exc;
    }
    [coder encodeString:self.name forKey:@"name"];
    [coder encodeDate:self.dob forKey:@"dob"];
    [coder encodeInt64:self.numberOfVisits forKey:@"numberOfVisits"];
    [coder encodeArray:self.children forKey:@"children"];
}
-(id)initWithCoder:(BSONDecoder *)coder {
    if (![coder isKindOfClass:[BSONDecoder class]]) {
        id exc = [NSException exceptionWithName:@"Needs a BSONDecoder"
                                       reason:@"Needs a BSONDecoder"
                                     userInfo:nil];
        @throw exc;
    }
    if (self = [super init]) {
        self.name = [coder decodeStringForKey:@"name"];
        self.dob = [coder decodeDateForKey:@"dob"];
        self.numberOfVisits = [coder decodeInt64ForKey:@"numberOfVisits"];
        self.children = [[coder decodeArrayForKey:@"children"
                                        withClass:[PersonWithCoding class]] mutableCopy];
    }
    return self;
}
@end

@interface TestEncoderDelegate : NSObject <BSONEncoderDelegate>
@property (retain) NSMutableArray *encodedObjects;
@property (retain) NSMutableArray *encodedKeyPaths;
@property (assign) NSUInteger encodedNilKeyPath;
@property (assign) BOOL willFinish;
@property (assign) BOOL didFinish;
@end
@implementation TestEncoderDelegate
@synthesize encodedObjects, encodedKeyPaths, encodedNilKeyPath, willFinish, didFinish;
-(id)init {
    self.encodedObjects = [NSMutableArray array];
    self.encodedKeyPaths = [NSMutableArray array];
    return self;
}
-(void)encoder:(BSONEncoder *)encoder didEncodeObject:(id) obj forKeyPath:(NSString *) keyPath {
    [encodedObjects addObject:obj];
    if (keyPath)
        [encodedKeyPaths addObject:keyPath];
    else
        self.encodedNilKeyPath = self.encodedNilKeyPath + 1;
}
- (void)encoderWillFinish:(BSONEncoder *)encoder {
    if (self.willFinish) {
        id exc = [NSException exceptionWithName:@"-encoderWillFinish: called more than once"
                                         reason:@"-encoderWillFinish: called more than once"
                                       userInfo:nil];
        @throw exc;
    }
    self.willFinish = YES;
}
- (void)encoderDidFinish:(BSONEncoder *)encoder {
    if (!self.willFinish) {
        id exc = [NSException exceptionWithName:@"-encoderDidFinish: called without -encoderWillFinish:"
                                         reason:@"-encoderDidFinish: called without -encoderWillFinish:"
                                       userInfo:nil];
        @throw exc;
    }
    if (self.didFinish) {
        id exc = [NSException exceptionWithName:@"-encoderDidFinish: called more than once"
                                         reason:@"-encoderDidFinish: called more than once"
                                       userInfo:nil];
        @throw exc;        
    }
    self.didFinish = YES;
}
- (BOOL) encoder:(BSONEncoder *) encoder shouldEncodeObject:(id) obj forKeyPath:(NSString *) keyPath {
    if ([obj isKindOfClass:[NSDate class]])
        return NO;
    else
        return YES;
}
@end

@implementation ObjCBSONTests
@synthesize df;

- (void)setUp
{
    [super setUp];
    self.df = [[NSDateFormatter alloc] init];
    [self.df setLenient:YES];
    [self.df setTimeStyle:NSDateFormatterNoStyle];
    [self.df setDateStyle:NSDateFormatterShortStyle];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testInvalidMongoDBKeys {
    BSONEncoder *encoder = nil;
    
    NSDictionary *sample = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:1], @"one",
                            [NSNumber numberWithDouble:2.0], @"two",
                            @"3", @"three",
                            [NSArray arrayWithObjects:@"zero", @"one", @"two", @"three", nil], @"four",
                            nil];
    
    encoder = [[BSONEncoder alloc] init];
    
    STAssertThrowsSpecificNamed([sample encodeWithCoder:encoder],
                                NSException,
                                NSInvalidArgumentException,
                                @"Default dictionary encodeWithCoder produces invalid MongoDB keys, but exception wasn't raised");
    
    NSDictionary *badSample1 = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"pickles", @"this.is.a.bad.key",
                                nil];
    encoder = [[BSONEncoder alloc] init];
    STAssertThrowsSpecificNamed([encoder encodeDictionary:badSample1],
                                NSException,
                                NSInvalidArgumentException,
                                @"Exception wasn't raised for invalid MongoDB key containing '.'");
    
    encoder = [[BSONEncoder alloc] init];
    encoder.restrictsKeyNamesForMongoDB = NO;
    STAssertNoThrowSpecificNamed([encoder encodeDictionary:badSample1],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"MongoDB checking disabled, but exception was still raised for invalid key");

    
    NSDictionary *badSample2 = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"pickles", @"bad$key",
                                nil];
    encoder = [[BSONEncoder alloc] init];
    STAssertThrowsSpecificNamed([encoder encodeDictionary:badSample2],
                                NSException,
                                NSInvalidArgumentException,
                                @"Exception wasn't raised for invalid MongoDB key containing '$'");
    
    encoder = [[BSONEncoder alloc] init];
    encoder.restrictsKeyNamesForMongoDB = NO;
    STAssertNoThrowSpecificNamed([encoder encodeDictionary:badSample2],
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
    
    BSONEncoder *encoder1 = [[BSONEncoder alloc] init];
    [encoder1 encodeDictionary:sample];

    BSONEncoder *encoder2 = [[BSONEncoder alloc] init];
    [encoder2 encodeDictionary:sample];
    
    STAssertEqualObjects([[encoder1 BSONDocument] dataValue],
                         [[encoder2 BSONDocument] dataValue],
                         @"Encoded same dictionary but got different data values.");

    STAssertEqualObjects([encoder1 BSONDocument],
                         [encoder2 BSONDocument],
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
    
    BSONEncoder *encoder1 = [[BSONEncoder alloc] init];
    [encoder1 encodeDictionary:sample1];
    
    BSONEncoder *encoder2 = [[BSONEncoder alloc] init];
    [encoder2 encodeDictionary:sample2];
        
    STAssertFalse([[encoder1 BSONDocument] isEqualTo:[encoder2 BSONDocument]],
                  @"Documents had different data and should not be equal");    
}

- (void) testEncodeAfterFinishedEncoding {
    NSDictionary *sample1 = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInt:1], @"one",
                             [NSNumber numberWithDouble:2.0], @"two",
                             @"3", @"three",
                             [NSArray arrayWithObjects:@"zero", @"one", @"two", @"three", nil], @"four",
                             nil];

    BSONEncoder *encoder = [[BSONEncoder alloc] init];
    [encoder encodeDictionary:sample1];
    [encoder BSONDocument];
    NSLog(@"hey");
    STAssertThrowsSpecificNamed([encoder encodeBool:NO forKey:@"testKey"],
                                NSException,
                                NSInvalidArchiveOperationException,
                                @"Attempted encoding after finishEncoding but didn't throw exception");
}

- (void) testEncodeNilKeys {
    BSONEncoder *encoder = [[BSONEncoder alloc] init];
    NSString *reason = @"Nil key should throw an exception";
    STAssertThrows([encoder encodeObject:@"test" forKey:nil], reason);
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"asdf", @"asdf", nil];
    STAssertThrows([encoder encodeDictionary:dict forKey:nil], reason);
    STAssertThrows([encoder encodeArray:[NSArray arrayWithObject:@"test"] forKey:nil], reason);
    STAssertThrows([encoder encodeBSONDocument:[[BSONDocument alloc] init] forKey:nil], reason);
    STAssertThrows([encoder encodeNullForKey:nil], reason);
    STAssertThrows([encoder encodeUndefinedForKey:nil], reason);
    STAssertThrows([encoder encodeObjectID:[[BSONObjectID alloc] init] forKey:nil], reason);
    STAssertThrows([encoder encodeInt:1 forKey:nil], reason);
    STAssertThrows([encoder encodeInt64:1 forKey:nil], reason);
    STAssertThrows([encoder encodeBool:YES forKey:nil], reason);
    STAssertThrows([encoder encodeDouble:3.25 forKey:nil], reason);
    STAssertThrows([encoder encodeNumber:[NSNumber numberWithInt:3] forKey:nil], reason);
    STAssertThrows([encoder encodeString:@"test" forKey:nil], reason);
    STAssertThrows([encoder encodeSymbol:[BSONSymbol symbol:@"test"] forKey:nil], reason);
    STAssertThrows([encoder encodeDate:[NSDate date] forKey:nil], reason);
    STAssertThrows([encoder encodeImage:[NSImage imageNamed:NSImageNameBonjour] forKey:nil], reason);
    STAssertThrows([encoder encodeRegularExpressionPattern:@"test" options:@"test" forKey:nil], reason);
    STAssertThrows([encoder encodeRegularExpression:[BSONRegularExpression regularExpressionWithPattern:@"test" options:@"test"]
                                              forKey:nil], reason);
    STAssertThrows([encoder encodeCode:[BSONCode code:@"test"] forKey:nil], reason);
    STAssertThrows([encoder encodeCodeString:@"test" forKey:nil], reason);
    STAssertThrows([encoder encodeCodeWithScope:[BSONCodeWithScope code:@"test" withScope:[[BSONDocument alloc] init]]
                                          forKey:nil], reason);
    STAssertThrows([encoder encodeCodeString:@"test" withScope:[[BSONDocument alloc] init]
                                          forKey:nil], reason);
    STAssertThrows([encoder encodeData:[NSData data] forKey:nil], reason);
    STAssertThrows([encoder encodeTimestamp:[BSONTimestamp timestampWithIncrement:10 timeInSeconds:10]
                                      forKey:nil], reason);
}

- (void) testEncodeNilValues {
    BSONEncoder *encoder = [[BSONEncoder alloc] init];
    
    NSString *reason = nil;
    
    reason = @"Half-nil values should throw an exception";
    STAssertThrows([encoder encodeRegularExpressionPattern:nil options:@"test" forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeRegularExpressionPattern:@"test" options:nil forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeCodeString:nil withScope:[[BSONDocument alloc] init] forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeCodeString:@"test" withScope:nil forKey:@"testKey"], reason);
    
    reason = @"With default behavior DoNothingOnNil, no exception should be raised for nil values";
    STAssertNoThrow([encoder encodeObject:nil forKey:@"testKey"], reason);
    STAssertNoThrow([encoder encodeDictionary:nil forKey:@"testKey"], reason);
    STAssertNoThrow([encoder encodeArray:nil forKey:@"testKey"], reason);
    STAssertNoThrow([encoder encodeBSONDocument:nil forKey:@"testKey"], reason);
    STAssertNoThrow([encoder encodeObjectID:nil forKey:@"testKey"], reason);
    STAssertNoThrow([encoder encodeNumber:nil forKey:@"testKey"], reason);
    STAssertNoThrow([encoder encodeString:nil forKey:@"testKey"], reason);
    STAssertNoThrow([encoder encodeSymbol:nil forKey:@"testKey"], reason);
    STAssertNoThrow([encoder encodeDate:nil forKey:@"testKey"], reason);
    STAssertNoThrow([encoder encodeImage:nil forKey:@"testKey"], reason);
    STAssertNoThrow([encoder encodeRegularExpression:nil forKey:@"testKey"], reason);
    STAssertNoThrow([encoder encodeCode:nil forKey:@"testKey"], reason);
    STAssertNoThrow([encoder encodeCodeString:nil forKey:@"testKey"], reason);
    STAssertNoThrow([encoder encodeCodeWithScope:nil forKey:@"testKey"], reason);
    STAssertNoThrow([encoder encodeData:nil forKey:@"testKey"], reason);
    STAssertNoThrow([encoder encodeTimestamp:nil forKey:@"testKey"], reason);
    
    STAssertEqualObjects([encoder BSONDocument],
                         [[BSONDocument alloc] init],
                         @"With default behavior, encoding nil values should result in an empty document");
    
    encoder = [[BSONEncoder alloc] init];
    
    reason = @"Zero value on primitive types should not throw an exception";
    STAssertNoThrow([encoder encodeInt:0 forKey:@"testKey"], reason);
    STAssertNoThrow([encoder encodeInt64:0 forKey:@"testKey"], reason);
    STAssertNoThrow([encoder encodeDouble:0 forKey:@"testKey"], reason);
    STAssertNoThrow([encoder encodeBool:NO forKey:@"testKey"], reason);
    
    STAssertFalse([[encoder BSONDocument] isEqualTo:[[BSONDocument alloc] init]],
                         @"With default behavior, encoding zero-value primitives should fill up the document");
    
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONRaiseExceptionOnNil;
    
    reason = @"Half-nil values should throw an exception";
    STAssertThrows([encoder encodeRegularExpressionPattern:nil options:@"test" forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeRegularExpressionPattern:@"test" options:nil forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeCodeString:nil withScope:[[BSONDocument alloc] init] forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeCodeString:@"test" withScope:nil forKey:@"testKey"], reason);
 
    reason = @"Nil value should throw an exception";
    STAssertThrows([encoder encodeObject:nil forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeDictionary:nil forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeArray:nil forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeBSONDocument:nil forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeObjectID:nil forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeNumber:nil forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeString:nil forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeSymbol:nil forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeDate:nil forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeImage:nil forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeRegularExpressionPattern:nil options:@"test" forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeRegularExpressionPattern:@"test" options:nil forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeRegularExpression:nil forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeCode:nil forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeCodeString:nil forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeCodeWithScope:nil forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeCodeString:nil withScope:[[BSONDocument alloc] init] forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeCodeString:@"test" withScope:nil forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeData:nil forKey:@"testKey"], reason);
    STAssertThrows([encoder encodeTimestamp:nil forKey:@"testKey"], reason);
    
    reason = @"Zero value on primitive types should not throw an exception";
    STAssertNoThrow([encoder encodeInt:0 forKey:@"testKey"], reason);
    STAssertNoThrow([encoder encodeInt64:0 forKey:@"testKey"], reason);
    STAssertNoThrow([encoder encodeDouble:0 forKey:@"testKey"], reason);
    STAssertNoThrow([encoder encodeBool:NO forKey:@"testKey"], reason);
    
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    
    // FIXME test encoding of nil as null
    [encoder encodeObject:nil forKey:@"testKey"];
    reason = @"Inserted nil and should have encoded null, but did not";
    STAssertEquals([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    STAssertThrows([encoder encodeDictionary:nil forKey:@"testKey"], @"Encoding finished");
    
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeDictionary:nil forKey:@"testKey"];
    STAssertEquals([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeArray:nil forKey:@"testKey"];
    STAssertEquals([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);

    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeBSONDocument:nil forKey:@"testKey"];
    STAssertEquals([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeObjectID:nil forKey:@"testKey"];
    STAssertEquals([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeNumber:nil forKey:@"testKey"];
    STAssertEquals([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeString:nil forKey:@"testKey"];
    STAssertEquals([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeSymbol:nil forKey:@"testKey"];
    STAssertEquals([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeDate:nil forKey:@"testKey"];
    STAssertEquals([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeImage:nil forKey:@"testKey"];
    STAssertEquals([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeRegularExpressionPattern:nil options:nil forKey:@"testKey"];
    STAssertEquals([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeRegularExpression:nil forKey:@"testKey"];
    STAssertEquals([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeCode:nil forKey:@"testKey"];
    STAssertEquals([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeCodeString:nil forKey:@"testKey"];
    STAssertEquals([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeCodeWithScope:nil forKey:@"testKey"];
    STAssertEquals([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeCodeString:nil withScope:nil forKey:@"testKey"];
    STAssertEquals([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeData:nil forKey:@"testKey"];
    STAssertEquals([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
    
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeTimestamp:nil forKey:@"testKey"];
    STAssertEquals([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null], reason);
}

- (void) testEncodeCustomObjectWithRecursiveChildren {
    BSONEncoder *encoder = nil;
    
    Person *lucy = [[Person alloc] init];
    lucy.name = @"Lucy Ricardo";
    lucy.dob = [self.df dateFromString:@"Jan 1, 1920"];
    lucy.numberOfVisits = 75;
    lucy.children = [NSMutableArray array];
    
    encoder = [[BSONEncoder alloc] init];
    STAssertThrows([encoder encodeObject:lucy],
                   @"Should have called our bogus encodeWithCoder: and raised an exception, but didn't");

    lucy = [[PersonWithCoding alloc] init];
    lucy.name = @"Lucy Ricardo";
    lucy.dob = [self.df dateFromString:@"Jan 1, 1920"];
    lucy.numberOfVisits = 75;
    lucy.children = [NSMutableArray array];

    PersonWithCoding *littleRicky = [[PersonWithCoding alloc] init];
    littleRicky.name = @"Ricky Ricardo, Jr.";
    littleRicky.dob = [self.df dateFromString:@"Jan 19, 1953"];
    littleRicky.numberOfVisits = 15;
    littleRicky.children = [NSMutableArray array];
        
    PersonWithCoding *littlerRicky = [[PersonWithCoding alloc] init];
    littlerRicky.name = @"Ricky Ricardo III";
    littlerRicky.dob = [self.df dateFromString:@"Jan 19, 1975"];
    littlerRicky.numberOfVisits = 1;
    
    [lucy.children addObject:littleRicky];
    [littleRicky.children addObject:littlerRicky];
    
    encoder = [[BSONEncoder alloc] init];
    STAssertNoThrow([encoder encodeObject:lucy],
                   @"Should have called our functional encodeWithCoder:, no exception");
    
    BSONDecoder *decoder = nil;
    decoder = [[BSONDecoder alloc] initWithDocument:encoder.BSONDocument];
    PersonWithCoding *lucy2 = [[PersonWithCoding alloc] initWithCoder:decoder];
    
    STAssertEqualObjects(lucy, lucy2, @"Encoded and decoded objects should be the same");
}

- (void)testDelegate {
    NSDictionary *sample = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:1], @"one",
                            [NSNumber numberWithDouble:2.0], @"two",
                            @"3", @"three",
                            [NSArray arrayWithObjects:@"zero", @"one", @"two", @"three", nil], @"four",
                            nil];
    
    NSMutableSet *allEncodedObjects = [NSMutableSet set];
    [allEncodedObjects addObjectsFromArray:[[sample objectForKey:@"four"] allObjects]];
    [allEncodedObjects addObjectsFromArray:[sample objectsForKeys:[sample allKeys] notFoundMarker:[NSNull null]]];
    [allEncodedObjects addObject:sample];
    
    NSMutableSet *allEncodedKeyPaths = [NSMutableSet set];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObject:@"one"]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObject:@"two"]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObject:@"three"]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObject:@"four"]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObjects:@"four", @"0", nil]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObjects:@"four", @"1", nil]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObjects:@"four", @"2", nil]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObjects:@"four", @"3", nil]];

    TestEncoderDelegate *delegate = [[TestEncoderDelegate alloc] init];
    BSONEncoder *encoder1 = [[BSONEncoder alloc] init];
    encoder1.delegate = delegate;
    [encoder1 encodeDictionary:sample];
    
    NSSet *delegateEncodedObjectsSet = [NSSet setWithArray:delegate.encodedObjects];
    STAssertEquals([delegateEncodedObjectsSet count],
                   [delegate.encodedObjects count],
                    @"Duplicate object notifications received");
    
    STAssertEqualObjects(delegateEncodedObjectsSet,
                         allEncodedObjects,
                         @"Delegate did not receive notification for all encoded objects");
    
    NSSet *delegateEncodeKeyPathsSet = [NSSet setWithArray:delegate.encodedKeyPaths];
    STAssertEquals([delegateEncodeKeyPathsSet count],
                   [delegate.encodedKeyPaths count],
                   @"Duplicate key path notifications received");
    
    STAssertEquals([delegateEncodeKeyPathsSet count],
                   [allEncodedKeyPaths count],
                   @"Delegate did not receive notification for all encoded key paths");
    
    NSMutableSet *missingObjects = [allEncodedKeyPaths mutableCopy];
    [missingObjects minusSet:delegateEncodeKeyPathsSet];
    
    STAssertEquals([missingObjects count],
                   (NSUInteger)0,
                   @"Delegate did not receive notification for all encoded key paths");
    
    NSMutableSet *unexpectedObjects = [delegateEncodeKeyPathsSet mutableCopy];
    [unexpectedObjects minusSet:allEncodedKeyPaths];
    
    STAssertEquals([missingObjects count],
                   (NSUInteger)0,
                   @"Delegate received notification for unexpected key paths");
    
    STAssertEquals(delegate.encodedNilKeyPath,
                   (NSUInteger)1,
                   @"Delegate did not receive exactly one notification for nil key path");
    
    
    
    STAssertFalse(delegate.willFinish, @"Delegate received -encoderWillFinish before encoding finished");
    STAssertFalse(delegate.didFinish, @"Delegate received -encoderDidFinish before encoding finished");
        
    BSONDocument *document = encoder1.BSONDocument;
    BSONDocument *document2 = encoder1.BSONDocument;
    document = nil;
    document2 = nil;

    STAssertTrue(delegate.willFinish, @"Delegate did not receive -encoderWillFinish");
    STAssertTrue(delegate.didFinish, @"Delegate did not receive -encoderDidFinish");
    
    
    
    PersonWithCoding *lucy = [[PersonWithCoding alloc] init];
    lucy.name = @"Lucy Ricardo";
    lucy.dob = [self.df dateFromString:@"Jan 1, 1920"];
    lucy.numberOfVisits = 75;
    lucy.children = [NSMutableArray array];
    
    PersonWithCoding *littleRicky = [[PersonWithCoding alloc] init];
    littleRicky.name = @"Ricky Ricardo, Jr.";
    littleRicky.dob = [self.df dateFromString:@"Jan 19, 1953"];
    littleRicky.numberOfVisits = 15;
    littleRicky.children = [NSMutableArray array];
    
    PersonWithCoding *littlerRicky = [[PersonWithCoding alloc] init];
    littlerRicky.name = @"Ricky Ricardo III";
    littlerRicky.dob = [self.df dateFromString:@"Jan 19, 1975"];
    littlerRicky.numberOfVisits = 1;
    
    [lucy.children addObject:littleRicky];
    [littleRicky.children addObject:littlerRicky];
    
    allEncodedObjects = [NSSet setWithObjects:
                                lucy, lucy.name, lucy.dob, lucy.children,
                                littleRicky, littleRicky.name, littleRicky.dob, littleRicky.children,
                                littlerRicky, littlerRicky.name, littlerRicky.dob,
                                nil];
        
    delegate = [[TestEncoderDelegate alloc] init];
    encoder1 = [[BSONEncoder alloc] init];
    encoder1.delegate = delegate;
    [encoder1 encodeObject:lucy];
    
    delegateEncodedObjectsSet = [NSSet setWithArray:delegate.encodedObjects];
    STAssertEquals([delegateEncodedObjectsSet count],
                   [delegate.encodedObjects count],
                   @"Duplicate notifications received");
        
    missingObjects = [allEncodedObjects mutableCopy];
    [missingObjects minusSet:delegateEncodedObjectsSet];
    
    unexpectedObjects = [delegateEncodedObjectsSet mutableCopy];
    [unexpectedObjects minusSet:allEncodedObjects];
    
    STAssertEquals([missingObjects count],
                   (NSUInteger)0,
                   @"Delegate did not receive notification for all encoded objects");
    
    STAssertEquals([unexpectedObjects count],
                   (NSUInteger)0,
                   @"Delegate received notification for unexpected objects");
    
    STAssertEquals(delegate.encodedNilKeyPath,
                   (NSUInteger)1,
                   @"Delegate did not receive exactly one notification for nil key path");
    
    delegateEncodeKeyPathsSet = [NSSet setWithArray:delegate.encodedKeyPaths];
    STAssertEquals([delegateEncodeKeyPathsSet count],
                   [delegate.encodedKeyPaths count],
                   @"Duplicate notifications received");
    
    allEncodedKeyPaths = [NSMutableSet set];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObject:@"name"]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObject:@"dob"]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObject:@"children"]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObjects:@"children", @"0", nil]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObjects:@"children", @"0", @"name", nil]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObjects:@"children", @"0", @"dob", nil]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObjects:@"children", @"0", @"children", nil]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObjects:@"children", @"0", @"children", @"0", nil]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObjects:@"children", @"0", @"children", @"0", @"name", nil]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObjects:@"children", @"0", @"children", @"0", @"dob", nil]];
    
    missingObjects = [allEncodedKeyPaths mutableCopy];
    [missingObjects minusSet:delegateEncodeKeyPathsSet];
    
    STAssertEquals([missingObjects count],
                   (NSUInteger)0,
                   @"Delegate did not receive notification for all encoded key paths");
    
    unexpectedObjects = [delegateEncodeKeyPathsSet mutableCopy];
    [unexpectedObjects minusSet:allEncodedKeyPaths];
    
    STAssertEquals([missingObjects count],
                   (NSUInteger)0,
                   @"Delegate received notification for unexpected key paths");
}

@end