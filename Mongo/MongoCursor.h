//
//  MongoCursor.h
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
#import "BSONDocument.h"

@interface MongoCursor : NSEnumerator

- (BSONDocument *) nextObject;
/* This method is optimized for efficiency, not safety. In particular subobjects
 (including code scope documents) may become invalid when the cursor advances or
 is deallocated. When in doubt, invoke -nextObject instead which makes a safe
 copy of the document. */
- (BSONDocument *) nextObjectNoCopy;
- (NSArray *) allObjects;

@end
