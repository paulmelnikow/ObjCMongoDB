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
#define maybe_autorelease_and_return(x) do { return x; } while(0)
#define maybe_retain_autorelease_and_return(x) do { return x; } while(0)
#else
#define maybe_autorelease_and_return(x) do { return [x autorelease]; } while(0)
#define maybe_retain_autorelease_and_return(x) do { return [[x retain] autorelease]; } while(0)
#endif

/**
 Raises an exception for a nil key.
 @param key The key to test
 */
void BSONAssertKeyNonNil (NSString *key);

/**
 Raises an exception for key which is illegal in MongoDB.
 @param key The key to test
 */
void BSONAssertKeyLegalForMongoDB(NSString *key);

/**
 Raises an exception for a nil value.
 @param key The value to test
 */
void BSONAssertValueNonNil (id key);

/**
 Raises an exception if the iterator's native value type doesn't match the
 expected type.
 @param iterator A BSON iterator
 @param valueType The expected native value type
 */
void BSONAssertIteratorIsValueType (BSONIterator * iterator, BSONType valueType);

/**
 Raises an exception if the iterator's native value type doesn't match one of the
 expected types.
 @param iterator A BSON iterator
 @param valueType A C array of allowed native value types
 */
void BSONAssertIteratorIsInValueTypeArray (BSONIterator * iterator, BSONType * valueType);

__autoreleasing NSString * NSStringFromBSONError(int err);
