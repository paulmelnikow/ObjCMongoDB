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
#import "OrderedDictionary.h"

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

- (BSONDecoder *) initWithData:(NSData *) data {
    return [self initWithDocument:[BSONDocument documentWithData:data]];
}

- (void) dealloc {
    maybe_release(_delegate);
    maybe_release(_managedObjectContext);
    maybe_release(_iterator);
    maybe_release(_iteratorStack);
    maybe_release(_privateKeyPathComponents);
    super_dealloc;
}

#pragma mark - Convenience methods

+ (NSDictionary *) decodeDictionaryWithDocument:(BSONDocument *)document {
    return [self decodeDictionaryWithClass:nil document:document];
}

+ (NSDictionary *) decodeDictionaryWithClass:(Class) classForDecoder document:(BSONDocument *) document {
    BSONDecoder *decoder = [[self alloc] initWithDocument:document];
    NSDictionary *result = [decoder decodeDictionaryWithClass:classForDecoder];
    maybe_release(decoder);
    maybe_retain_autorelease_and_return(result);
}

+ (NSDictionary *) decodeDictionaryWithData:(NSData *)data {
    return [self decodeDictionaryWithClass:nil data:data];
}

+ (NSDictionary *) decodeDictionaryWithClass:(Class) classForDecoder data:(NSData *) data {
    BSONDecoder *decoder = [[self alloc] initWithData:data];
    NSDictionary *result = [decoder decodeDictionaryWithClass:classForDecoder];
    maybe_release(decoder);
    maybe_retain_autorelease_and_return(result);
}

+ (NSDictionary *) decodeObjectWithClass:(Class) classForDecoder document:(BSONDocument *) document {
    BSONDecoder *decoder = [[self alloc] initWithDocument:document];
    NSDictionary *result = [decoder decodeObjectWithClass:classForDecoder];
    maybe_release(decoder);
    maybe_retain_autorelease_and_return(result);
}

+ (id) decodeObjectWithClass:(Class) classForDecoder data:(NSData *) data {
    BSONDecoder *decoder = [[self alloc] initWithData:data];
    id result = [decoder decodeObjectWithClass:classForDecoder];
    maybe_release(decoder);
    maybe_retain_autorelease_and_return(result);
}

+ (id) decodeManagedObjectWithClass:(Class) classForDecoder
                            context:(NSManagedObjectContext *) context
                               data:(NSData *) data {
    BSONDecoder *decoder = [[self alloc] initWithData:data];
    decoder.managedObjectContext = context;
    decoder.behaviorOnNull = BSONReturnNilForNull;
    NSDictionary *result = [decoder decodeObjectWithClass:classForDecoder];
    maybe_release(decoder);
    maybe_retain_autorelease_and_return(result);
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
            // result will not be set
            NSLog(@"Raised while decoding: %@", exception);
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
            // result will not be set
            NSLog(@"Raised while decoding: %@", exception);
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
    if (![self.iteratorStack count])
        [NSException raise:NSInvalidUnarchiveOperationException
                    format:@"-leaveInternalObject called too many times (without matching call to -enterInternalObjectAsArray:)"];
    
    self.iterator = [self.iteratorStack lastObject];
    [self.iteratorStack removeLastObject];
    [self.privateKeyPathComponents removeLastObject];
}

- (NSDictionary *) decodeDictionaryForKey:(NSString *) key {
    return [self decodeDictionaryForKey:key withClass:nil];
}

- (NSDictionary *) decodeDictionaryForKey:(NSString *) key withClass:(Class) classForDecoder {
    id result = nil;
    if ([self _decodingHelperForKey:key allowedValueType:BSONTypeEmbeddedDocument result:&result]) return result;
    
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
    if ([self _decodingHelperForKey:key allowedValueType:BSONTypeArray result:&result]) return result;
    
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
            result = maybe_retain([self _decodeExposedDictionaryWithClassOrNil:nil]);
        else if ([classForDecoder instancesRespondToSelector:@selector(initWithBSONDecoder:)])
            result = [[classForDecoder allocWithZone:self.objectZone] initWithBSONDecoder:self];
        else if ([classForDecoder instancesRespondToSelector:@selector(initWithCoder:)])
            result = [[classForDecoder allocWithZone:self.objectZone] initWithCoder:self];
        else
            [NSException raise:NSInvalidUnarchiveOperationException
                        format:@"Class %@ does not implement initWithCoder: or initWithBSONDecoder:",
             NSStringFromClass(classForDecoder)];
    }
    maybe_autorelease_and_return(result);
}

