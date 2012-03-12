//
//  MongoDBCollection.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MongoPredicate.h"

@class MongoConnection;

@interface MongoDBCollection : NSObject {
    const char * utf8Name;
}

- (BOOL) insert:(BSONDocument *) document error:(NSError **) error;
- (BOOL) insertDictionary:(NSDictionary *) dictionary error:(NSError **) error;
- (BOOL) insertObject:(id) object error:(NSError **) error;

- (BOOL) insertBatch:(NSArray *) documentArray error:(NSError **) error;



- (NSError *) error;

@property (retain) MongoConnection * connection;
@property (copy, nonatomic) NSString * name;

@end
