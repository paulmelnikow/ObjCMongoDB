//
//  BSONUnarchiver.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "bson.h"

@class BSONIterator;
@class BSONDocument;
@class BSONObjectID;

@interface BSONUnarchiver : NSCoder {
    BSONIterator *_iterator;
}

+ (BSONUnarchiver *) unarchiverWithDocument:(BSONDocument *)document;
+ (BSONUnarchiver *) unarchiverWithData:(NSData *)data;

- (NSDictionary *) decodeDictionary;
- (NSArray *) decodeArray;

- (NSDictionary *)decodeDictionaryForKey:(NSString *)key;
- (NSArray *)decodeArrayForKey:(NSString *)key;
- (id) decodeObjectForKey:(NSString *)key;

- (BSONObjectID *) decodeObjectIDForKey:(NSString *)key;
- (int) decodeIntForKey:(NSString *)key;
- (int64_t) decodeInt64ForKey:(NSString *)key;
- (BOOL) decodeBoolForKey:(NSString *)key;
- (double) decodeDoubleForKey:(NSString *)key;
- (NSDate *) decodeDateForKey:(NSString *)key;
- (NSImage *) decodeImageForKey:(NSString *)key;
- (NSString *) decodeStringForKey:(NSString *)key;
- (id) decodeSymbolForKey:(NSString *)key;
- (id) decodeRegularExpressionForKey:(NSString *)key;
- (BSONDocument *) decodeBSONDocumentForKey:(NSString *)key;
- (NSData *)decodeDataForKey:(NSString *)key;
- (id) decodeCodeForKey:(NSString *)key;
- (id) decodeCodeWithScopeForKey:(NSString *)key;


@property (strong) id objectForNull;
@property (strong) id objectForUndefined;

@end
