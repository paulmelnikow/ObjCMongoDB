//
//  Mongo_PrivateInterfaces.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 1/23/13.
//
//

//
// This file is imported internally by classes in the framework to interact with each other. Don't use it in
// your application. Use the classes' public interfaces instead.
//

#import "BSON_PrivateInterfaces.h"

@interface MongoConnection (Project)
- (mongo *) connValue;
@end