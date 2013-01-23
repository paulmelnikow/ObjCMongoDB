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

@implementation BSONDocument

- (id) init {
    if (self = [super init]) {
        bson * newBson = bson_create();
        bson_empty(newBson);
        _bson = newBson;
        _destroyOnDealloc = NO;
        _data = [NSData dataWithBytesNoCopy:(void *)bson_data(newBson) length:bson_size(newBson) freeWhenDone:NO];
#if !__has_feature(objc_arc)
        [_data retain];
#endif
    }
    return self;
}

- (BSONDocument *)initForEmbeddedDocumentWithIterator:(BSONIterator *) iterator parent:(id) parent {
    if (self = [super init]) {
        bson * newBson = bson_create();
        bson_iterator_subobject([iterator nativeIteratorValue], newBson);
        _bson = newBson;
        _destroyOnDealloc = NO;
        _data = [NSData dataWithBytesNoCopy:(void *)bson_data(_bson) length:bson_size(_bson) freeWhenDone:NO];
#if __has_feature(objc_arc)
        _source = parent;
#else
        _source = [parent retain];
        [_data retain];
#endif
    }
    return self;
}

- (BSONDocument *) initWithData:(NSData *) data {
    if (!data || !data.length) return [self init];
    if ([data isKindOfClass:[NSMutableData class]])
        data = [NSData dataWithData:data];
    if (self = [super init]) {
        bson * newBson = bson_create();
        if (BSON_ERROR == bson_init_data(newBson, (char *)data.bytes)) {
#if !__has_feature(objc_arc)
            bson_dispose(newBson);
            [self release];
#endif
            return nil;
        }
        _bson = newBson;
#if __has_feature(objc_arc)
        _data = data;
#else
        _data = [data retain];
#endif
    }
    return self;
}

- (BSONDocument *) initWithNativeDocument:(const bson *) b destroyOnDealloc:(BOOL) destroyOnDealloc {
    if (!b) {
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }
    if (self = [super init]) {
        _bson = b;
        _destroyOnDealloc = destroyOnDealloc;
        // Copy the buffer into a new NSData. That way, objects which invoke -dataValue can retain the
        // NSData object without also retaining the BSONDocument object.
        _data = NSDataFromBSON(_bson, YES);
#if !__has_feature(objc_arc)
        [_data retain];
#endif
    }
    return self;
}

- (void) dealloc {
    // override const qualifier
    if (_destroyOnDealloc) bson_destroy((bson *)_bson);
    bson_dispose((bson *)_bson);
#if !__has_feature(objc_arc)
    [_data release];
    [_source release];
    [super dealloc];
#endif
}

- (const bson *) bsonValue {
    return _bson;
}

- (id) copy {
//    bson *newBson = malloc(sizeof(bson));
    bson *newBson = bson_create();
    bson_copy(newBson, _bson);
    BSONDocument *copy = [[BSONDocument alloc] initWithNativeDocument:newBson destroyOnDealloc:YES];
    return copy;
}

- (NSData *) dataValue {
    return _data;
}

- (BSONIterator *) iterator {
#if __has_feature(objc_arc)
    return [[BSONIterator alloc] initWithDocument:self keyPathComponentsOrNil:nil];
#else
    return [[[BSONIterator alloc] initWithDocument:self keyPathComponentsOrNil:nil] autorelease];
#endif
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
    NSString *identifier = [NSString stringWithFormat:@"%@ <%p>  bson.data: %p  bson.cur: %p  bson.dataSize: %i  bson.stackPos: %i  bson.err: %@\n",
                            [[self class] description], self,
                            _bson->data,
                            _bson->cur,
                            _bson->dataSize,
                            _bson->stackPos,
                            NSStringFromBSONError(_bson->err)];
//                            _bson->errstr];
    return [identifier stringByAppendingString:NSStringFromBSON(_bson)];
}

@end