- (NSDictionary *) _decodeExposedDictionaryWithClassOrNil:(Class) classForDecoder {
    OrderedDictionary *dictionary = [OrderedDictionary dictionary];
    while ([self.iterator next])
        [dictionary setObject:[self _decodeCurrentObjectWithClassOrNil:classForDecoder]
                       forKey:[self.iterator key]];
    return dictionary;
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
    if ([self _decodingHelperForKey:key allowedValueType:BSONTypeObjectID result:&result]) return result;
    return [self _postDecodingHelper:[self.iterator objectIDValue] keyOrNil:key topLevel:NO];
}

- (id) decodeObjectIDForKey:(NSString *) key substituteObjectWithClass:(Class) classForDecoder {
    id result = nil;
    if ([self _decodingHelperForKey:key allowedValueType:BSONTypeObjectID result:&result]) return result;
    return [self _postDecodingHelper:[self.iterator objectIDValue] keyOrNil:key topLevel:NO substituteClassForObjectID:classForDecoder];
}

- (int) decodeIntForKey:(NSString *) key {
    static NSArray *allowedTypes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allowedTypes = @[
                         @(BSONTypeInteger),
                         @(BSONTypeLong),
                         @(BSONTypeDouble)
                         ];
        maybe_retain_void(allowedTypes);
    });
    id result = nil;
    if ([self _decodingHelperForKey:key
              allowedValueTypeArray:allowedTypes
                             result:&result])
        return 0;
    
    return [self.iterator intValue];
}
- (int64_t) decodeInt64ForKey:(NSString *) key {
    static NSArray *allowedTypes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allowedTypes = @[
                         @(BSONTypeInteger),
                         @(BSONTypeLong),
                         @(BSONTypeDouble)
                         ];
        maybe_retain_void(allowedTypes);
    });
    id result = nil;
    if ([self _decodingHelperForKey:key
              allowedValueTypeArray:allowedTypes
                             result:&result])
        return 0;
    
    return [self.iterator int64Value];
}
- (BOOL) decodeBoolForKey:(NSString *) key {
    static NSArray *allowedTypes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allowedTypes = @[
                         @(BSONTypeBoolean),
                         @(BSONTypeInteger),
                         @(BSONTypeLong),
                         @(BSONTypeDouble)
                         ];
        maybe_retain_void(allowedTypes);
    });
    id result = nil;
    if ([self _decodingHelperForKey:key
              allowedValueTypeArray:allowedTypes
                             result:&result])
        return 0;
    
    return [self.iterator doubleValue];
}
- (double) decodeDoubleForKey:(NSString *) key {
    static NSArray *allowedTypes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allowedTypes = @[
                         @(BSONTypeInteger),
                         @(BSONTypeLong),
                         @(BSONTypeDouble)
                         ];
        maybe_retain_void(allowedTypes);
    });
    id result = nil;
    if ([self _decodingHelperForKey:key
              allowedValueTypeArray:allowedTypes
                             result:&result])
        return 0;
    
    return [self.iterator doubleValue];
}

- (NSDate *) decodeDateForKey:(NSString *)key {
    id result = nil;
    if ([self _decodingHelperForKey:key
                   allowedValueType:BSONTypeDate
                             result:&result])
        return result;
    return [self _postDecodingHelper:[self.iterator dateValue] keyOrNil:key topLevel:NO];
}
- (BSONImageClassName *) decodeImageForKey:(NSString *) key {
    NSData *data = [self decodeDataForKey:key];
    if (data)
        maybe_autorelease_and_return([[BSONImageClassName alloc] initWithData:data]);
    else
        return nil;
}

- (NSString *) decodeStringForKey:(NSString *) key {
    static NSArray *allowedTypes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allowedTypes = @[
                         @(BSONTypeString),
                         @(BSONTypeCode),
                         @(BSONTypeSymbol)
                         ];
        maybe_retain_void(allowedTypes);
    });
    id result = nil;
    if ([self _decodingHelperForKey:key
              allowedValueTypeArray:allowedTypes
                             result:&result])
        return result;
    
    return [self _postDecodingHelper:[self.iterator stringValue] keyOrNil:key topLevel:NO];
}

- (BSONSymbol *) decodeSymbolForKey:(NSString *) key {
    id result = nil;
    if ([self _decodingHelperForKey:key allowedValueType:BSONTypeSymbol result:&result]) return result;
    return [self _postDecodingHelper:[self.iterator symbolValue] keyOrNil:key topLevel:NO];
}

- (BSONRegularExpression *) decodeRegularExpressionForKey:(NSString *) key {
    id result = nil;
    if ([self _decodingHelperForKey:key allowedValueType:BSONTypeRegularExpression result:&result]) return result;
    return [self _postDecodingHelper:[self.iterator regularExpressionValue] keyOrNil:key topLevel:NO];
}

