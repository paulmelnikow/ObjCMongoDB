 //
//  ObjCBSONTests.m
//  ObjCBSONTests
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

#import "ObjCBSONTests.h"
#import "BSONEncoder.h"
#import "BSONDecoder.h"
#import "BSONDocument.h"
#import "BSONTypes.h"
#import "BSONCoding.h"

@interface Person : NSObject
@property (retain) NSString * name;
@property (retain) NSDate * dob;
@property (assign) NSInteger numberOfVisits;
@property (retain) NSMutableArray * children;
@property (retain) Person * parent;
@property (assign) BOOL awakeAfterCoder;
@end
@implementation Person
@synthesize name, dob, numberOfVisits, children, parent, awakeAfterCoder;
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
    [string appendFormat:@"  parent: %@", parent];
    [string appendFormat:@"  children: %@", children];
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
@interface PersonWithCoding : Person <NSCoding, BSONCoding>
@property (retain) BSONObjectID *BSONObjectID;
@end
@implementation PersonWithCoding
@synthesize BSONObjectID;

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
    [coder encodeObject:self.parent forKey:@"parent"];
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
        self.parent = [coder decodeObjectForKey:@"parent" withClass:[PersonWithCoding class]];
    }
    return self;
}

-(id)awakeAfterUsingCoder:(NSCoder *)aDecoder {
    if (self.awakeAfterCoder) {
        id exc = [NSException exceptionWithName:@"awakeAfterUsingCoder: was called more than once"
                                         reason:@"awakeAfterUsingCoder: was called more than once"
                                       userInfo:nil];
        @throw exc;
    }
    self.awakeAfterCoder = YES;
    return self;
}

@end

@interface PersonWithBriefCoding : PersonWithCoding
@end
@implementation PersonWithBriefCoding

- (id) replacementObjectForCoder:(BSONEncoder *) encoder {
    // Encode the name only, unless encoding at the top level
    if (encoder.keyPathComponents.count)
        return self.name;
    else
        return self;
}

@end

@interface PersonWithBriefCoding2 : PersonWithCoding
@end
@implementation PersonWithBriefCoding2

- (id) replacementObjectForBSONEncoder:(BSONEncoder *) encoder {
    // Encode the name only, unless encoding at the top level
    if (encoder.keyPathComponents.count)
        return self.name;
    else
        return self;
}

@end

@interface TestEncoderDelegate : NSObject <BSONEncoderDelegate>
@property (retain) NSMutableArray *encodedObjects;
@property (retain) NSMutableArray *willEncodeKeyPaths;
@property (retain) NSMutableArray *encodedKeyPaths;
@property (assign) NSUInteger encodedNilKeyPath;
@property (assign) BOOL willFinish;
@property (assign) BOOL didFinish;
@end
@implementation TestEncoderDelegate
@synthesize encodedObjects, willEncodeKeyPaths, encodedKeyPaths, encodedNilKeyPath, willFinish, didFinish;

-(id)init {
    self.encodedObjects = [NSMutableArray array];
    self.willEncodeKeyPaths = [NSMutableArray array];
    self.encodedKeyPaths = [NSMutableArray array];
    return self;
}

