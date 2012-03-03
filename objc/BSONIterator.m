//
//  BSONIterator.m
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BSONIterator.h"

@interface BSONIterator (Private)
+ (NSString *) stringForUTF8:(const char *)cString;
- (BOOL) hasMore;
- (bson_type) next;
- (bson_type) findKey:(NSString *)key;
@end

@implementation BSONIterator

@synthesize objectForUndefined;

#pragma mark - Initialization

- (BSONIterator *)initWithDocument:(BSONDocument *)document {
    if (self = [super init]) {
#if __has_feature(objc_arc)
        _document = document;
#else
        _document = [document retain];
#endif
        _b = [document bsonValue];
        _iter = malloc(sizeof(bson_iterator));
        bson_iterator_init(_iter, _b->data);
        _type = bson_iterator_type(_iter);
        
        self.objectForUndefined = nil;
    }
    return self;
}

// Called internally when creating subiterators
// Takes ownership of the bson_iterator it's passed
- (BSONIterator *)initAsSubIteratorWithDocument:(BSONDocument *)document
                                       iterator:(BSONIterator *)iterator
                                newBsonIterator:(bson_iterator *)bsonIter {
    if (self = [super init]) {
#if __has_feature(objc_arc)
        _document = document;
        self.objectForUndefined = iterator.objectForUndefined;
#else
        _document = [document retain];
        self.objectForUndefined = [iterator.objectForUndefined retain];
#endif
        _iter = bsonIter;
        _type = bson_iterator_type(_iter);
        
    }
    return self;
}

+ (BSONIterator *)iteratorWithDocument:(BSONDocument *)document {
    return [[self alloc] initWithDocument:document];
}

- (void) dealloc {
    free(_iter);
#if !__has_feature(objc_arc)
    [_document release];
    [self.objectForUndefined release];
#endif
}

#pragma mark - Searching

- (id) valueForKey:(NSString *)key {
    [self findKey:key];
    return [self objectValue];
}

#pragma mark - High level iteration

// Set objectForUndefined
- (id) nextObject {
    if (!self.objectForUndefined)
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"To use the NSEnumerator interface, set objectForNull and objectForUndefined to non-nil (e.g. [NSNUll null])"
                                     userInfo:nil];    
    [self next];
    return [self objectValue];
}

- (NSArray *) allObjects {
    if (!self.objectForUndefined)
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"To use the NSEnumerator interface, set objectForNull and objectForUndefined to non-nil (e.g. [NSNUll null])"
                                     userInfo:nil];
    
    NSMutableArray *array = [NSMutableArray array];
    while ([self next]) [array addObject:[self objectValue]];
    return [NSArray arrayWithArray:array];
}

#pragma mark - Primitives for advancing the iterator and searching

- (BOOL) hasMore { return bson_iterator_more(_iter); }

- (bson_type) next {
    return _type = bson_iterator_next(_iter);
}

- (bson_type) findKey:(NSString *)key {
    return _type = bson_find(_iter, _b, [BSONArchiver utf8ForString:key]);
}

#pragma mark - Information about the current key

- (bson_type) type { return _type; }
- (BOOL) isSubDocument { return bson_object == _type; }
- (BOOL) isArray { return bson_array == _type; }

- (NSString *) currentKey { return [BSONIterator stringForUTF8:bson_iterator_key(_iter)]; }

//not implemeneted
//const char * bson_iterator_value( const bson_iterator * i );

#pragma mark - Values for collections

- (BSONDocument *)subDocumentValue {
    BSONDocument *document = [[BSONDocument alloc] init];
    bson_iterator_subobject(_iter, [document bsonValue]);
#if __has_feature(objc_arc)
    return document;
#else
    return [document autorelease];
#endif
}

- (BSONIterator *)subIteratorValue {
    bson_iterator *subIter = malloc(sizeof(bson_iterator));
    bson_iterator_subiterator(_iter, subIter);
    BSONIterator *iterator = [[BSONIterator alloc] initAsSubIteratorWithDocument:_document
                                                      iterator:self
                                               newBsonIterator:subIter];
#if __has_feature(objc_arc)
    return iterator;
#else
    return [iterator autorelease];
#endif    
}

- (id)objectValue {
    switch([self type]) {
        case bson_eoo:
            return nil;
        case bson_double:
            return [NSNumber numberWithDouble:[self doubleValue]];
        case bson_string:
            return [self stringValue];
        case bson_object:
            return [self subDocumentValue];
        case bson_array:
            return [self subIteratorValue];
        case bson_bindata:
            return [self dataValue];
        case bson_undefined:
            return [self objectForUndefined];
        case bson_oid:
            return [self objectIDValue];
        case bson_bool:
            return [NSNumber numberWithBool:[self boolValue]];
        case bson_date:
            return [self dateValue];
        case bson_null:
            return [NSNull null];
        case bson_regex:
            return [self regularExpressionValue];
        case bson_code:
            return [self codeValue];
        case bson_symbol:
            return [self symbolValue];
        case bson_codewscope:
            return [self codeWithScopeValue];
        case bson_int:
            return [NSNumber numberWithInt:[self intValue]];
        case bson_timestamp:
            return [self timestampValue];
        case bson_long:
            return [NSNumber numberWithLongLong:[self int64Value]];
        default:
            return nil;
    }
}

