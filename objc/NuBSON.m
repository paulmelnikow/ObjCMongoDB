#import <AppKit/AppKit.h>
#import "NuBSON.h"
#import "bson.h"

@protocol NuCellProtocol
- (id) car;
- (id) cdr;
@end

@protocol NuSymbolProtocol
- (NSString *) labelName;
@end

@interface NuBSON (Private)
- (NuBSON *) initWithBSON:(bson) b;
- (id) initWithObjectIDPointer:(const bson_oid_t *) objectIDPointer;
@end

void add_object_to_bson_buffer(bson_buffer *bb, id key, id object)
{
    const char *name = [key cStringUsingEncoding:NSUTF8StringEncoding];
    Class NuCell = NSClassFromString(@"NuCell");
    Class NuSymbol = NSClassFromString(@"NuSymbol");

    if ([object isKindOfClass:[NSNumber class]]) {
        const char *objCType = [object objCType];
        switch (*objCType) {
            case 'd':
            case 'f':
                bson_append_double(bb, name, [object doubleValue]);
                break;
            case 'l':
            case 'L':
                bson_append_long(bb, name, [object longValue]);
                break;
            case 'q':
            case 'Q':
                bson_append_long(bb, name, [object longLongValue]);
                break;
            case 'B': // C++/C99 bool
            case 'c': // ObjC BOOL
                bson_append_bool(bb, name, [object boolValue]);
                break;
            case 'C':
            case 's':
            case 'S':
            case 'i':
            case 'I':
            default:
                bson_append_int(bb, name, [object intValue]);
                break;
        }
    }
    else if ([object isKindOfClass:[NSDictionary class]]) {
        bson_buffer *sub = bson_append_start_object(bb, name);
        id keys = [object allKeys];
        for (int i = 0; i < [keys count]; i++) {
            id key = [keys objectAtIndex:i];
            add_object_to_bson_buffer(sub, key, [object objectForKey:key]);
        }
        bson_append_finish_object(sub);
    }
    else if ([object isKindOfClass:[NSArray class]]) {
        bson_buffer *arr = bson_append_start_array(bb, name);
        for (int i = 0; i < [object count]; i++) {
            add_object_to_bson_buffer(arr,
                [[NSNumber numberWithInt:i] stringValue],
                [object objectAtIndex:i]);
        }
        bson_append_finish_object(arr);
    }
    else if ([object isKindOfClass:[NSNull class]]) {
        bson_append_null(bb, name);
    }
    else if ([object isKindOfClass:[NSDate class]]) {
        bson_date_t millis = (bson_date_t) ([object timeIntervalSince1970] * 1000.0);
        bson_append_date(bb, name, millis);
    }
    else if ([object isKindOfClass:[NSData class]]) {
        bson_append_binary(bb, name, 0, [object bytes], [object length]);
    }
    else if ([object isKindOfClass:[NSImage class]]) {
        NSData *data = [object TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:1.0L];
        if (data) {
            bson_append_binary(bb, name, 0, [data bytes], [data length]);
        }
    }
    else if ([object isKindOfClass:[BSONObjectID class]]) {
        bson_append_oid(bb, name, [((BSONObjectID *) object) objectIDPointer]);
    }
    else if (NuCell && [object isKindOfClass:[NuCell class]]) {
        // serialize Nu code as binary data of type 1
        NSData *serialization = [NSKeyedArchiver archivedDataWithRootObject:object];
        bson_append_binary(bb, name, 1, [serialization bytes], [serialization length]);
    }
    else if (NuSymbol && [object isKindOfClass:[NuSymbol class]]) {
        if ([[object stringValue] isEqualToString:@"t"]) {
            bson_append_bool(bb, name, YES);
        }
    }
    else if ([object respondsToSelector:@selector(cStringUsingEncoding:)]) {
        // Check if we are dealing with an regular expression in the form of "/<regex>/<options>"
        char *stringData = (char *)[object cStringUsingEncoding:NSUTF8StringEncoding];
        if (stringData[0] == '/') { // Quick check to see if we are dealing with a regex
            NSArray *regexpComponents = [object componentsSeparatedByString:@"/"];
            NSString *expression = nil;
            NSString *options = nil;
            if ([regexpComponents count] == 3) {
                expression = [regexpComponents objectAtIndex:1];
                options = [regexpComponents objectAtIndex:2];
                if (expression != nil) {
                    bson_append_regex(bb, name, [expression cStringUsingEncoding:NSUTF8StringEncoding],[options cStringUsingEncoding:NSUTF8StringEncoding]);
                }
            }
            if (expression == nil) { // looks like we are dealing with a regular string
                bson_append_string(bb, name, stringData);
            }
        }
        else {
            bson_append_string(bb, name, stringData);
        }
    }
    else {
        NSLog(@"We have a problem. %@ cannot be serialized to bson", object);
    }
}


