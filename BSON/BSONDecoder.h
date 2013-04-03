//
//  BSONDecoder.h
//  ObjCMongoDB
//
//  Copyright 2012 Paul Melnikow and other contributors
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

#import <Foundation/Foundation.h>
#import "BSONTypes.h"

typedef enum {
    BSONReturnNSNull,
    BSONReturnNilForNull,
    BSONRaiseExceptionOnNull
} BSONDecoderBehaviorOnNull;

typedef enum {
    BSONReturnBSONUndefined,
    BSONReturnNSNullForUndefined,
    BSONReturnNilForUndefined,
    BSONRaiseExceptionOnUndefined
} BSONDecoderBehaviorOnUndefined;

@class BSONDecoder;
@class BSONIterator;
@class BSONDocument;
@class BSONObjectID;
@class NSManagedObjectContext;
@class NSImage;

@protocol BSONDecoderDelegate
@optional

- (id) decoder:(BSONDecoder *) decoder didDecodeObject: (id) object forKeyPath:(NSArray *) keyPathComponents;
- (void) decoder:(BSONDecoder *) decoder willReplaceObject: (id) object withObject:(id) newObject forKeyPath:(NSArray *) keyPathComponents;
- (void) decoderWillFinish:(BSONDecoder *) decoder;
- (Class) decoder:(BSONDecoder *) decoder classToSubstituteForObjectID:(BSONObjectID *) objectID forKeyPath:(NSArray *) keyPathComponents;

@end

/**
 Provides a high-level interface for creating a tree of objects from a BSON document.
 <code>BSONDecoder</code> handles BSON-supported types, arrays and dictionaries, custom objects
 which conform to <code>NSCoding</code> and support keyed archiving, and Core Data managed
 objects.

 Create a <code>BSONDecoder</code> from a <code>BSONDocument</code> or an <code>NSData</code>
 containing a BSON document, and decode the root object using one of the root decoding methods:
 - <code>-decodeDictionary</code>
 - <code>-decodeDictionaryWithClass:</code>
 - <code>-decodeObjectWithClass:</code> 
 To decode another BSON document, instantiate another decoder.

 As much as possible <code>BSONDecoder</code> follows the design of <code>NSCoder</code>. For more
 information, refer to Apple's Archives and Serializations Guide.
 
 Important differences from <code>NSKeyedUnarchiver</code>:
 
 - <code>BSONDecoder</code> provides its own support for unarchiving these types from BSON objects:
 - <code>NSString</code>
 - <code>NSNumber</code>
 - <code>NSDate</code>
 - <code>NSData</code>
 - <code>NSImage</code>
 - <code>NSDictionary</code>
 - <code>NSArray</code>
 - <code>BSONObjectID</code> and the other classes defined in <code>BSONTypes.h</code>
 - <code>BSONDecoder</code> relies on subclasses to de
 does not store class information. While BSON documents include enough
 type information to decode to appropriate Objective-C object types, <code>BSONDecoder</code> relies
 on subclasses to encode themselves.
 - <code>BSONDecoder</code> relies on the caller to provide class information for custom objects,
 and relies on objects to provide class information for their descendent objects. While BSON documents
 include enough type information to decode to appropriate Objective-C object types,
 <code>BSONEncoder</code> does not specifically encode class information.
 - <code>BSONDecoder</code> does not support unkeyed coding. (If your custom objects can't implement
 unkeyed coding, you can implement unkeyed coding by subclassing <code>BSONEncoder</code> and
 overriding the unkeyed methods to automatically generate pre-defined, sequential key names, and
 subclassing <code>BSONDecoder</code> to override the decoding methods to use these pre-defined key
 names in the same sequence.)
 - A BSON document may contain only one root object. When fetching multiple items from a MongoDB
 collection, each item returned is its own document.
 - <code>BSONDecoder</code> does not allow objects to override their decoding with
 <code>classForCoder</code>. This would be little help, since class information is always provided
 at the time of decoding. Use <code>-initWithCoder:</code> (from <code>NSCoding</code>),
 <code>-awakeAfterUsingCoder:</code> (from <code>NSObject</code>),
 <code>-initWithBSONDecoder:</code>, or <code>-awakeAfterUsingBSONDecoder:</code> (both from
 <code>BSONCoding</code>) instead.
 - <code>BSONDecoder</code> decodes BSON object IDs but relies on the parent object or the delegate
 to resolve replace the reference with another object if desired. 
 - <code>BSONDecoderDelegate</code> provides a similar interface to <code>NSKeyedUnarchiver</code>, but
 conveys additional state information in the encoder's key path, and provides an additional delegate
 method for resolving BSON object IDs during decoding.
 
 Resolving references
 
 While by default <code>BSONDecoder</code> simply decodes BSON object IDs without resolving them,
 it provides a mechanism for parent objects or delegates to resolve these references to the specified
 object. If an object <i>always</i> encodes a child as an object ID, its <code>-initWithCoder:</code>
 can invoke <code>-decodeObjectIDForKey:substituteObjectWithClass:</code>. The delegate will invoke
 <code>+instanceForObjectID:decoder:</code> (defined in <code>BSONCoding</code>) on the class which
 is responsible for locating the specified instance or returning a suitable placeholder.
 
 If the appropriate behavior depends on context or other factors, instead the delegate can implement
 <code>-decoder:classToSubstituteForObjectID:forKeyPath:</code> returning <code>YES</code>
 and providing class information after considering the key path, key path depth, the object ID, or
 the delegate's own state.

  
 To decode some other reference structure, build the logic into <code>-initWithCoder:</code> or use
 the delegate substitution method <code>-decoder:didDecodeObject:forKeyPath</code>.
  
 Controlling decoding of sub-objects
 
 Objects control their own decoding by implementing one of these methods:
 - <code>-initWithCoder:</code>
 - <code>-initWithBSONDecoder:</code>
 - <code>-awakeAfterUsingCoder:</code>
 - <code>-awakeAfterUsingBSONDecoder:</code>
 
 In addition, a delegate may control encoding by implementing one of these methods:
 - <code>-decoder:classToSubstituteForObjectID:forKeyPath:</code>
 - <code>-decoder:didDecodeObject:forKeyPath</code>
 
 Decoding managed objects
 
 The <code>BSONCoding</code> category on <code>NSManagedObject</code> uses the entity description
 to automatically insert objects into a managed object context and decode properties. To use this
 functionality, set the <code>managedObjectContext</code> on the decoder and invoke any of the
 <code>-decode...:withClass:</code> methods. <code>NSManagedObject</code>'s default implementation
 of <code>-initWithBSONDecoder:</code> uses the property names as key names, and decodes
 and sets all persistent attributes and relationships. If you need to skip certain relationships or
 attributes, resolve references to entities, or otherwise customize their decoding, override one of
 the category's helper methods, providing your own logic where needed and invoking <code>super</code>
 the rest of the time. 
 - <code>-initializeAttribute:withDecoder:</code>
 - <code>-initializeelationship:withDecoder:</code>
 - <code>-initializeFetchedProperty:withDecoder:</code>
 You can also override <code>-initWithBSONDecoder:</code> if necessary.
 
 <code>BSONIterator</code> is a lower-level alternative to <code>BSONEncoder</code>

 <code>BSONDecoder</code> depends on <code>BSONIterator</code> to access the contents of BSON documents.
 It provides methods for getting information from the iterator including <code>-containsValueForKey:</code>,
 and <code>-valueIsEmbeddedDocumentForKey:</code>, and <code>-valueIsArrayForKey:</code>. For some
 applications you may prefer to work with the iterator directly. In that case, don't use
 <code>BSONDecoder</code>, just work directly with tht document's `-iterator`. 
 */
