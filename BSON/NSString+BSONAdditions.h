//
//  NSString+BSONAdditions.h
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

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const BSONErrorDomain;
FOUNDATION_EXPORT NSInteger const BSONKeyNameErrorStartsWithDollar;
FOUNDATION_EXPORT NSInteger const BSONKeyNameErrorHasDot;

@interface NSString (BSONAdditions)

/**
 Returns an <code>NSString</code> for a UTF-8 C string.
 @param cString A UTF-8 C string
 @return An <code>NSString</code> representation of the string
 */
+ (NSString *) stringWithBSONString:(const char *) cString;

/**
 Returns a UTF-8 C string for the receiver
 @return A UTF-8 C string representation of the receiver
 */
- (const char *) bsonString;

/**
 Tests if the receiver is a valid key name for MongoDB.
 @param error An optional error pointer to get a message about why it's invalid
 @return <code>YES</code> if the receiver is a valid
 */
- (BOOL) isValidKeyNameForMongoDB:(NSError * __autoreleasing *) error;

@end