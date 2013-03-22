//
//  MongoTypes.h
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

@interface MongoIndex : NSObject

@property (nonatomic, readonly, retain) NSString *name;
@property (nonatomic, readonly, retain) NSString *namespaceContext;
@property (nonatomic, readonly, retain) NSNumber *version;
@property (nonatomic, readonly, retain) NSDictionary *fields;

@property (nonatomic, readonly, retain) NSDictionary *dictionaryValue;

@end

@interface MongoMutableIndex : MongoIndex

+ (MongoMutableIndex *) mutableIndex;

@property (nonatomic, readwrite, retain) NSString *name;
@property (assign) BOOL unique;
@property (assign) BOOL sparse;
@property (assign) BOOL createInBackground;
@property (assign) BOOL createDroppingDuplicates;

- (void) addField:(NSString *) fieldName;
- (void) addField:(NSString *) fieldName ascending:(BOOL) ascending;
- (void) addGeospatialField:(NSString *) fieldName;

@end
