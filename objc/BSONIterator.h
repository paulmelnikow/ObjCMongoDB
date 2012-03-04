//
//  BSONDocument.h
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
#import "bson.h"
#import "BSONTypes.h"

@class BSONDocument;
@class BSONObjectID;

@interface BSONIterator : NSObject {
@private
    bson_iterator *_iter;
    BSONDocument *_document;
    bson *_b;
    bson_type _type;
}

+ (id) objectForUndefinedValue;

/*
 Searches for the key <i>key</i> in the iterator's BSON document.
 @return <code>YES</code> if the key is present, and <code>NO</code> otherwise.
 @param key The key to search for
 */
- (BOOL) containsValueForKey:(NSString *) key;

/*
 Searches for the key <i>key</i> in the iterator's BSON document.
 @param key The key to search for
 @return The native BSON type of the key (<code>bson_eoo</code> if the key is not present)
 */
- (bson_type) nativeValueTypeForKey:(NSString *)key;

/*
 Attempts to advance the iterator to the next item in the document.
 @return The native BSON type of the next item in the document (<code>bson_eoo</code> if there are no more)
 */
- (bson_type) next;

/*
 Returns a Boolean indicating whether there are more items in the document.
 @return <code>YES</code> if there are more items, <code>NO</code> otherwise
 */
- (BOOL) hasMore;

/*
 Returns the key of the current item.
 @return An autoreleased string with the key for the current item
 */
- (NSString *) key;

/*
 Returns the BSON value type of the current item.
 @return The native BSON value type of the current item.
 */
- (bson_type) nativeValueType;

- (id) objectValue;
- (id) objectForKey:(NSString *)key;

- (BOOL) isSubDocument;
- (BOOL) isArray;

- (BSONIterator *) subIteratorValue;
- (BSONDocument *) subDocumentValue;

- (double) doubleValue;
- (int) intValue;
- (int64_t) int64Value;
- (BOOL) boolValue;

- (BSONObjectID *) objectIDValue;

- (NSString *) stringValue;
- (int) stringLength;
- (BSONSymbol *) symbolValue;

- (BSONCode *) codeValue;
- (BSONCodeWithScope *) codeWithScopeValue;

- (NSDate *) dateValue;

- (char) dataLength;
- (char) dataBinType;
- (NSData *) dataValue;

- (NSString *)regularExpressionPatternValue;
- (NSString *)regularExpressionOptionsValue;
- (BSONRegularExpression *)regularExpressionValue;

- (BSONTimestamp *) timestampValue;

@end
