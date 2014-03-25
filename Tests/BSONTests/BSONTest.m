//
//  BSONTest.m
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

#import <XCTest/XCTest.h>
#import "BSON_Helper.h"
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
-(void)dealloc {
    maybe_release(_name);
    maybe_release(_dob);
    maybe_release(_children);
    maybe_release(_parent);
    super_dealloc;
}
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
    static NSDateFormatter *df;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setTimeStyle:NSDateFormatterNoStyle];
        [df setDateStyle:NSDateFormatterShortStyle];
    });
    
    NSMutableString *string = [NSMutableString stringWithFormat:@"<%@: %p>", [[self class] description], self];
    [string appendFormat:@"  name: %@", self.name];
    [string appendFormat:@"  dob: %@", [df stringFromDate:self.dob]];
    [string appendFormat:@"  numberOfVisits: %ld", (long)self.numberOfVisits];
    [string appendFormat:@"  parent: %@", self.parent];
    [string appendFormat:@"  children: %@", self.children];
    return string;
}
-(BOOL)isEqual:(Person *) obj {
    if (![obj isKindOfClass:[Person class]]) return NO;
    return ((!self.name && !obj.name) || [self.name isEqual:obj.name])
    && ((!self.dob && !obj.dob) || [self.dob isEqual:obj.dob])
    && self.numberOfVisits == obj.numberOfVisits
    && ((!self.children && !obj.children) || [self.children isEqual:obj.children]);
}
@end
@interface PersonWithCoding : Person <NSCoding, BSONCoding>
@property (retain) BSONObjectID *BSONObjectID;
@end
@implementation PersonWithCoding

-(void)dealloc {
    maybe_release(_BSONObjectID);
    super_dealloc;
}

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
        self.children =
        maybe_autorelease([[coder decodeArrayForKey:@"children"
                                          withClass:[PersonWithCoding class]] mutableCopy]);
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

-(id)init {
    self.encodedObjects = [NSMutableArray array];
    self.willEncodeKeyPaths = [NSMutableArray array];
    self.encodedKeyPaths = [NSMutableArray array];
    return self;
}

-(void)dealloc {
    maybe_release(_encodedObjects);
    maybe_release(_willEncodeKeyPaths);
    maybe_release(_encodedKeyPaths);
    super_dealloc;
}

-(void)encoder:(BSONEncoder *)encoder didEncodeObject:(id) obj forKeyPath:(NSString *) keyPathComponents {
    [self.encodedObjects addObject:obj];
    if (keyPathComponents)
        [self.encodedKeyPaths addObject:keyPathComponents];
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
    if (keyPathComponents) [self.willEncodeKeyPaths addObject:keyPathComponents];
    return obj;
}

@end

@interface TestEncoderDelegateRedactDates : TestEncoderDelegate
+(NSString *)redactedDate;
@property (retain) NSMutableArray *replacedObjects;
@property (retain) NSMutableArray *replacedKeyPaths;
@end
@implementation TestEncoderDelegateRedactDates

-(id)init {
    if (self = [super init]) {
        self.replacedObjects = [NSMutableArray array];
        self.replacedKeyPaths = [NSMutableArray array];
    }
    return self;
}

