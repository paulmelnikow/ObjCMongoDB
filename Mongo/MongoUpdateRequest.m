//
//  MongoUpdateRequest.m
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

#import "MongoUpdateRequest.h"
#import "ObjCMongoDB.h"
#import "mongo.h"
#import "Mongo_PrivateInterfaces.h"
#import "BSON_Helper.h"

@interface MongoUpdateRequest ()
@property (retain) BSONDocument *replacementDocument;
@property (retain) OrderedDictionary *operationDictionary;
@end

@implementation MongoUpdateRequest

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
    maybe_release(_predicate);
    maybe_release(_writeConcern);
    maybe_release(_replacementDocument);
    maybe_release(_operationDictionary);
    super_dealloc;
}

+ (MongoUpdateRequest *) updateRequestForFirstMatchOnly:(BOOL) firstMatchOnly {
    MongoUpdateRequest *result = [[self alloc] initForFirstMatchOnly:firstMatchOnly];
    maybe_autorelease_and_return(result);
}

+ (MongoUpdateRequest *) updateRequestWithPredicate:(MongoPredicate *) predicate
                                     firstMatchOnly:(BOOL) firstMatchOnly {
    MongoUpdateRequest *request = [self updateRequestForFirstMatchOnly:firstMatchOnly];
    request.predicate = predicate;
    return request;
}

#pragma mark - Manipulating the request

- (void) replaceDocumentWithDocument:(BSONDocument *) replacementDocument {
    if (self.operationDictionary)
        [NSException raise:NSInvalidArgumentException
                    format:@"Replacement document can't be combined with other operations"];
    self.replacementDocument = replacementDocument;
}

- (void) replaceDocumentWithDictionary:(NSDictionary *) replacementDictionary {
    [self replaceDocumentWithDocument:[replacementDictionary BSONDocument]];
}

- (void) keyPath:(NSString *) keyPath setValue:(id) value {
    [self _operation:@"$set" keyPath:keyPath setObject:value];
}

- (void) unsetValueForKeyPath:(NSString *) keyPath {
    [self _operation:@"$unset" keyPath:keyPath setObject:@(1)];
}

- (void) incrementValueForKeyPath:(NSString *) keyPath {
    [self keyPath:keyPath incrementValueBy:@(1)];
}

- (void) keyPath:(NSString *) keyPath incrementValueBy:(NSNumber *) increment {
    [self _operation:@"$inc" keyPath:keyPath setObject:increment];
}

- (void) keyPath:(NSString *) keyPath bitwiseAndWithValue:(NSInteger) value {
    [self _operation:@"$bit" keyPath:keyPath subKey:@"and" object:@(value)];
}

- (void) keyPath:(NSString *) keyPath bitwiseOrWithValue:(NSInteger) value {
    [self _operation:@"$bit" keyPath:keyPath subKey:@"or" object:@(value)];
}

- (void) setForKeyPath:(NSString *) keyPath addValue:(NSString *) value {
    [self _operation:@"$addToSet" keyPath:keyPath setObject:value];
}

- (void) setForKeyPath:(NSString *) keyPath addValuesFromArray:(NSArray *) values {
    [self _operation:@"$addToSet" keyPath:keyPath subKey:@"$each" object:values];
}

- (void) arrayForKeyPath:(NSString *) keyPath removeItemsMatchingValue:(id) value {
    [self _operation:@"$pull" keyPath:keyPath setObject:value];
}

- (void) arrayForKeyPath:(NSString *) keyPath removeItemsMatchingAnyFromArray:(NSArray *) array {
    [self _operation:@"$pullAll" keyPath:keyPath setObject:array];
}

- (void) removeMatchingValuesFromArrayUsingKeyedPredicate:(MongoKeyedPredicate *) keyedPredicate {
    [self _operation:@"$pull" setDictionary:keyedPredicate.dictionary];
}

- (void) arrayForKeyPath:(NSString *) keyPath appendValue:(id) value {
    [self _operation:@"$push" keyPath:keyPath setObject:value];
}

