//
//  BSON_Helper.h
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

#import "BSON_Helper.h"
#import "BSON_PrivateInterfaces.h"

__autoreleasing NSString * NSStringFromBSONError(int err) {
    NSMutableArray *errors = [NSMutableArray array];
    if (err & BSON_NOT_UTF8) [errors addObject:@"BSON_NOT_UTF8"];
    if (err & BSON_FIELD_HAS_DOT) [errors addObject:@"BSON_FIELD_HAS_DOT"];
    if (err & BSON_FIELD_INIT_DOLLAR) [errors addObject:@"BSON_FIELD_INIT_DOLLAR"];
    if (err & BSON_ALREADY_FINISHED) [errors addObject:@"BSON_ALREADY_FINISHED"];
    
    if (errors.count)
        return [errors componentsJoinedByString:@" | "];
    else
        return @"BSON_VALID";
}