-(void)dealloc {
    maybe_release(_replacedObjects);
    maybe_release(_replacedKeyPaths);
    super_dealloc;
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

-(id)init {
    self.decodedObjects = [NSMutableArray array];
    self.decodedKeyPaths = [NSMutableArray array];
    self.replacedObjects = [NSMutableArray array];
    return self;
}
-(void)dealloc {
    maybe_release(_decodedObjects);
    maybe_release(_decodedKeyPaths);
    maybe_release(_replacedObjects);
    super_dealloc;
}
-(id)decoder:(BSONDecoder *)decoder didDecodeObject:(id) object forKeyPath:(NSArray *) keyPathComponents {
    [self.decodedObjects addObject:object];
    if (keyPathComponents)
        [self.decodedKeyPaths addObject:keyPathComponents];
    else
        self.decodedNilKeyPath = self.decodedNilKeyPath + 1;
    return object;
}
-(void)decoder:(BSONDecoder *)decoder willReplaceObject:(id)object withObject:(id)newObject forKeyPath:(NSArray *)keyPathComponents {
    [self.replacedObjects addObject:object];
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
    if ([object isEqual:@"one"])
        return @"uno";
    else if ([object isEqual:@"two"])
        return @"dos";
    else if ([object isEqual:@"three"])
        return @"tres";
    else if ([object isEqual:@"four"])
        return @"quattro";
    else if ([object isEqual:@"five"])
        return @"cinco";
    else if ([object isEqual:@"six"])
        return @"seis";
    else if ([object isEqual:@"seven"])
        return @"siete";
    else if ([object isEqual:@"eight"])
        return @"ocho";
    else if ([object isEqual:@"nine"])
        return @"nueve";
    else
        return object;
}
@end

@interface BSONTest : XCTestCase

@property (retain) NSDateFormatter *df;

@end

@implementation BSONTest

+ (NSCountedSet *) missingValuesInResultSet:(NSCountedSet *) one expectedSet:(NSCountedSet *) two {
    if (!one && !two) return [NSCountedSet set];
    
    NSCountedSet *intersection = [one copy];
    [intersection intersectSet:two];
    
//    NSCountedSet *oneOnly = [one copy];
//    [oneOnly minusSet:intersection];
    
    NSCountedSet *twoOnly = [two copy];
    [twoOnly minusSet:intersection];
    
    maybe_release(intersection);
    maybe_autorelease_and_return(twoOnly);
}

+ (NSCountedSet *) unexpectedValuesInResultSet:(NSCountedSet *) one expectedSet:(NSCountedSet *) two {
    if (!one && !two) return [NSCountedSet set];
    
    NSCountedSet *intersection = [one copy];
    [intersection intersectSet:two];
    
    NSCountedSet *oneOnly = [one copy];
    [oneOnly minusSet:intersection];
    
//    NSCountedSet *twoOnly = [two copy];
//    [twoOnly minusSet:intersection];
    
    maybe_release(intersection);
    maybe_autorelease_and_return(oneOnly);
}

- (void) assertResultSet:(NSCountedSet *) one isEqualToExpectedSet:(NSCountedSet *) two name:(NSString *) name {
    if (!one && !two) return;
    
    NSCountedSet *intersection = [one copy];
    [intersection intersectSet:two];
    
    NSCountedSet *oneOnly = [one copy];
    [oneOnly minusSet:intersection];
    
    NSCountedSet *twoOnly = [two copy];
    [twoOnly minusSet:intersection];
    
    XCTAssertEqual(twoOnly.count,
                   (NSUInteger)0,
                   @"Expected %@ missing from result", name);
    XCTAssertEqual(oneOnly.count,
                   (NSUInteger)0,
                   @"Unexpected %@ found in result", name);
    
    maybe_release(intersection);
    maybe_release(oneOnly);
    maybe_release(twoOnly);
}


-(void)setUp {
    self.df = [[NSDateFormatter alloc] init];
    [self.df setLenient:YES];
    [self.df setTimeStyle:NSDateFormatterNoStyle];
    [self.df setDateStyle:NSDateFormatterShortStyle];
    [super setUp];
}

-(void)tearDown {
    maybe_release(self.df);
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
    
    XCTAssertThrows([sample encodeWithCoder:encoder]);
    
    NSDictionary *badSample1 = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"pickles", @"this.is.a.bad.key",
                                nil];
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    XCTAssertThrows([encoder encodeDictionary:badSample1]);
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    encoder.restrictsKeyNamesForMongoDB = NO;
    XCTAssertNoThrow([encoder encodeDictionary:badSample1]);
    
    NSDictionary *badSample2 = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"pickles", @"$bad$key",
                                nil];
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    XCTAssertThrows([encoder encodeDictionary:badSample2]);
    
    NSDictionary *goodSample = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"pickles", @"good$key",
                                nil];
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    XCTAssertNoThrow([encoder encodeDictionary:goodSample]);
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    encoder.restrictsKeyNamesForMongoDB = NO;
    XCTAssertNoThrow([encoder encodeDictionary:badSample2]);
    
    maybe_release(encoder);
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
    
    XCTAssertEqualObjects([[encoder1 BSONDocument] dataValue],
                         [[encoder2 BSONDocument] dataValue],
                         @"Encoded same dictionary but got different data values.");

    XCTAssertEqualObjects([encoder1 BSONDocument],
                         [encoder2 BSONDocument],
                         @"Encoded same dictionary but documents were not equal.");
    
    maybe_release(encoder1);
    maybe_release(encoder2);
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
    
    XCTAssertFalse([[encoder1 BSONDocument] isEqual:[encoder2 BSONDocument]],
                  @"Documents had different data and should not be equal");    

    maybe_release(encoder1);
    maybe_release(encoder2);
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
    XCTAssertThrowsSpecificNamed([encoder encodeBool:NO forKey:@"testKey"],
                                NSException,
                                NSInvalidArchiveOperationException,
                                @"Attempted encoding after finishEncoding but didn't throw exception");
    maybe_release(encoder);
}

- (void) testEncodeNilKeys {
    BSONEncoder *encoder = [[BSONEncoder alloc] init];
    // Nil key should throw an exception
    XCTAssertThrows([encoder encodeObject:@"test" forKey:nil]);
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"asdf", @"asdf", nil];
    XCTAssertThrows([encoder encodeDictionary:dict forKey:nil]);
    XCTAssertThrows([encoder encodeArray:[NSArray arrayWithObject:@"test"] forKey:nil]);
    XCTAssertThrows([encoder encodeBSONDocument:[BSONDocument document] forKey:nil]);
    XCTAssertThrows([encoder encodeNullForKey:nil]);
    XCTAssertThrows([encoder encodeUndefinedForKey:nil]);
    XCTAssertThrows([encoder encodeObjectID:[BSONObjectID objectID] forKey:nil]);
    XCTAssertThrows([encoder encodeInt:1 forKey:nil]);
    XCTAssertThrows([encoder encodeInt64:1 forKey:nil]);
    XCTAssertThrows([encoder encodeBool:YES forKey:nil]);
    XCTAssertThrows([encoder encodeDouble:3.25 forKey:nil]);
    XCTAssertThrows([encoder encodeNumber:[NSNumber numberWithInt:3] forKey:nil]);
    XCTAssertThrows([encoder encodeString:@"test" forKey:nil]);
    XCTAssertThrows([encoder encodeSymbol:[BSONSymbol symbol:@"test"] forKey:nil]);
    XCTAssertThrows([encoder encodeDate:[NSDate date] forKey:nil]);
