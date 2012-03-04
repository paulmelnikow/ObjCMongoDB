//
//  BSONUnarchiver.h
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

@class BSONIterator;
@class BSONDocument;
@class BSONObjectID;

@interface BSONUnarchiver : NSCoder {
    BSONIterator *_iterator;
}

+ (BSONUnarchiver *) unarchiverWithDocument:(BSONDocument *)document;
+ (BSONUnarchiver *) unarchiverWithData:(NSData *)data;

- (NSDictionary *) decodeDictionary;

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
- (BSONSymbol *) decodeSymbolForKey:(NSString *)key;
- (BSONRegularExpression *) decodeRegularExpressionForKey:(NSString *)key;
- (BSONDocument *) decodeBSONDocumentForKey:(NSString *)key;
- (NSData *)decodeDataForKey:(NSString *)key;
- (id) decodeCodeForKey:(NSString *)key;
- (id) decodeCodeWithScopeForKey:(NSString *)key;


@property (strong) id objectForNull;
@property (strong) id objectForUndefined;

@end
