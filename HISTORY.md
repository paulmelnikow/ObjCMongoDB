# ObjCMongoDB Release History

## v0.9.7
July 4, 2013

The submodule URL changed from an unofficial fork to the official 10gen
repository. After pulling these changes, run:

```
git submodule sync
git submodule update
```

Changes:

 -  Fix memory leaks under manual retain–release
 -  Switch from the unofficial fork of the C driver to the official 10gen
    repository
 -  Update memory ownership based on improvements in the C driver
 -  Minor refactoring, compilation fixes, and bug fixes

## v0.9.6
March 16, 2013

Be sure to add these files to your existing projects:

 -  NSDictionary+BSONAdditions.[hm]
 -  MongoTypes.[hm]
 -  MongoConnection+Diagnosics.[hm]

Changes:

 -  Add support for iOS
 -  Add streamlined interface `[dict BSONDocument]` to replace
    `[BSONEncoder documentForDictionary:dict]`
 -  `+[BSONDocument documentForObject:restrictsKeyNamesForMongoDB:]` is now
    `+[BSONDocument documentForObject:restrictingKeyNamesForMongoDB:]`
 -  `+[BSONDocument documentForDictionary:restrictsKeyNamesForMongoDB:]` is now
    `+[BSONDocument documentForDictionary:restrictingKeyNamesForMongoDB:]`
 -  Allow mutating the write concern on MongoConnection
 -  Add support to MongoDBCollection for creating and listing indexes
 -  Add support for dropping collections
 -  Add support for diagnostic commands
 -  Fix a bug that prevented driver error descriptions from populating NSError
    objects
 -  Allow passing nil blocks to reset the default fuzz and increment functions
 -  Standardize exception throwing using [NSException raise:format:]
 -  Prevent compilation on platforms using the legacy runtime
 -  Remove support for automatically encoding the Core Data model version hash

## v0.9.5
February 4, 2013

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
 
## v0.9
February 2, 2013

Be sure to update these file references in your existing projects:

 -  MongoFetchRequest.[hm] -> MongoFindRequest.[hm]

In prepation for v1.0 release announcement, tweak method and class names in
public APIs for clarity.

-  MongoFetchRequest is now MongoFindRequest
-  `-[MongoDBCollection insert:error:]` is now
   `-[MongoDBCollection insertDocument:error:]`   
-  `-[MongoDBCollection insertBatch:error:]` is now
   `-[MongoDBCollection insertDocuments:error:]`
-  `-[MongoDBCollection update:error:]` is now
   `-[MongoDBCollection updateWithRequest:error:]`
-  `-[MongoDBCollection remove:error:]` is now
   `-[MongoDBCollection removeWithPredicate:error:]`
-  `-[MongoDBCollection find:error:]` is now
   `-[MongoDBCollection findWithRequest:error:]`
-  `-[MongoDBCollection cursorForFind:error:]` is now
   `-[MongoDBCollection cursorForFindRequest:error:]`
-  `-[MongoDBCollection findOne:error:]` is now
   `-[MongoDBCollection findOneWithRequest:error:]`
-  `-[MongoUpdateRequest replaceDocumentWith:]` is now
   `-[MongoUpdateRequest replaceDocumentWithDocument:]`
-  `-serverStatusForLastOperation:error` is now
   `lastOperationWasSuccessful:error`
-  `-serverStatusAsDictionaryForLastOperation` is now
   `-lastOperationDictionary`
-  When encoding NSManagedObjects, instead of raising an exception for fetched
   properties, just skip them
-  Move methods not meant for public consumption to BSON_PrivateInterfaces.h
   and Mongo_PrivateInterfaces.h
-  Remove instance variables from .h files and declare private properties
-  Prepend private methods with underscores and remove private method
   declarations from top of .m files
-  Adopt `@(1)` syntax in place of `[NSNUmber numberWithInt:1]`
-  Remove const strings for Mongo operators
-  Update for Xcode 4.6
