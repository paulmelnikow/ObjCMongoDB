//
//  BSONIterator.m
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

#import "BSONIterator.h"
#import "BSON_PrivateInterfaces.h"
#import "BSON_Helper.h"

NSString * const BSONException = @"BSONException";

@interface BSONIterator ()
@property (retain) id dependentOn; // An object which retains the bson we're using
@property (retain) NSArray *privateKeyPathComponents;
@property (assign) BSONType type;
@end

@implementation BSONIterator {
    bson_iterator *_iter;
    const bson *_b;
}

#pragma mark - Initialization

- (id) initWithDocument:(BSONDocument *)document
 keyPathComponentsOrNil:(NSArray *) keyPathComponents {
    if (self = [super init]) {
        self.dependentOn = document;
        self.privateKeyPathComponents = keyPathComponents ? keyPathComponents : [NSArray array];
        _b = [document bsonValue];
        _iter = bson_iterator_alloc();
        bson_iterator_init(_iter, _b);
        self.type = bson_iterator_type(_iter);
    }
    return self;
}

/**
 Called internally when creating subiterators
 Takes ownership of the bson_iterator it's passed
 */
- (id) initWithNativeIterator:(bson_iterator *) bsonIter
                  dependentOn:(id) dependentOn
            keyPathComponents:(NSArray *) keyPathComponents {
    if (self = [super init]) {
        self.dependentOn = dependentOn;
        self.privateKeyPathComponents = keyPathComponents;
        _iter = bsonIter;
        self.type = bson_iterator_type(_iter);
        
    }
    return self;
}

- (void) dealloc {
    bson_iterator_dealloc(_iter);
    maybe_release(_dependentOn);
    maybe_release(_privateKeyPathComponents);
    super_dealloc;
}

- (bson_iterator *) nativeIteratorValue { return _iter; }

#pragma mark - Searching

- (BSONType) valueTypeForKey:(NSString *) key {
    [self _assertSupportsKeyedSearching];
    NSParameterAssert(key != nil);
    return self.type = bson_find(_iter, _b, key.bsonString);
}

- (BOOL) containsValueForKey:(NSString *) key {
    [self _assertSupportsKeyedSearching];
    NSParameterAssert(key != nil);
    return BSONTypeEndOfObject != [self valueTypeForKey:key];
}

- (id) objectForKey:(NSString *)key {
    [self valueTypeForKey:key];
    return [self objectValue];
}

- (id) valueForKey:(NSString *)key {
    return [self objectForKey:key];
}

#pragma mark - High level iteration

- (id) nextObject {
    [self next];
    return [self objectValue];
}

#pragma mark - Primitives for advancing the iterator and searching

- (BOOL) hasMore { return bson_iterator_more(_iter); }

- (BSONType) next {
    return self.type = bson_iterator_next(_iter);
}

#pragma mark - Information about the current key

- (BSONType) valueType { return self.type; }
- (BOOL) isEmbeddedDocument { return BSONTypeEmbeddedDocument == self.type; }
- (BOOL) isArray { return BSONTypeArray == self.type; }
- (BOOL) valueTypeIsInArray:(NSArray *) allowedTypes {
    for (NSNumber *cur in allowedTypes) if (self.valueType == [cur intValue])
        return YES;
    return NO;
}

- (NSString *) key { return [NSString stringWithBSONString:bson_iterator_key(_iter)]; }
- (NSArray *) keyPathComponents {
    NSArray *result = [self.privateKeyPathComponents arrayByAddingObject:self.key];
    maybe_retain_autorelease_and_return(result);
}

#pragma mark - Values for collections

- (BSONIterator *) sequentialSubIteratorValue {
    bson_iterator *subIter = bson_iterator_alloc();
    bson_iterator_subiterator(_iter, subIter);
    BSONIterator *iterator = [[BSONIterator alloc] initWithNativeIterator:subIter
                                                              dependentOn:self.dependentOn
                                                        keyPathComponents:self.keyPathComponents];
    maybe_autorelease_and_return(iterator);
}

- (BSONDocument *) embeddedDocumentValue {
    bson * newBson = bson_alloc();
    bson_iterator_subobject_init(_iter, newBson, 0);
    return [BSONDocument documentWithNativeDocument:newBson dependentOn:self.dependentOn];
}

- (BSONIterator *) embeddedDocumentIteratorValue {
    BSONIterator *iterator = [[BSONIterator alloc] initWithDocument:self.embeddedDocumentValue
                                             keyPathComponentsOrNil:self.keyPathComponents];
    maybe_autorelease_and_return(iterator);
}

- (NSArray *) arrayValue {
    NSMutableArray *array = [NSMutableArray array];
    BSONIterator *subIterator = [self sequentialSubIteratorValue];
    while ([subIterator next]) [array addObject:[subIterator objectValue]];
    return [NSArray arrayWithArray:array];
}

