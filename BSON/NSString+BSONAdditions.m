//
//  NSString+BSONAdditions.m
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 2/3/13.
//
//

#import "NSString+BSONAdditions.h"

@implementation NSString (BSONAdditions)

+ (NSString *) stringWithBSONString:(const char *) cString {
    if (!cString) return nil;
    return [self stringWithCString:cString encoding:NSUTF8StringEncoding];
}

- (const char *) bsonString {
    return [self cStringUsingEncoding:NSUTF8StringEncoding];
}

@end
