//
//  BSON_PrivateInterfaces.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 1/23/13.
//
//

//
// This file is imported internally by classes in the framework to interact with each other. Don't use it in
// your application. Use the classes' public interfaces instead.
//

#import "BSONDocument.h"
#import "BSONEncoder.h"

@interface BSONDocument (Project)
- (const bson *) bsonValue;
@end

@interface BSONEncoder (Project)
- (bson *) bsonValue;
@end

@interface BSONObjectID (Project)
- (bson_oid_t) oid;
- (const bson_oid_t *) objectIDPointer;
@end

@interface BSONTimestamp (Project)
- (bson_timestamp_t *) timestampPointer;
@end

@interface BSONIterator (Project)
- (BSONIterator *) initWithDocument:(BSONDocument *)document
             keyPathComponentsOrNil:(NSArray *) keyPathComponents;
- (bson_iterator *) nativeIteratorValue;
@end