//
//  BSON_Helper.h
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

#import "BSON_Helper.h"

NSString * NSStringFromBSONString (const char *cString) {
#if __has_feature(objc_arc)
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
#else
//    return [[NSString stringWithCString:cString encoding:NSUTF8StringEncoding] autorelease];
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
#endif    
}

const char * BSONStringFromNSString (NSString * key) {
    return [key cStringUsingEncoding:NSUTF8StringEncoding];
}

void BSONAssertKeyNonNil(NSString *key) {
    if (key) return;
    id exc = [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:@"Key must not be nil"
                                 userInfo:nil];
    @throw exc;
}

void BSONAssertKeyLegalForMongoDB(NSString *key) {
    static NSString *singletonString;
    static NSCharacterSet *singletonCharacterSet;
    if (!singletonString) {
#if __has_feature(objc_arc)
        singletonString = @"$.";
        singletonCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"$."];
#else
        singletonString = @"$.";
        singletonCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"$."] retain];
#endif
    }

    BSONAssertKeyNonNil(key);
    if (NSNotFound == [key rangeOfCharacterFromSet:singletonCharacterSet].location) return;
    NSString *reason = [NSString stringWithFormat:@"Invalid key %@ - MongoDB keys may not contain the following characters: %@",
                        key,
                        singletonString];
    id exc = [NSException exceptionWithName:NSInvalidArgumentException
                                    reason:reason
                                  userInfo:nil];
    @throw exc;
}

void BSONAssertValueNonNil(id value) {
    if (value) return;
    id exc = [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:@"Value must not be nil"
                                 userInfo:nil];
    @throw exc;
}

void BSONAssertIteratorIsValueType(BSONIterator * iterator, bson_type valueType) {
    if (iterator && iterator.nativeValueType == valueType) return;
    NSString *reason = [NSString stringWithFormat:@"Operation requires BSON type %@, but has %@ instead",
                        NSStringFromBSONType(valueType),
                        NSStringFromBSONType(iterator.nativeValueType),
                        nil];
    id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                   reason:reason
                                 userInfo:nil];
    @throw exc;
}

void BSONAssertIteratorIsInValueTypeArray(BSONIterator * iterator, bson_type * valueType) {
    if (iterator) return;
    for (bson_type *cur = valueType; cur < valueType + sizeof(valueType); ++cur)
        if (iterator.nativeValueType == *cur) return;
    NSMutableArray *allowedTypes = [NSMutableArray array];
    for (bson_type *cur = valueType; cur < valueType + sizeof(valueType); ++cur)
        [allowedTypes addObject:NSStringFromBSONType(*cur)];

    NSString *reason = [NSString stringWithFormat:@"Operation requires one of BSON types %@, but has %@ instead",
                        allowedTypes,
                        NSStringFromBSONType(iterator.nativeValueType),
                        nil];
    id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                   reason:reason
                                 userInfo:nil];
    @throw exc;
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

void bson_appendString_raw( const char * data , int depth, NSMutableString *string ){
    bson_iterator i;
    const char * key;
    int temp;
    bson_timestamp_t ts;
    char oidhex[25];
    bson_iterator_init( &i , data );
    
    while ( bson_iterator_next( &i ) ){
        bson_type t = bson_iterator_type( &i );
        if ( t == 0 )
            break;
        key = bson_iterator_key( &i );
        
        [string appendString:@"\n"];
        for ( temp=0; temp<=depth; temp++ )
            [string appendString:@"\t"];
        [string appendFormat:@"%s : %d \t " , key , t];
        switch ( (int)t ){
            case bson_int: [string appendFormat:@"%d", bson_iterator_int( &i ) ]; break;
            case bson_double: [string appendFormat:@"%f" , bson_iterator_double( &i ) ]; break;
            case bson_bool: [string appendString: bson_iterator_bool( &i ) ? @"true" : @"false" ]; break;
            case bson_string: [string appendString: NSStringFromBSONString(bson_iterator_string( &i ) )]; break;
            case bson_null: [string appendString:@"null" ]; break;
            case bson_oid: bson_oid_to_string(bson_iterator_oid(&i), oidhex); [string appendString:NSStringFromBSONString(oidhex)]; break;
            case bson_timestamp:
                ts = bson_iterator_timestamp( &i );
                [string appendFormat:@"i: %d, t: %d", ts.i, ts.t];
                break;
            case bson_object:
            case bson_array:
                bson_appendString_raw( bson_iterator_value( &i ) , depth + 1, string );
//                [string appendString:@"\n"];
                break;
            default:
                [string appendString:@"[can't print this type]"];
        }
    }
}

NSString * NSStringFromBSON( bson * b ){
    NSMutableString *result = [NSMutableString string];
    bson_appendString_raw( b->data , 0, result );
    return [result stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}


