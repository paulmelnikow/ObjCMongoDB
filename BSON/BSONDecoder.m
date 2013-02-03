//
//  BSONDecoder.m
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

#import "BSONDecoder.h"
#import "bson.h"
#import "BSONIterator.h"
#import "BSONCoding.h"
#import "BSON_PrivateInterfaces.h"
#import "BSON_Helper.h"

@interface BSONDecoder ()
@property (retain) BSONIterator *iterator;
@property (retain) NSMutableArray *iteratorStack;
@property (retain) NSMutableArray *privateKeyPathComponents;
@end

@implementation BSONDecoder

#pragma mark - Initialization

- (BSONDecoder *) initWithDocument:(BSONDocument *) document {
    self = [super init];
    if (self) {
        self.iterator = [document iterator];
        self.iteratorStack = [NSMutableArray array];
        self.privateKeyPathComponents = [NSMutableArray array];
        self.objectZone = NSDefaultMallocZone();
    }
    return self;
}

- (BSONDecoder *) initWithData:(NSData *)data {
#if __has_feature(objc_arc)
    return [self initWithDocument:[[BSONDocument alloc] initWithData:data]];
#else
    return [self initWithDocument:[[[BSONDocument alloc] initWithData:data] autorelease]];
#endif
}

- (void) dealloc {
#if !__has_feature(objc_arc)
    self.privateKeyPathComponents = nil;
    self.iteratorStack = nil;
    self.iterator = nil;
    self.managedObjectContext = nil;
    self.delegate = nil;
    [super dealloc];
#endif
}

#pragma mark - Convenience methods

+ (NSDictionary *) decodeDictionaryWithDocument:(BSONDocument *)document {
    return [self decodeDictionaryWithClass:nil document:document];
}

+ (NSDictionary *) decodeDictionaryWithClass:(Class) classForDecoder document:(BSONDocument *) document {
    BSONDecoder *decoder = [[self alloc] initWithDocument:document];
    NSDictionary *result = [decoder decodeDictionaryWithClass:classForDecoder];
#if !__has_feature(objc_arc)
    [[result retain] autorelease];
    [decoder release];
#endif
    return result;
}

+ (NSDictionary *) decodeDictionaryWithData:(NSData *)data {
    return [self decodeDictionaryWithClass:nil data:data];
}

+ (NSDictionary *) decodeDictionaryWithClass:(Class) classForDecoder data:(NSData *) data {
    BSONDecoder *decoder = [[self alloc] initWithData:data];
    NSDictionary *result = [decoder decodeDictionaryWithClass:classForDecoder];
#if !__has_feature(objc_arc)
    [[result retain] autorelease];
    [decoder release];
#endif
    return result;
}

+ (NSDictionary *) decodeObjectWithClass:(Class) classForDecoder document:(BSONDocument *) document {
    BSONDecoder *decoder = [[self alloc] initWithDocument:document];
    NSDictionary *result = [decoder decodeObjectWithClass:classForDecoder];
#if !__has_feature(objc_arc)
    [[result retain] autorelease];
    [decoder release];
#endif
    return result;
}

+ (NSDictionary *) decodeObjectWithClass:(Class) classForDecoder data:(NSData *) data {
    BSONDecoder *decoder = [[self alloc] initWithData:data];
    NSDictionary *result = [decoder decodeObjectWithClass:classForDecoder];
#if !__has_feature(objc_arc)
    [[result retain] autorelease];
    [decoder release];
#endif
    return result;
}

#pragma mark - Decoding top-level objects

- (NSDictionary *) decodeDictionary {
    return [self decodeDictionaryWithClass:nil];
}

- (NSDictionary *) decodeDictionaryWithClass:(Class) classForDecoder {
    id result = nil;
    @try {
        result = [self _decodeExposedDictionaryWithClassOrNil:classForDecoder];
    }
    @catch (NSException *exception) {
        if (BSONException == exception.name) {
            NSLog(@"Raised while decoding: %@", exception);
#if !__has_feature(objc_arc)
            [result release];
#endif
            result = nil;
        } else @throw;
    }
    return [self _postDecodingHelper:result keyOrNil:nil topLevel:YES];
}