-(void)encoder:(BSONEncoder *)encoder didEncodeObject:(id) obj forKeyPath:(NSString *) keyPathComponents {
    [encodedObjects addObject:obj];
    if (keyPathComponents)
        [encodedKeyPaths addObject:keyPathComponents];
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

-(id)encoder:(BSONEncoder *)encoder willEncodeObject:(id)obj forKeyPath:(NSArray *)keyPathComponents {
    if (keyPathComponents) [willEncodeKeyPaths addObject:keyPathComponents];
    return obj;
}

@end

@interface TestEncoderDelegateRedactDates : TestEncoderDelegate
+(NSString *)redactedDate;
@property (retain) NSMutableArray *replacedObjects;
@property (retain) NSMutableArray *replacedKeyPaths;
@end
@implementation TestEncoderDelegateRedactDates
@synthesize replacedObjects, replacedKeyPaths;

-(id)init {
    if (self = [super init]) {
        self.replacedObjects = [NSMutableArray array];
        self.replacedKeyPaths = [NSMutableArray array];
    }
    return self;
}

+(NSString *)redactedDate {
    static NSString *singleton;
    if (!singleton)
        singleton = @"--redacted!--";
    return singleton;
}

-(void)encoder:(BSONEncoder *)encoder willReplaceObject:(id) obj withObject:(id) replacementObj forKeyPath:(NSArray *)keyPathComponents {
    [self.replacedObjects addObject:obj];
    [self.replacedKeyPaths addObject:keyPathComponents];
}

-(id)encoder:(BSONEncoder *)encoder willEncodeObject:(id)obj forKeyPath:(NSArray *)keyPathComponents {
    [super encoder:encoder willEncodeObject:obj forKeyPath:keyPathComponents];
    if ([obj isKindOfClass:[NSDate class]])
        return [TestEncoderDelegateRedactDates redactedDate];
    else
        return obj;
}

@end

@interface EncodesObjectIDForChildren : TestEncoderDelegate
@end
@implementation EncodesObjectIDForChildren

-(BOOL)encoder:(BSONEncoder *)encoder shouldSubstituteObjectIDForObject:(id)obj forKeyPath:(NSArray *)keyPathComponents {
    return [obj isKindOfClass:[PersonWithCoding class]];
}

@end

@interface EncodesParentByReferenceDelegate : NSObject <BSONEncoderDelegate>
@end

@implementation EncodesParentByReferenceDelegate

-(id)encoder:(BSONEncoder *)encoder willEncodeObject:(Person *)obj forKeyPath:(NSArray *)keyPathComponents {
    if ([obj isKindOfClass:[Person class]] && [[keyPathComponents lastObject] isEqualToString:@"parent"])
        return [obj name];
    else
        return obj;
}

@end

@interface TestDecoderDelegate : NSObject <BSONDecoderDelegate>
@property (retain) NSMutableArray *decodedObjects;
@property (retain) NSMutableArray *decodedKeyPaths;
@property (assign) NSUInteger decodedNilKeyPath;
@property (retain) NSMutableArray *replacedObjects;
@property (assign) BOOL willFinish;
@property (assign) BOOL didFinish;
@end
@implementation TestDecoderDelegate
@synthesize decodedObjects, decodedKeyPaths, decodedNilKeyPath, replacedObjects, willFinish, didFinish;

-(id)init {
    self.decodedObjects = [NSMutableArray array];
    self.decodedKeyPaths = [NSMutableArray array];
    self.replacedObjects = [NSMutableArray array];
    return self;
}
-(id)decoder:(BSONDecoder *)decoder didDecodeObject:(id) object forKeyPath:(NSArray *) keyPathComponents {
    [decodedObjects addObject:object];
    if (keyPathComponents)
        [decodedKeyPaths addObject:keyPathComponents];
    else
        self.decodedNilKeyPath = self.decodedNilKeyPath + 1;
    return object;
}
-(void)decoder:(BSONDecoder *)decoder willReplaceObject:(id)object withObject:(id)newObject forKeyPath:(NSArray *)keyPathComponents {
    [replacedObjects addObject:object];
}
-(void)decoderWillFinish:(BSONDecoder *)decoder {
    if (self.willFinish) {
        id exc = [NSException exceptionWithName:@"-decoderWillFinish: called more than once"
                                         reason:@"-decoderWillFinish: called more than once"
                                       userInfo:nil];
        @throw exc;
    }
    self.willFinish = YES;
}

@end

@interface TranslatingTestDecoderDelegate : TestDecoderDelegate
@end
@implementation TranslatingTestDecoderDelegate

-(id)decoder:(BSONDecoder *)decoder didDecodeObject:(id)object forKeyPath:(NSArray *)keyPathComponents {
    [super decoder:decoder didDecodeObject:object forKeyPath:keyPathComponents];
    if ([object isEqualTo:@"one"])
        return @"uno";
    else if ([object isEqualTo:@"two"])
        return @"dos";
    else if ([object isEqualTo:@"three"])
        return @"tres";
    else if ([object isEqualTo:@"four"])
        return @"quattro";
    else if ([object isEqualTo:@"five"])
        return @"cinco";
    else if ([object isEqualTo:@"six"])
        return @"seis";
    else if ([object isEqualTo:@"seven"])
        return @"siete";
    else if ([object isEqualTo:@"eight"])
        return @"ocho";
    else if ([object isEqualTo:@"nine"])
        return @"nueve";
    else
        return object;
}
@end



@implementation ObjCBSONTests
@synthesize df;

+ (NSCountedSet *) missingValuesInResultSet:(NSCountedSet *) one expectedSet:(NSCountedSet *) two {
    if (!one && !two) return [NSCountedSet set];
    
    NSCountedSet *intersection = [one copy];
    [intersection intersectSet:two];
    
//    NSCountedSet *oneOnly = [one copy];
//    [oneOnly minusSet:intersection];
    
    NSCountedSet *twoOnly = [two copy];
    [twoOnly minusSet:intersection];
    
    return twoOnly;
}

+ (NSCountedSet *) unexpectedValuesInResultSet:(NSCountedSet *) one expectedSet:(NSCountedSet *) two {
    if (!one && !two) return [NSCountedSet set];
    
    NSCountedSet *intersection = [one copy];
    [intersection intersectSet:two];
    
    NSCountedSet *oneOnly = [one copy];
    [oneOnly minusSet:intersection];
    
//    NSCountedSet *twoOnly = [two copy];
//    [twoOnly minusSet:intersection];
    
    return oneOnly;
}

- (void) assertResultSet:(NSCountedSet *) one isEqualToExpectedSet:(NSCountedSet *) two name:(NSString *) name {
    if (!one && !two) return;
    
    NSCountedSet *intersection = [one copy];
    [intersection intersectSet:two];
    
    NSCountedSet *oneOnly = [one copy];
    [oneOnly minusSet:intersection];
    
    NSCountedSet *twoOnly = [two copy];
    [twoOnly minusSet:intersection];
    
    STAssertEquals(twoOnly.count,
                   (NSUInteger)0,
                   @"Expected %@ missing from result", name);
    STAssertEquals(oneOnly.count,
                   (NSUInteger)0,
                   @"Unexpected %@ found in result", name);    
}

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
    PersonWithCoding *lucy2 = [decoder decodeObjectWithClass:[PersonWithCoding class]];
    
    STAssertEqualObjects(lucy, lucy2, @"Encoded and decoded objects should be the same");
}

