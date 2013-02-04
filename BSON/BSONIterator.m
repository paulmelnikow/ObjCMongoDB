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
@end

@implementation BSONIterator {
    bson_iterator *_iter;
    const bson *_b;
    BSONType _type;
}

#pragma mark - Initialization

- (id) initWithDocument:(BSONDocument *)document
 keyPathComponentsOrNil:(NSArray *) keyPathComponents {
    if (self = [super init]) {
        self.dependentOn = document;
        self.privateKeyPathComponents = keyPathComponents ? keyPathComponents : [NSArray array];
        _b = [document bsonValue];
        _iter = bson_iterator_create();
        bson_iterator_init(_iter, _b);
        _type = bson_iterator_type(_iter);
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
        _type = bson_iterator_type(_iter);
        
    }
    return self;
}

- (void) dealloc {
    bson_iterator_dispose(_iter);
#if !__has_feature(objc_arc)
    self.dependentOn = nil;
    self.privateKeyPathComponents = nil;
    [super dealloc];
#endif
}

- (bson_iterator *) nativeIteratorValue { return _iter; }

#pragma mark - Searching

- (BSONType) valueTypeForKey:(NSString *) key {
    [self _assertSupportsKeyedSearching];
    BSONAssertKeyNonNil(key);
    return _type = bson_find(_iter, _b, key.bsonString);
}

- (BOOL) containsValueForKey:(NSString *) key {
    [self _assertSupportsKeyedSearching];
    BSONAssertKeyNonNil(key);
    return BSON_EOO != [self valueTypeForKey:key];
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
    return _type = bson_iterator_next(_iter);
}

#pragma mark - Information about the current key

- (BSONType) valueType { return _type; }
- (BOOL) isEmbeddedDocument { return BSON_OBJECT == _type; }
- (BOOL) isArray { return BSON_ARRAY == _type; }

- (NSString *) key { return [NSString stringWithBSONString:bson_iterator_key(_iter)]; }
- (NSArray *) keyPathComponents {
    NSArray *result = [self.privateKeyPathComponents arrayByAddingObject:self.key];
    maybe_retain_autorelease_and_return(result);
}

#pragma mark - Values for collections

- (BSONIterator *) sequentialSubIteratorValue {
    bson_iterator *subIter = bson_iterator_create();
    bson_iterator_subiterator(_iter, subIter);
    BSONIterator *iterator = [[BSONIterator alloc] initWithNativeIterator:subIter
                                                              dependentOn:self.dependentOn
                                                        keyPathComponents:self.keyPathComponents];
    maybe_autorelease_and_return(iterator);
}

- (BSONDocument *) embeddedDocumentValue {
    BSONDocument *document = [[BSONDocument alloc] initForEmbeddedDocumentWithIterator:self
                                                                           dependentOn:self.dependentOn];
    maybe_autorelease_and_return(document);
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
        case BSON_EOO:
            return nil;
        case BSON_DOUBLE:
            return [NSNumber numberWithDouble:[self doubleValue]];
        case BSON_STRING:
            return [self stringValue];
        case BSON_OBJECT:
            return [self embeddedDocumentValue];
        case BSON_ARRAY:
            return [self sequentialSubIteratorValue];
        case BSON_BINDATA:
            return [self dataValue];
        case BSON_UNDEFINED:
            return [BSONIterator objectForUndefined];
        case BSON_OID:
            return [self objectIDValue];
        case BSON_BOOL:
            return [NSNumber numberWithBool:[self boolValue]];
        case BSON_DATE:
            return [self dateValue];
        case BSON_NULL:
            return [NSNull null];
        case BSON_REGEX:
            return [self regularExpressionValue];
        case BSON_CODE:
            return [self codeValue];
        case BSON_SYMBOL:
            return [self symbolValue];
        case BSON_CODEWSCOPE:
            return [self codeWithScopeValue];
        case BSON_INT:
            return [NSNumber numberWithInt:[self intValue]];
        case BSON_TIMESTAMP:
            return [self timestampValue];
        case BSON_LONG:
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
    bson *newBson = bson_create();
    bson_iterator_code_scope(_iter, newBson);
    BSONDocument *document = [BSONDocument documentWithNativeDocument:newBson destroyWhenDone:NO];
    return [BSONCodeWithScope code:[NSString stringWithBSONString:bson_iterator_code(_iter)]
                         withScope:document];
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
    if (!_b) {
        id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                         reason:@"Can't perform keyed searching on a sequential iterator; use -embeddedDocumentIterator instead"
                                       userInfo:nil];
        @throw exc;
    }
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
    [string appendFormat:@"\n\n    nativeValueType:\n        %@", NSStringFromBSONType([self valueType])];
    [string appendString:@"\n"];
    maybe_retain_autorelease_and_return(string);
}

@end