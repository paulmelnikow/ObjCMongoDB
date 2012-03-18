//
//  GetLastErrorTest.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

//  Logic unit tests contain unit test code that is designed to be linked into an independent test executable.

#import <SenTestingKit/SenTestingKit.h>
#import "MongoConnection.h"

@interface GetLastErrorTest : SenTestCase {
    MongoConnection *_mongo;
}

@end