@implementation NuBSON

+ (NuBSON *) bsonWithData:(NSData *) data
{
    return [[[NuBSON alloc] initWithData:data] autorelease];
}

+ (NSMutableArray *) bsonArrayWithData:(NSData *) data
{
    NSMutableArray *results = [NSMutableArray array];
    bson bsonBuffer;
    bsonBuffer.data = (char *) [data bytes];
    bsonBuffer.owned = NO;
    while (bson_size(&bsonBuffer)) {
        bson bsonValue;
        bson_copy(&bsonValue, &bsonBuffer);
        bsonBuffer.data += bson_size(&bsonValue);
        NuBSON *bsonObject = [[[NuBSON alloc] initWithBSON:bsonValue] autorelease];
        [results addObject:bsonObject];
    }
    bson_destroy(&bsonBuffer);
    return results;
}

+ (NuBSON *) bsonWithDictionary:(NSDictionary *) dictionary
{
    return [[[NuBSON alloc] initWithDictionary:dictionary] autorelease];
}

+ (NuBSON *) bsonWithList:(id) list
{
    return [[[NuBSON alloc] initWithList:list] autorelease];
}

// internal, takes ownership of argument
- (NuBSON *) initWithBSON:(bson) b
{
    if ((self = [super init])) {
        bsonValue = b;
    }
    return self;
}

- (NuBSON *) initWithData:(NSData *) data
{
    bson bsonBuffer;
    bsonBuffer.data = (char *) [data bytes];
    bsonBuffer.owned = NO;
    bson_copy(&bsonValue, &bsonBuffer);
    bson_destroy(&bsonBuffer);
    return self;
}

- (NSData *) dataRepresentation
{
    return [[[NSData alloc]
        initWithBytes:(bsonValue.data)
        length:bson_size(&(bsonValue))] autorelease];
}

- (NuBSON *) initWithDictionary:(NSDictionary *) dict
{
    bson b;
    bson_buffer bb;
    bson_buffer_init(& bb );
    id keys = [dict allKeys];
    for (int i = 0; i < [keys count]; i++) {
        id key = [keys objectAtIndex:i];
        add_object_to_bson_buffer(&bb, key, [dict objectForKey:key]);
    }
    bson_from_buffer(&b, &bb);
    return [self initWithBSON:b];
}

- (NuBSON *) initWithList:(id) cell
{
    bson b;
    bson_buffer bb;
    bson_buffer_init(& bb );
    id cursor = cell;
    while (cursor && (cursor != [NSNull null])) {
        id key = [[cursor car] labelName];
        id value = [[cursor cdr] car];
        add_object_to_bson_buffer(&bb, key, value);
        cursor = [[cursor cdr] cdr];
    }
    bson_from_buffer(&b, &bb);
    return [self initWithBSON:b];
}

- (void) dealloc
{
    bson_destroy(&bsonValue);
    [super dealloc];
}

