//
//  MongoConnection+Commands.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 2/11/13.
//
//

#import <ObjCMongoDB/ObjCMongoDB.h>

@interface MongoConnection (Commands)

- (NSString *) serverVersion;

@end
