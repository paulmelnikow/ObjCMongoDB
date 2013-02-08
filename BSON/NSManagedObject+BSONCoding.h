//
//  NSManagedObject+BSONCoding.h
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

#import <CoreData/CoreData.h>
#import "BSONCoding.h"
#import "BSONEncoder.h"
#import "BSONDecoder.h"

/**
 Provides BSON encoding and decoding support for NSManagedObjects. The default implementation
 uses the entity description to automatically encode and decode each attribute and
 relationship, using the property names as  key names. It raises exceptions for fetched
 properties.
 
 If you need to skip certain relationships or attributes, implement
 <code>-shouldAutomaticallyHandlePropertyName:</code> and return <code>NO</code>.
 
 If you need to encode entities in relationships by reference or otherwise customize the
 encoding or decoding, override one of the category's helper methods, providing your own
 logic where needed and invoking <code>super</code> the rest of the time:
 - <code>-encodeAttribute:withEncoder:</code>
 - <code>-encodeRelationship:withEncoder:</code>
 - <code>-encodeFetchedProperty:withEncoder:</code>
 - <code>-initializeAttribute:withDecoder:</code>
 - <code>-initializeRelationship:withDecoder:</code>
 - <code>-initializeFetchedProperty:withDecoder:</code>
 
 To encode relationship entities by their BSON object ID, in the target class, implement
 the object ID substitution methods (defined in <code>BSONCoding</code>):
 - <code>-BSONObjectID</code> or <code>-BSONObjectIDForEncoder:</code>
 - <code>+instanceForObjectID:decoder:</code>
 Then the parent object can invoke these coder methods:
 - <code>-[BSONEncoder encodeObjectIDForObject:forKey:]</code>
 - <code>-[BSONDecoder decodeObjectIDForKey:substituteObjectWithClass:]</code>

 You may also implement your own encoding or decoding behavior using the substitution
 methods of the <code>BSONCoding</code> protocol:
 - (id) replacementObjectForBSONEncoder:(BSONEncoder *) encoder;
 - (id) awakeAfterUsingBSONDecoder:(BSONDecoder *) decoder;
 or by reimplementing the base methods:
 - <code>-encodeWithBSONEncoder:</code>
 - <code>-initWithBSONDecoder:</code>
 */
@interface NSManagedObject (BSONCoding) <BSONCoding>

/**
 Indicates whether the receiver should automatically handle the specified property, initializing
 the property when the receiver is initialized, and decoding the property when the receiver is
 decoded. The default is <code>YES</code>. Subclasses may override this method to easily skip
 cetain properties.
 
 Note that transient properties are never automatically encoded, even if this method returns
 <code>YES</code>.
 
 If subclasses need to customize the encoding of a specific property, they can override
 <code>-initialize<PropertyType>:withDecoder:</code> and
 <code>-encode<PropertyType>:withEncoder:</code> instead.
 
 @param propertyName The name of the property
 @return <code>YES</code> if the receiver should automatically handle the specified property,
 <code>NO</code> if not
 */
- (BOOL) shouldAutomaticallyHandlePropertyName:(NSString *) propertyName;

/**
 Encodes the receiver with the BSON encoder provided. The receiver may invoke any of the
 encoder's keyed encoding methods to encode its properties and instance variables.
 
 The default implementation iterates over the entity's properties, invoking these methods:
 - <code>-encodeAttribute:withEncoder:</code>
 - <code>-encodeRelationship:withEncoder:</code>
 - <code>-encodeFetchedProperty:withEncoder:</code>
 
 To adjust the default behavior, consider overriding one of those methods instead of this one.
 
 The default implementation expects the encoder's <code>behaviorOnNil</code> is
 <code>BSONDoNothingOnNil</code>, and raises an exception otherwise.
 @param encoder The active encoder
 */
- (void) encodeWithBSONEncoder:(BSONEncoder *) encoder;

/**
 Encodes an attribute with the BSON encoder provided.
 
 When overriding this method, subclasses may provide their own logic when needed, and
 invoke <code>super</code> to get the default behavior the rest of the time.
 @param attribute The attribute to encode
 @param encoder The active encoder
 */
- (void) encodeAttribute:(NSAttributeDescription *) attribute withEncoder:(BSONEncoder *) encoder;

/**
 Encodes a relationship with the BSON encoder provided.
 
 When overriding this method, subclasses may provide their own logic when needed, and
 invoke <code>super</code> to get the default behavior the rest of the time.
 
 For example:
 
     NSString *key = [relationship name];
     if ([key isEqualToString:@"parent"])
         [encoder encodeString:[self.parent name] forKey:key];
     else
         [super encodeRelationship:relationship withEncoder:encoder];
 
 @param relationship The relationship to encode
 @param encoder The active encoder
 */
- (void) encodeRelationship:(NSRelationshipDescription *) relationship withEncoder:(BSONEncoder *) encoder;

/**
 Encodes a fetched property with the BSON encoder provided.
 
 The default implementation raises an exception.
 @param fetchedProperty The fetched property to encode
 @param encoder The active encoder
 */
- (void) encodeFetchedProperty:(NSFetchedPropertyDescription *) fetchedProperty withEncoder:(BSONEncoder *) encoder;

/**
 Returns a managed object initialized using data from the BSON decoder provided.
 
 The default implementation inserts a new object into the decoder's managed object
 context and iterates over the entity's properties, invoking these methods:
 - <code>-initializeAttribute:withDecoder:</code>
 - <code>-initializeRelationship:withDecoder:</code>
 - <code>-initializeFetchedProperty:withDecoder:</code>
 
 To adjust the default behavior, consider overriding one of those methods instead of this one.
 
 Most of the <code>-decode...:forKey:</code> methods invoke the decoder's delegate,
 which provides a way to customize this behavior at the time of decoding.
 @param decoder The active decoder
 @return An object for the decoder to return
 */
- (id) initWithBSONDecoder:(BSONDecoder *) decoder;

/**
 Initializes one of the receiver's attributes using data from the BSON decoder provided.
 
 When overriding this method, subclasses may provide their own logic when needed, and
 invoke <code>super</code> to get the default behavior the rest of the time.
 @param attribute The attribute to initialize
 @param decoder The active decoder
 */
- (void) initializeAttribute:(NSAttributeDescription *) attribute withDecoder:(BSONDecoder *) decoder;

/**
 Initializes one of the receiver's relationships using data from the BSON decoder provided.
 
 When overriding this method, subclasses may provide their own logic when needed, and
 invoke <code>super</code> to get the default behavior the rest of the time.
 
 For example:
 
    NSString *parentName = [decoder decodeStringForKey:key];
    if (parentName) {
        NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:[[self entity] name]];
        [req setPredicate:[NSPredicate predicateWithFormat:@"name = %@", parentName]];
        NSArray *result = [self.managedObjectContext executeFetchRequest:req error:nil];
        if (result && 1 == result.count)
            self.parent = [result objectAtIndex:0];
    }

 @param attribute The relationship to initialize
 @param decoder The active decoder
 */
- (void) initializeRelationship:(NSRelationshipDescription *) relationship withDecoder:(BSONDecoder *) decoder;

/**
 Initializes one of the receiver's fetched properties using data from the BSON decoder provided.
 
 The default implementation raises an exception.
 @param fetchedProperty The fetched property to initialize
 @param decoder The active decoder
 */
- (void) initializeFetchedProperty:(NSFetchedPropertyDescription *) fetchedProperty withDecoder:(BSONDecoder *) decoder;

@end