- (id) decodeObjectWithClass:(Class) classForDecoder {
    id result = nil;
    @try {
        result = [self _decodeExposedCustomObjectWithClassOrNil:classForDecoder];
    }
    @catch (NSException *exception) {
        if (BSONException == exception.name) {
            NSLog(@"Raised while decoding: %@", exception);
#if !__has_feature(objc_arc)
            [result release];
#endif
            result = nil;
        } else @throw;
    }
    return [self _postDecodingHelper:result keyOrNil:nil topLevel:YES];
}

#pragma mark - Exposing internal objects

- (void) _exposeKey:(NSString *)key asArray:(BOOL) asArray {
    [self.iteratorStack addObject:self.iterator];
    if (asArray)
        self.iterator = [self.iterator sequentialSubIteratorValue];
    else
        self.iterator = [self.iterator embeddedDocumentIteratorValue];
    [self.privateKeyPathComponents addObject:key];
}

- (void) _closeInternalObject {
    if (![self.iteratorStack count]) {
        id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                         reason:@"-leaveInternalObject called too many times (without matching call to -enterInternalObjectAsArray:)"
                                       userInfo:nil];
        @throw exc;
    }
    self.iterator = [self.iteratorStack lastObject];
    [self.iteratorStack removeLastObject];
    [self.privateKeyPathComponents removeLastObject];
}

- (NSDictionary *) decodeDictionaryForKey:(NSString *) key {
    return [self decodeDictionaryForKey:key withClass:nil];
}

- (NSDictionary *) decodeDictionaryForKey:(NSString *) key withClass:(Class) classForDecoder {
    id result = nil;
    if ([self _decodingHelperForKey:key nativeValueType:BSON_OBJECT result:&result]) return result;
    
    [self _exposeKey:key asArray:NO];
    result = [self _decodeExposedDictionaryWithClassOrNil:classForDecoder];
    [self _closeInternalObject];
    return [self _postDecodingHelper:result keyOrNil:key topLevel:NO];
}

- (NSArray *) decodeArrayForKey:(NSString *) key {
    return [self decodeArrayForKey:key withClass:nil];
}

- (NSArray *) decodeArrayForKey:(NSString *) key withClass:(Class) classForDecoder {
    id result = nil;
    if ([self _decodingHelperForKey:key nativeValueType:BSON_ARRAY result:&result]) return result;
    
    [self _exposeKey:key asArray:YES];
    result = [self _decodeExposedArrayWithClassOrNil:classForDecoder];
    [self _closeInternalObject];
    return [self _postDecodingHelper:result keyOrNil:key topLevel:NO];
}

#pragma mark - Decoding exposed internal objects

- (id) _decodeExposedCustomObjectWithClassOrNil:(Class) classForDecoder {
    id result = nil;
    @autoreleasepool {
        if (!classForDecoder)
#if __has_feature(objc_arc)
            result = [self _decodeExposedDictionaryWithClassOrNil:nil];
#else
            result = [[self _decodeExposedDictionaryWithClassOrNil:nil] retain];
#endif
        else if ([classForDecoder instancesRespondToSelector:@selector(initWithBSONDecoder:)])
            result = [[classForDecoder allocWithZone:self.objectZone] initWithBSONDecoder:self];
        else if ([classForDecoder instancesRespondToSelector:@selector(initWithCoder:)])
            result = [[classForDecoder allocWithZone:self.objectZone] initWithCoder:self];
        else {
            NSString *reason = [NSString stringWithFormat:@"Class %@ does not implement initWithCoder: or initWithBSONDecoder:",
                                NSStringFromClass(classForDecoder)];
            id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                             reason:reason
                                           userInfo:nil];
            @throw exc;
        }
    }
#if __has_feature (objc_arc)
    return result;
#else
    return [result autorelease];
#endif
}

