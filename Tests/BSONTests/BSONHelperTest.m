//
//  BSONHelperTest.m
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 2/3/13.
//
//

#import "BSONHelperTest.h"
#import "BSON_Helper.h"

@implementation BSONHelperTest

- (void) testNSStringFromBSONType {
    STAssertEqualObjects(@"BSONTypeLong",
                         NSStringFromBSONType(BSONTypeLong);
}

@end
