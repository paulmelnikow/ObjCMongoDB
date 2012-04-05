//
//  MongoUpdateRequest.m
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 4/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MongoUpdateRequest.h"
#import "BSONEncoder.h"
#import "BSONDocument.h"
#import "MongoKeyedPredicate.h"
#import "mongo.h"

NSString * const MongoAtomicFlag = @"$atomic";

NSString * const MongoSetOperatorKey = @"$set";
NSString * const MongoUnsetOperatorKey = @"$unset";
NSString * const MongoIncrementOperatorKey = @"$inc";
NSString * const MongoBitwiseOperatorKey = @"$bit";
NSString * const MongoBitwiseAnd = @"and";
NSString * const MongoBitwiseOr = @"or";
NSString * const MongoAddToSetOperator = @"$addToSet";
NSString * const MongoAddToSetEachQualifier = @"$each";
NSString * const MongoPullOperator = @"$pull";
NSString * const MongoPullAllOperator = @"$pullAll";
NSString * const MongoPushOperator = @"$push";
NSString * const MongoPushAllOperator = @"$pushAll";
NSString * const MongoPopOperator = @"$pop";
NSString * const MongoRenameOperator = @"$rename";

@interface MongoUpdateRequest (Private)
- (void) operation:(NSString *) operation keyPath:(NSString *) keyPath subKey:(NSString *) subKey object:(id) object;
- (void) operation:(NSString *) operation keyPath:(NSString *) keyPath setObject:(id) object;
- (void) operation:(NSString *) operation setDictionary:(OrderedDictionary *) dictionary;
@end

@implementation MongoUpdateRequest
@synthesize predicate, updatesFirstMatchOnly, insertsIfNoMatches, blocksDuringMultiUpdates;

#pragma mark - Initialization

- (id) initForFirstMatchOnly:(BOOL) firstMatchOnly {
    if (self = [super init]) {
        self.updatesFirstMatchOnly = firstMatchOnly;
        self.insertsIfNoMatches = NO;
        self.blocksDuringMultiUpdates = NO;
    }
    return self;
}

- (void) dealloc {
#if !__has_feature(objc_arc)

#endif
}

+ (MongoUpdateRequest *) updateRequestForFirstMatchOnly:(BOOL) firstMatchOnly {
    MongoUpdateRequest *result = [[self alloc] initForFirstMatchOnly:firstMatchOnly];
#if !__has_feature(objc_arc)
    [result autorelease];
#endif
    return result;
}

+ (MongoUpdateRequest *) updateRequestWithPredicate:(MongoPredicate *) predicate firstMatchOnly:(BOOL) firstMatchOnly {
    MongoUpdateRequest *request = [self updateRequestForFirstMatchOnly:firstMatchOnly];
    request.predicate = predicate;
    return request;
}

#pragma mark - Manipulating the request

- (void) replaceDocumentWith:(BSONDocument *) replacementDocument {
    if (_operDict)
        [NSException raise:NSInvalidArgumentException
                    format:@"Replacement document can't be combined with other operations"];
#if __has_feature(objc_arc)
    _replacementDocument = replacementDocument;
#else
    _replacementDocument = [replacementDocument retain];
#endif
}

- (void) replaceDocumentWithDictionary:(NSDictionary *) replacementDictionary {
    [self replaceDocumentWith:[BSONEncoder documentForDictionary:replacementDictionary]];
}

- (void) keyPath:(NSString *) keyPath setValue:(id) value {
    [self operation:MongoSetOperatorKey keyPath:keyPath setObject:value];
}

- (void) unsetValueForKeyPath:(NSString *) keyPath {
    [self operation:MongoUnsetOperatorKey keyPath:keyPath setObject:[NSNumber numberWithInt:1]];
}

- (void) incrementValueForKeyPath:(NSString *) keyPath {
    [self keyPath:keyPath incrementValueBy:[NSNumber numberWithInt:1]];
}

- (void) keyPath:(NSString *) keyPath incrementValueBy:(NSNumber *) increment {
    [self operation:MongoIncrementOperatorKey keyPath:keyPath setObject:increment];
}

- (void) keyPath:(NSString *) keyPath bitwiseAndWithValue:(NSInteger) value {
    [self operation:MongoBitwiseOperatorKey
            keyPath:keyPath
             subKey:MongoBitwiseAnd
             object:[NSNumber numberWithInteger:value]];
}

- (void) keyPath:(NSString *) keyPath bitwiseOrWithValue:(NSInteger) value {
    [self operation:MongoBitwiseOperatorKey
            keyPath:keyPath
             subKey:MongoBitwiseOr
             object:[NSNumber numberWithInteger:value]];
}

- (void) setForKeyPath:(NSString *) keyPath addValue:(NSString *) value {
    [self operation:MongoAddToSetOperator keyPath:keyPath setObject:value];
}

- (void) setForKeyPath:(NSString *) keyPath addValuesFromArray:(NSArray *) values {
    [self operation:MongoAddToSetOperator
            keyPath:keyPath
             subKey:MongoAddToSetEachQualifier
             object:values];
}

- (void) arrayForKeyPath:(NSString *) keyPath removeItemsMatchingValue:(id) value {
    [self operation:MongoPullOperator keyPath:keyPath setObject:value];
}