#if TARGET_OS_IPHONE
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(36, 36), NO, 0.0);
    UIImage *testImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    XCTAssertNotNil(testImage);
    XCTAssertThrows([encoder encodeImage:testImage forKey:nil]);
#else
    XCTAssertThrows([encoder encodeImage:[NSImage imageNamed:NSImageNameBonjour] forKey:nil]);
#endif
    XCTAssertThrows([encoder encodeRegularExpressionPattern:@"test" options:@"test" forKey:nil]);
    XCTAssertThrows([encoder encodeRegularExpression:[BSONRegularExpression regularExpressionWithPattern:@"test" options:@"test"]
                                              forKey:nil]);
    XCTAssertThrows([encoder encodeCode:[BSONCode code:@"test"] forKey:nil]);
    XCTAssertThrows([encoder encodeCodeString:@"test" forKey:nil]);
    XCTAssertThrows([encoder encodeCodeWithScope:[BSONCodeWithScope code:@"test" withScope:[BSONDocument document]]
                                          forKey:nil]);
    XCTAssertThrows([encoder encodeCodeString:@"test" withScope:[BSONDocument document]
                                          forKey:nil]);
    XCTAssertThrows([encoder encodeData:[NSData data] forKey:nil]);
    XCTAssertThrows([encoder encodeTimestamp:[BSONTimestamp timestampWithIncrement:10 timeInSeconds:10]
                                      forKey:nil]);
    
    maybe_release(encoder);
}