- (void) finalize {
    bson_destroy(&bsonValue);
    [super finalize];
}

void dump_bson_iterator(bson_iterator it, const char *indent)
{
    bson_iterator it2;
    bson subobject;

    char more_indent[2000];
    sprintf(more_indent, "  %s", indent);

    while(bson_iterator_next(&it)) {
        fprintf(stderr, "%s  %s: ", indent, bson_iterator_key(&it));
        char hex_oid[25];

        switch(bson_iterator_type(&it)) {
            case bson_double:
                fprintf(stderr, "(double) %e\n", bson_iterator_double(&it));
                break;
            case bson_int:
                fprintf(stderr, "(int) %d\n", bson_iterator_int(&it));
                break;
            case bson_string:
            {                    
                fprintf(stderr, "(string) \"%s\"\n", bson_iterator_string(&it));
            }
                break;
            case bson_oid:
                bson_oid_to_string(bson_iterator_oid(&it), hex_oid);
                fprintf(stderr, "(oid) \"%s\"\n", hex_oid);
                break;
            case bson_object:
                fprintf(stderr, "(subobject) {...}\n");
                bson_iterator_subobject(&it, &subobject);
                bson_iterator_init(&it2, subobject.data);
                dump_bson_iterator(it2, more_indent);
                break;
            case bson_array:
                fprintf(stderr, "(array) [...]\n");
                bson_iterator_subobject(&it, &subobject);
                bson_iterator_init(&it2, subobject.data);
                dump_bson_iterator(it2, more_indent);
                break;
            default:
                fprintf(stderr, "(type %d)\n", bson_iterator_type(&it));
                break;
        }
    }
}

- (void) dump
{
    bson_iterator it;
    bson_iterator_init(&it, bsonValue.data);
    dump_bson_iterator(it, "");
    fprintf(stderr, "\n");
}

// When an unknown message is received by a NuBSON object, treat it as a call to objectForKey:
- (id) handleUnknownMessage:(id) method withContext:(NSMutableDictionary *) context
{
    Class NuSymbol = NSClassFromString(@"NuSymbol");
    id Nu__null = [NSNull null];
    id cursor = method;
    if (cursor && (cursor != Nu__null)) {
        // if the method is a label, use its value as the key.
        if (NuSymbol && [[cursor car] isKindOfClass:[NuSymbol class]] && ([[cursor car] isLabel])) {
            id result = [self objectForKey:[[cursor car] labelName]];
            return result ? result : Nu__null;
        }
        else {
            id result = [self objectForKey:[[cursor car] evalWithContext:context]];
            return result ? result : Nu__null;
        }
    }
    else {
        return Nu__null;
    }
}

void add_bson_to_object(bson_iterator it, id object, BOOL expandChildren);

