//
//  ObjCBSON.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "BSON_Helper.h"
#import "BSONTypes.h"
#import "BSONDocument.h"
#import "BSONCoding.h"
#import "NSManagedObject+BSONCoding.h"
#import "BSONEncoder.h"
#import "BSONDecoder.h"

FOUNDATION_EXPORT NSString * const MongoDBObjectIDKey;
FOUNDATION_EXPORT const char * const MongoDBObjectIDBSONKey;