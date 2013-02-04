//
//  ObjCBSON.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
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


/*
 Convenience header for the library's public interface
 */


#import "BSONTypes.h"
#import "BSONDocument.h"
#import "BSONEncoder.h"
#import "BSONDecoder.h"
#import "BSONCoding.h"
#import "NSManagedObject+BSONCoding.h"

FOUNDATION_EXPORT NSString * const MongoDBObjectIDKey;
