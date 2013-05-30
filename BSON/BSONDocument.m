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

#import "BSONDocument.h"
#import "BSONDecoder.h"
#import "BSON_PrivateInterfaces.h"
#import "BSON_Helper.h"

static NSMutableString * target_for_substitute_for_printf = nil;

int substitute_for_printf(const char *format, ...);
int substitute_for_printf(const char *format, ...) {
    if (!target_for_substitute_for_printf) return 0;
    
    va_list args;
    va_start(args, format);
    NSString *stringToAppend = [[NSString alloc] initWithFormat:[NSString stringWithBSONString:format]
                                                      arguments:args];
    va_end(args);
    
    [target_for_substitute_for_printf appendString:stringToAppend];
    
    maybe_release(stringToAppend);
    return 0;
}

@interface BSONDocument ()
@property (retain) id dependentOn; // An object which retains the bson we're using
@property (retain) NSData *privateData;
@end

@implementation BSONDocument {
    /**
     The <code>bson</code> structure.
     */
    bson *_bson;
}

- (id) init {
    bson * newBson = bson_alloc();
    bson_init_empty(newBson);
    id result = [self initWithNativeDocument:newBson dependentOn:nil];
    if (nil == result) bson_dealloc(newBson);
    return result;
}

- (id) initWithNativeDocument:(bson *) b dependentOn:(id) dependentOn {
    if (!b) nullify_self_and_return;
    if (self = [super init]) {
        _bson = b;
        self.dependentOn = dependentOn;
    }
    return self;
}

- (id) initWithData:(NSData *) data {
    if (!data.length) return [self init];
    if (self = [super init]) {
        self.privateData = [data isKindOfClass:[NSMutableData class]] ? [NSData dataWithData:data] : data;
        _bson = bson_alloc();
        if (BSON_ERROR == bson_init_finished_data(_bson, (char *) self.privateData.bytes, 0)) {
            bson_dealloc(_bson);
            nullify_self_and_return;
        }
    }
    return self;
}

- (void) dealloc {
    bson_destroy(_bson);
    bson_dealloc(_bson);
    _bson = NULL;
    maybe_release(_dependentOn);
    maybe_release(_privateData);
    super_dealloc;
}

+ (BSONDocument *) document {
    BSONDocument *result = [[self alloc] init];
    maybe_autorelease_and_return(result);
}

+ (BSONDocument *) documentWithNativeDocument:(bson *) b dependentOn:(id) dependentOn {
    BSONDocument *result = [[self alloc] initWithNativeDocument:b dependentOn:dependentOn];
    maybe_autorelease_and_return(result);
}

+ (BSONDocument *) documentWithData:(NSData *) data {
    BSONDocument *result = [[self alloc] initWithData:data];
    maybe_autorelease_and_return(result);    
}

- (const bson *) bsonValue {
    return _bson;
}

- (id) copy {
    bson *newBson = bson_alloc();
    bson_copy(newBson, _bson);
    BSONDocument *copy = [[BSONDocument alloc] initWithNativeDocument:newBson dependentOn:nil];
    return copy;
}

- (NSData *) dataValue {
    @synchronized (self) {
        if (nil == self.privateData)
            self.privateData = [NSData dataWithNativeBSONObject:_bson copy:YES];
        return self.privateData;
    }
}

- (BSONIterator *) iterator {
    BSONIterator *result = [[BSONIterator alloc] initWithDocument:self
                                           keyPathComponentsOrNil:nil];
    maybe_autorelease_and_return(result);
}

- (NSDictionary *) dictionaryValue {
    return [BSONDecoder decodeDictionaryWithDocument:self];
}

- (BOOL) isEqual:(id)object {
    NSData *objectData = nil;
    if ([object isKindOfClass:[NSData class]])
        objectData = object;
    else if ([object isKindOfClass:[BSONDocument class]])
        objectData = [object dataValue];
    return [objectData isEqualToData:[self dataValue]];
}

- (NSString *) description {        
    NSMutableString *result =
    [[NSMutableString alloc] initWithFormat:
      @"%@ <%p>  bson.data: %p  bson.cur: %p  bson.dataSize: %i  bson.stackPos: %i  bson.err: %@\n",
      [[self class] description], self,
      _bson->data,
      _bson->cur,
      _bson->dataSize,
      _bson->stackPos,
      NSStringFromBSONError(_bson->err)];
    
    static id substitute_for_printf_lock_token;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        substitute_for_printf_lock_token = [[NSObject alloc] init];
    });
    
    @synchronized (substitute_for_printf_lock_token) {    
        target_for_substitute_for_printf = result;
        bson_errprintf = bson_printf = substitute_for_printf;
        bson_print(_bson);
        bson_errprintf = bson_printf = printf;
        target_for_substitute_for_printf = nil;
    }

    maybe_autorelease_void(result);
    return [result stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

@end