- (NSDictionary *) _decodeExposedDictionaryWithClassOrNil:(Class) classForDecoder {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    while ([self.iterator next])
        [dictionary setObject:[self _decodeCurrentObjectWithClassOrNil:classForDecoder]
                       forKey:[self.iterator key]];
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

- (NSArray *) _decodeExposedArrayWithClassOrNil:(Class) classForDecoder {
    NSMutableArray *array = [NSMutableArray array];
    while ([self.iterator next])
        [array addObject:[self _decodeCurrentObjectWithClassOrNil:classForDecoder]];
    return [NSArray arrayWithArray:array];
}

- (id) _decodeCurrentObjectWithClassOrNil:(Class) classForDecoder {
    id result = nil;
    if ([self _decodingHelper:&result]) return result;
    
    if (![self.iterator isArray] && ![self.iterator isEmbeddedDocument]) {
        result = [self.iterator objectValue];
        
    } else if (classForDecoder) {
        [self _exposeKey:[self.iterator key] asArray:NO];
        result = [self _decodeExposedCustomObjectWithClassOrNil:classForDecoder];
        [self _closeInternalObject];
        
    } else if ([self.iterator isEmbeddedDocument]) {
        [self _exposeKey:[self.iterator key] asArray:NO];
        result = [self _decodeExposedDictionaryWithClassOrNil:nil];
        [self _closeInternalObject];        
        
    } else {
        [self _exposeKey:[self.iterator key] asArray:YES];
        result = [self _decodeExposedArrayWithClassOrNil:nil];
        [self _closeInternalObject];        
    }
    
    return [self _postDecodingHelper:result keyOrNil:[self.iterator key] topLevel:NO];
}


#pragma mark - Basic decoding methods

- (id) decodeObjectForKey:(NSString *) key {
    return [self decodeObjectForKey:key withClass:nil];
}

- (id) decodeObjectForKey:(NSString *) key withClass:(Class) classForDecoder {
    id result = nil;
    if ([self _decodingHelperForKey:key result:&result]) return result;
    
    if (![self.iterator isArray] && ![self.iterator isEmbeddedDocument]) {
        result = [self.iterator objectValue];
        
    } else if (classForDecoder) {
        [self _exposeKey:key asArray:NO];
        result = [self _decodeExposedCustomObjectWithClassOrNil:classForDecoder];
        [self _closeInternalObject];
        
    } else if ([self.iterator isEmbeddedDocument]) {
        [self _exposeKey:key asArray:NO];
        result = [self _decodeExposedDictionaryWithClassOrNil:nil];
        [self _closeInternalObject];        
        
    } else {
        [self _exposeKey:key asArray:YES];
        result = [self _decodeExposedArrayWithClassOrNil:nil];
        [self _closeInternalObject];        
    }
    
    return result;
}

#pragma mark - Decoding supported types

- (BSONObjectID *) decodeObjectIDForKey:(NSString *) key {
    id result = nil;
    if ([self _decodingHelperForKey:key nativeValueType:BSON_OID result:&result]) return result;
    return [self _postDecodingHelper:[self.iterator objectIDValue] keyOrNil:key topLevel:NO];
}

- (id) decodeObjectIDForKey:(NSString *) key substituteObjectWithClass:(Class) classForDecoder {
    id result = nil;
    if ([self _decodingHelperForKey:key nativeValueType:BSON_OID result:&result]) return result;
    return [self _postDecodingHelper:[self.iterator objectIDValue] keyOrNil:key topLevel:NO substituteClassForObjectID:classForDecoder];
}

- (int) decodeIntForKey:(NSString *) key {
    bson_type allowedTypes[3];
    allowedTypes[0] = BSON_INT;
    allowedTypes[1] = BSON_LONG;
    allowedTypes[2] = BSON_DOUBLE;
    
    id result = nil;
    if ([self _decodingHelperForKey:key nativeValueTypeArray:allowedTypes result:&result]) return 0;
    
    return [self.iterator intValue];
}
- (int64_t) decodeInt64ForKey:(NSString *) key {
    bson_type allowedTypes[3];
    allowedTypes[0] = BSON_INT;
    allowedTypes[1] = BSON_LONG;
    allowedTypes[2] = BSON_DOUBLE;
    
    id result = nil;
    if ([self _decodingHelperForKey:key nativeValueTypeArray:allowedTypes result:&result]) return 0;
    
    return [self.iterator int64Value];
}
- (BOOL) decodeBoolForKey:(NSString *) key {
    bson_type allowedTypes[4];
    allowedTypes[0] = BSON_BOOL;
    allowedTypes[1] = BSON_INT;
    allowedTypes[2] = BSON_LONG;
    allowedTypes[3] = BSON_DOUBLE;
    
    id result = nil;
    if ([self _decodingHelperForKey:key nativeValueTypeArray:allowedTypes result:&result]) return 0;
    
    return [self.iterator doubleValue];
}
- (double) decodeDoubleForKey:(NSString *) key {
    bson_type allowedTypes[3];
    allowedTypes[0] = BSON_INT;
    allowedTypes[1] = BSON_LONG;
    allowedTypes[2] = BSON_DOUBLE;
    
    id result = nil;
    if ([self _decodingHelperForKey:key nativeValueTypeArray:allowedTypes result:&result]) return 0;
    
    return [self.iterator doubleValue];
}

- (NSDate *) decodeDateForKey:(NSString *)key {
    id result = nil;
    if ([self _decodingHelperForKey:key nativeValueType:BSON_DATE result:&result]) return result;
    return [self _postDecodingHelper:[self.iterator dateValue] keyOrNil:key topLevel:NO];
}
- (NSImage *) decodeImageForKey:(NSString *) key {
    NSData *data = [self decodeDataForKey:key];
    if (data)
#if __has_feature(objc_arc)
        return [[NSImage alloc] initWithData:data];
#else
        return [[[NSImage alloc] initWithData:data] autorelease];
#endif
    else
        return nil;
}

- (NSString *) decodeStringForKey:(NSString *) key {
    bson_type allowedTypes[3];
    allowedTypes[0] = BSON_STRING;
    allowedTypes[1] = BSON_CODE;
    allowedTypes[2] = BSON_SYMBOL;
    
    id result = nil;
    if ([self _decodingHelperForKey:key nativeValueTypeArray:allowedTypes result:&result]) return result;
    
    return [self _postDecodingHelper:[self.iterator stringValue] keyOrNil:key topLevel:NO];
}

- (BSONSymbol *) decodeSymbolForKey:(NSString *) key {
    id result = nil;
    if ([self _decodingHelperForKey:key nativeValueType:BSON_SYMBOL result:&result]) return result;
    return [self _postDecodingHelper:[self.iterator symbolValue] keyOrNil:key topLevel:NO];
}

- (BSONRegularExpression *) decodeRegularExpressionForKey:(NSString *) key {
    id result = nil;
    if ([self _decodingHelperForKey:key nativeValueType:BSON_REGEX result:&result]) return result;
    return [self _postDecodingHelper:[self.iterator regularExpressionValue] keyOrNil:key topLevel:NO];
}

- (BSONDocument *) decodeBSONDocumentForKey:(NSString *) key {
    id result = nil;
    if ([self _decodingHelperForKey:key nativeValueType:BSON_OBJECT result:&result]) return result;
    return [self _postDecodingHelper:[self.iterator embeddedDocumentValue] keyOrNil:key topLevel:NO];
}

- (NSData *)decodeDataForKey:(NSString *) key {
    id result = nil;
    if ([self _decodingHelperForKey:key nativeValueType:BSON_BINDATA result:&result]) return result;
    return [self _postDecodingHelper:[self.iterator dataValue] keyOrNil:key topLevel:NO];
}

- (BSONCode *) decodeCodeForKey:(NSString *) key {
    id result = nil;
    if ([self _decodingHelperForKey:key nativeValueType:BSON_CODE result:&result]) return result;
    return [self _postDecodingHelper:[self.iterator codeValue] keyOrNil:key topLevel:NO];
}
- (BSONCodeWithScope *) decodeCodeWithScopeForKey:(NSString *) key {
    id result = nil;
    if ([self _decodingHelperForKey:key nativeValueType:BSON_CODEWSCOPE result:&result]) return result;
    return [self _postDecodingHelper:[self.iterator codeWithScopeValue] keyOrNil:key topLevel:NO];
}

#pragma mark - Helper methods for -decode... methods

- (BOOL) _decodingHelper:(id*) result {
    if (BSON_NULL == [self.iterator nativeValueType]) {
        switch(self.behaviorOnNull) {
            case BSONReturnNSNull:
                *result = [NSNull null]; return YES;
            case BSONReturnNilForNull:
                *result = nil; return YES;
            case BSONRaiseExceptionOnNull:
                @throw [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                               reason:@"Tried to decode null value with BSONRaiseExceptionOnNull set"
                                             userInfo:nil];
        }
    } else if (BSON_UNDEFINED == [self.iterator nativeValueType]) {
        switch(self.behaviorOnUndefined) {
            case BSONReturnBSONUndefined:
                *result = [BSONDecoder objectForUndefined]; return YES;
            case BSONReturnNSNullForUndefined:
                *result = [NSNull null]; return YES;
            case BSONReturnNilForUndefined:
                *result = nil; return YES;
            case BSONRaiseExceptionOnUndefined:
                @throw [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                               reason:@"Tried to decode undefined value with BSONRaiseExceptionOnUndefined set"
                                             userInfo:nil];
        }
    }
    return NO;
}

- (BOOL) _decodingHelperForKey:(NSString *) key result:(id*) result {
    BSONAssertKeyNonNil(key);
    if (![self.iterator containsValueForKey:key]) {
        result = nil; return YES;
    }
    return [self _decodingHelper:result];
}

- (BOOL) _decodingHelperForKey:(NSString *) key nativeValueType:(bson_type) nativeValueType result:(id*) result {
    if ([self _decodingHelperForKey:key result:result]) return YES;
    BSONAssertIteratorIsValueType(self.iterator, nativeValueType);
    return NO;
}

- (BOOL) _decodingHelperForKey:(NSString *) key nativeValueTypeArray:(bson_type*) nativeValueTypeArray result:(id*) result {
    if ([self _decodingHelperForKey:key result:result]) return YES;
    BSONAssertIteratorIsInValueTypeArray(self.iterator, nativeValueTypeArray);
    return NO;
}

- (id) _postDecodingHelper:(id) object keyOrNil:(NSString *) key topLevel:(BOOL) topLevel {
    return [self _postDecodingHelper:object keyOrNil:key topLevel:topLevel substituteClassForObjectID:nil];
}

- (id) _postDecodingHelper:(id) object keyOrNil:(NSString *) key topLevel:(BOOL) topLevel substituteClassForObjectID:(Class) classForObjectID {
    id originalObject = object;
    
    if ([object isKindOfClass:[BSONObjectID class]]) {
        if (!classForObjectID
            && [self.delegate respondsToSelector:@selector(decoder:classToSubstituteForObjectID:forKeyPath:)])
            classForObjectID = [self.delegate decoder:self classToSubstituteForObjectID:object forKeyPath:[self _keyPathComponentsAddingKeyOrNil:key]];
        
        if (classForObjectID) {
            if ([classForObjectID respondsToSelector:@selector(instanceForObjectID:decoder:)])
#if __has_feature(objc_arc)
                object = [classForObjectID instanceForObjectID:object decoder:self];
#else
                object = [[classForObjectID instanceForObjectID:[object retain] decoder:self] autorelease];
#endif
            else {
                NSString *reason = [NSString stringWithFormat:@"Substituting class %@ for object ID but class doesn't respond to +instanceForObjectID:decoder:",
                                    NSStringFromClass(classForObjectID)];
                id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                                 reason:reason
                                               userInfo:nil];
                @throw exc;
            }
        }
    }
    
#if __has_feature(objc_arc)
    if ([object respondsToSelector:@selector(awakeAfterUsingBSONDecoder:)])
        object = [object awakeAfterUsingBSONDecoder:self];
    else if ([object respondsToSelector:@selector(awakeAfterUsingCoder:)])
        object = [object awakeAfterUsingCoder:self];
#else
    if ([object respondsToSelector:@selector(awakeAfterUsingBSONDecoder:)])
        object = [[[object retain] awakeAfterUsingBSONDecoder:self] autorelease];
    else if ([object respondsToSelector:@selector(awakeAfterUsingCoder:)])
        object = [[[object retain] awakeAfterUsingCoder:self] autorelease];
#endif
    
    if ([self.delegate respondsToSelector:@selector(decoder:didDecodeObject:forKeyPath:)])
        object = [self.delegate decoder:self didDecodeObject:object forKeyPath:[self _keyPathComponentsAddingKeyOrNil:key]];
    
    if (originalObject != object
        && [self.delegate respondsToSelector:@selector(decoder:willReplaceObject:withObject:forKeyPath:)])
        [self.delegate decoder:self willReplaceObject:originalObject withObject:object forKeyPath:[self _keyPathComponentsAddingKeyOrNil:key]];
    
    if (topLevel && [self.delegate respondsToSelector:@selector(decoderWillFinish:)])
        [self.delegate decoderWillFinish:self];
    
    return object;
}

