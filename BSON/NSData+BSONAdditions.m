//
//  NSData+BSONAdditions.m
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

#import "NSData+BSONAdditions.h"

@implementation NSData (BSONAdditions)

+ (NSData *) dataWithNativeBSONObject:(const bson *) bson copy:(BOOL) copy {
    if (!bson) return nil;
    void *bytes = (void *)bson_data(bson);
    int size = bson_size(bson);
    if (copy)
        return [NSData dataWithBytes:bytes length:size];
    else
        return [NSData dataWithBytesNoCopy:bytes length:size freeWhenDone:NO];    
}

@end
