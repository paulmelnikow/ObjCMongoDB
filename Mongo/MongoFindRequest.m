//
//  MongoFindRequest.m
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

#import "MongoFindRequest.h"
#import "ObjCMongoDB.h"
#import "mongo.h"
#import "Mongo_PrivateInterfaces.h"
#import "BSON_Helper.h"

@interface MongoFindRequest ()

@property (retain) OrderedDictionary *fields;
@property (retain) OrderedDictionary *sort;
@property (retain) OrderedDictionary *hint;

@end

@implementation MongoFindRequest

#pragma mark - Initialization

- (id) init {
    if (self = [super init]) {
        self.fields = [OrderedDictionary dictionary];
        self.sort = [OrderedDictionary dictionary];
        self.hint = [OrderedDictionary dictionary];
        self.timeoutEnabled = YES;
    }
    return self;
}

- (void) dealloc {
    maybe_release(_predicate);
    maybe_release(_lowerIndexBound);
    maybe_release(_upperIndexBound);
    maybe_release(_fields);
    maybe_release(_sort);
    maybe_release(_hint);
    super_dealloc;
}

+ (MongoFindRequest *) findRequest {
    return [self findRequestWithPredicate:nil];
}

+ (MongoFindRequest *) findRequestWithPredicate:(MongoPredicate *) predicate {
    MongoFindRequest *result = [[self alloc] init];
    result.predicate = predicate;
    maybe_autorelease_and_return(result);
}

#pragma mark - Manipulating the request

- (void) includeKey:(NSString *) key {
    [self.fields setValue:@(1) forKey:key];
}

- (void) excludeKey:(NSString *) key {
    [self.fields setValue:@(0) forKey:key];
}

- (void) includeFirst:(NSUInteger) numElements objectsFromArrayWithKey:(NSString *) key {
    id operator = [OrderedDictionary dictionaryWithObject:@(numElements)
                                                   forKey:@"$slice"];
    [self.fields setValue:operator forKey:key];
}

- (void) includeLast:(NSUInteger) numElements objectsFromArrayWithKey:(NSString *) key {
    id operator = [OrderedDictionary dictionaryWithObject:@(-numElements)
                                                   forKey:@"$slice"];
    [self.fields setValue:operator forKey:key];
}

- (void) includeRange:(NSRange) range objectsFromArrayWithKey:(NSString *) key {
    id rangeAsArray = [NSArray arrayWithObjects:
                       @(range.location),
                       @(NSMaxRange(range)),
                       nil];
    id operator = [OrderedDictionary dictionaryWithObject:rangeAsArray
                                                   forKey:@"$slice"];
    [self.fields setValue:operator forKey:key];
}

- (void) sortByKey:(NSString *) key ascending:(BOOL) ascending {
    [self.sort setValue:@(ascending ? 1 : -1) forKey:key];
}

- (void) hintIndexKey:(NSString *) key ascending:(BOOL) ascending {
    [self.hint setValue:@(ascending ? 1 : -1) forKey:key];
}

#pragma mark - Getting the result

- (BSONDocument *) fieldsDocument {
    if (![self.fields count]) return nil;
    return [self.fields BSONDocumentRestrictingKeyNamesForMongoDB:NO];
}

- (OrderedDictionary *) queryDictionaryValue {
    OrderedDictionary *result = [OrderedDictionary dictionary];
    
    if (self.predicate)
        [result setObject:[self.predicate dictionary] forKey:@"$query"];
    else
        [result setObject:[NSDictionary dictionary] forKey:@"$query"];
    
    if ([self.sort count])
        [result setObject:self.sort forKey:@"$orderby"];
    if ([self.hint count])
        [result setObject:self.hint forKey:@"$hint"];
    if (self.includeIndexKeyOnly)
        [result setObject:@(YES) forKey:@"$returnKey"];
    if (self.explain)
        [result setObject: @(YES) forKey:@"$explain"];
    if (self.snapshotMode)
        [result setObject: @(YES) forKey:@"$snapshot"];
    if (self.showDiskLocation)
        [result setObject: @(YES) forKey:@"$showDiskLoc"];
    if (self.comment)
        [result setObject:self.comment forKey:@"$comment"];
    if (self.maximumDocumentsToScan)
        [result setObject:@(self.maximumDocumentsToScan)
                   forKey:@"$maxScan"];
    if (self.lowerIndexBound)
        [result setObject:[self.lowerIndexBound dictionary] forKey:@"$min"];
    if (self.upperIndexBound)
        [result setObject:[self.upperIndexBound dictionary] forKey:@"$max"];
    
    if (1 == [result count])
        // that means $query is the only key in the dictionary
        return [result objectForKey:@"$query"];
    else
        return result;
}

- (BSONDocument *) queryDocument {
    return [self.queryDictionaryValue BSONDocumentRestrictingKeyNamesForMongoDB:NO];
}

- (int) options {
    int options = 0;
    if (self.fetchAllResultsImmediately) options |= MONGO_EXHAUST;
    if (!self.timeoutEnabled) options |= MONGO_NO_CURSOR_TIMEOUT;
    if (self.tailable) options |= MONGO_TAILABLE;
    if (self.tailableQueryBlocksAwaitingData) options |= MONGO_AWAIT_DATA;
    if (self.allowQueryOfNonPrimaryServer) options |= MONGO_SLAVE_OK;
    if (self.allowPartialResults) options |= MONGO_PARTIAL;
    return options;
}

- (NSString *) description {
    NSMutableString *result = [NSMutableString stringWithFormat:@"%@ <%p>\n", [[self class] description], self];
    [result appendFormat:@"predicate = %@\n", self.predicate ? self.predicate : @"{ }"];
    [result appendFormat:@"fields = %@\n", [self.fields count] ? self.fields : @"{ }"];
    [result appendFormat:@"sort = %@\n", [self.sort count] ? self.sort : @"{ }"];
    [result appendFormat:@"limitResults = %d\nskipResults = %d\n", self.limitResults, self.skipResults];
    [result appendString:@"options = {\n"];
    static NSArray *optionKeys;
    if (!optionKeys)
        optionKeys = [NSArray arrayWithObjects:
                      @"fetchAllResultsImmediately",
                      @"timeoutEnabled",
                      @"tailable",
                      @"tailableQueryBlocksAwaitingData",
                      @"allowQueryOfNonPrimaryServer",
                      @"allowPartialResults",
                      nil];
    for (NSString *key in optionKeys)
        [result appendFormat:@"    %@ = %@\n", key, [self valueForKey:key]];
    [result appendFormat:@"    intValue = %i\n}\n", [self options]];
    [result appendString:@"specials = {\n"];
    static NSArray *specialKeys;
    if (!specialKeys)
        specialKeys = [NSArray arrayWithObjects:
                       @"includeIndexKeyOnly",
                       @"explain",
                       @"snapshotMode",
                       @"showDiskLocation",
                       @"comment",
                       @"maximumDocumentsToScan",
                       @"lowerIndexBound",
                       @"upperIndexBound",
                       nil];
    for (NSString *key in specialKeys)
        [result appendFormat:@"    %@ = %@\n", key, [self valueForKey:key]];
    [result appendString:@"}\n"];

    return result;
}

@end