- (BSONDocument *) decodeBSONDocumentForKey:(NSString *) key {
    id result = nil;
    if ([self _decodingHelperForKey:key allowedValueType:BSONTypeEmbeddedDocument result:&result]) return result;
    return [self _postDecodingHelper:[self.iterator embeddedDocumentValue] keyOrNil:key topLevel:NO];
}

- (NSData *)decodeDataForKey:(NSString *) key {
    id result = nil;
    if ([self _decodingHelperForKey:key allowedValueType:BSONTypeBinaryData result:&result]) return result;
    return [self _postDecodingHelper:[self.iterator dataValue] keyOrNil:key topLevel:NO];
}

- (BSONCode *) decodeCodeForKey:(NSString *) key {
    id result = nil;
    if ([self _decodingHelperForKey:key allowedValueType:BSONTypeCode result:&result]) return result;
    return [self _postDecodingHelper:[self.iterator codeValue] keyOrNil:key topLevel:NO];
}
- (BSONCodeWithScope *) decodeCodeWithScopeForKey:(NSString *) key {
    id result = nil;
    if ([self _decodingHelperForKey:key allowedValueType:BSONTypeCodeWithScope result:&result]) return result;
    return [self _postDecodingHelper:[self.iterator codeWithScopeValue] keyOrNil:key topLevel:NO];
}

#pragma mark - Helper methods for -decode... methods

- (BOOL) _decodingHelper:(id*) result {
    if (BSONTypeNull == [self.iterator valueType]) {
        switch(self.behaviorOnNull) {
            case BSONReturnNSNull:
                *result = [NSNull null]; return YES;
            case BSONReturnNilForNull:
                *result = nil; return YES;
            case BSONRaiseExceptionOnNull:
                [NSException raise:NSInvalidUnarchiveOperationException
                            format:@"Tried to decode null value with BSONRaiseExceptionOnNull set"];
        }
    } else if (BSONTypeUndefined == [self.iterator valueType]) {
        switch(self.behaviorOnUndefined) {
            case BSONReturnBSONUndefined:
                *result = [BSONDecoder objectForUndefined]; return YES;
            case BSONReturnNSNullForUndefined:
                *result = [NSNull null]; return YES;
            case BSONReturnNilForUndefined:
                *result = nil; return YES;
            case BSONRaiseExceptionOnUndefined:
                [NSException raise:NSInvalidUnarchiveOperationException
                            format:@"Tried to decode undefined value with BSONRaiseExceptionOnUndefined set"];
        }
    }
    return NO;
}

- (BOOL) _decodingHelperForKey:(NSString *) key result:(id*) result {
    NSParameterAssert(key != nil);
    if (![self.iterator containsValueForKey:key]) {
        result = nil; return YES;
    }
    return [self _decodingHelper:result];
}

- (BOOL) _decodingHelperForKey:(NSString *) key
              allowedValueType:(BSONType) allowedValueType
                        result:(id*) result {
    if ([self _decodingHelperForKey:key result:result]) return YES;
    
    if (self.iterator.valueType != allowedValueType) {
        [NSException raise:NSInvalidUnarchiveOperationException
                    format:@"Operation requires BSON type %@, but has %@ instead",
         NSStringFromBSONType(allowedValueType),
         NSStringFromBSONType(self.iterator.valueType),
         nil];
    }
    
    return NO;
}

- (BOOL) _decodingHelperForKey:(NSString *) key
         allowedValueTypeArray:(NSArray *) allowedValueTypeArray
                        result:(id*) result {
    if ([self _decodingHelperForKey:key result:result]) return YES;
    
    if (![self.iterator valueTypeIsInArray:allowedValueTypeArray]) {
        NSMutableArray *allowedTypesAsStrings = [NSMutableArray array];
        for (NSNumber *cur in allowedValueTypeArray)
            [allowedTypesAsStrings addObject:NSStringFromBSONType([cur intValue])];
        
        [NSException raise:NSInvalidUnarchiveOperationException
                    format:@"Operation requires one of BSON types %@, but has %@ instead",
         allowedTypesAsStrings,
         NSStringFromBSONType(self.iterator.valueType),
         nil];
    }

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
                object = maybe_autorelease([classForObjectID instanceForObjectID:maybe_retain(object) decoder:self]);
            else
                [NSException raise:NSInvalidUnarchiveOperationException
                            format:@"Substituting class %@ for object ID but class doesn't respond to +instanceForObjectID:decoder:",
                 NSStringFromClass(classForObjectID)];
        }
    }
    
    if ([object respondsToSelector:@selector(awakeAfterUsingBSONDecoder:)])
        object = maybe_autorelease([maybe_retain(object) awakeAfterUsingBSONDecoder:self]);
    else if ([object respondsToSelector:@selector(awakeAfterUsingCoder:)])
        object = maybe_autorelease([maybe_retain(object) awakeAfterUsingCoder:self]);
    
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

