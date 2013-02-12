//
//  MongoConnection+Commands.m
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 2/11/13.
//
//

#import "MongoConnection+Commands.h"

@implementation MongoConnection (Commands)

- (NSString *) serverVersion {
    BSONDocument *result = [self runCommandWithName:@"buildInfo"
                                     onDatabaseName:@"admin"
                                              error:nil];
    if (!result) return nil;
    NSDictionary *resultDict = [BSONDecoder decodeDictionaryWithDocument:result];
    return [resultDict objectForKey:@"version"];
}

@end
