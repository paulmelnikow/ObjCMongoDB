//
//  NSArray+MongoAdditions.m
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

#import "NSArray+MongoAdditions.h"

@implementation NSArray (MongoAdditions)

+ (NSArray *) arrayWithPoint:(CGPoint) point {
    return @[ @(point.x), @(point.y) ];
}

+ (NSArray *) arrayWithRect:(CGRect) rect {
    id firstCoord = @[ @(rect.origin.x), @(rect.origin.y) ];
    id secondCoord = @[ @(rect.origin.x + rect.size.width), @(rect.origin.y + rect.size.height) ];
    return @[ firstCoord, secondCoord ];
}

@end
