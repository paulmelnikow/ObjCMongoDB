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
#import "BSON_PrivateInterfaces.h"

void BSONAssertKeyNonNil(NSString *key) {
    if (key) return;
    id exc = [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:@"Key must not be nil"
                                 userInfo:nil];
    @throw exc;
}

void BSONAssertKeyLegalForMongoDB(NSString *key) {
    BSONAssertKeyNonNil(key);
    if ([key hasPrefix:@"$"]) {
        NSString *reason = [NSString stringWithFormat:@"Invalid key %@ - MongoDB keys may not begin with '$'",
                            key];
        id exc = [NSException exceptionWithName:NSInvalidArgumentException
                                         reason:reason
                                       userInfo:nil];
        @throw exc;
    } else if (NSNotFound != [key rangeOfString:@"."].location) {
        NSString *reason = [NSString stringWithFormat:@"Invalid key %@ - MongoDB keys may not contain '.'",
                            key];
        id exc = [NSException exceptionWithName:NSInvalidArgumentException
                                         reason:reason
                                       userInfo:nil];
        @throw exc;
    }
}

void BSONAssertValueNonNil(id value) {
    if (value) return;
    id exc = [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:@"Value must not be nil"
                                 userInfo:nil];
    @throw exc;
}

void BSONAssertIteratorIsValueType(BSONIterator * iterator, BSONType valueType) {
    if (iterator && iterator.valueType == valueType) return;
    NSString *reason = [NSString stringWithFormat:@"Operation requires BSON type %@, but has %@ instead",
                        NSStringFromBSONType(valueType),
                        NSStringFromBSONType(iterator.valueType),
                        nil];
    id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                   reason:reason
                                 userInfo:nil];
    @throw exc;
}

void BSONAssertIteratorIsInValueTypeArray(BSONIterator * iterator, BSONType * valueType) {
    if (iterator) return;
    for (BSONType *cur = valueType; cur < valueType + sizeof(valueType); ++cur)
        if (iterator.valueType == *cur) return;
    NSMutableArray *allowedTypes = [NSMutableArray array];
    for (BSONType *cur = valueType; cur < valueType + sizeof(valueType); ++cur)
        [allowedTypes addObject:NSStringFromBSONType(*cur)];

    NSString *reason = [NSString stringWithFormat:@"Operation requires one of BSON types %@, but has %@ instead",
                        allowedTypes,
                        NSStringFromBSONType(iterator.valueType),
                        nil];
    id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                   reason:reason
                                 userInfo:nil];
    @throw exc;
}

__autoreleasing NSString * NSStringFromBSONError(int err) {
    NSMutableArray *errors = [NSMutableArray array];
    if (err & BSON_NOT_UTF8) [errors addObject:@"BSON_NOT_UTF8"];
    if (err & BSON_FIELD_HAS_DOT) [errors addObject:@"BSON_FIELD_HAS_DOT"];
    if (err & BSON_FIELD_INIT_DOLLAR) [errors addObject:@"BSON_FIELD_INIT_DOLLAR"];
    if (err & BSON_ALREADY_FINISHED) [errors addObject:@"BSON_ALREADY_FINISHED"];
    
    if (errors.count)
        return [errors componentsJoinedByString:@" | "];
    else
        return @"BSON_VALID";
}