#pragma mark - Values for basic types

- (double)doubleValue { return bson_iterator_double(_iter); }
- (int)intValue { return bson_iterator_int(_iter); }
- (int64_t)int64Value { return bson_iterator_long(_iter); }
- (BOOL)boolValue { return bson_iterator_bool(_iter); }

- (BSONObjectID *)objectIDValue {
    BSONObjectID *objid = [BSONObjectID objectIDWithNativeOID:bson_iterator_oid(_iter)];
    return [objid autorelease];
}

- (NSString *)stringValue { return [BSONIterator stringForUTF8:bson_iterator_string(_iter)]; }
- (int)stringLength { return bson_iterator_string_len(_iter); }
- (NSString *)symbolValue { return [self stringValue]; }

- (NSString *) codeValue { return [BSONIterator stringForUTF8:bson_iterator_code(_iter)]; }
- (BSONDocument *) codeScopeValue {
    BSONDocument *document = [[BSONDocument alloc] init];
    bson_iterator_code_scope(_iter, [document bsonValue]);
    return document;
}
- (NSDictionary *)codeWithScopeValue {
    id value = [NSDictionary dictionaryWithObjectsAndKeys:
            [self codeValue], @"code",
            [self codeScopeValue], @"scope",
            nil];
#if __has_feature(objc_arc)
    return value;
#else
    return [value autorelease];
#endif
}

- (NSDate *)dateValue {
#if __has_feature(objc_arc)
    return [NSDate dateWithTimeIntervalSince1970:0.001 * bson_iterator_date(_iter)];
#else
    return [[NSDate dateWithTimeIntervalSince1970:0.001 * bson_iterator_date(_iter)] autorelease];
#endif
}

- (char)dataLength { return bson_iterator_bin_len(_iter); }
- (char)dataBinType { return bson_iterator_bin_type(_iter); }
- (NSData *)dataValue {
    id value = [NSData dataWithBytes:bson_iterator_bin_data(_iter)
                          length:bson_iterator_bin_len(_iter)];
#if __has_feature(objc_arc)
    return value;
#else
    return [value autorelease];
#endif
}

- (NSString *)regularExpressionPatternValue { 
    return [BSONIterator stringForUTF8:bson_iterator_regex(_iter)];
}
- (NSString *)regularExpressionOptionsValue { 
    return [BSONIterator stringForUTF8:bson_iterator_regex_opts(_iter)];
}
- (NSArray *)regularExpressionValue {
    return [NSArray arrayWithObjects:
            [self regularExpressionPatternValue],
            [self regularExpressionOptionsValue],
            nil];
}

- (bson_timestamp_t)nativeTimestampValue {
    return bson_iterator_timestamp(_iter);
}
- (NSDictionary *)timestampValue {
    bson_timestamp_t timeval = [self nativeTimestampValue];
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:timeval.i], @"increment",
            [NSNumber numberWithInt:timeval.t], @"timeInSeconds",
            nil];
}

#pragma mark - Helper methods

+ (NSString *) stringForUTF8:(const char *)cString {
#if __has_feature(objc_arc)
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
#else
    return [[NSString stringWithCString:cString encoding:NSUTF8StringEncoding] autorelease];
#endif
}

NSString * NSStringFromBSONType(bson_type t) {
    NSString *name = nil;
    switch(t) {
        case bson_eoo:
            name = @"bson_eoo"; break;
        case bson_double:
            name = @"bson_double"; break;
        case bson_string:
            name = @"bson_string"; break;
        case bson_object:
            name = @"bson_object"; break;
        case bson_array:
            name = @"bson_array"; break;
        case bson_bindata:
            name = @"bson_bindata"; break;
        case bson_undefined:
            name = @"bson_undefined"; break;
        case bson_oid:
            name = @"bson_oid"; break;
        case bson_bool:
            name = @"bson_bool"; break;
        case bson_date:
            name = @"bson_date"; break;
        case bson_null:
            name = @"bson_null"; break;
        case bson_regex:
            name = @"bson_regex"; break;
        case bson_code:
            name = @"bson_code"; break;
        case bson_symbol:
            name = @"bson_symbol"; break;
        case bson_codewscope:
            name = @"bson_codewscope"; break;
        case bson_int:
            name = @"bson_int"; break;
        case bson_timestamp:
            name = @"bson_timestamp"; break;
        case bson_long:
            name = @"bson_long"; break;
        default:
            name = @"???";
    }
#if __has_feature(objc_arc)
    return name;
#else
    return [name autorelease];
#endif
}

@end
