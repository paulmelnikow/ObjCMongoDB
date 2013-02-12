//
//  MongoWriteConcern.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 2/3/13.
//
//

#import <Foundation/Foundation.h>

typedef enum {
    MongoWriteErrorsIgnored = -1,
    MongoWriteUnacknowledged = 0,
    MongoWriteAcknowledged = 1,
    MongoWriteReplicaAcknowledged = 2
} MongoWriteAcknowledgementMode;

@interface MongoWriteConcern : NSObject <NSCopying>

+ (MongoWriteConcern *) writeConcern;

/*! Default is MongoWriteAcknowledged */
@property (assign) MongoWriteAcknowledgementMode writeAcknowledgementBehavior;

/*! Default is 0, meaning do not timeout. Value in seconds, will be rounded to the nearest millisecond. */
@property (assign) NSTimeInterval replicationTimeout;

/*! Default is NO */
@property (assign) BOOL synchronizeToDisk;

@end