- (BSONType) valueTypeForKey:(NSString *) key {
    return [self.iterator valueTypeForKey:key];
}

- (BOOL) valueIsEmbeddedDocumentForKey:(NSString *) key {
    return BSONTypeEmbeddedDocument == [self valueTypeForKey:key];
}

- (BOOL) valueIsArrayForKey:(NSString *) key {
    return BSONTypeArray == [self valueTypeForKey:key];
}

+ (id) objectForUndefined {
    return [BSONIterator objectForUndefined];
}

- (NSArray *) keyPathComponents {
    maybe_autorelease_and_return([self.privateKeyPathComponents copy]);
}

- (NSArray *) _keyPathComponentsAddingKeyOrNil:(NSString *) key {
    NSArray *result = [self keyPathComponents];
    if (key) result = [result arrayByAddingObject:key];
    return result.count ? result : nil;
}

#pragma mark - Unsupported unkeyed encoding methods

+ (void) _raiseUnsupportedUnkeyedCodingSelector:(SEL)selector {
    [NSException raise:NSInvalidUnarchiveOperationException
                format:@"%@ called, but unkeyed decoding methods are not supported. Subclass if unkeyed coding is needed.",
     NSStringFromSelector(selector)];
}

- (void) decodeArrayOfObjCType:(const char *) itemType count:(NSUInteger) count at:(void *) array {
    [BSONDecoder _raiseUnsupportedUnkeyedCodingSelector:_cmd];
}
- (NSData *) decodeDataObject {
    [BSONDecoder _raiseUnsupportedUnkeyedCodingSelector:_cmd];
    return nil;
}
- (void) decodeValueOfObjCType:(const char *) type at:(void *) data {
    [BSONDecoder _raiseUnsupportedUnkeyedCodingSelector:_cmd];
}
- (void) decodeValuesOfObjCTypes:(const char *)types, ... {
    [BSONDecoder _raiseUnsupportedUnkeyedCodingSelector:_cmd];
}

#pragma mark - Unsupported decoding types

+ (void) _raiseUnsupportedCodingSelector:(SEL) selector {
    [NSException raise:NSInvalidUnarchiveOperationException
                format:@"%@ is not supported. Subclass if coding this type is needed.",
     NSStringFromSelector(selector)];
}

- (const uint8_t *) decodeBytesForKey:(NSString *) key returnedLength:(NSUInteger *)lengthp {
    [BSONDecoder _raiseUnsupportedCodingSelector:_cmd];
    return NULL;
}
- (void *) decodeBytesWithReturnedLength:(NSUInteger *) lengthp {
    [BSONDecoder _raiseUnsupportedCodingSelector:_cmd];
    return NULL;
}
- (float) decodeFloatForKey:(NSString *) key {
    [BSONDecoder _raiseUnsupportedCodingSelector:_cmd];
    return 0;
}
- (int32_t) decodeInt32ForKey:(NSString *) key {
    [BSONDecoder _raiseUnsupportedCodingSelector:_cmd];
    return 0;
}
- (NSInteger) decodeIntegerForKey:(NSString *) key {
    [BSONDecoder _raiseUnsupportedCodingSelector:_cmd];
    return 0;
}
- (id)decodeObject {
    [NSException raise:NSInvalidUnarchiveOperationException
                format:@"Use -decodeObjectWithClass: instead."];
    return nil;
}
-(id)decodePropertyList {
    [BSONDecoder _raiseUnsupportedCodingSelector:_cmd];
    return nil;
}
#if !TARGET_OS_IPHONE
-(NSPoint)decodePoint {
    [BSONDecoder _raiseUnsupportedCodingSelector:_cmd];
    return NSZeroPoint;
}
-(NSPoint)decodePointForKey:(NSString *)key {
    [BSONDecoder _raiseUnsupportedCodingSelector:_cmd];
    return NSZeroPoint;
}
-(NSRect)decodeRect {
    [BSONDecoder _raiseUnsupportedCodingSelector:_cmd];
    return NSZeroRect;    
}
-(NSRect)decodeRectForKey:(NSString *)key {
    [BSONDecoder _raiseUnsupportedCodingSelector:_cmd];
    return NSZeroRect;    
}
-(NSSize)decodeSize {
    [BSONDecoder _raiseUnsupportedCodingSelector:_cmd];
    return NSZeroSize;    
}
-(NSSize)decodeSizeForKey:(NSString *)key {
    [BSONDecoder _raiseUnsupportedCodingSelector:_cmd];
    return NSZeroSize;    
}
#endif

@end