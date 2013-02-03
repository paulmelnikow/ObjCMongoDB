//
//  NSString+BSONAdditions.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 2/3/13.
//
//

#import <Foundation/Foundation.h>

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

@end