- (void) arrayForKeyPath:(NSString *) keyPath appendValuesFromArray:(NSArray *) values {
    [self _operation:@"$pushAll" keyPath:keyPath setObject:values];
}

- (void) removeLastValueFromArrayForKeyPath:(NSString *) keyPath {
    [self _operation:@"$pop" keyPath:keyPath setObject:@(1)];
}

- (void) removeFirstValueFromArrayForKeyPath:(NSString *) keyPath {
    [self _operation:@"$pop" keyPath:keyPath setObject:@(-1)];
}

- (void) keyPath:(NSString *) oldKey renameToKey:(NSString *) newKey {
    [self _operation:@"$rename" keyPath:oldKey setObject:newKey];
}

#pragma mark - Getting the result

- (BSONDocument *) conditionDocumentValue {
    return [self.conditionDictionaryValue BSONDocumentRestrictingKeyNamesForMongoDB:NO];
}

- (OrderedDictionary *) conditionDictionaryValue {
    OrderedDictionary *result;
    
    if (self.predicate)
        result = [OrderedDictionary dictionaryWithDictionary:[self.predicate dictionary]];
    else
        result = [OrderedDictionary dictionary];
    
    if (self.blocksDuringMultiUpdates)
        [result setObject:[NSNumber numberWithBool:YES] forKey:@"$atomic"];
    
    return result;
}

- (BSONDocument *) operationDocumentValue {
    if (self.replacementDocument)
        return self.replacementDocument;
    else if (self.operationDictionary)
        return [self.operationDictionary BSONDocumentRestrictingKeyNamesForMongoDB:NO];
    else
        return [BSONDocument document];
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
    NSMutableString *result = [NSMutableString stringWithFormat:@"%@ <%p>\n",
                               [[self class] description],
                               self
                               ];
    [result appendFormat:@"predicate = %@\n",
     self.predicate ? self.predicate : @"{ }"];
    [result appendFormat:@"replacementDocument = %@\n",
     self.replacementDocument ? @"(not nil)" : @"(nil)"];
    [result appendFormat:@"operations = %@\n",
     self.operationDictionary];
    return result;
}

#pragma mark - Helper methods
     
- (void) _ensureOperDict {
    if (self.operationDictionary) return;
    
    // Can have an operation dictionary or a replacement document, but not both
    if (!self.replacementDocument)
        self.operationDictionary = [OrderedDictionary dictionary];
    else
        [NSException raise:NSInvalidArgumentException
                    format:@"Operation can't be combined with replacement document"];
}

- (OrderedDictionary *) dictForOperation:(NSString *) operation {
    [self _ensureOperDict];
    OrderedDictionary *dictForThisOper = [self.operationDictionary objectForKey:operation];
    if (!dictForThisOper) {
        dictForThisOper = [OrderedDictionary dictionary];
        [self.operationDictionary setObject:dictForThisOper forKey:operation];
    }
    return dictForThisOper;
}
    
- (void) _operation:(NSString *) operation
            keyPath:(NSString *) keyPath
             subKey:(NSString *) subKey
             object:(id) object {
    
    OrderedDictionary *dictForOperation = [self dictForOperation:operation];
    OrderedDictionary *dictForKeyPath = [dictForOperation objectForKey:keyPath];
    if (!dictForKeyPath) {
        dictForKeyPath = [OrderedDictionary dictionary];
        [dictForOperation setObject:dictForKeyPath forKey:keyPath];        
    }
    [dictForKeyPath setObject:object forKey:subKey];
}

- (void) _operation:(NSString *) operation keyPath:(NSString *) keyPath setObject:(id) object {
    [[self dictForOperation:operation] setObject:object forKey:keyPath];
}
     
- (void) _operation:(NSString *) operation setDictionary:(OrderedDictionary *) dictionary {
    [self _ensureOperDict];
    if ([self.operationDictionary objectForKey:operation])
        [NSException raise:NSInvalidArgumentException
                    format:@"Operations already set using %@", operation];
    [self.operationDictionary setObject:dictionary forKey:operation];
}

@end