- (void)testDelegate1 {
    NSCountedSet *resultSet, *missing, *unexpected;

    NSDictionary *sample = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:1], @"one",
                            [NSNumber numberWithDouble:2.0], @"two",
                            @"3", @"three",
                            [NSArray arrayWithObjects:@"zero", @"one", @"two", @"three", nil], @"four",
                            nil];
    
    NSCountedSet *allEncodedObjects = [NSCountedSet set];
    [allEncodedObjects addObjectsFromArray:[[sample objectForKey:@"four"] allObjects]];
    [allEncodedObjects addObjectsFromArray:[sample objectsForKeys:[sample allKeys] notFoundMarker:[NSNull null]]];
    [allEncodedObjects addObject:sample];
    
    NSCountedSet *allEncodedKeyPaths = [NSCountedSet set];
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
    
    resultSet = [NSCountedSet setWithArray:delegate.encodedObjects];
    missing = [ObjCBSONTests missingValuesInResultSet:resultSet expectedSet:allEncodedObjects];
    unexpected = [ObjCBSONTests unexpectedValuesInResultSet:resultSet expectedSet:allEncodedObjects];
    
    STAssertEquals(missing.count, (NSUInteger)0, @"Missing objects in result set");
    STAssertEquals(unexpected.count, (NSUInteger)0, @"Unexpected objects in result set");
    
    resultSet = [NSCountedSet setWithArray:delegate.encodedKeyPaths];
    missing = [ObjCBSONTests missingValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    unexpected = [ObjCBSONTests unexpectedValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    
    STAssertEquals(missing.count, (NSUInteger)0, @"Missing key paths in result set");
    STAssertEquals(unexpected.count, (NSUInteger)0, @"Unexpected key paths in result set");

    STAssertEquals(delegate.encodedNilKeyPath,
                   (NSUInteger)1,
                   @"Delegate did not receive exactly one notification for nil key path");
    
    STAssertFalse(delegate.willFinish, @"Delegate received -encoderWillFinish before encoding finished");
    STAssertFalse(delegate.didFinish, @"Delegate received -encoderDidFinish before encoding finished");
    
    // Do this twice; the delegate throws an exception if it receives two sets of notifications
    BSONDocument *document = encoder1.BSONDocument;
    BSONDocument *document2 = encoder1.BSONDocument;
    document = nil;
    document2 = nil;

    STAssertTrue(delegate.willFinish, @"Delegate did not receive -encoderWillFinish");
    STAssertTrue(delegate.didFinish, @"Delegate did not receive -encoderDidFinish");
}

- (void)testDelegate2 {
    NSCountedSet *resultSet, *missing, *unexpected;
    
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
    
    NSCountedSet *allEncodedObjects = [NSCountedSet setWithObjects:
                                lucy, lucy.name, lucy.dob, lucy.children,
                                littleRicky, littleRicky.name, littleRicky.dob, littleRicky.children,
                                littlerRicky, littlerRicky.name, littlerRicky.dob,
                                nil];
    
    NSCountedSet *allEncodedKeyPaths = [NSCountedSet set];
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
        
    TestEncoderDelegate *delegate = [[TestEncoderDelegate alloc] init];
    BSONEncoder *encoder1 = [[BSONEncoder alloc] init];
    encoder1.delegate = delegate;
    [encoder1 encodeObject:lucy];
        
    resultSet = [NSCountedSet setWithArray:delegate.encodedObjects];
    missing = [ObjCBSONTests missingValuesInResultSet:resultSet expectedSet:allEncodedObjects];
    unexpected = [ObjCBSONTests unexpectedValuesInResultSet:resultSet expectedSet:allEncodedObjects];
    
    STAssertEquals(missing.count, (NSUInteger)0, @"Missing objects in result set");
    STAssertEquals(unexpected.count, (NSUInteger)0, @"Unexpected objects in result set");
    
    STAssertEquals(delegate.encodedNilKeyPath,
                   (NSUInteger)1,
                   @"Delegate did not receive exactly one notification for nil key path");
        
    resultSet = [NSCountedSet setWithArray:delegate.encodedKeyPaths];
    missing = [ObjCBSONTests missingValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    unexpected = [ObjCBSONTests unexpectedValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    
    STAssertEquals(missing.count, (NSUInteger)0, @"Missing key paths in result set");
    STAssertEquals(unexpected.count, (NSUInteger)0, @"Unexpected key paths in result set");
    
    resultSet = [NSCountedSet setWithArray:delegate.willEncodeKeyPaths];
    missing = [ObjCBSONTests missingValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    unexpected = [ObjCBSONTests unexpectedValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    
    STAssertEquals(missing.count, (NSUInteger)0, @"Missing key paths in result set");
    STAssertEquals(unexpected.count, (NSUInteger)0, @"Unexpected key paths in result set");
}

- (void)testDelegateSubstitution {
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

    BSONEncoder *encoder = [[BSONEncoder alloc] init];
    TestEncoderDelegateRedactDates *delegate = [[TestEncoderDelegateRedactDates alloc] init];
    encoder.delegate = delegate;
    [encoder encodeObject:lucy];
    
    BSONDecoder *decoder = nil;
    decoder = [[BSONDecoder alloc] initWithDocument:encoder.BSONDocument];
    NSDictionary *lucyAsDictionary = [[decoder decodeDictionary] retain];

    STAssertEqualObjects([lucyAsDictionary objectForKey:@"dob"],
                         [TestEncoderDelegateRedactDates redactedDate],
                         @"Date should have been redacted");
    
    NSCountedSet *allEncodedObjects = [NSCountedSet setWithObjects:
                                       lucy, lucy.name, [TestEncoderDelegateRedactDates redactedDate], lucy.children,
                                       littleRicky, littleRicky.name, [TestEncoderDelegateRedactDates redactedDate], littleRicky.children,
                                       littlerRicky, littlerRicky.name, [TestEncoderDelegateRedactDates redactedDate],
                                       nil];
    
    NSCountedSet *allEncodedKeyPaths = [NSCountedSet set];
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

    NSCountedSet *resultSet, *missing, *unexpected;
    
    resultSet = [NSCountedSet setWithArray:delegate.encodedObjects];
    missing = [ObjCBSONTests missingValuesInResultSet:resultSet expectedSet:allEncodedObjects];
    unexpected = [ObjCBSONTests unexpectedValuesInResultSet:resultSet expectedSet:allEncodedObjects];
    
    STAssertEquals(missing.count, (NSUInteger)0, @"Missing objects in result set");
    STAssertEquals(unexpected.count, (NSUInteger)0, @"Unexpected objects in result set");
    
    STAssertEquals(delegate.encodedNilKeyPath,
                   (NSUInteger)1,
                   @"Delegate did not receive exactly one notification for nil key path");
    
    resultSet = [NSCountedSet setWithArray:delegate.encodedKeyPaths];
    missing = [ObjCBSONTests missingValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    unexpected = [ObjCBSONTests unexpectedValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    
    STAssertEquals(missing.count, (NSUInteger)0, @"Missing key paths in result set");
    STAssertEquals(unexpected.count, (NSUInteger)0, @"Unexpected key paths in result set");
    
    resultSet = [NSCountedSet setWithArray:delegate.willEncodeKeyPaths];
    missing = [ObjCBSONTests missingValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    unexpected = [ObjCBSONTests unexpectedValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    
    STAssertEquals(missing.count, (NSUInteger)0, @"Missing key paths in result set");
    STAssertEquals(unexpected.count, (NSUInteger)0, @"Unexpected key paths in result set");
    
    NSCountedSet *replacedKeyPaths = [NSCountedSet set];
    [replacedKeyPaths addObject:[NSArray arrayWithObject:@"dob"]];
    [replacedKeyPaths addObject:[NSArray arrayWithObjects:@"children", @"0", @"dob", nil]];
    [replacedKeyPaths addObject:[NSArray arrayWithObjects:@"children", @"0", @"children", @"0", @"dob", nil]];

    NSCountedSet *replacedObjects = [NSCountedSet setWithObjects:
                                     lucy.dob,
                                     littleRicky.dob,
                                     littlerRicky.dob,
                                     nil];

    resultSet = [NSCountedSet setWithArray:delegate.replacedKeyPaths];
    missing = [ObjCBSONTests missingValuesInResultSet:resultSet expectedSet:replacedKeyPaths];
    unexpected = [ObjCBSONTests unexpectedValuesInResultSet:resultSet expectedSet:replacedKeyPaths];
    
    STAssertEquals(missing.count, (NSUInteger)0, @"Missing key paths in result set");
    STAssertEquals(unexpected.count, (NSUInteger)0, @"Unexpected key paths in result set");

    resultSet = [NSCountedSet setWithArray:delegate.replacedObjects];
    missing = [ObjCBSONTests missingValuesInResultSet:resultSet expectedSet:replacedObjects];
    unexpected = [ObjCBSONTests unexpectedValuesInResultSet:resultSet expectedSet:replacedObjects];
    
    STAssertEquals(missing.count, (NSUInteger)0, @"Missing objects in result set");
    STAssertEquals(unexpected.count, (NSUInteger)0, @"Unexpected objects in result set");
}

- (void)testObjectLoop {
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
    littlerRicky.children = [NSMutableArray array];
    
    [lucy.children addObject:littleRicky];
    [littleRicky.children addObject:littlerRicky];
    
    STAssertNoThrow([BSONEncoder BSONDocumentForObject:lucy],
                    @"Encoding a loop should raise an exception");

    [littlerRicky.children addObject:lucy];
    
    STAssertThrows([BSONEncoder BSONDocumentForObject:lucy],
                   @"Encoding a loop should raise an exception");
}

- (void)testEncodeObjectsByInclusionAndByReference {
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
    littlerRicky.children = [NSMutableArray array];

    [lucy.children addObject:littleRicky];
    littleRicky.parent = lucy;
    [littleRicky.children addObject:littlerRicky];
    littlerRicky.parent = littleRicky;

    BSONEncoder *encoder = [[BSONEncoder alloc] initForWriting];
    EncodesParentByReferenceDelegate *delegate = [[EncodesParentByReferenceDelegate alloc] init];
    encoder.delegate = delegate;
    [encoder encodeObject:lucy];
    BSONDocument *document = [encoder BSONDocument];
    
    BSONDecoder *decoder = [[BSONDecoder alloc] initWithDocument:document];
    
    PersonWithCoding *lucy2 = [decoder decodeObjectWithClass:[PersonWithCoding class]];
    PersonWithCoding *littleRicky2 = [lucy2.children objectAtIndex:0];
    PersonWithCoding *littlerRicky2 = [littleRicky2.children objectAtIndex:0];
    
    STAssertEqualObjects(littleRicky2.parent,
                         lucy.name,
                         @"Parent encoded by name should match");
    STAssertEqualObjects(littlerRicky2.parent,
                         littleRicky.name,
                         @"Parent encoded by name should match");
}

- (void) testReplacementObjectForCoder {
    PersonWithBriefCoding *lucy = [[PersonWithBriefCoding alloc] init];
    lucy.name = @"Lucy Ricardo";
    lucy.dob = [self.df dateFromString:@"Jan 1, 1920"];
    lucy.numberOfVisits = 75;
    lucy.children = [NSMutableArray array];
    
    PersonWithBriefCoding *littleRicky = [[PersonWithBriefCoding alloc] init];
    littleRicky.name = @"Ricky Ricardo, Jr.";
    littleRicky.dob = [self.df dateFromString:@"Jan 19, 1953"];
    littleRicky.numberOfVisits = 15;
    littleRicky.children = [NSMutableArray array];
    
    PersonWithBriefCoding *littlerRicky = [[PersonWithBriefCoding alloc] init];
    littlerRicky.name = @"Ricky Ricardo III";
    littlerRicky.dob = [self.df dateFromString:@"Jan 19, 1975"];
    littlerRicky.numberOfVisits = 1;
    littlerRicky.children = [NSMutableArray array];
    
    [lucy.children addObject:littleRicky];
    [littleRicky.children addObject:littlerRicky];
    
    BSONDocument *document = [BSONEncoder BSONDocumentForObject:lucy];

    BSONDecoder *decoder = [[BSONDecoder alloc] initWithDocument:document];
    PersonWithCoding *lucy2 = [decoder decodeObjectWithClass:[PersonWithCoding class]];
    
    STAssertEqualObjects(lucy2.name,
                         lucy.name,
                         @"Encoded name should match");
    STAssertEqualObjects([lucy2.children objectAtIndex:0],
                         ((Person *)[lucy.children objectAtIndex:0]).name,
                         @"Encoded child should match child's name");
}

- (void) testReplacementObjectForBSONEncoder {
    PersonWithBriefCoding2 *lucy = [[PersonWithBriefCoding2 alloc] init];
    lucy.name = @"Lucy Ricardo";
    lucy.dob = [self.df dateFromString:@"Jan 1, 1920"];
    lucy.numberOfVisits = 75;
    lucy.children = [NSMutableArray array];
    
    PersonWithBriefCoding2 *littleRicky = [[PersonWithBriefCoding2 alloc] init];
    littleRicky.name = @"Ricky Ricardo, Jr.";
    littleRicky.dob = [self.df dateFromString:@"Jan 19, 1953"];
    littleRicky.numberOfVisits = 15;
    littleRicky.children = [NSMutableArray array];
    
    PersonWithBriefCoding2 *littlerRicky = [[PersonWithBriefCoding2 alloc] init];
    littlerRicky.name = @"Ricky Ricardo III";
    littlerRicky.dob = [self.df dateFromString:@"Jan 19, 1975"];
    littlerRicky.numberOfVisits = 1;
    littlerRicky.children = [NSMutableArray array];
    
    [lucy.children addObject:littleRicky];
    [littleRicky.children addObject:littlerRicky];
    
    BSONDocument *document = [BSONEncoder BSONDocumentForObject:lucy];
    
    BSONDecoder *decoder = [[BSONDecoder alloc] initWithDocument:document];
    PersonWithCoding *lucy2 = [decoder decodeObjectWithClass:[PersonWithCoding class]];
    
    STAssertEqualObjects(lucy2.name,
                         lucy.name,
                         @"Encoded name should match");
    STAssertEqualObjects([lucy2.children objectAtIndex:0],
                         ((Person *)[lucy.children objectAtIndex:0]).name,
                         @"Encoded child should match child's name");
}

- (void) testDidDecodeDelegateMethod {
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
    
    NSCountedSet *allEncodedObjects = [NSCountedSet setWithObjects:
                                       lucy, lucy.name, lucy.dob, lucy.children,
                                       littleRicky, littleRicky.name, littleRicky.dob, littleRicky.children,
                                       littlerRicky, littlerRicky.name, littlerRicky.dob,
                                       nil];
    
    NSCountedSet *allEncodedKeyPaths = [NSCountedSet set];
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
    
    TestEncoderDelegate *delegate = [[TestEncoderDelegate alloc] init];
    BSONEncoder *encoder1 = [[BSONEncoder alloc] initForWriting];
    encoder1.delegate = delegate;
    [encoder1 encodeObject:lucy];
    
    NSCountedSet *resultSet, *missing, *unexpected;
    resultSet = [NSCountedSet setWithArray:delegate.encodedObjects];
    missing = [ObjCBSONTests missingValuesInResultSet:resultSet expectedSet:allEncodedObjects];
    unexpected = [ObjCBSONTests unexpectedValuesInResultSet:resultSet expectedSet:allEncodedObjects];
    
    STAssertEquals(missing.count, (NSUInteger)0, @"Missing objects in result set");
    STAssertEquals(unexpected.count, (NSUInteger)0, @"Unexpected objects in result set");
    
    STAssertEquals(delegate.encodedNilKeyPath,
                   (NSUInteger)1,
                   @"Delegate did not receive exactly one notification for nil key path");
    
    
    BSONDecoder *decoder = [[BSONDecoder alloc] initWithDocument:encoder1.BSONDocument];
    TestDecoderDelegate *delegate2 = [[TestDecoderDelegate alloc] init];
    decoder.delegate = delegate2;
    PersonWithCoding *lucy2 = [decoder decodeObjectWithClass:[PersonWithCoding class]];
    [lucy2 retain];
    
    resultSet = [NSCountedSet setWithArray:delegate2.decodedKeyPaths];
    missing = [ObjCBSONTests missingValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    unexpected = [ObjCBSONTests unexpectedValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    
    STAssertEquals(missing.count, (NSUInteger)0, @"Missing key paths in result set");
    STAssertEquals(unexpected.count, (NSUInteger)0, @"Unexpected key paths in result set");
    
    STAssertEquals(delegate2.decodedNilKeyPath,
                   (NSUInteger)1,
                   @"Delegate did not receive exactly one notification for nil key path");
    
    
    resultSet = [NSCountedSet setWithArray:delegate.willEncodeKeyPaths];
    missing = [ObjCBSONTests missingValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    unexpected = [ObjCBSONTests unexpectedValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    
    STAssertEquals(missing.count, (NSUInteger)0, @"Missing key paths in result set");
    STAssertEquals(unexpected.count, (NSUInteger)0, @"Unexpected key paths in result set");
}

- (void) testDidDecodeDelegateMethod2 {    
    NSDictionary *sample = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:1], @"one",
                            [NSNumber numberWithDouble:2.0], @"two",
                            @"3", @"three",
                            [NSArray arrayWithObjects:@"zero", @"one", @"two", @"three", nil], @"four",
                            nil];
    
    NSCountedSet *allEncodedObjects = [NSCountedSet set];
    [allEncodedObjects addObjectsFromArray:[[sample objectForKey:@"four"] allObjects]];
    [allEncodedObjects addObjectsFromArray:[sample objectsForKeys:[sample allKeys] notFoundMarker:[NSNull null]]];
    [allEncodedObjects addObject:sample];
    
    NSCountedSet *allEncodedKeyPaths = [NSCountedSet set];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObject:@"one"]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObject:@"two"]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObject:@"three"]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObject:@"four"]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObjects:@"four", @"0", nil]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObjects:@"four", @"1", nil]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObjects:@"four", @"2", nil]];
    [allEncodedKeyPaths addObject:[NSArray arrayWithObjects:@"four", @"3", nil]];
    
    TestEncoderDelegate *delegate = [[TestEncoderDelegate alloc] init];
    BSONEncoder *encoder1 = [[BSONEncoder alloc] initForWriting];
    encoder1.delegate = delegate;
    [encoder1 encodeDictionary:sample];
    
    NSCountedSet *resultSet, *missing, *unexpected;
    resultSet = [NSCountedSet setWithArray:delegate.encodedObjects];
    missing = [ObjCBSONTests missingValuesInResultSet:resultSet expectedSet:allEncodedObjects];
    unexpected = [ObjCBSONTests unexpectedValuesInResultSet:resultSet expectedSet:allEncodedObjects];
    
    STAssertEquals(missing.count, (NSUInteger)0, @"Missing objects in result set");
    STAssertEquals(unexpected.count, (NSUInteger)0, @"Unexpected objects in result set");
    
    STAssertEquals(delegate.encodedNilKeyPath,
                   (NSUInteger)1,
                   @"Delegate did not receive exactly one notification for nil key path");
    
    
    BSONDecoder *decoder = [[BSONDecoder alloc] initWithDocument:encoder1.BSONDocument];
    TestDecoderDelegate *delegate2 = [[TestDecoderDelegate alloc] init];
    decoder.delegate = delegate2;
    NSDictionary *sample2 = [decoder decodeDictionary];
    [sample2 retain];
    
    resultSet = [NSCountedSet setWithArray:delegate2.decodedKeyPaths];
    missing = [ObjCBSONTests missingValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    unexpected = [ObjCBSONTests unexpectedValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    
    STAssertEquals(missing.count, (NSUInteger)0, @"Missing key paths in result set");
    STAssertEquals(unexpected.count, (NSUInteger)0, @"Unexpected key paths in result set");
    
    STAssertEquals(delegate2.decodedNilKeyPath,
                   (NSUInteger)1,
                   @"Delegate did not receive exactly one notification for nil key path");
    
    
    resultSet = [NSCountedSet setWithArray:delegate.willEncodeKeyPaths];
    missing = [ObjCBSONTests missingValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    unexpected = [ObjCBSONTests unexpectedValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    
    STAssertEquals(missing.count, (NSUInteger)0, @"Missing key paths in result set");
    STAssertEquals(unexpected.count, (NSUInteger)0, @"Unexpected key paths in result set");
}

- (void) testDidDecodeDelegateSubstitutions {    
    NSDictionary *sample = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:1], @"one",
                            [NSNumber numberWithDouble:2.0], @"two",
                            @"3", @"three",
                            [NSArray arrayWithObjects:@"zero", @"one", @"two", @"three", nil], @"four",
                            nil];
        
    BSONEncoder *encoder1 = [[BSONEncoder alloc] initForWriting];
    [encoder1 encodeDictionary:sample];
    
    BSONDecoder *decoder = [[BSONDecoder alloc] initWithDocument:encoder1.BSONDocument];
    TranslatingTestDecoderDelegate *delegate2 = [[TranslatingTestDecoderDelegate alloc] init];
    decoder.delegate = delegate2;
    NSDictionary *sample2 = [decoder decodeDictionary];
    [sample2 retain];
    
    NSArray *sample2_4 = [sample2 objectForKey:@"four"];
    NSArray *expectedResult = [NSArray arrayWithObjects:@"zero", @"uno", @"dos", @"tres", nil];
    STAssertEqualObjects(sample2_4,
                         expectedResult, @"Values should have been translated");
    
    NSArray *substitutedObjects = [NSArray arrayWithObjects:@"one", @"two", @"three", nil];

    STAssertEqualObjects(delegate2.replacedObjects,
                         substitutedObjects,
                         @"Should have been notified of translated values");
}

- (void) testAwakeAfterUsingCoder {
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
        
    BSONEncoder *encoder1 = [[BSONEncoder alloc] initForWriting];
    [encoder1 encodeObject:lucy];
        
    BSONDecoder *decoder = [[BSONDecoder alloc] initWithDocument:encoder1.BSONDocument];
    TestDecoderDelegate *delegate2 = [[TestDecoderDelegate alloc] init];
    decoder.delegate = delegate2;
    
    STAssertFalse(delegate2.willFinish, @"Delegate received -decoderWillFinish before encoding finished");
    
    PersonWithCoding *lucy2 = [decoder decodeObjectWithClass:[PersonWithCoding class]];
    [lucy2 retain];
    
    STAssertTrue(delegate2.willFinish, @"Delegate did not receive -decoderWillFinish");
    
    NSArray *createdPersonObjects = [NSArray arrayWithObjects:
                                     lucy2,
                                     [lucy2.children objectAtIndex:0],
                                     [[(PersonWithCoding *)[lucy2.children objectAtIndex:0] children] objectAtIndex:0],
    nil];
    
    NSUInteger awakenedPersonObjects = 0;
    for (PersonWithCoding *person in createdPersonObjects)
        if (person.awakeAfterCoder) awakenedPersonObjects = awakenedPersonObjects + 1;
    
    STAssertEquals(awakenedPersonObjects,
                   createdPersonObjects.count,
                   @"Person objects should have received awakeAfterUsingCoder");
}

- (void) testShouldSubstituteObjectID {
    
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
    littlerRicky.children = [NSMutableArray array];
    
    [lucy.children addObject:littleRicky];
    [littleRicky.children addObject:littlerRicky];
    
    BSONEncoder *encoder = [[BSONEncoder alloc] initForWriting];
    EncodesObjectIDForChildren *delegate = [[EncodesObjectIDForChildren alloc] init];
    encoder.delegate = delegate;
    STAssertThrows([encoder encodeObject:lucy],
                   @"Attempting to encode a nil objectID for a non-nil object should throw an exception");
    
    littleRicky.BSONObjectID = [BSONObjectID objectID];
    
    encoder = [[BSONEncoder alloc] initForWriting];
    encoder.delegate = delegate;
    [encoder encodeObject:lucy];
    
    BSONDecoder *decoder = [[BSONDecoder alloc] initWithDocument:[encoder BSONDocument]];
    PersonWithCoding *lucy2 = [decoder decodeObjectWithClass:[PersonWithCoding class]];
    
    STAssertEqualObjects(lucy2.name,
                         lucy.name,
                         @"Encoded name should match");
    STAssertEquals([lucy2.children count],
                   (NSUInteger)1,
                   @"Lucy should still have one child");
    STAssertEqualObjects([lucy2.children objectAtIndex:0],
                   littleRicky.BSONObjectID,
                   @"Lucy's child should be the object id");
}

@end