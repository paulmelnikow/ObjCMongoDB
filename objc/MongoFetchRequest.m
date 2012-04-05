//
//  MongoFetchRequest.m
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MongoFetchRequest.h"

NSString * const MongoSliceOperator = @"$slice";

NSString * const MongoQueryMetaOperator = @"$query";
NSString * const MongoReturnIndexOnlyMetaOperator = @"$returnKey";
NSString * const MongoMaximumDocumentsToScanMetaOperator = @"$maxScan";
NSString * const MongoOrderByMetaOperator = @"$orderby";
NSString * const MongoExplainMetaOperator = @"$explain";
NSString * const MongoSnapshotMetaOperator = @"$snapshot";
NSString * const MongoLowerIndexBoundMetaOperator = @"$min";
NSString * const MongoUpperIndexBoundMetaOperator = @"$max";
NSString * const MongoShowDiskLocationMetaOperator = @"$showDiskLoc";
NSString * const MongoIndexHintMetaOperator = @"$hint";
NSString * const MongoCommentMetaOperator = @"$comment";

@implementation MongoFetchRequest
@synthesize predicate, limitResults, skipResults;
@synthesize fetchAllResultsImmediately, timeoutEnabled, tailable, tailableQueryBlocksAwaitingData;
@synthesize allowQueryOfNonPrimaryServer, allowPartialResults;
@synthesize includeIndexKeyOnly, explain, snapshotMode, showDiskLocation, comment;
@synthesize maximumDocumentsToScan, lowerIndexBound, upperIndexBound;

#pragma mark - Initialization

- (id) init {
    if (self = [super init]) {
        _fields = [[OrderedDictionary alloc] init];
        _sort = [[OrderedDictionary alloc] init];
        _hint = [[OrderedDictionary alloc] init];        
        self.timeoutEnabled = YES;
    }
    return self;
}

- (void) dealloc {
#if !__has_feature(objc_arc)
    [_fields release];
    [_sort release];
    [_hint release];
#endif
}

+ (MongoFetchRequest *) fetchRequest {
    MongoFetchRequest *result = [[self alloc] init];
#if !__has_feature(objc_arc)
    [result autorelease];
#endif
    return result;
}

+ (MongoFetchRequest *) fetchRequestWithPredicate:(MongoPredicate *) predicate {
    MongoFetchRequest *request = [self fetchRequest];
    request.predicate = predicate;
    return request;
}

#pragma mark - Manipulating the request

- (void) includeKey:(NSString *) key {
    [_fields setValue:[NSNumber numberWithInt:1] forKey:key];
}

- (void) excludeKey:(NSString *) key {
    [_fields setValue:[NSNumber numberWithInt:0] forKey:key];
}

- (void) includeFirst:(NSUInteger) numElements objectsFromArrayWithKey:(NSString *) key {
    id operator = [OrderedDictionary dictionaryWithObject:[NSNumber numberWithInteger:numElements]
                                                   forKey:MongoSliceOperator];
    [_fields setValue:operator forKey:key];
}

- (void) includeLast:(NSUInteger) numElements objectsFromArrayWithKey:(NSString *) key {
    id operator = [OrderedDictionary dictionaryWithObject:[NSNumber numberWithInteger:-numElements]
                                                   forKey:MongoSliceOperator];
    [_fields setValue:operator forKey:key];
}

- (void) includeRange:(NSRange) range objectsFromArrayWithKey:(NSString *) key {
    id rangeAsArray = [NSArray arrayWithObjects:
                [NSNumber numberWithInteger:range.location],
                [NSNumber numberWithInteger:NSMaxRange(range)],
                nil];
    id operator = [OrderedDictionary dictionaryWithObject:rangeAsArray
                                                   forKey:MongoSliceOperator];
    [_fields setValue:operator forKey:key];
}

- (void) sortByKey:(NSString *) key ascending:(BOOL) ascending {
    [_sort setValue:[NSNumber numberWithInteger:ascending ? 1 : -1] forKey:key];
}

- (void) hintIndexKey:(NSString *) key ascending:(BOOL) ascending {
    [_hint setValue:[NSNumber numberWithInteger:ascending ? 1 : -1] forKey:key];    
}

#pragma mark - Getting the result

- (BSONDocument *) fieldsDocument {
    if (![_fields count]) return nil;
    return [BSONEncoder documentForDictionary:_fields restrictsKeyNamesForMongoDB:NO];
}

- (OrderedDictionary *) queryDictionaryValue {
    OrderedDictionary *result = [OrderedDictionary dictionary];
    
    if (self.predicate)
        [result setObject:[self.predicate dictionary] forKey:MongoQueryMetaOperator];
    else
        [result setObject:[OrderedDictionary dictionary] forKey:MongoQueryMetaOperator];
    
    if ([_sort count])
        [result setObject:_sort forKey:MongoOrderByMetaOperator];
    if ([_hint count])
        [result setObject:_hint forKey:MongoIndexHintMetaOperator];
    if (self.includeIndexKeyOnly)
        [result setObject:[NSNumber numberWithBool:YES] forKey:MongoReturnIndexOnlyMetaOperator];
    if (self.explain)
        [result setObject:[NSNumber numberWithBool:YES] forKey:MongoExplainMetaOperator];
    if (self.snapshotMode)
        [result setObject:[NSNumber numberWithBool:YES] forKey:MongoSnapshotMetaOperator];
    if (self.showDiskLocation)
        [result setObject:[NSNumber numberWithBool:YES] forKey:MongoShowDiskLocationMetaOperator];
    if (self.comment)
        [result setObject:self.comment forKey:MongoCommentMetaOperator];
    if (self.maximumDocumentsToScan)
        [result setObject:[NSNumber numberWithInteger:self.maximumDocumentsToScan]
                   forKey:MongoMaximumDocumentsToScanMetaOperator];
    if (self.lowerIndexBound)
        [result setObject:[self.lowerIndexBound dictionary] forKey:MongoLowerIndexBoundMetaOperator];
    if (self.upperIndexBound)
        [result setObject:[self.lowerIndexBound dictionary] forKey:MongoUpperIndexBoundMetaOperator];
    
    if (1 == [result count])
        return [result objectForKey:MongoQueryMetaOperator];
    else
        return result;
}

- (BSONDocument *) queryDocument {
    return [BSONEncoder documentForObject:[self queryDictionaryValue] restrictsKeyNamesForMongoDB:NO];
}

- (int) options {
    int options = 0;
    if (self.fetchAllResultsImmediately)
        options = options | MONGO_EXHAUST;
    if (!self.timeoutEnabled)
        options = options | MONGO_NO_CURSOR_TIMEOUT;
    if (self.tailable)
        options = options | MONGO_TAILABLE;
    if (self.tailableQueryBlocksAwaitingData)
        options = options | MONGO_AWAIT_DATA;
    if (self.allowQueryOfNonPrimaryServer)
        options = options | MONGO_SLAVE_OK;
    if (self.allowPartialResults)
        options = options | MONGO_PARTIAL;
    return options;
}

- (NSString *) description {
    NSMutableString *result = [NSMutableString stringWithFormat:@"%@ <%p>\n", [[self class] description], self];
    [result appendFormat:@"predicate = %@\n", predicate ? predicate : @"{ }"];
    [result appendFormat:@"fields = %@\n", [_fields count] ? _fields : @"{ }"];
    [result appendFormat:@"sort = %@\n", [_sort count] ? _sort : @"{ }"];
    [result appendFormat:@"limitResults = %ld\nskipResults = %ld\n", limitResults, skipResults];
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