- (id) objectValue {
    switch([self valueType]) {
        case BSONTypeEndOfObject:
            return nil;
        case BSONTypeDouble:
            return [NSNumber numberWithDouble:[self doubleValue]];
        case BSONTypeString:
            return [self stringValue];
        case BSONTypeEmbeddedDocument:
            return [self embeddedDocumentValue];
        case BSONTypeArray:
            return [self sequentialSubIteratorValue];
        case BSONTypeBinaryData:
            return [self dataValue];
        case BSONTypeUndefined:
            return [BSONIterator objectForUndefined];
        case BSONTypeObjectID:
            return [self objectIDValue];
        case BSONTypeBoolean:
            return [NSNumber numberWithBool:[self boolValue]];
        case BSONTypeDate:
            return [self dateValue];
        case BSONTypeNull:
            return [NSNull null];
        case BSONTypeRegularExpression:
            return [self regularExpressionValue];
        case BSONTypeCode:
            return [self codeValue];
        case BSONTypeSymbol:
            return [self symbolValue];
        case BSONTypeCodeWithScope:
            return [self codeWithScopeValue];
        case BSONTypeInteger:
            return [NSNumber numberWithInt:[self intValue]];
        case BSONTypeTimestamp:
            return [self timestampValue];
        case BSONTypeLong:
            return [NSNumber numberWithLongLong:[self int64Value]];
        default:
            [NSException raise:NSInvalidUnarchiveOperationException
                        format:@"Unrecognized BSON type: %ld (Is this a BSON document?)", (long)[self valueType]];
            return nil;
    }
}

#pragma mark - Values for basic types

- (double) doubleValue { return bson_iterator_double(_iter); }
- (int) intValue { return bson_iterator_int(_iter); }
- (int64_t) int64Value { return bson_iterator_long(_iter); }
- (BOOL) boolValue { return bson_iterator_bool(_iter); }

- (BSONObjectID *) objectIDValue {
    return [BSONObjectID objectIDWithNativeOID:bson_iterator_oid(_iter)];
}

- (NSString *) stringValue {
    return [NSString stringWithBSONString:bson_iterator_string(_iter)];
}
- (int) stringLength {
    return bson_iterator_string_len(_iter);
}
- (BSONSymbol *) symbolValue {
    return [BSONSymbol symbol:[self stringValue]];
}

- (BSONCode *) codeValue {
    return [BSONCode code:[NSString stringWithBSONString:bson_iterator_code(_iter)]];
}
- (BSONCodeWithScope *) codeWithScopeValue {
    // Does not copy the scope, but retains the document we depend on
    bson *newBson = bson_alloc();
    bson_iterator_code_scope_init(_iter, newBson, 0);
    return [BSONCodeWithScope code:[NSString stringWithBSONString:bson_iterator_code(_iter)]
                         withScope:[BSONDocument documentWithNativeDocument:newBson dependentOn:self.dependentOn]];
}

- (NSDate *) dateValue {
    return [NSDate dateWithTimeIntervalSince1970:0.001 * bson_iterator_date(_iter)];
}

- (NSUInteger) dataLength { return (NSUInteger)bson_iterator_bin_len(_iter); }
- (char) dataBinType { return bson_iterator_bin_type(_iter); }
- (NSData *) dataValue {
    id value = [NSData dataWithBytes:bson_iterator_bin_data(_iter)
                              length:[self dataLength]];
    return value;
}

- (NSString *) regularExpressionPatternValue { 
    return [NSString stringWithBSONString:bson_iterator_regex(_iter)];
}
- (NSString *) regularExpressionOptionsValue { 
    return [NSString stringWithBSONString:bson_iterator_regex_opts(_iter)];
}
- (BSONRegularExpression *) regularExpressionValue {
    return [BSONRegularExpression regularExpressionWithPattern:[self regularExpressionPatternValue]
                                                       options:[self regularExpressionOptionsValue]];
}

- (BSONTimestamp *) timestampValue {
    return [BSONTimestamp timestampWithNativeTimestamp:bson_iterator_timestamp(_iter)];
}

#pragma mark - Helper methods

+ (id) objectForUndefined {
    static NSString *singleton;
    if (!singleton) singleton = @"bson:undefined";
    return singleton;
}

- (void) _assertSupportsKeyedSearching {
    if (!_b)
        [NSException raise:NSInvalidUnarchiveOperationException
                    format:@"Can't perform keyed searching on a sequential iterator; use -embeddedDocumentIterator instead"];
}

#pragma mark - Debugging and error handling

void objc_bson_error_handler(const char * message);
void objc_bson_error_handler(const char * message) {
    [NSException raise:BSONException format:@"BSON error: %s", message, nil];
}

+ (void) initialize {
    set_bson_err_handler(objc_bson_error_handler);
}

- (NSString *) description {
    NSMutableString *string = [NSMutableString stringWithFormat:@"<%@: %p>", [[self class] description], self];
    [string appendFormat:@"\n    keyPathComponents:"];
    for (NSString *keyPath in [self keyPathComponents])
        [string appendFormat:@"\n        %@", keyPath];
    [string appendFormat:@"\n\n    valueType:\n        %@", NSStringFromBSONType([self valueType])];
    [string appendString:@"\n"];
    maybe_retain_autorelease_and_return(string);
}

@end