#pragma mark - Other helper methods

- (BOOL) allowsKeyedCoding { return YES; }

- (BOOL) containsValueForKey:(NSString *) key {
    return [self.iterator containsValueForKey:key];
}

- (bson_type) nativeValueTypeForKey:(NSString *) key {
    return [self.iterator nativeValueTypeForKey:key];
}

- (BOOL) valueIsEmbeddedDocumentForKey:(NSString *) key {
    return BSON_OBJECT == [self nativeValueTypeForKey:key];
}

- (BOOL) valueIsArrayForKey:(NSString *) key {
    return BSON_ARRAY == [self nativeValueTypeForKey:key];
}

+ (id) objectForUndefined {
    return [BSONIterator objectForUndefined];
}

- (NSArray *) keyPathComponents {
#if __has_feature(objc_arc)
    return [self.privateKeyPathComponents copy];
#else
    return [[self.privateKeyPathComponents copy] autorelease];
#endif
}

- (NSArray *) _keyPathComponentsAddingKeyOrNil:(NSString *) key {
    NSArray *result = [self keyPathComponents];
    if (key) result = [result arrayByAddingObject:key];
    return result.count ? result : nil;
}

#pragma mark - Unsupported unkeyed encoding methods

+ (NSException *) _unsupportedUnkeyedCodingSelector:(SEL)selector {
    NSString *reason = [NSString stringWithFormat:@"%@ called, but unkeyed decoding methods are not supported. Subclass if unkeyed coding is needed.",
                        NSStringFromSelector(selector)];
    id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                     reason:reason
                                   userInfo:nil];
    @throw exc;
}

