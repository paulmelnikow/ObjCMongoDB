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

NSString * NSStringFromBSONType(bson_type t);

@class BSONDocument;
@class BSONObjectID;

@interface BSONIterator : NSObject {
@private
    bson_iterator *_iter;
    BSONDocument *_document;
    bson *_b;
    bson_type _type;
}

- (BOOL) hasMore;
- (bson_type) next;
- (bson_type) findKey:(NSString *)key;

- (bson_type) type;
- (NSString *) currentKey;

- (id) objectValue;
- (id) objectForKey:(NSString *)key;

- (BOOL) isSubDocument;
- (BOOL) isArray;

- (BSONDocument *) subDocumentValue;
- (BSONIterator *) subIteratorValue;

- (double) doubleValue;
- (int) intValue;
- (int64_t) int64Value;
- (BOOL) boolValue;

- (BSONObjectID *)objectIDValue;

- (NSString *) stringValue;
- (int) stringLength;
- (NSString *) symbolValue;

- (NSString *) codeValue;
- (BSONDocument *) codeScopeValue;
- (NSDictionary *) codeWithScopeValue;

- (NSDate *) dateValue;

- (char) dataLength;
- (char) dataBinType;
- (NSData *) dataValue;

- (NSString *)regularExpressionPatternValue;
- (NSString *)regularExpressionOptionsValue;
- (NSArray *)regularExpressionValue;

- (bson_timestamp_t)nativeTimestampValue;
- (NSDictionary *)timestampValue;

@property (strong) id objectForUndefined;

@end