id object_for_bson_iterator(bson_iterator it, BOOL expandChildren)
{
    id value = nil;

    bson_iterator it2;
    bson subobject;
    char bintype;
    switch(bson_iterator_type(&it)) {
        case bson_eoo:
            break;
        case bson_double:
            value = [NSNumber numberWithDouble:bson_iterator_double(&it)];
            break;
        case bson_string:
            value = [[[NSString alloc]
                initWithCString:bson_iterator_string(&it) encoding:NSUTF8StringEncoding]
                autorelease];
            break;
        case bson_object:
            if (expandChildren) {
                value = [NSMutableDictionary dictionary];
                bson_iterator_subobject(&it, &subobject);
                bson_iterator_init(&it2, subobject.data);
                add_bson_to_object(it2, value, expandChildren);
            }
            else {
                bson_iterator_subobject(&it, &subobject);
                value = [[[NuBSON alloc] initWithBSON:subobject] autorelease];
            }
            break;
        case bson_array:
            value = [NSMutableArray array];
            bson_iterator_subobject(&it, &subobject);
            bson_iterator_init(&it2, subobject.data);
            add_bson_to_object(it2, value, expandChildren);
            break;
        case bson_bindata:
            bintype = bson_iterator_bin_type(&it);
            value = [NSData
                dataWithBytes:bson_iterator_bin_data(&it)
                length:bson_iterator_bin_len(&it)];
            if (bintype == 1) {
                value = [NSKeyedUnarchiver unarchiveObjectWithData:value];
            }
            break;
        case bson_undefined:
            break;
        case bson_oid:
            value = [[[BSONObjectID alloc]
                initWithObjectIDPointer:bson_iterator_oid(&it)]
                autorelease];
            break;
        case bson_bool:
            value = [NSNumber numberWithBool:bson_iterator_bool(&it)];
            break;
        case bson_date:
            value = [NSDate dateWithTimeIntervalSince1970:(0.001 * bson_iterator_date(&it))];
            break;
        case bson_null:
            value = [NSNull null];
            break;
        case bson_regex:
            break;
        case bson_code:
            break;
        case bson_symbol:
            break;
        case bson_codewscope:
            break;
        case bson_int:
            value = [NSNumber numberWithInt:bson_iterator_int(&it)];
            break;
        case bson_timestamp:
            break;
        case bson_long:
            value = [NSNumber numberWithLong:bson_iterator_long(&it)];
            break;
        default:
            break;
    }
    return value;
}

void add_bson_to_object(bson_iterator it, id object, BOOL expandChildren)
{
    while(bson_iterator_next(&it)) {
        NSString *key = [[[NSString alloc]
            initWithCString:bson_iterator_key(&it) encoding:NSUTF8StringEncoding]
            autorelease];

        id value = object_for_bson_iterator(it, expandChildren);
        if (value) {
            if ([object isKindOfClass:[NSDictionary class]]) {
                [object setObject:value forKey:key];
            }
            else if ([object isKindOfClass:[NSArray class]]) {
                [object addObject:value];
            }
            else {
                fprintf(stderr, "(type %d)\n", bson_iterator_type(&it));
                NSLog(@"we don't know how to add to %@", object);
            }
        }
    }
}

- (NSMutableDictionary *) dictionaryValue
{
    id object = [NSMutableDictionary dictionary];
    bson_iterator it;
    bson_iterator_init(&it, bsonValue.data);
    add_bson_to_object(it, object, YES);
    return object;
}

- (NSArray *) allKeys
{
    NSMutableArray *result = [NSMutableArray array];
    bson_iterator it;
    bson_iterator_init(&it, bsonValue.data);

    while(bson_iterator_next(&it)) {
        NSString *key = [[[NSString alloc]
            initWithCString:bson_iterator_key(&it) encoding:NSUTF8StringEncoding]
            autorelease];
        [result addObject:key];
    }
    return result;
}

- (int) count
{
    int count = 0;
    bson_iterator it;
    bson_iterator_init(&it, bsonValue.data);
    
    while(bson_iterator_next(&it)) {
        count++;
    }
    return count;
}

- (id) objectForKey:(NSString *) key
{
    bson_iterator it;
    bson_iterator_init(&it, bsonValue.data);
    bson_find(&it, &bsonValue, [key cStringUsingEncoding:NSUTF8StringEncoding]);
    id value = object_for_bson_iterator(it, NO);
    return value;
}

- (id) objectForKeyPath:(NSString *) keypath
{
    NSArray *parts = [keypath componentsSeparatedByString:@"."];
    id cursor = self;
    for (int i = 0; i < [parts count]; i++) {
        cursor = [cursor objectForKey:[parts objectAtIndex:i]];
    }
    return cursor;
}

- (id) valueForKey:(NSString *) key {
    return [self objectForKey:key];
}

- (id) valueForKeyPath:(NSString *)keypath {
    return [self objectForKeyPath:keypath];
}

@end

