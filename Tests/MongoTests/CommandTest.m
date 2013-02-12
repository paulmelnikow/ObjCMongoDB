//
//  CommandTest.m
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 2/11/13.
//
//

#import "CommandTest.h"
#import "ObjCMongoDB.h"

@implementation CommandTest {
    MongoConnection *_mongo;
}

-(void) setUp {
    NSError *error = nil;
    _mongo = [MongoConnection connectionForServer:@"127.0.0.1" error:&error];
    STAssertNil(error, error.localizedDescription);
}

- (void) tearDown {
    [_mongo disconnect];
    _mongo = nil;
}

- (void) testBuildInfo {
    NSError *error = nil;
    BSONDocument *result = [_mongo runCommandWithName:@"buildInfo"
                                       onDatabaseName:@"admin"
                                                error:&error];
    NSDictionary *resultDict = [BSONDecoder decodeDictionaryWithDocument:result];
    NSString *version = [resultDict objectForKey:@"version"];
    STAssertNotNil(version, nil);
    STAssertTrue(version.length > 3, nil);
}

- (void) testServerVersion {
    NSError *error = nil;
    BSONDocument *result = [_mongo runCommandWithName:@"buildInfo"
                                       onDatabaseName:@"admin"
                                                error:&error];
    NSDictionary *resultDict = [BSONDecoder decodeDictionaryWithDocument:result];
    NSString *myVersion = [resultDict objectForKey:@"version"];

    NSString *version = [_mongo serverVersion];
    
    STAssertEqualObjects(myVersion, version, nil);
}

@end
