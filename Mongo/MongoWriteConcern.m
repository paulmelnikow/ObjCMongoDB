//
//  MongoWriteConcern.m
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 2/3/13.
//
//

#import "MongoWriteConcern.h"
#import "Mongo_Helper.h"
#import "mongo.h"

@implementation MongoWriteConcern

- (id) init {
    if (self = [super init]) {
        self.writeAcknowledgementBehavior = MongoWriteAcknowledged;
        self.replicationTimeout = 0.f;
        self.synchronizeToDisk = NO;
    }
    return self;
}

+ (MongoWriteConcern *) writeConcern {
    maybe_autorelease_and_return([[self alloc] init]);
}

- (id) copy {
    MongoWriteConcern *result = [[self alloc] init];
    result.writeAcknowledgementBehavior = self.writeAcknowledgementBehavior;
    result.replicationTimeout = self.replicationTimeout;
    result.synchronizeToDisk = self.synchronizeToDisk;
    return result;
}

/* Creates a new write concern. Upon invocation, you assume ownership. */
- (mongo_write_concern *) nativeWriteConcern {
    mongo_write_concern *wc = mongo_write_concern_create();
    mongo_write_concern_init(wc);
    wc->w = self.writeAcknowledgementBehavior;
    wc->wtimeout = self.replicationTimeout;
    wc->fsync = (int) self.synchronizeToDisk;
    mongo_write_concern_finish(wc);
    return wc;
}

@end
