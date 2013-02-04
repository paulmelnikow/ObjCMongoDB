//
//  BSONIterator.h
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

FOUNDATION_EXPORT NSString * const BSONException;

@class BSONDocument;
@class BSONObjectID;

/**
 Encapsulates a BSON iterator, an interface for accessing the content in a BSON document.
 
 An iterator starts before the first item in a BSON document, an embedded document, or an array. It
 can move sequentially through the items by calling <code>-next</code>, or find a specific item by
 calling <code>-containsValueForKey:</code> or <code>-valueTypeForKey:</code>.
 
 To get an item's object representation, call <code>-objectForKey:</code> or <code>-objectValue</code>,
 which returns an Objective-C type appropriate for the item's native type. You can also call one of
 the type-specific accessors like <code>-intValue</code> or <code>-stringValue</code>. To query the
 item's native type, call <code>-valueType</code>, and to get its key, call <code>-key</code>.
 
 In most cases, you won't need to use <code>BSONIterator</code> directly. <code>BSONDecoder</code>
 provides a higher-level interface for creating an object graph from a BSON document, suitable for
 handling BSON-supported types, arrays and dictionaries, and custom objects which conform to
 <code>NSCoding</code> and support keyed archiving. In more complex cases, you can use delegation and
 subclassing to control the unarchiving process, and may use methods of
 <code>BSONIterator</code>.
 
 Each instance of <code>BSONIterator</code> creates a <code>bson_iterator</code> structure during
 initialization and destoys it on deallocation. Each instance retains its associated document.
 */
@interface BSONIterator : NSObject

/**
 Returns the object which iterators return for undefined values (type 0x06).
 @return The object which iterators return for undefined values
 */
+ (id) objectForUndefined;

/**
 Searches for the key <i>key</i> in the iterator's BSON document.
 @return <code>YES</code> if the key is present, and <code>NO</code> otherwise.
 @param key The key to search for
 */
- (BOOL) containsValueForKey:(NSString *) key;

/**
 Searches for the key <i>key</i> in the iterator's BSON document.
 @param key The key to search for
 @return The native BSON type of the item with key <i>key</i> (<code>bson_eoo</code> if the key is not present)
 */
- (BSONType) valueTypeForKey:(NSString *)key;

/**
 Attempts to advance the iterator to the next item in the document.
 @return The native BSON type of the next item in the document (<code>bson_eoo</code> if there are no more)
 */
- (BSONType) next;

/**
 Returns a Boolean indicating whether there are more items in the document.
 @return <code>YES</code> if there are more items, <code>NO</code> otherwise
 */
- (BOOL) hasMore;

/**
 Returns the key of the current item.
 @return An autoreleased string with the key for the current item
 */
- (NSString *) key;

- (NSArray *) keyPathComponents;

/**
 Returns the BSON value type of the current item.
 @return The native BSON value type of the current item.
 */
- (BSONType) valueType;

/**
 Helper method which checks if the type is one of an array of allowed types.
 @param allowedTypes An array of NSNumber objects with BSONType values.
 @return The native BSON value type of the current item.
 */
- (BOOL) valueTypeIsInArray:(NSArray *) allowedTypes;

/**
 Returns a Boolean indicating whether the current item is an embedded document (<code>bson_object</code>).
 @return <code>YES</code> if the current item is an embedded document, <code>NO</code> otherwise
 */
- (BOOL) isEmbeddedDocument;

/**
 Returns a Boolean indicating whether the current item is an array(<code>bson_array</code>).
 @return <code>YES</code> if the current item is an array, <code>NO</code> otherwise
 */
- (BOOL) isArray;

/**
 Returns an <code>NSObject</code> representation of the current item. Returns a different class depending
 on the item's native type:
 - An instance of <code>NSNumber</code> for <code>bson_double</code>, <code>bson_bool</code>, <code>bson_int</code>, or <code>bson_long</code>
 - An instance of <code>NSString</code> for <code>bson_string</code>
 - An instance of <code>NSData</code> for <code>bson_bindata</code>
 - An instance of <code>NSDate</code> for <code>bson_date</code>
 - An instance of <code>BSONObjectID</code> for <code>bson_oid</code>
 - An instance of <code>BSONCode</code> for <code>bson_code</code>
 - An instance of <code>BSONCodeWithScope</code> for <code>bson_codewscope</code>
 - An instance of <code>BSONSymbol</code> for <code>bson_symbol</code>
 - An instance of <code>BSONRegularExpression</code> for <code>bson_regex</code>
 - An instance of <code>BSONTimestamp</code> for <code>bson_timestamp</code>
 - <code>nil</code> for <code>bson_eoo</code>
 - The object <code>[NSNull null]</code> for <code>bson_null</code>
 - The object <code>[BSONIterator objectForUndefinedValue]</code> for <code>bson_undefined</code>
 - A sub-iterator of type <code>BSONIterator</code> for <code>bson_array</code>
 - An embedded document of type <code>BSONDocument</code> for <code>bson_object</code>
 @return An object representation of the current item
 */ 