- (void) testEncodeNilValues {
    BSONEncoder *encoder = [[BSONEncoder alloc] init];
    NSString *reason = nil;
    
    XCTAssertNoThrow([encoder encodeRegularExpressionPattern:@"test" options:nil forKey:@"testKey"]);
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    
    // Half-nil values should throw an exception
    XCTAssertThrows([encoder encodeRegularExpressionPattern:nil options:@"test" forKey:@"testKey"]);
    XCTAssertThrows([encoder encodeCodeString:nil withScope:[BSONDocument document] forKey:@"testKey"]);
    XCTAssertThrows([encoder encodeCodeString:@"test" withScope:nil forKey:@"testKey"]);
    
    // With default behavior DoNothingOnNil, no exception should be raised for nil values
    XCTAssertNoThrow([encoder encodeObject:nil forKey:@"testKey"]);
    XCTAssertNoThrow([encoder encodeDictionary:nil forKey:@"testKey"]);
    XCTAssertNoThrow([encoder encodeArray:nil forKey:@"testKey"]);
    XCTAssertNoThrow([encoder encodeBSONDocument:nil forKey:@"testKey"]);
    XCTAssertNoThrow([encoder encodeObjectID:nil forKey:@"testKey"]);
    XCTAssertNoThrow([encoder encodeNumber:nil forKey:@"testKey"]);
    XCTAssertNoThrow([encoder encodeString:nil forKey:@"testKey"]);
    XCTAssertNoThrow([encoder encodeSymbol:nil forKey:@"testKey"]);
    XCTAssertNoThrow([encoder encodeDate:nil forKey:@"testKey"]);
    XCTAssertNoThrow([encoder encodeImage:nil forKey:@"testKey"]);
    XCTAssertNoThrow([encoder encodeRegularExpression:nil forKey:@"testKey"]);
    XCTAssertNoThrow([encoder encodeCode:nil forKey:@"testKey"]);
    XCTAssertNoThrow([encoder encodeCodeString:nil forKey:@"testKey"]);
    XCTAssertNoThrow([encoder encodeCodeWithScope:nil forKey:@"testKey"]);
    XCTAssertNoThrow([encoder encodeData:nil forKey:@"testKey"]);
    XCTAssertNoThrow([encoder encodeTimestamp:nil forKey:@"testKey"]);
    
    XCTAssertEqualObjects([encoder BSONDocument],
                         [BSONDocument document],
                         @"With default behavior, encoding nil values should result in an empty document");

    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    
    // Zero value on primitive types should not throw an exception
    XCTAssertNoThrow([encoder encodeInt:0 forKey:@"testKey"]);
    XCTAssertNoThrow([encoder encodeInt64:0 forKey:@"testKey"]);
    XCTAssertNoThrow([encoder encodeDouble:0 forKey:@"testKey"]);
    XCTAssertNoThrow([encoder encodeBool:NO forKey:@"testKey"]);
    
    XCTAssertFalse([[encoder BSONDocument] isEqual:[BSONDocument document]],
                         @"With default behavior, encoding zero-value primitives should fill up the document");
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONRaiseExceptionOnNil;
    
    reason = @"Nil regex options should be OK";
    XCTAssertNoThrow([encoder encodeRegularExpressionPattern:@"test" options:nil forKey:@"testKey"]);
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONRaiseExceptionOnNil;
    
    // Half-nil values should throw an exception
    XCTAssertThrows([encoder encodeRegularExpressionPattern:nil options:@"test" forKey:@"testKey"]);
    XCTAssertThrows([encoder encodeCodeString:nil withScope:[BSONDocument document] forKey:@"testKey"]);
    XCTAssertThrows([encoder encodeCodeString:@"test" withScope:nil forKey:@"testKey"]);
 
    // Nil value should throw an exception
    XCTAssertThrows([encoder encodeObject:nil forKey:@"testKey"]);
    XCTAssertThrows([encoder encodeDictionary:nil forKey:@"testKey"]);
    XCTAssertThrows([encoder encodeArray:nil forKey:@"testKey"]);
    XCTAssertThrows([encoder encodeBSONDocument:nil forKey:@"testKey"]);
    XCTAssertThrows([encoder encodeObjectID:nil forKey:@"testKey"]);
    XCTAssertThrows([encoder encodeNumber:nil forKey:@"testKey"]);
    XCTAssertThrows([encoder encodeString:nil forKey:@"testKey"]);
    XCTAssertThrows([encoder encodeSymbol:nil forKey:@"testKey"]);
    XCTAssertThrows([encoder encodeDate:nil forKey:@"testKey"]);
    XCTAssertThrows([encoder encodeImage:nil forKey:@"testKey"]);
    XCTAssertThrows([encoder encodeRegularExpressionPattern:nil options:@"test" forKey:@"testKey"]);
    XCTAssertThrows([encoder encodeRegularExpression:nil forKey:@"testKey"]);
    XCTAssertThrows([encoder encodeCode:nil forKey:@"testKey"]);
    XCTAssertThrows([encoder encodeCodeString:nil forKey:@"testKey"]);
    XCTAssertThrows([encoder encodeCodeWithScope:nil forKey:@"testKey"]);
    XCTAssertThrows([encoder encodeCodeString:nil withScope:[BSONDocument document] forKey:@"testKey"]);
    XCTAssertThrows([encoder encodeCodeString:@"test" withScope:nil forKey:@"testKey"]);
    XCTAssertThrows([encoder encodeData:nil forKey:@"testKey"]);
    XCTAssertThrows([encoder encodeTimestamp:nil forKey:@"testKey"]);
    
    // Zero value on primitive types should not throw an exception
    XCTAssertNoThrow([encoder encodeInt:0 forKey:@"testKey"]);
    XCTAssertNoThrow([encoder encodeInt64:0 forKey:@"testKey"]);
    XCTAssertNoThrow([encoder encodeDouble:0 forKey:@"testKey"]);
    XCTAssertNoThrow([encoder encodeBool:NO forKey:@"testKey"]);
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    
    [encoder encodeObject:nil forKey:@"testKey"];
    // Inserted nil and should have encoded null, but did not
    XCTAssertEqual([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null]);
    XCTAssertThrows([encoder encodeDictionary:nil forKey:@"testKey"], @"Encoding finished");
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeDictionary:nil forKey:@"testKey"];
    XCTAssertEqual([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null]);
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeArray:nil forKey:@"testKey"];
    XCTAssertEqual([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null]);

    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeBSONDocument:nil forKey:@"testKey"];
    XCTAssertEqual([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null]);
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeObjectID:nil forKey:@"testKey"];
    XCTAssertEqual([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null]);
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeNumber:nil forKey:@"testKey"];
    XCTAssertEqual([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null]);
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeString:nil forKey:@"testKey"];
    XCTAssertEqual([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null]);
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeSymbol:nil forKey:@"testKey"];
    XCTAssertEqual([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null]);
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeDate:nil forKey:@"testKey"];
    XCTAssertEqual([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null]);
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeImage:nil forKey:@"testKey"];
    XCTAssertEqual([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null]);
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeRegularExpressionPattern:nil options:nil forKey:@"testKey"];
    XCTAssertEqual([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null]);
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeRegularExpression:nil forKey:@"testKey"];
    XCTAssertEqual([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null]);
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeCode:nil forKey:@"testKey"];
    XCTAssertEqual([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null]);
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeCodeString:nil forKey:@"testKey"];
    XCTAssertEqual([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null]);
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeCodeWithScope:nil forKey:@"testKey"];
    XCTAssertEqual([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null]);
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeCodeString:nil withScope:nil forKey:@"testKey"];
    XCTAssertEqual([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null]);
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeData:nil forKey:@"testKey"];
    XCTAssertEqual([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null]);
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    encoder.behaviorOnNil = BSONEncodeNullOnNil;
    [encoder encodeTimestamp:nil forKey:@"testKey"];
    XCTAssertEqual([encoder.BSONDocument.iterator objectForKey:@"testKey"], [NSNull null]);

    maybe_release(encoder);
}

