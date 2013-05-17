//
//  BSONCoreDataTest.m
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

#import <SenTestingKit/SenTestingKit.h>
#import <CoreData/CoreData.h>
#import "CDPerson.h"
#import "BSONEncoder.h"
#import "BSONDecoder.h"
#import "BSONDocument.h"
#import "BSONTypes.h"
#import "BSONCoding.h"
#import "BSON_Helper.h"

@interface BSONCoreDataTest : SenTestCase

@property (retain) NSManagedObjectModel *mom;
@property (retain) NSPersistentStoreCoordinator *psc;
@property (retain) NSManagedObjectContext *moc;
@property (retain) NSDateFormatter *df;

@end

@implementation BSONCoreDataTest

-(void)setUp {
    self.df = [[NSDateFormatter alloc] init];
    [self.df setLenient:YES];
    [self.df setTimeStyle:NSDateFormatterNoStyle];
    [self.df setDateStyle:NSDateFormatterShortStyle];

    // Set up managed object context
    self.mom = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:[NSBundle bundleForClass:[self class]]]];
    self.psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_mom];
    self.moc = [[NSManagedObjectContext alloc] init];
    self.moc.persistentStoreCoordinator = self.psc;
}

-(void)tearDown {
    maybe_release(_mom);
    maybe_release(_psc);
    maybe_release(_moc);
    [super tearDown];
}

- (void) testEncodeCDPerson {
    CDPerson *lucy = [NSEntityDescription insertNewObjectForEntityForName:[[CDPerson class] description] inManagedObjectContext:_moc];
    lucy.name = @"Lucy Ricardo";
    lucy.dob = [self.df dateFromString:@"Jan 1, 1920"];
    lucy.numberOfVisits = [NSNumber numberWithInteger:75];
    
    CDPerson *littleRicky = [NSEntityDescription insertNewObjectForEntityForName:[[CDPerson class] description] inManagedObjectContext:_moc];
    littleRicky.name = @"Ricky Ricardo, Jr.";
    littleRicky.dob = [self.df dateFromString:@"Jan 19, 1953"];
    littleRicky.numberOfVisits = [NSNumber numberWithInteger:15];

    CDPerson *littlerRicky = [NSEntityDescription insertNewObjectForEntityForName:[[CDPerson class] description] inManagedObjectContext:_moc];
    littlerRicky.name = @"Ricky Ricardo III";
    littlerRicky.dob = [self.df dateFromString:@"Jan 19, 1975"];
    littlerRicky.numberOfVisits = [NSNumber numberWithInteger:1];
    
    [lucy addChildrenObject:littleRicky];
    [littleRicky addChildrenObject:littlerRicky];
    
    BSONEncoder *encoder = [[BSONEncoder alloc] initForWriting];
    [encoder encodeObject:lucy];
    
    BSONDecoder *decoder = [[BSONDecoder alloc] initWithDocument:[encoder BSONDocument]];
    decoder.managedObjectContext = self.moc;
    CDPerson *lucy2 = [decoder decodeObjectWithClass:[CDPerson class]];
    CDPerson *littleRicky2 = [[[lucy2 children] allObjects] objectAtIndex:0];
    CDPerson *littlerRicky2 = [[[littleRicky2 children] allObjects] objectAtIndex:0];
    
    STAssertTrue([littlerRicky2 isEqualForTesting:littlerRicky], @"Objects should be equal");
    STAssertTrue([littleRicky2 isEqualForTesting:littleRicky], @"Objects should be equal");
    STAssertTrue([lucy2 isEqualForTesting:lucy], @"Objects should be equal");
    
    maybe_release(encoder);
    maybe_release(decoder);
}

@end