- (id) objectValue;

/**
 Searches for the key <i>key</i> in the iterator's BSON document and returns that item's object representation.
 @param key The key to search for
 @return An object representation of the item with key <i>key</i>
 */
- (id) objectForKey:(NSString *)key;

/**
 Returns a sub-iterator for the current item, supporting sequential access (not keyed access). The current
 item's native type must be <code>bson_array</code> or <code>bson_object</code>.
 
 For keyed access to a <code>bson_object</code> use <code>-keyedSubIteratorValue</code> instead.
 @return A sub-iterator for the current item
 */
- (BSONIterator *) sequentialSubIteratorValue;

/**
 Returns an iterator initialized to the embedded document. The current item's native type must be
 <code>bson_object</code>.
 
 For sequential access to keys you can use <code>-sequentialSubIteratorValue</code> instead which is slightly
 more efficient.
 */
- (BSONIterator *) embeddedDocumentIteratorValue;

/**
 Returns an embedded document for the current item, whose native type must be <code>bson_object</code>.
 @return An embedded document for the current item
 */
- (BSONDocument *) embeddedDocumentValue;

/**
 Returns a double-precision floating point number for the current item, whose native type must be supported by
 <code>bson_iterator_double(.)</code>.
 @return A <code>double</code> for the current item
 */
- (double) doubleValue;

/**
 Returns an integer for the current item, whose native type must be supported by <code>bson_iterator_int(.)</code>.
 @return An integer for the current item
 */
- (int) intValue;

/**
 Returns a 64-bit integer for the current item, whose native type must be supported by <code>bson_iterator_long(.)</code>.
 @return A 64-bit integer for the current item
 */
- (int64_t) int64Value;

/**
 Returns a Boolean for the current item, whose native type must be supported by <code>bson_iterator_bool(.)</code>.
 @return A Boolean for the current item
 */
- (BOOL) boolValue;

/**
 Returns a BSON object ID for the current item, whose native type must be supported by <code>bson_iterator_oid(.)</code>.
 @return A BSON object ID for the current item
 */
- (BSONObjectID *) objectIDValue;

/**
 Returns a string  for the current item, whose native type must be supported by <code>bson_iterator_string(.)</code>.
 @return A string for the current item
 */
- (NSString *) stringValue;

/**
 Returns a string for the current item, whose native type must be supported by <code>bson_iterator_string_len(.)</code>.
 @return A string for the current item
 */
- (int) stringLength;

/**
 Returns a symbol for the current item. The item's native type must be supported by <code>bson_iterator_string(.)</code>,
 so this method will return a symbol even if the native type is a string.
 @return A BSON symbol for the current item
 */
- (BSONSymbol *) symbolValue;

/**
 Returns a code object for the current item, whose native type must be supported by <code>bson_iterator_code(.)</code>. 
 @return A BSON code object for the current item
 */
- (BSONCode *) codeValue;

/**
 Returns a code-with-scope object for the current item, whose native type must be supported by
 <code>bson_iterator_code(.)</code> and <code>bson_iterator_code_scope</code>.
 @return A BSON code-with-scope object for the current item
 */
- (BSONCodeWithScope *) codeWithScopeValue;

/**
 Returns a date for the current item, whose native type must be supported by <code>bson_iterator_date(.)</code>.
 @return A date for the current item
 */
- (NSDate *) dateValue;

/**
 Returns the number of bytes of binary data for the current item, whose native type must be
 supported by <code>bson_iterator_bin_len</code>.
 @return The number of bytes of binary data for the current item
 */
- (NSUInteger) dataLength;

/**
 Returns the binary subtype for the current item, whose native type must be
 supported by <code>bson_iterator_bin_type</code>.
 @return The binary subtype for the current item
 */
- (char) dataBinType;

/**
 Returns a data representation containing a copy of the current item's binary data. The item's
 native type must be supported by <code>bson_iterator_bin_len</code> and <code>bson_iterator_bin_data</code>.
 @return The data representation for the current item
 */
- (NSData *) dataValue;

/**
 Returns a BSON regular expression for the current item, whose native type must be supported
 by <code>bson_iterator_regex</code> and <code>bson_iterator_regex_opts</code>.
 @return The regular expression options for the current item
 */
- (BSONRegularExpression *)regularExpressionValue;

/**
 Returns a regular expression pattern for the current item, whose native type must be supported
 by <code>bson_iterator_regex</code>.
 @return The regular expression pattern for the current item
 */
- (NSString *)regularExpressionPatternValue;

/**
 Returns a regular expression options for the current item, whose native type must be supported
 by <code>bson_iterator_regex_opts</code>.
 @return The regular expression options for the current item
 */
- (NSString *)regularExpressionOptionsValue;

/**
 Returns a BSON timestamp for the current item, whose native type must be supported
 by <code>bson_iterator_timestamp</code>.
 @return A timestamp value for the current time
 */
- (BSONTimestamp *) timestampValue;

@end
