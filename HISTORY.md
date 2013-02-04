# ObjCMongoDB Release History

## Pending changes
0.9.5
February _, 2013

Be sure to add these files to your existing projects:

 -  NSString+BSONAdditions.[hm]
 -  NSData+BSONAdditions.[hm]
 -  NSArray+MongoAdditions.[hm]
 -  MongoWriteConcern.[hm]

Changes:

 -  Upgrade to driver v0.7.1
 -  MongoConnection has a configurable write concern, an instance of
    MongoWriteConcern. The default is _acknowledged writes_.
 -  MongoDBCollection write methods take an optional write concern which
    overrides the connection's write concern. For updates, MongoUpdateRequest
    has an optional write concern property.
 -  `-[MongoDBCollection collection:]` is now
    `-[MongoDBCollection collectionWithName:]`
 -  `-[MongoConnection connectToReplicaSet:seed:error]` is now
    `-[MongoConnection connectToReplicaSet:seedArray:error]`
 -  `-[MongoConncetion dropDatabase:]` is now
    `-[MongoConnection dropDatabaseWithName:]`
 -  `-[BSONObjectID description]` now returns values like
    `510d411a1acbf9014ad6c26b` instead of
    `Object ID: "510d411a1acbf9014ad6c26b"`
 -  BSONObjectID accepts custom fuzz and increment blocks
 -  Make `-[BSONDocument description]` thread-safe and move to BSONDocument.m
 -  Avoid importing driver C headers in headers users will need to import
 -  Move initializers and factory methods not meant for public consumption
    to BSON_PrivateInterfaces.h and Mongo_PrivateInterfaces.h
 -  Rename -nativeValueType to -valueType throughout. Create BSONType enum
    mirroring native bson_type enum.
 -  Use categories instead of helper methods for NSString and NSData
 -  Replace all instances of malloc and free with calls to driver create and
    dispose functions
 -  Reduce need for `#if __has_feature(objc_arc)` by using private properties,
    factory methods, and `maybe_autorelease_and_return` macro defined in
    BSON_Helper.h.
 -  Rename `destroyOnDealloc` parameters to `destroyWhenDone` for consistency
    with parameter names of NSData initializers
 -  Where BSONDecoder and BSONIterator retain objects to keep the native
    BSON document from being deallocated, consistently name these objects
    `dependentOn`
 
## 0.9

-  `-serverStatusForLastOperation:error` is now
   `lastOperationWasSuccessful:error`
-  `-serverStatusForLastOperationAsDictionary` is now
   `-lastOperationDictionary`


installation - add category files
