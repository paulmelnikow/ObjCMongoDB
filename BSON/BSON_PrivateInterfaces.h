//
//  BSON_PrivateInterfaces.h
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


//
// This file is imported internally by classes in the framework to interact with each other. Don't use it in
// your application. Use the classes' public interfaces instead.
//

#import "BSONDocument.h"
#import "BSONEncoder.h"

@interface BSONDocument (Project)
- (const bson *) bsonValue;
@end

@interface BSONEncoder (Project)
- (bson *) bsonValue;
@end

@interface BSONObjectID (Project)
- (bson_oid_t) oid;
- (const bson_oid_t *) objectIDPointer;
@end

@interface BSONTimestamp (Project)
- (bson_timestamp_t *) timestampPointer;
@end

@interface BSONIterator (Project)
- (BSONIterator *) initWithDocument:(BSONDocument *)document
             keyPathComponentsOrNil:(NSArray *) keyPathComponents;
- (bson_iterator *) nativeIteratorValue;
@end