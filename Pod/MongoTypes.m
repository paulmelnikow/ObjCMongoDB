//
//  MongoTypes.m
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

#import "MongoTypes.h"
#import "Interfaces-private.h"
#import <OrderedDictionary.h>

@interface MongoIndex ()
@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, retain, readwrite) NSString *namespaceContext;
@property (nonatomic, retain, readwrite) NSNumber *version;
@property (nonatomic, retain, readwrite) NSDictionary *fields;
@property (nonatomic, retain, readwrite) NSDictionary *dictionaryValue;
@end

@implementation MongoIndex

// Takes a result dictionary from db.collection.getIndexes
// http://docs.mongodb.org/manual/reference/method/db.collection.getIndexes
- (id) initWithDictionary:(NSDictionary *) dictionary {
    if (self = [super init]) {
        self.name = [dictionary objectForKey:@"name"];
        self.namespaceContext = [dictionary objectForKey:@"ns"];
        self.version = [dictionary objectForKey:@"v"];
        self.fields = [dictionary objectForKey:@"key"];
        self.dictionaryValue = dictionary;
    }
    return self;
}

+ (MongoIndex *) indexWithDictionary:(NSDictionary *) dictionary {
    return [[self alloc] initWithDictionary:dictionary];
}

- (NSString *) description {
    NSMutableString *result = [NSMutableString stringWithFormat:@"%@ <%p>\n", [[self class] description], self];
    [result appendFormat:@"name = %@\n", self.name];
    [result appendFormat:@"namespaceContext = %@\n", self.namespaceContext];
    [result appendFormat:@"version = %@\n", self.version];
    [result appendFormat:@"fields = %@\n", [self.fields count] ? self.fields : @"{ }"];
    return result;
}

@end

@implementation MongoMutableIndex

- (id) init {
    if (self = [super init]) {
        self.fields = [MutableOrderedDictionary dictionary];
    }
    return self;
}

+ (MongoMutableIndex *) mutableIndex {
    return [[self alloc] init];
}

- (MutableOrderedDictionary *) mutableFields {
    return (MutableOrderedDictionary *) self.fields;
}

- (void) _setField:(NSString *) fieldName value:(id) value {
    if ([self.mutableFields objectForKey:fieldName])
        [NSException raise:NSInvalidArgumentException format:@"Duplicate field name"];
    [self.mutableFields setObject:value forKey:fieldName];
}

- (void) addField:(NSString *) fieldName {
    [self addField:fieldName ascending:YES];
}

- (void) addField:(NSString *) fieldName ascending:(BOOL) ascending {
    [self _setField:fieldName value:ascending ? @(1) : @(-1)];
}

- (void) addGeospatialField:(NSString *) fieldName {
    [self _setField:fieldName value:@"2d"];
}

- (void) addGeospatialSphericalField:(NSString *) fieldName {
    [self _setField:fieldName value:@"2dsphere"];
}

- (NSDictionary *) dictionaryValue {
    return nil;
}

- (mongoc_index_opt_t) options {
    mongoc_index_opt_t options;
    mongoc_index_opt_init(&options);
    
    options.unique = self.unique;
    options.sparse = self.sparse;
    options.background = self.createInBackground;
    options.drop_dups = self.createDroppingDuplicates;
    
    // TODO more options
    
    return options;
}

@end