bson *bson_for_object(id object)
{
    bson *b = malloc(sizeof(bson));
    if (!object) {
        object = [NSDictionary dictionary];
    }
    if ([object isKindOfClass:[NuBSON class]]) {
        bson_copy(b,&(((NuBSON *)object)->bsonValue));
    }
    else if ([object isKindOfClass:[NSDictionary class]]) {
        NuBSON *bsonObject = [[[NuBSON alloc] initWithDictionary:object] autorelease];
        bson_copy(b,&(bsonObject->bsonValue)); // Needed for GC
    }
    else {
        NSLog(@"unable to convert objects of type %s to BSON (%@).",
            object_getClassName(object), object);
    }
    return b;
}

@implementation NuBSONBuffer

- (id) init
{
    if ((self = [super init])) {
        bson_buffer_init(& bb );
    }
    return self;
}

- (NuBSON *) bsonValue
{
    bson b;
    bson_from_buffer(&b, &bb);
    return [[[NuBSON alloc] initWithBSON:b] autorelease];
}

- (void) addObject:(id) object withKey:(id) key
{
    add_object_to_bson_buffer(&bb, key, object);
}

// When an unknown message is received by a NuBSONBuffer, treat it as a call to addObject:withKey:
- (id) handleUnknownMessage:(id) method withContext:(NSMutableDictionary *) context
{
    Class NuSymbol = NSClassFromString(@"NuSymbol");
    id cursor = method;
    id Nu__null = [NSNull null];
    while (cursor && (cursor != Nu__null) && ([cursor cdr]) && ([cursor cdr] != Nu__null)) {
        id key = [cursor car];
        id value = [[cursor cdr] car];
        if (NuSymbol && [key isKindOfClass:[NuSymbol class]] && [key isLabel]) {
            id evaluated_key = [key labelName];
            id evaluated_value = [value evalWithContext:context];
            [self addObject:evaluated_value withKey:evaluated_key];
        }
        else {
            id evaluated_key = [key evalWithContext:context];
            id evaluated_value = [value evalWithContext:context];
            [self addObject:evaluated_value withKey:evaluated_key];
        }
        cursor = [[cursor cdr] cdr];
    }
    return Nu__null;
}

@end

// deprecated convenience categories
@implementation NSData (NuBSON)
- (NSMutableDictionary *) BSONValue
{
    return [[NuBSON bsonWithData:self] dictionaryValue];
}

@end

@implementation NSDictionary (NuBSON)
- (NSData *) BSONRepresentation
{
    return [[NuBSON bsonWithDictionary:self] dataRepresentation];
}

@end

@implementation NuBSONComparator

+ (NuBSONComparator *) comparatorWithBSONSpecification:(NuBSON *) s
{
    NuBSONComparator *comparator = [[[NuBSONComparator alloc] init] autorelease];
    comparator->specification = [s retain];
    return comparator;
}

- (int) compareDataAtAddress:(void *) aptr withSize:(int) asiz withDataAtAddress:(void *) bptr withSize:(int) bsiz
{
    bson bsonA;
    bsonA.data = aptr;
    bsonA.owned = NO;
    NuBSON *a = [[NuBSON alloc] initWithBSON:bsonA];

    bson bsonB;
    bsonB.data = bptr;
    bsonB.owned = NO;
    NuBSON *b = [[NuBSON alloc] initWithBSON:bsonB];

    bson_iterator it;
    bson_iterator_init(&it, specification->bsonValue.data);

    int result = 0;
    while(bson_iterator_next(&it)) {
        NSString *key = [[[NSString alloc]
            initWithCString:bson_iterator_key(&it) encoding:NSUTF8StringEncoding]
            autorelease];
        id value = object_for_bson_iterator(it, NO);
        id a_value = [a objectForKey:key];
        id b_value = [b objectForKey:key];
        result = [a_value compare:b_value] * [value intValue];
        if (result != 0)
            break;
    }
    [a release];
    [b release];
    return result;
}

@end
