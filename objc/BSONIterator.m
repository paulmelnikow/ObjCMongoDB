//
//  BSONDocument.m
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

@interface BSONIterator (Private)
- (void) assertSupportsKeyedSearching;
@end

@implementation BSONIterator

#pragma mark - Initialization

- (id) initWithDocument:(BSONDocument *)document
             keyPathComponentsOrNil:(NSArray *) keyPathComponents {
    if (self = [super init]) {
#if __has_feature(objc_arc)
        _parent = document;
        _keyPathComponents = keyPathComponents ? keyPathComponents : [NSArray array];
#else
        _parent = [document retain];
        _keyPathComponents = keyPathComponents ? [keyPathComponents retain] : [[NSArray array] retain];
#endif
        _b = [document bsonValue];
        _iter = malloc(sizeof(bson_iterator));
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
                                  parent:(id) parent
                        keyPathComponents:(NSArray *) keyPathComponents {
    if (self = [super init]) {
#if __has_feature(objc_arc)
        _parent = parent;
        _keyPathComponents = keyPathComponents;
#else
        _parent = [parent retain];
        _keyPathComponents = [keyPathComponents retain];
#endif
        _iter = bsonIter;
        _type = bson_iterator_type(_iter);
        
    }
    return self;
}

- (void) dealloc {
    free(_iter);
#if !__has_feature(objc_arc)
    [_parent release];
#endif
}

- (bson_iterator *) nativeIteratorValue { return _iter; }

#pragma mark - Searching

- (bson_type) nativeValueTypeForKey:(NSString *) key {
    [self assertSupportsKeyedSearching];
    BSONAssertKeyNonNil(key);
    return _type = bson_find(_iter, _b, BSONStringFromNSString(key));
}

- (BOOL) containsValueForKey:(NSString *) key {
    [self assertSupportsKeyedSearching];
    BSONAssertKeyNonNil(key);
    return BSON_EOO != [self nativeValueTypeForKey:key];
}

- (id) objectForKey:(NSString *)key {
    [self nativeValueTypeForKey:key];
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

- (bson_type) next {
    return _type = bson_iterator_next(_iter);
}

#pragma mark - Information about the current key

- (bson_type) nativeValueType { return _type; }
- (BOOL) isEmbeddedDocument { return BSON_OBJECT == _type; }
- (BOOL) isArray { return BSON_ARRAY == _type; }

- (NSString *) key { return NSStringFromBSONString(bson_iterator_key(_iter)); }
- (NSArray *) keyPathComponents {
#if __has_feature(objc_arc)
    return [_keyPathComponents arrayByAddingObject:self.key];
#else
    return [[_keyPathComponents arrayByAddingObject:[self.key retain]] autorelease];
#endif
}

//not implemeneted
//const char * bson_iterator_value( const bson_iterator * i );

#pragma mark - Values for collections

- (BSONIterator *) sequentialSubIteratorValue {
    bson_iterator *subIter = malloc(sizeof(bson_iterator));
    bson_iterator_subiterator(_iter, subIter);
    BSONIterator *iterator = [[BSONIterator alloc] initWithNativeIterator:subIter
                                                                   parent:_parent
                                                        keyPathComponents:self.keyPathComponents];
#if __has_feature(objc_arc)
    return iterator;
#else
    return [iterator autorelease];
#endif
}

- (BSONDocument *) embeddedDocumentValue {
    BSONDocument *document = [[BSONDocument alloc] initForEmbeddedDocumentWithIterator:self parent:_parent];
#if __has_feature(objc_arc)
    return document;
#else
    return [document autorelease];
#endif
}

- (BSONIterator *) embeddedDocumentIteratorValue {
    BSONIterator *iterator = [[BSONIterator alloc] initWithDocument:self.embeddedDocumentValue
                                             keyPathComponentsOrNil:self.keyPathComponents];
#if __has_feature(objc_arc)
    return iterator;
#else
    return [iterator autorelease];
#endif
}

- (NSArray *) arrayValue {
    NSMutableArray *array = [NSMutableArray array];
    BSONIterator *subIterator = [self sequentialSubIteratorValue];
    while ([subIterator next]) [array addObject:[subIterator objectValue]];
    return [NSArray arrayWithArray:array];
}

- (id) objectValue {
    switch([self nativeValueType]) {
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
            return nil;
    }
}

#pragma mark - Values for basic types

- (double) doubleValue { return bson_iterator_double(_iter); }
- (int) intValue { return bson_iterator_int(_iter); }
- (int64_t) int64Value { return bson_iterator_long(_iter); }
- (BOOL) boolValue { return bson_iterator_bool(_iter); }

- (BSONObjectID *) objectIDValue {
#if __has_feature(objc_arc)
    return [BSONObjectID objectIDWithNativeOID:bson_iterator_oid(_iter)];
#else
    return [[BSONObjectID objectIDWithNativeOID:bson_iterator_oid(_iter)] autorelease];
#endif
    
}

- (NSString *) stringValue { return NSStringFromBSONString(bson_iterator_string(_iter)); }
- (int) stringLength { return bson_iterator_string_len(_iter); }
- (BSONSymbol *) symbolValue { return [BSONSymbol symbol:[self stringValue]]; }

- (BSONCode *) codeValue { return [BSONCode code:NSStringFromBSONString(bson_iterator_code(_iter))]; }
- (BSONCodeWithScope *) codeWithScopeValue {
    bson *newBson = malloc(sizeof(bson));
    bson_iterator_code_scope(_iter, newBson);
#if __has_feature(objc_arc)
    BSONDocument *document = [[BSONDocument alloc] initWithNativeDocument:newBson destroyOnDealloc:NO];
#else
    BSONDocument *document = [[[BSONDocument alloc] initWithNativeDocument:newBson destroyOnDealloc:NO] autorelease];
#endif
    return [BSONCodeWithScope code:NSStringFromBSONString(bson_iterator_code(_iter)) withScope:document];
}

- (NSDate *) dateValue {
#if __has_feature(objc_arc)
    return [NSDate dateWithTimeIntervalSince1970:0.001 * bson_iterator_date(_iter)];
#else
    return [[NSDate dateWithTimeIntervalSince1970:0.001 * bson_iterator_date(_iter)] autorelease];
#endif
}

- (char) dataLength { return bson_iterator_bin_len(_iter); }
- (char) dataBinType { return bson_iterator_bin_type(_iter); }
- (NSData *) dataValue {
    id value = [NSData dataWithBytes:bson_iterator_bin_data(_iter)
                          length:[self dataLength]];
#if __has_feature(objc_arc)
    return value;
#else
    return [value autorelease];
#endif
}

- (NSString *) regularExpressionPatternValue { 
    return NSStringFromBSONString(bson_iterator_regex(_iter));
}
- (NSString *) regularExpressionOptionsValue { 
    return NSStringFromBSONString(bson_iterator_regex_opts(_iter));
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

- (void) assertSupportsKeyedSearching {
    if (!_b) {
        id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                         reason:@"Can't perform keyed searching on a sequential iterator; use -embeddedDocumentIterator instead"
                                       userInfo:nil];
        @throw exc;
    }
}

+ (NSException *) assert:(SEL)selector {
    NSString *reason = [NSString stringWithFormat:@"%@ called, but unkeyed decoding methods are not supported. Subclass if unkeyed coding is needed.",
                        NSStringFromSelector(selector)];
    return [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                   reason:reason
                                 userInfo:nil];
}

#pragma mark - Debugging

- (NSString *) description {
    NSMutableString *string = [NSMutableString stringWithFormat:@"<%@: %p>", [[self class] description], self];
    [string appendFormat:@"\n    keyPathComponents:"];
    for (NSString *keyPath in [self keyPathComponents])
        [string appendFormat:@"\n        %@", keyPath];
    [string appendFormat:@"\n\n    nativeValueType:\n        %@", NSStringFromBSONType([self nativeValueType])];
    [string appendString:@"\n"];
#if __has_feature(objc_arc)
    return string;
#else
    return [[string retain] autorelease];
#endif
}

@end