- (void) testEncodeCustomObjectWithRecursiveChildren {
    BSONEncoder *encoder = nil;
    
    Person *lucy = [[Person alloc] init];
    lucy.name = @"Lucy Ricardo";
    lucy.dob = [self.df dateFromString:@"Jan 1, 1920"];
    lucy.numberOfVisits = 75;
    lucy.children = [NSMutableArray array];
    
    encoder = [[BSONEncoder alloc] init];
    XCTAssertThrows([encoder encodeObject:lucy],
                   @"Should have called our bogus encodeWithCoder: and raised an exception, but didn't");

    maybe_release(lucy);
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
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] init];
    XCTAssertNoThrow([encoder encodeObject:lucy],
                   @"Should have called our functional encodeWithCoder:, no exception");
    
    BSONDecoder *decoder = nil;
    decoder = [[BSONDecoder alloc] initWithDocument:encoder.BSONDocument];
    PersonWithCoding *lucy2 = [decoder decodeObjectWithClass:[PersonWithCoding class]];
    
    XCTAssertEqualObjects(lucy, lucy2, @"Encoded and decoded objects should be the same");
    
    lucy.children = nil;
    littleRicky.children = nil;
    littlerRicky.children = nil;
    
    lucy2.children = nil;
    
    maybe_release(lucy);
    maybe_release(littleRicky);
    maybe_release(littlerRicky);
    maybe_release(encoder);
    maybe_release(decoder);
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
    missing = [BSONTest missingValuesInResultSet:resultSet expectedSet:allEncodedObjects];
    unexpected = [BSONTest unexpectedValuesInResultSet:resultSet expectedSet:allEncodedObjects];
    
    XCTAssertEqual(missing.count, (NSUInteger)0, @"Missing objects in result set");
    XCTAssertEqual(unexpected.count, (NSUInteger)0, @"Unexpected objects in result set");
    
    resultSet = [NSCountedSet setWithArray:delegate.encodedKeyPaths];
    missing = [BSONTest missingValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    unexpected = [BSONTest unexpectedValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    
    XCTAssertEqual(missing.count, (NSUInteger)0, @"Missing key paths in result set");
    XCTAssertEqual(unexpected.count, (NSUInteger)0, @"Unexpected key paths in result set");

    XCTAssertEqual(delegate.encodedNilKeyPath,
                   (NSUInteger)1,
                   @"Delegate did not receive exactly one notification for nil key path");
    
    XCTAssertFalse(delegate.willFinish, @"Delegate received -encoderWillFinish before encoding finished");
    XCTAssertFalse(delegate.didFinish, @"Delegate received -encoderDidFinish before encoding finished");
    
    // Do this twice; the delegate throws an exception if it receives two sets of notifications
    BSONDocument *document = encoder1.BSONDocument;
    BSONDocument *document2 = encoder1.BSONDocument;
    document = nil;
    document2 = nil;

    XCTAssertTrue(delegate.willFinish, @"Delegate did not receive -encoderWillFinish");
    XCTAssertTrue(delegate.didFinish, @"Delegate did not receive -encoderDidFinish");
    
    maybe_release(delegate);
    maybe_release(encoder1);
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
    missing = [BSONTest missingValuesInResultSet:resultSet expectedSet:allEncodedObjects];
    unexpected = [BSONTest unexpectedValuesInResultSet:resultSet expectedSet:allEncodedObjects];
    
    XCTAssertEqual(missing.count, (NSUInteger)0, @"Missing objects in result set");
    XCTAssertEqual(unexpected.count, (NSUInteger)0, @"Unexpected objects in result set");
    
    XCTAssertEqual(delegate.encodedNilKeyPath,
                   (NSUInteger)1,
                   @"Delegate did not receive exactly one notification for nil key path");
        
    resultSet = [NSCountedSet setWithArray:delegate.encodedKeyPaths];
    missing = [BSONTest missingValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    unexpected = [BSONTest unexpectedValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    
    XCTAssertEqual(missing.count, (NSUInteger)0, @"Missing key paths in result set");
    XCTAssertEqual(unexpected.count, (NSUInteger)0, @"Unexpected key paths in result set");
    
    resultSet = [NSCountedSet setWithArray:delegate.willEncodeKeyPaths];
    missing = [BSONTest missingValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    unexpected = [BSONTest unexpectedValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    
    XCTAssertEqual(missing.count, (NSUInteger)0, @"Missing key paths in result set");
    XCTAssertEqual(unexpected.count, (NSUInteger)0, @"Unexpected key paths in result set");
    
    lucy.children = nil;
    littleRicky.children = nil;
    littlerRicky.children = nil;
    
    maybe_release(lucy);
    maybe_release(littleRicky);
    maybe_release(littlerRicky);
    maybe_release(delegate);
    maybe_release(encoder1);
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
    NSDictionary *lucyAsDictionary = [decoder decodeDictionary];
    
    XCTAssertEqualObjects([lucyAsDictionary objectForKey:@"dob"],
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
    missing = [BSONTest missingValuesInResultSet:resultSet expectedSet:allEncodedObjects];
    unexpected = [BSONTest unexpectedValuesInResultSet:resultSet expectedSet:allEncodedObjects];
    
    XCTAssertEqual(missing.count, (NSUInteger)0, @"Missing objects in result set");
    XCTAssertEqual(unexpected.count, (NSUInteger)0, @"Unexpected objects in result set");
    
    XCTAssertEqual(delegate.encodedNilKeyPath,
                   (NSUInteger)1,
                   @"Delegate did not receive exactly one notification for nil key path");
    
    resultSet = [NSCountedSet setWithArray:delegate.encodedKeyPaths];
    missing = [BSONTest missingValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    unexpected = [BSONTest unexpectedValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    
    XCTAssertEqual(missing.count, (NSUInteger)0, @"Missing key paths in result set");
    XCTAssertEqual(unexpected.count, (NSUInteger)0, @"Unexpected key paths in result set");
    
    resultSet = [NSCountedSet setWithArray:delegate.willEncodeKeyPaths];
    missing = [BSONTest missingValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    unexpected = [BSONTest unexpectedValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    
    XCTAssertEqual(missing.count, (NSUInteger)0, @"Missing key paths in result set");
    XCTAssertEqual(unexpected.count, (NSUInteger)0, @"Unexpected key paths in result set");
    
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
    missing = [BSONTest missingValuesInResultSet:resultSet expectedSet:replacedKeyPaths];
    unexpected = [BSONTest unexpectedValuesInResultSet:resultSet expectedSet:replacedKeyPaths];
    
    XCTAssertEqual(missing.count, (NSUInteger)0, @"Missing key paths in result set");
    XCTAssertEqual(unexpected.count, (NSUInteger)0, @"Unexpected key paths in result set");

    resultSet = [NSCountedSet setWithArray:delegate.replacedObjects];
    missing = [BSONTest missingValuesInResultSet:resultSet expectedSet:replacedObjects];
    unexpected = [BSONTest unexpectedValuesInResultSet:resultSet expectedSet:replacedObjects];
    
    XCTAssertEqual(missing.count, (NSUInteger)0, @"Missing objects in result set");
    XCTAssertEqual(unexpected.count, (NSUInteger)0, @"Unexpected objects in result set");
    
    lucy.children = nil;
    littleRicky.children = nil;
    littlerRicky.children = nil;
    
    maybe_release(lucy);
    maybe_release(littleRicky);
    maybe_release(littlerRicky);
    maybe_release(encoder);
    maybe_release(delegate);
    maybe_release(decoder);
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
    
    XCTAssertNoThrow([BSONEncoder documentForObject:lucy],
                    @"Encoding a loop should raise an exception");

    [littlerRicky.children addObject:lucy];
    
    XCTAssertThrows([BSONEncoder documentForObject:lucy],
                   @"Encoding a loop should raise an exception");
    
    lucy.children = nil;
    littleRicky.children = nil;
    littlerRicky.children = nil;
    
    maybe_release(lucy);
    maybe_release(littleRicky);
    maybe_release(littlerRicky);
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
    
    XCTAssertEqualObjects(littleRicky2.parent,
                         lucy.name,
                         @"Parent encoded by name should match");
    XCTAssertEqualObjects(littlerRicky2.parent,
                         littleRicky.name,
                         @"Parent encoded by name should match");
    
    littleRicky.parent = nil;
    littlerRicky.parent = nil;
    maybe_release(lucy);
    maybe_release(littleRicky);
    maybe_release(littlerRicky);
    maybe_release(encoder);
    maybe_release(delegate);
    maybe_release(decoder);
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
    
    BSONDocument *document = [BSONEncoder documentForObject:lucy];

    BSONDecoder *decoder = [[BSONDecoder alloc] initWithDocument:document];
    PersonWithCoding *lucy2 = [decoder decodeObjectWithClass:[PersonWithCoding class]];
    
    XCTAssertEqualObjects(lucy2.name,
                         lucy.name,
                         @"Encoded name should match");
    XCTAssertEqualObjects([lucy2.children objectAtIndex:0],
                         ((Person *)[lucy.children objectAtIndex:0]).name,
                         @"Encoded child should match child's name");
    
    lucy.children = nil;
    littleRicky.children = nil;
    littlerRicky.children = nil;
    
    maybe_release(lucy);
    maybe_release(littleRicky);
    maybe_release(littlerRicky);
    maybe_release(decoder);
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
    
    BSONDocument *document = [BSONEncoder documentForObject:lucy];
    
    BSONDecoder *decoder = [[BSONDecoder alloc] initWithDocument:document];
    PersonWithCoding *lucy2 = [decoder decodeObjectWithClass:[PersonWithCoding class]];
    
    XCTAssertEqualObjects(lucy2.name,
                         lucy.name,
                         @"Encoded name should match");
    XCTAssertEqualObjects([lucy2.children objectAtIndex:0],
                         ((Person *)[lucy.children objectAtIndex:0]).name,
                         @"Encoded child should match child's name");
    
    lucy.children = nil;
    littleRicky.children = nil;
    littlerRicky.children = nil;
    
    maybe_release(lucy);
    maybe_release(littleRicky);
    maybe_release(littlerRicky);
    maybe_release(decoder);
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
    missing = [BSONTest missingValuesInResultSet:resultSet expectedSet:allEncodedObjects];
    unexpected = [BSONTest unexpectedValuesInResultSet:resultSet expectedSet:allEncodedObjects];
    
    XCTAssertEqual(missing.count, (NSUInteger)0, @"Missing objects in result set");
    XCTAssertEqual(unexpected.count, (NSUInteger)0, @"Unexpected objects in result set");
    
    XCTAssertEqual(delegate.encodedNilKeyPath,
                   (NSUInteger)1,
                   @"Delegate did not receive exactly one notification for nil key path");
    
    
    BSONDecoder *decoder = [[BSONDecoder alloc] initWithDocument:encoder1.BSONDocument];
    TestDecoderDelegate *delegate2 = [[TestDecoderDelegate alloc] init];
    decoder.delegate = delegate2;
    [decoder decodeObjectWithClass:[PersonWithCoding class]];
    
    resultSet = [NSCountedSet setWithArray:delegate2.decodedKeyPaths];
    missing = [BSONTest missingValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    unexpected = [BSONTest unexpectedValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    
    XCTAssertEqual(missing.count, (NSUInteger)0, @"Missing key paths in result set");
    XCTAssertEqual(unexpected.count, (NSUInteger)0, @"Unexpected key paths in result set");
    
    XCTAssertEqual(delegate2.decodedNilKeyPath,
                   (NSUInteger)1,
                   @"Delegate did not receive exactly one notification for nil key path");
    
    
    resultSet = [NSCountedSet setWithArray:delegate.willEncodeKeyPaths];
    missing = [BSONTest missingValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    unexpected = [BSONTest unexpectedValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    
    XCTAssertEqual(missing.count, (NSUInteger)0, @"Missing key paths in result set");
    XCTAssertEqual(unexpected.count, (NSUInteger)0, @"Unexpected key paths in result set");
    
    lucy.children = nil;
    littleRicky.children = nil;
    littlerRicky.children = nil;
    
    maybe_release(lucy);
    maybe_release(littleRicky);
    maybe_release(littlerRicky);
    maybe_release(delegate);
    maybe_release(delegate2);
    maybe_release(encoder1);
    maybe_release(decoder);
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
    missing = [BSONTest missingValuesInResultSet:resultSet expectedSet:allEncodedObjects];
    unexpected = [BSONTest unexpectedValuesInResultSet:resultSet expectedSet:allEncodedObjects];
    
    XCTAssertEqual(missing.count, (NSUInteger)0, @"Missing objects in result set");
    XCTAssertEqual(unexpected.count, (NSUInteger)0, @"Unexpected objects in result set");
    
    XCTAssertEqual(delegate.encodedNilKeyPath,
                   (NSUInteger)1,
                   @"Delegate did not receive exactly one notification for nil key path");
    
    
    BSONDecoder *decoder = [[BSONDecoder alloc] initWithDocument:encoder1.BSONDocument];
    TestDecoderDelegate *delegate2 = [[TestDecoderDelegate alloc] init];
    decoder.delegate = delegate2;
    [decoder decodeDictionary];
    
    resultSet = [NSCountedSet setWithArray:delegate2.decodedKeyPaths];
    missing = [BSONTest missingValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    unexpected = [BSONTest unexpectedValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    
    XCTAssertEqual(missing.count, (NSUInteger)0, @"Missing key paths in result set");
    XCTAssertEqual(unexpected.count, (NSUInteger)0, @"Unexpected key paths in result set");
    
    XCTAssertEqual(delegate2.decodedNilKeyPath,
                   (NSUInteger)1,
                   @"Delegate did not receive exactly one notification for nil key path");
    
    
    resultSet = [NSCountedSet setWithArray:delegate.willEncodeKeyPaths];
    missing = [BSONTest missingValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    unexpected = [BSONTest unexpectedValuesInResultSet:resultSet expectedSet:allEncodedKeyPaths];
    
    XCTAssertEqual(missing.count, (NSUInteger)0, @"Missing key paths in result set");
    XCTAssertEqual(unexpected.count, (NSUInteger)0, @"Unexpected key paths in result set");
    
    maybe_release(delegate);
    maybe_release(delegate2);
    maybe_release(encoder1);
    maybe_release(decoder);
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

    NSArray *sample2_4 = [sample2 objectForKey:@"four"];
    NSArray *expectedResult = [NSArray arrayWithObjects:@"zero", @"uno", @"dos", @"tres", nil];
    XCTAssertEqualObjects(sample2_4,
                         expectedResult, @"Values should have been translated");
    
    NSArray *substitutedObjects = [NSArray arrayWithObjects:@"one", @"two", @"three", nil];

    XCTAssertEqualObjects(delegate2.replacedObjects,
                         substitutedObjects,
                         @"Should have been notified of translated values");
    
    maybe_release(encoder1);
    maybe_release(decoder);
    maybe_release(delegate2);
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
    
    XCTAssertFalse(delegate2.willFinish, @"Delegate received -decoderWillFinish before encoding finished");
    
    PersonWithCoding *lucy2 = [decoder decodeObjectWithClass:[PersonWithCoding class]];
    
    XCTAssertTrue(delegate2.willFinish, @"Delegate did not receive -decoderWillFinish");
    
    NSArray *createdPersonObjects = [NSArray arrayWithObjects:
                                     lucy2,
                                     [lucy2.children objectAtIndex:0],
                                     [[(PersonWithCoding *)[lucy2.children objectAtIndex:0] children] objectAtIndex:0],
    nil];
    
    NSUInteger awakenedPersonObjects = 0;
    for (PersonWithCoding *person in createdPersonObjects)
        if (person.awakeAfterCoder) awakenedPersonObjects = awakenedPersonObjects + 1;
    
    XCTAssertEqual(awakenedPersonObjects,
                   createdPersonObjects.count,
                   @"Person objects should have received awakeAfterUsingCoder");
    
    lucy.children = nil;
    littleRicky.children = nil;
    littlerRicky.children = nil;
    
    maybe_release(lucy);
    maybe_release(littleRicky);
    maybe_release(littlerRicky);
    maybe_release(encoder1);
    maybe_release(decoder);
    maybe_release(delegate2);
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
    XCTAssertThrows([encoder encodeObject:lucy],
                   @"Attempting to encode a nil objectID for a non-nil object should throw an exception");
    
    littleRicky.BSONObjectID = [BSONObjectID objectID];
    
    maybe_release(encoder);
    encoder = [[BSONEncoder alloc] initForWriting];
    encoder.delegate = delegate;
    [encoder encodeObject:lucy];
    
    BSONDecoder *decoder = [[BSONDecoder alloc] initWithDocument:[encoder BSONDocument]];
    PersonWithCoding *lucy2 = [decoder decodeObjectWithClass:[PersonWithCoding class]];
    
    XCTAssertEqualObjects(lucy2.name,
                         lucy.name,
                         @"Encoded name should match");
    XCTAssertEqual([lucy2.children count],
                   (NSUInteger)1,
                   @"Lucy should still have one child");
    XCTAssertEqualObjects([lucy2.children objectAtIndex:0],
                   littleRicky.BSONObjectID,
                   @"Lucy's child should be the object id");
    
    maybe_release(lucy);
    maybe_release(littleRicky);
    maybe_release(littlerRicky);
    maybe_release(encoder);
    maybe_release(delegate);
    maybe_release(decoder);
}

- (void) testDescription {
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

    BSONDocument *document = [BSONEncoder documentForObject:lucy];
    NSString *description = [document description];
    
/*
BSONDocument <0x106236cd0>   bson.data: 0x10623c440   bson.owned: 1
	name : 2 	 Lucy Ricardo
	dob : 9 	 [can't print this type]
	numberOfVisits : 18 	 [can't print this type]
	children : 4 	 
		0 : 3 	 
			name : 2 	 Ricky Ricardo, Jr.
			dob : 9 	 [can't print this type]
			numberOfVisits : 18 	 [can't print this type]
			children : 4 	 
				0 : 3 	 
					name : 2 	 Ricky Ricardo III
					dob : 9 	 [can't print this type]
					numberOfVisits : 18 	 [can't print this type]
					children : 4 	 
*/
    
    NSArray *searchTerms = [NSArray arrayWithObjects:@"name", @"dob", @"numberOfVisits", @"children", nil];
    NSCountedSet *occurrences = [NSCountedSet set];
    for (NSString *line in [description componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]])
        for (NSString *term in searchTerms)
            if (NSNotFound != [line rangeOfString:term].location)
                [occurrences addObject:term];
    
    XCTAssertEqual([occurrences countForObject:[searchTerms objectAtIndex:0]],
                    (NSUInteger)3,
                    @"'name' should appear three times");
    XCTAssertEqual([occurrences countForObject:[searchTerms objectAtIndex:1]],
                   (NSUInteger)3,
                   @"'dob' should appear three times");
    XCTAssertEqual([occurrences countForObject:[searchTerms objectAtIndex:2]],
                   (NSUInteger)3,
                   @"'numberOfVisits' should appear three times");
    XCTAssertEqual([occurrences countForObject:[searchTerms objectAtIndex:3]],
                   (NSUInteger)3,
                   @"'children' should appear three times");
    
    maybe_release(lucy);
    maybe_release(littleRicky);
    maybe_release(littlerRicky);
}

@end