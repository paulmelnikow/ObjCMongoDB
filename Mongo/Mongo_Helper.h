//
//  Mongo_Helper.h
//  ObjCMongoDB
//
//  Copyright 2012 Paul Melnikow and other contributors
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
#import "mongo.h"

__autoreleasing NSString * NSStringFromMongoErrorCode(mongo_error_t err);
__autoreleasing NSString * MongoErrorCodeDescription(mongo_error_t err);
__autoreleasing NSString * NSStringFromMongoCursorErrorCode(mongo_cursor_error_t err);
__autoreleasing NSString * MongoCursorErrorCodeDescription(mongo_cursor_error_t err);

#define set_error_and_return_NO   do { if (error) *error = [self error]; return NO; } while(0)
#define set_error_and_return_nil   do { if (error) *error = [self error]; return nil; } while(0)
#define set_error_and_return_BSON_ERROR   do { if (error) *error = [self error]; return BSON_ERROR; } while(0)

#define va_addToNSMutableArray(firstObject, array) \
do { \
    va_list args; \
    va_start(args, firstObject); \
    for (id obj = firstObject; obj != nil; obj = va_arg(args, id)) \
        [array addObject:obj]; \
    va_end(args); \
} while (0)