- (void) decodeArrayOfObjCType:(const char *) itemType count:(NSUInteger) count at:(void *) array {
    [BSONDecoder _unsupportedUnkeyedCodingSelector:_cmd];
}
- (NSData *) decodeDataObject {
    [BSONDecoder _unsupportedUnkeyedCodingSelector:_cmd];
    return nil;
}
- (void) decodeValueOfObjCType:(const char *) type at:(void *) data {
    [BSONDecoder _unsupportedUnkeyedCodingSelector:_cmd];
}
- (void) decodeValuesOfObjCTypes:(const char *)types, ... {
    [BSONDecoder _unsupportedUnkeyedCodingSelector:_cmd];
}

#pragma mark - Unsupported decoding types

+ (void) _unsupportedCodingSelector:(SEL) selector {
    NSString *reason = [NSString stringWithFormat:@"%@ is not supported. Subclass if coding this type is needed.",
                        NSStringFromSelector(selector)];
    id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                     reason:reason
                                   userInfo:nil];
    @throw exc;
}

- (const uint8_t *) decodeBytesForKey:(NSString *) key returnedLength:(NSUInteger *)lengthp {
    [BSONDecoder _unsupportedCodingSelector:_cmd];
    return NULL;
}
- (void *) decodeBytesWithReturnedLength:(NSUInteger *) lengthp {
    [BSONDecoder _unsupportedCodingSelector:_cmd];
    return NULL;
}
- (float) decodeFloatForKey:(NSString *) key {
    [BSONDecoder _unsupportedCodingSelector:_cmd];
    return 0;
}
- (int32_t) decodeInt32ForKey:(NSString *) key {
    [BSONDecoder _unsupportedCodingSelector:_cmd];
    return 0;
}
- (NSInteger) decodeIntegerForKey:(NSString *) key {
    [BSONDecoder _unsupportedCodingSelector:_cmd];
    return 0;
}
- (id)decodeObject {
    id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                     reason:@"Use -decodeObjectWithClass: instead."
                                   userInfo:nil];
    @throw exc;
}
-(NSPoint)decodePoint {
    [BSONDecoder _unsupportedCodingSelector:_cmd];
    return NSZeroPoint;
}
-(NSPoint)decodePointForKey:(NSString *)key {
    [BSONDecoder _unsupportedCodingSelector:_cmd];
    return NSZeroPoint;
}
-(id)decodePropertyList {
    [BSONDecoder _unsupportedCodingSelector:_cmd];
    return nil;
}
-(NSRect)decodeRect {
    [BSONDecoder _unsupportedCodingSelector:_cmd];
    return NSZeroRect;    
}
-(NSRect)decodeRectForKey:(NSString *)key {
    [BSONDecoder _unsupportedCodingSelector:_cmd];
    return NSZeroRect;    
}
-(NSSize)decodeSize {
    [BSONDecoder _unsupportedCodingSelector:_cmd];
    return NSZeroSize;    
}
-(NSSize)decodeSizeForKey:(NSString *)key {
    [BSONDecoder _unsupportedCodingSelector:_cmd];
    return NSZeroSize;    
}

@end