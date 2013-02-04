//
//  NSString+BSONAdditions.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 2/3/13.
//
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