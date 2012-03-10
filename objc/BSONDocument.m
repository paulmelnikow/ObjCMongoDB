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

- (BSONDocument *)init {
    if (self = [super init]) {
        _bson = malloc(sizeof(bson));
        bson_empty(_bson);
        _destroyOnDealloc = YES;
    }
    return self;
}

- (BSONDocument *)initForEmbeddedDocumentWithIterator:(BSONIterator *) iterator parent:(id) parent {
    if (self = [super init]) {
        _bson = malloc(sizeof(bson));
        bson_iterator_subobject([iterator nativeIteratorValue], _bson);
        _destroyOnDealloc = NO;
#if __has_feature(objc_arc)
        _source = parent;
#else
        _source = [parent retain];
#endif
    }
    return self;
}

- (BSONDocument *) initWithData:(NSData *) data {
    if (!data) return [self init];
    if ([data isKindOfClass:[NSMutableData class]])
        data = [NSData dataWithData:data];
    if (self = [super init]) {
#if __has_feature(objc_arc)
        _source = data;
#else
        _source = [data retain];
#endif
        bson_init_data(_bson, (char *)data.bytes);
    }
    return self;
}

- (BSONDocument *) initWithNativeDocument:(bson *) b {
    if (!b) {
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }
    if (self = [super init]) {
        _bson = b;
    }
    return self;
}

- (void) dealloc {
    if (_destroyOnDealloc) bson_destroy(_bson);
    free(_bson);
#if !__has_feature(objc_arc)
    [_source release];
#endif
}

- (bson *) bsonValue {
    return _bson;
}

- (NSData *) dataValue {
#if __has_feature(objc_arc)
    return [NSData dataWithBytesNoCopy:_bson.data length:bson_size(&_bson) freeWhenDone:NO];
#else
    return [NSData dataWithBytesNoCopy:(void *)bson_data(_bson) length:bson_size(_bson) freeWhenDone:NO];
#endif
}

- (BSONIterator *) iterator {
    return [[BSONIterator alloc] initWithDocument:self keyPathComponentsOrNil:nil];
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
    NSString *identifier = [NSString stringWithFormat:@"%@ <%p>  bson.data: %p  bson.cur: %p  bson.dataSize: %i  bson.stackPos: %i  bson.err: %i  bson.errstr: %s\n",
                            [[self class] description], self,
                            bson_data(_bson),
                            _bson->cur,
                            _bson->dataSize,
                            _bson->stackPos,
                            _bson->err,
                            _bson->errstr];
    return [identifier stringByAppendingString:NSStringFromBSON(_bson)];
}

@end