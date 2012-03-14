//
//  Mongo_Helper.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "mongo.h"

#define set_error_and_return_NO   do { if (error) *error = [self error]; return NO; } while(0)
#define set_error_and_return_nil   do { if (error) *error = [self error]; return nil; } while(0)
#define set_error_and_return_BSON_ERROR   do { if (error) *error = [self error]; return BSON_ERROR; } while(0)

NSString * NSStringFromMongoErrorCode(mongo_error_t err);
NSString * MongoErrorCodeDescription(mongo_error_t err);


#define va_addToNSMutableArray(firstObject, array) \
do { \
    va_list args; \
    va_start(args, firstObject); \
    for (id obj = firstObject; obj != nil; obj = va_arg(args, id)) \
        [array addObject:obj]; \
    va_end(args); \
} while (0)