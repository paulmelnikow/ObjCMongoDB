//
//  NSString+BSONAdditions.m
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 2/3/13.
//
//

#import "NSString+BSONAdditions.h"

NSString * const BSONErrorDomain = @"BSONErrorDomain";
NSInteger const BSONKeyNameErrorStartsWithDollar = 101;
NSInteger const BSONKeyNameErrorHasDot = 102;

@implementation NSString (BSONAdditions)

+ (NSString *) stringWithBSONString:(const char *) cString {
    if (!cString) return nil;
    return [self stringWithCString:cString encoding:NSUTF8StringEncoding];
}

- (const char *) bsonString {
    return [self cStringUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL) isValidKeyNameForMongoDB:(NSError * __autoreleasing *) error {
    NSString *message = nil;
    NSInteger code = 0;
    
    if ([self hasPrefix:@"$"]) {
        message = [NSString stringWithFormat:
                   @"Invalid key %@ - MongoDB keys may not begin with '$'", self];
        code = BSONKeyNameErrorStartsWithDollar;
    } else if (NSNotFound != [self rangeOfString:@"."].location) {
        message = [NSString stringWithFormat:
                   @"Invalid key %@ - MongoDB keys may not contain '.'", self];
        code = BSONKeyNameErrorHasDot;
    }
    
    if (code == 0) return YES;
    
    if (error) {
        *error = [NSError errorWithDomain:BSONErrorDomain
                                     code:code
                                 userInfo:@{ NSLocalizedDescriptionKey : message }];
    }
    return NO;
}

@end
