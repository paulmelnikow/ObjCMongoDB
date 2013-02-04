//
//  NSString+BSONAdditions.m
//  ObjCMongoDB
//
//  Copyright 2013 Paul Melnikow and other contributors
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
