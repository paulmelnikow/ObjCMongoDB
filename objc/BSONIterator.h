//
//  BSONIterator.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "bson.h"

NSString * NSStringFromBSONType(bson_type t);

@class BSONDocument;
@class BSONObjectID;

@interface BSONIterator : NSEnumerator {
@private
    bson_iterator *_iter;
    BSONDocument *_document;
    bson *_b;
    bson_type _type;
}

+ (BSONIterator *)iteratorWithDocument:(BSONDocument *)document;

- (BOOL) hasMore;
- (bson_type) next;
- (bson_type) findKey:(NSString *)key;

- (bson_type) type;
- (NSString *) currentKey;
- (BOOL) isSubDocument;
- (BOOL) isArray;

- (BSONDocument *)subDocumentValue;
- (BSONIterator *)subIteratorValue;
- (id)objectValue;

- (double)doubleValue;
- (int)intValue;
- (int64_t)int64Value;
- (BOOL)boolValue;

- (BSONObjectID *)objectIDValue;

- (NSString *)stringValue;
- (int)stringLength;
- (id)symbolValue;

- (id) codeValue;
- (BSONDocument *) codeScopeValue;
- (id)codeWithScopeValue;

- (NSDate *)dateValue;

- (char)dataLength;
- (char)dataBinType;
- (NSData *)dataValue;

- (NSString *)regularExpressionPatternValue;
- (NSString *)regularExpressionOptionsValue;
- (id)regularExpressionValue;

- (bson_timestamp_t)nativeTimestampValue;
- (id)timestampValue;

@property (strong) id objectForNull;
@property (strong) id objectForUndefined;
@property (strong) id objectForEndOfObject;

@end