@interface BSONDecoder : NSCoder

- (BSONDecoder *) initWithDocument:(BSONDocument *) document;
- (BSONDecoder *) initWithData:(NSData *) data;

+ (NSDictionary *) decodeDictionaryWithDocument:(BSONDocument *) document;
+ (NSDictionary *) decodeDictionaryWithClass:(Class) classForDecoder document:(BSONDocument *) document;
+ (NSDictionary *) decodeDictionaryWithData:(NSData *) data;
+ (NSDictionary *) decodeDictionaryWithClass:(Class) classForDecoder data:(NSData *) data;

+ (id) decodeObjectWithClass:(Class) classForDecoder document:(BSONDocument *) document;
+ (id) decodeObjectWithClass:(Class) classForDecoder data:(NSData *) data;
+ (id) decodeManagedObjectWithClass:(Class) classForDecoder
                            context:(NSManagedObjectContext *) context
                               data:(NSData *) data;

- (NSDictionary *) decodeDictionary;
- (NSDictionary *) decodeDictionaryWithClass:(Class) classForDecoder;
- (id) decodeObjectWithClass:(Class) classForDecoder;

- (NSDictionary *) decodeDictionaryForKey:(NSString *) key;
- (NSDictionary *) decodeDictionaryForKey:(NSString *) key withClass:(Class) classForDecoder;
- (NSArray *) decodeArrayForKey:(NSString *) key;
- (NSArray *) decodeArrayForKey:(NSString *) key withClass:(Class) classForDecoder;
- (id) decodeObjectForKey:(NSString *) key;
- (id) decodeObjectForKey:(NSString *) key withClass:(Class) classForDecoder;

- (id) decodeObjectIDForKey:(NSString *) key substituteObjectWithClass:(Class) classForDecoder;
- (BSONObjectID *) decodeObjectIDForKey:(NSString *)key;
- (int) decodeIntForKey:(NSString *)key;
- (int64_t) decodeInt64ForKey:(NSString *)key;
- (BOOL) decodeBoolForKey:(NSString *)key;
- (double) decodeDoubleForKey:(NSString *)key;
- (NSDate *) decodeDateForKey:(NSString *)key;
- (NSImage *) decodeImageForKey:(NSString *)key;
- (NSString *) decodeStringForKey:(NSString *)key;
- (BSONSymbol *) decodeSymbolForKey:(NSString *)key;
- (BSONRegularExpression *) decodeRegularExpressionForKey:(NSString *)key;
- (BSONDocument *) decodeBSONDocumentForKey:(NSString *)key;
- (NSData *)decodeDataForKey:(NSString *)key;
- (BSONCode *) decodeCodeForKey:(NSString *)key;
- (BSONCodeWithScope *) decodeCodeWithScopeForKey:(NSString *)key;

// has side effect of moving the iterator
- (BOOL) containsValueForKey:(NSString *) key;
- (BSONType) valueTypeForKey:(NSString *) key;
- (BOOL) valueIsEmbeddedDocumentForKey:(NSString *) key;
- (BOOL) valueIsArrayForKey:(NSString *) key;

- (NSArray *) keyPathComponents;

/**
 Returns the object which iterators return for undefined values (type 0x06).
 @return The object which iterators return for undefined values
 */
+ (id) objectForUndefined;

@property (retain) NSObject<BSONDecoderDelegate> * delegate;
@property (retain) NSManagedObjectContext * managedObjectContext;
@property (assign) BSONDecoderBehaviorOnNull behaviorOnNull;
@property (assign) BSONDecoderBehaviorOnUndefined behaviorOnUndefined;
@property (assign) NSZone * objectZone;

@end
