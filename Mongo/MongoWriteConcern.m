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
#import "Mongo_Helper.h"
#import "BSON_Helper.h"
#import "mongo.h"

@interface MongoWriteConcern ()

@property (assign) MongoWriteAcknowledgementMode previousWriteAcknowledgementBehavior;
@property (assign) NSTimeInterval previousReplicationTimeout;
@property (assign) BOOL previousSynchronizeToDisk;

@end

@implementation MongoWriteConcern {
    mongo_write_concern *_nativeWriteConcern;
}

- (id) init {
    if (self = [super init]) {
        self.writeAcknowledgementBehavior = MongoWriteAcknowledged;
        self.replicationTimeout = 0.f;
        self.synchronizeToDisk = NO;
    }
    return self;
}

- (void) dealloc {
    if (_nativeWriteConcern ) {
        mongo_write_concern_destroy(_nativeWriteConcern);
        mongo_write_concern_dealloc(_nativeWriteConcern);
        _nativeWriteConcern = NULL;
    }
    super_dealloc;
}

+ (MongoWriteConcern *) writeConcern {
    maybe_autorelease_and_return([[self alloc] init]);
}

-(id)copyWithZone:(NSZone *) zone {
    MongoWriteConcern *result = [[self.class allocWithZone:zone] init];
    result.writeAcknowledgementBehavior = self.writeAcknowledgementBehavior;
    result.replicationTimeout = self.replicationTimeout;
    result.synchronizeToDisk = self.synchronizeToDisk;
    return result;
}

/* Result is owned by receiver. If receiver is subsequently mutated, this object may also be mutated.
   If you need it to stay the same, copy the receiver, retain it, and invoke on that instead. */
- (mongo_write_concern *) nativeWriteConcern {
    if (_nativeWriteConcern) {
        if (self.writeAcknowledgementBehavior == self.previousWriteAcknowledgementBehavior &&
            self.replicationTimeout == self.previousReplicationTimeout &&
            self.synchronizeToDisk == self.previousSynchronizeToDisk) {
            return _nativeWriteConcern;
        } else {
            mongo_write_concern_destroy(_nativeWriteConcern);
        }
    } else {
        _nativeWriteConcern = mongo_write_concern_alloc();
    }
    mongo_write_concern_init(_nativeWriteConcern);
    _nativeWriteConcern->w = self.writeAcknowledgementBehavior;
    _nativeWriteConcern->wtimeout = self.replicationTimeout;
    _nativeWriteConcern->fsync = (int) self.synchronizeToDisk;
    mongo_write_concern_finish(_nativeWriteConcern);
    return _nativeWriteConcern;
}

@end
