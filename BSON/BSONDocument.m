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

static id substitute_for_printf_lock_token = nil;
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
    
#if !__has_feature(objc_arc)
    [stringToAppend release];
#endif
    return 0;
}

@interface BSONDocument ()
@property (retain) id dependentOn; // An object which retains the bson we're using
@property (retain) NSData *data;
@property (assign) BOOL destroyWhenDone;
@end

@implementation BSONDocument {
    /**
     The <code>bson</code> structure.
     */
    const bson *_bson;
}

- (id) init {
    if (self = [super init]) {
        _bson = bson_create();
        bson_empty((bson *)_bson); // _bson is const-qualified
        self.destroyWhenDone = NO;
        self.data = [NSData dataWithBytesNoCopy:(void *)bson_data(_bson)
                                         length:bson_size(_bson)
                                   freeWhenDone:NO];
    }
    return self;
}

- (id) initForEmbeddedDocumentWithIterator:(BSONIterator *) iterator dependentOn:(id) dependentOn {
    if (self = [super init]) {
        _bson = bson_create();
        // _bson is const-qualified
        bson_iterator_subobject([iterator nativeIteratorValue], (bson *)_bson);
        self.destroyWhenDone = NO;
        self.data = [NSData dataWithBytesNoCopy:(void *)bson_data(_bson)
                                         length:bson_size(_bson)
                                   freeWhenDone:NO];
        self.dependentOn = dependentOn;
    }
    return self;
}

- (id) initWithData:(NSData *) data {
    if (!data || !data.length) return [self init];
    if ([data isKindOfClass:[NSMutableData class]])
        data = [NSData dataWithData:data];
    if (self = [super init]) {
        _bson = bson_create();
        if (BSON_ERROR == bson_init_finished_data((bson *)_bson, (char *)data.bytes)) {
            bson_dispose((bson *)_bson);
#if !__has_feature(objc_arc)
            [self release];
#endif
            return nil;
        }
        self.data = data;
    }
    return self;
}

+ (BSONDocument *) documentWithNativeDocument:(const bson *) b destroyWhenDone:(BOOL) destroyWhenDone {
    BSONDocument *result = [[self alloc] initWithNativeDocument:b destroyWhenDone:destroyWhenDone];
    maybe_autorelease_and_return(result);
}

- (id) initWithNativeDocument:(const bson *) b destroyWhenDone:(BOOL) destroyWhenDone {
    if (!b) {
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }
    if (self = [super init]) {
        _bson = b;
        self.destroyWhenDone = destroyWhenDone;
        // Copy the buffer into a new NSData we own. That way, objects which invoke -dataValue can
        // retain the NSData object without needing to retain the document object too.
        self.data = [NSData dataWithNativeBSONObject:_bson copy:YES];
    }
    return self;
}

- (void) dealloc {
    // override const qualifier
    if (self.destroyWhenDone) bson_destroy((bson *)_bson);
    bson_dispose((bson *)_bson);
#if !__has_feature(objc_arc)
    self.data = nil;
    self.dependentOn = nil;
    [super dealloc];
#endif
}

- (const bson *) bsonValue {
    return _bson;
}

- (id) copy {
    bson *newBson = bson_create();
    bson_copy(newBson, _bson);
    BSONDocument *copy = [[BSONDocument alloc] initWithNativeDocument:newBson destroyWhenDone:YES];
    return copy;
}

- (NSData *) dataValue {
    return _data;
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
    [[NSString stringWithFormat:
      @"%@ <%p>  bson.data: %p  bson.cur: %p  bson.dataSize: %i  bson.stackPos: %i  bson.err: %@\n",
      [[self class] description], self,
      _bson->data,
      _bson->cur,
      _bson->dataSize,
      _bson->stackPos,
      NSStringFromBSONError(_bson->err)] mutableCopy];    
    // Note: _bson->errstr is omitted. As of driver v0.7.1 it's always NULL.
    
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
    
    return [result stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

@end