- (void) arrayForKeyPath:(NSString *) keyPath removeItemsMatchingAnyFromArray:(NSArray *) array {
    [self operation:MongoPullAllOperator keyPath:keyPath setObject:array];
}

- (void) removeMatchingValuesFromArrayUsingKeyedPredicate:(MongoKeyedPredicate *) keyedPredicate {
    [self operation:MongoPullOperator setDictionary:keyedPredicate.dictionary];
}

- (void) arrayForKeyPath:(NSString *) keyPath appendValue:(id) value {
    [self operation:MongoPushOperator keyPath:keyPath setObject:value];
}

- (void) arrayForKeyPath:(NSString *) keyPath appendValuesFromArray:(NSArray *) values {
    [self operation:MongoPushAllOperator keyPath:keyPath setObject:values];
}

- (void) removeLastValueFromArrayForKeyPath:(NSString *) keyPath {
    [self operation:MongoPopOperator keyPath:keyPath setObject:[NSNumber numberWithInt:1]];
}

- (void) removeFirstValueFromArrayForKeyPath:(NSString *) keyPath {
    [self operation:MongoPopOperator keyPath:keyPath setObject:[NSNumber numberWithInt:-1]];
}

- (void) keyPath:(NSString *) oldKey renameToKey:(NSString *) newKey {
    [self operation:MongoRenameOperator keyPath:oldKey setObject:newKey];
}

#pragma mark - Getting the result

- (BSONDocument *) conditionDocumentValue {
    return [BSONEncoder documentForObject:[self conditionDictionaryValue] restrictsKeyNamesForMongoDB:NO];
}

- (OrderedDictionary *) conditionDictionaryValue {
    OrderedDictionary *result;
    
    if (self.predicate)
        result = [OrderedDictionary dictionaryWithDictionary:[self.predicate dictionary]];
    else
        result = [OrderedDictionary dictionary];
    
    if (self.blocksDuringMultiUpdates)
        [result setObject:[NSNumber numberWithBool:YES] forKey:MongoAtomicFlag];
    
    return result;
}

- (BSONDocument *) operationDocumentValue {
    if (_replacementDocument)
        return _replacementDocument;
    else if (_operDict)
        return [BSONEncoder documentForDictionary:_operDict restrictsKeyNamesForMongoDB:NO];
    else
#if __has_feature(objc_arc)
        return [[BSONDocument alloc] init];
#else
        return [[[BSONDocument alloc] init] autorelease];
#endif
}

- (int) flags {
    int result = 0;
    if (!self.updatesFirstMatchOnly) result += MONGO_UPDATE_MULTI;
    if (self.insertsIfNoMatches) result += MONGO_UPDATE_UPSERT;
    if (!result) result += MONGO_UPDATE_BASIC;
    return result;
}

#pragma mark - Debugging

- (NSString *) description {
    NSMutableString *result = [NSMutableString stringWithFormat:@"%@ <%p>\n", [[self class] description], self];
    [result appendFormat:@"predicate = %@\n", predicate ? predicate : @"{ }"];
    [result appendFormat:@"replacementDocument = %@\n", _replacementDocument ? @"(non-nil)" : @"(nil)"];
    [result appendFormat:@"operations = %@\n", _operDict];
//    [result appendFormat:@"sort = %@\n", [_sort count] ? _sort : @"{ }"];
    return result;
}

#pragma mark - Helper methods
     
- (void) ensureOperDict {
    if (_operDict) return;
    
    // Can have an operation dictionary or a replacement document, but not both
    if (!_replacementDocument)
#if __has_feature(objc_arc)
        _operDict = [OrderedDictionary dictionary];
#else
        _operDict = [[OrderedDictionary dictionary] retain];
#endif
    else
        [NSException raise:NSInvalidArgumentException
                    format:@"Operation can't be combined with replacement document"];
}

- (OrderedDictionary *) dictForOperation:(NSString *) operation {
    [self ensureOperDict];    
    OrderedDictionary *dictForThisOper = [_operDict objectForKey:operation];
    if (!dictForThisOper) {
        dictForThisOper = [OrderedDictionary dictionary];
        [_operDict setObject:dictForThisOper forKey:operation];
    }
    return dictForThisOper;
}
    
- (void) operation:(NSString *) operation keyPath:(NSString *) keyPath subKey:(NSString *) subKey object:(id) object {
    OrderedDictionary *dictForOperation = [self dictForOperation:operation];
    OrderedDictionary *dictForKeyPath = [dictForOperation objectForKey:keyPath];
    if (!dictForKeyPath) {
        dictForKeyPath = [OrderedDictionary dictionary];
        [dictForOperation setObject:dictForKeyPath forKey:keyPath];        
    }
    [dictForKeyPath setObject:object forKey:subKey];
}

- (void) operation:(NSString *) operation keyPath:(NSString *) keyPath setObject:(id) object {
    [[self dictForOperation:operation] setObject:object forKey:keyPath];
}
     
- (void) operation:(NSString *) operation setDictionary:(OrderedDictionary *) dictionary {
    [self ensureOperDict];
    if ([_operDict objectForKey:operation])
        [NSException raise:NSInvalidArgumentException
                    format:@"Operations already set using %@", operation];
    [_operDict setObject:dictionary forKey:operation];
}

@end
