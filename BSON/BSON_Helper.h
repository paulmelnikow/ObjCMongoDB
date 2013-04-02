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

#import <Foundation/Foundation.h>
#import "BSONIterator.h"

#if __has_feature(objc_arc)
#define maybe_retain(x) x
#define maybe_retain_void(x)
#define maybe_release(x)
#define maybe_autorelease(x) x
#define maybe_autorelease_void(x)
#define maybe_autorelease_and_return(x) do { return x; } while(0)
#define maybe_retain_autorelease_and_return(x) do { return x; } while(0)
#define super_dealloc
#define nullify_self_and_return do { return self = nil; } while(0)
#else
#define maybe_retain(x) [x retain]
#define maybe_retain_void(x) [x retain]
#define maybe_release(x) [x release]
#define maybe_autorelease(x) [x autorelease]
#define maybe_autorelease_void(x) [x autorelease]
#define maybe_autorelease_and_return(x) do { return [x autorelease]; } while(0)
#define maybe_retain_autorelease_and_return(x) do { return [[x retain] autorelease]; } while(0)
#define super_dealloc [super dealloc]
#define nullify_self_and_return do { [self release]; return self = nil; } while(0)
#endif

// For macros bson_type_case in BSONTypes.m, mongo_error_case in Mongo_Helper.m
#define NSStringize_helper(x) #x
#define NSStringize(x) @NSStringize_helper(x)

__autoreleasing NSString * NSStringFromBSONError(int err);
