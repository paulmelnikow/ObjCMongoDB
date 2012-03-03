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
- (NSString *)symbolValue;

- (NSString *) codeValue;
- (BSONDocument *) codeScopeValue;
- (NSDictionary *)codeWithScopeValue;

- (NSDate *)dateValue;

- (char)dataLength;
- (char)dataBinType;
- (NSData *)dataValue;

- (NSString *)regularExpressionPatternValue;
- (NSString *)regularExpressionOptionsValue;
- (NSArray *)regularExpressionValue;

- (bson_timestamp_t)nativeTimestampValue;
- (NSDictionary *)timestampValue;

@property (strong) id objectForUndefined;

@end
