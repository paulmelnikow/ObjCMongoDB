# MongoDB C Driver History

## 0.9.1
February _, 2013

Be sure to add these files to your existing projects:

 -  NSString+BSONAdditions.[hm]
 -  NSData+BSONAdditions.[hm]
 -  NSArray+MongoAdditions.[hm]
 -  MongoWriteConcern.[hm]

Changes:

 -  Upgraded to driver v0.7.1
 -  `-[MongoDBCollection collection:]` is now
    `-[MongoDBCollection collectionWithName:]`
 -  `-[MongoConnection connectToReplicaSet:seed:error]` is now
    `-[MongoConnection connectToReplicaSet:seedArray:error]`
 -  `-[MongoConncetion dropDatabase:]` is now
    `-[MongoConnection dropDatabaseWithName:]`
 -  MongoConnection now has a configurable write concern. The default is
    acknowledged writes.
 -  Write concern is encapsulated using MongoWriteConcern.
 -  MongoDBCollection write methods now take an optional write concern, which
    overrides the connection's write concern.
 -  MongoUpdateRequest has an optional write concern.
 -  `-[BSONObjectID description]` now returns `-[BSONObjectID stringValue]`.
 -  BSONObjectID accepts custom fuzz and increment blocks.
 -  Avoid importing driver C headers in headers users will need to import.
 -  Rename -nativeValueType to -valueType throughout. Create BSONType enum
    mirroring native bson_type enum.
 -  Use categories instead of helper methods for NSString and NSData.
 -  Replace all instances of malloc and free with calls to driver create and
    dispose functions.
 -  Make `-[BSONDocument description]` thread-safe and move to BSONDocument.m
 -  Reduce need for `#if __has_feature(objc_arc)` with private properties,
    factory methods, and `maybe_autorelease_and_return` macro defined in
    BSON_Helper.h.
 -  For consistency with NSData, rename `destroyOnDealloc` parameters to
    `destroyWhenDone`.
 -  Where BSONDecoder and BSONIterator retain objects to keep the native
    BSON document from being deallocated, consistently name these objects
    `dependentOn`.
 -  Move initializers and factory methods not meant for public consumption
    to BSON_PrivateInterfaces.h and Mongo_PrivateInterfaces.h.

## 0.9

-  `-serverStatusForLastOperation:error` is now
   `lastOperationWasSuccessful:error`
-  `-serverStatusForLastOperationAsDictionary` is now
   `-lastOperationDictionary`


installation - add category files
