//
//  MongoWriteConcern.m
//  ObjCMongoDB
//
//  Copyright 2013 Paul Melnikow and other contributors
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

#import "MongoWriteConcern.h"
#import "Helper-private.h"
#import <mongoc.h>

@implementation MongoWriteConcern {
    mongoc_write_concern_t *_writeConcern;
}

- (id) init {
    if (self = [super init]) {
        self.writeAcknowledgementBehavior = MongoWriteAcknowledged;
        self.replicationTimeout = 0.f;
        self.synchronizeToDisk = NO;

        _writeConcern = mongoc_write_concern_new();
    }
    return self;
}

- (void) dealloc {
    mongoc_write_concern_destroy(_writeConcern);
    _writeConcern = NULL;
}

+ (MongoWriteConcern *) writeConcern {
    return [[self alloc] init];
}

- (id) copyWithZone:(NSZone *) zone {
    MongoWriteConcern *result = [[self.class allocWithZone:zone] init];
    result.writeAcknowledgementBehavior = self.writeAcknowledgementBehavior;
    result.replicationTimeout = self.replicationTimeout;
    result.synchronizeToDisk = self.synchronizeToDisk;
    return result;
}

/**
 Result is owned by receiver. If receiver is subsequently mutated, this object may
 also be mutated.
 
 If you need it to stay the same, copy the receiver, and invoke on the copy.
 */
- (mongoc_write_concern_t *) nativeWriteConcern {
    mongoc_write_concern_set_w(_writeConcern, self.writeAcknowledgementBehavior);
    mongoc_write_concern_set_wtimeout(_writeConcern, self.replicationTimeout);
    mongoc_write_concern_set_fsync(_writeConcern, self.synchronizeToDisk);
    
    return _writeConcern;
}

@end
