#import "NuMongoDB.h"

@interface NuBSON (Private)
- (NuBSON *) initWithBSON:(bson) b;
@end

@interface NuMongoDBObjectID : NSObject
{
    @public
    bson_oid_t oid;
}

@end

@implementation NuMongoDBObjectID
- (id) initWithString:(NSString *) s
{
    if (self = [super init]) {
        bson_oid_from_string(&oid, [s cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    return self;
}

- (id) initWithObjectIDPointer:(const bson_oid_t *) objectIDPointer
{
    if (self = [super init]) {
        oid = *objectIDPointer;
    }
    return self;
}

- (const bson_oid_t *) objectIDPointer {return &oid;}

- (NSString *) description
{
    char buffer[25];                              /* str must be at least 24 hex chars + null byte */
    bson_oid_to_string(&oid, buffer);
    return [NSString stringWithFormat:@"(oid \"%s\")", buffer];
}

- (NSString *) stringValue
{
    char buffer[25];                              /* str must be at least 24 hex chars + null byte */
    bson_oid_to_string(&oid, buffer);
    return [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
}

- (NSComparisonResult)compare:(NuMongoDBObjectID *) other
{
    for (int i = 0; i < 3; i++) {
        int diff = oid.ints[i] - other->oid.ints[i];
        if (diff < 0)
            return NSOrderedAscending;
        else if (diff > 0)
            return NSOrderedDescending;
    }
    return  NSOrderedSame;
}

- (BOOL)isEqual:(id)other
{
    return ([self compare:other] == 0);
}

@end

@implementation NuMongoDBCursor

- (NuMongoDBCursor *) initWithCursor:(mongo_cursor *) c
{
    if (self = [super init]) {
        cursor = c;
    }
    return self;
}

- (mongo_cursor *) cursor
{
    return cursor;
}

- (BOOL) next
{
    return mongo_cursor_next(cursor);
}

- (bson) current
{
    return cursor->current;
}

- (NuBSON *) currentBSON
{
    return [[[NuBSON alloc] initWithBSON:cursor->current] autorelease];
}

- (NSDictionary *) currentObject
{
    return [[self currentBSON] dictionaryValue];
}

- (void) dealloc
{
    mongo_cursor_destroy(cursor);
    [super dealloc];
}

- (NSMutableArray *) arrayValue
{
    NSMutableArray *result = [NSMutableArray array];
    while([self next]) {
        [result addObject:[self currentObject]];
    }
    return result;
}

- (NSMutableArray *) arrayValueWithLimit:(int) limit
{
    int count = 0;
    NSMutableArray *result = [NSMutableArray array];
    while([self next] && (count < limit)) {
        [result addObject:[self currentObject]];
        count++;
    }
    return result;
}

@end

@implementation NuBSON

- (NuBSON *) initWithBSON:(bson) b
{
    if (self = [super init]) {
        bsonValue = b;
    }
    return self;
}

void add_object_to_bson_buffer(bson_buffer *bb, id key, id object)
{
    const char *name = [key cStringUsingEncoding:NSUTF8StringEncoding];

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
            case 'B':
                bson_append_bool(bb, name, [object boolValue]);
                break;
            case 'c':
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
    else if ([object respondsToSelector:@selector(cStringUsingEncoding:)]) {
        bson_append_string(bb, name,[object cStringUsingEncoding:NSUTF8StringEncoding]);
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
            add_object_to_bson_buffer(arr, [[NSNumber numberWithInt:i] stringValue], [object objectAtIndex:i]);
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
    else if ([object isKindOfClass:[NuMongoDBObjectID class]]) {
        bson_append_oid(bb, name, [((NuMongoDBObjectID *) object) objectIDPointer]);
    }
    else {
        NSLog(@"We have a problem. %@ cannot be serialized to bson", object);
    }
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
                fprintf(stderr, "(string) \"%s\"\n", bson_iterator_string(&it));
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

void add_bson_to_object(bson_iterator it, id object)
{
    bson_iterator it2;
    bson subobject;

    while(bson_iterator_next(&it)) {

        NSString *key = [[[NSString alloc] initWithCString:bson_iterator_key(&it) encoding:NSUTF8StringEncoding] autorelease];

        id value = nil;
        char hex_oid[25];
        switch(bson_iterator_type(&it)) {
            case bson_eoo:
                break;
            case bson_double:
                value = [NSNumber numberWithDouble:bson_iterator_double(&it)];
                break;
            case bson_string:
                value = [[[NSString alloc] initWithCString:bson_iterator_string(&it) encoding:NSUTF8StringEncoding] autorelease];
                break;
            case bson_object:
                value = [NSMutableDictionary dictionary];
                bson_iterator_subobject(&it, &subobject);
                bson_iterator_init(&it2, subobject.data);
                add_bson_to_object(it2, value);
                break;
            case bson_array:
                value = [NSMutableArray array];
                bson_iterator_subobject(&it, &subobject);
                bson_iterator_init(&it2, subobject.data);
                add_bson_to_object(it2, value);
                break;
            case bson_bindata:
                value = [NSData
                    dataWithBytes:bson_iterator_bin_data(&it)
                    length:bson_iterator_bin_len(&it)];
                break;
            case bson_undefined:
                break;
            case bson_oid:
                value = [[[NuMongoDBObjectID alloc] initWithObjectIDPointer:bson_iterator_oid(&it)] autorelease];
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
    add_bson_to_object(it, object);
    return object;
}

@end

@implementation NuMongoDB

- (int) connectWithOptions:(NSDictionary *) options
{
    id host = options ? [options objectForKey:@"host"] : nil;
    if (host) {
        strncpy(opts.host, [host cStringUsingEncoding:NSUTF8StringEncoding], 255);
        opts.host[254] = '\0';
    }
    else {
        strncpy(opts.host, "127.0.0.1", 255);
        opts.host[254] = '\0';
    }
    id port = options ? [options objectForKey:@"port"] : nil;
    if (port) {
        opts.port = [port intValue];
    }
    else {
        opts.port = 27017;
    }
    return mongo_connect(conn, &opts);
}

- (BOOL) authenticateUser:(NSString *) user withPassword:(NSString *) password forDatabase:(NSString *) database
{
    return mongo_cmd_authenticate(conn, [database cStringUsingEncoding:NSUTF8StringEncoding],
        [user cStringUsingEncoding:NSUTF8StringEncoding],
        [password cStringUsingEncoding:NSUTF8StringEncoding]);
}

bson *bson_for_object(id object)
{
    bson *b = 0;
    if (!object) {
        object = [NSDictionary dictionary];
    }
    if ([object isKindOfClass:[NuBSON class]]) {
        b = &(((NuBSON *)object)->bsonValue);
    }
    else if ([object isKindOfClass:[NSDictionary class]]) {
        NuBSON *bsonObject = [[[NuBSON alloc] initWithDictionary:object] autorelease];
        b = &(bsonObject->bsonValue);
    }
    else {
        NSLog(@"unable to convert objects of type %@ to BSON (%@).", [object className], object);
    }
    return b;
}

- (NuMongoDBCursor *) find:(id) query inCollection:(NSString *) collection
{
    bson *b = bson_for_object(query);
    mongo_cursor *cursor = mongo_find(conn, [collection cStringUsingEncoding:NSUTF8StringEncoding], b, 0, 0, 0, 0 );
    return [[[NuMongoDBCursor alloc] initWithCursor:cursor] autorelease];
}

- (NuMongoDBCursor *) find:(id) query inCollection:(NSString *) collection returningFields:(id) fields numberToReturn:(int) nToReturn numberToSkip:(int) nToSkip
{
    bson *b = bson_for_object(query);
    bson *f = bson_for_object(fields);
    mongo_cursor *cursor = mongo_find(conn, [collection cStringUsingEncoding:NSUTF8StringEncoding], b, f, nToReturn, nToSkip, 0 );
    return [[[NuMongoDBCursor alloc] initWithCursor:cursor] autorelease];
}

- (NSMutableArray *) findArray:(id) query inCollection:(NSString *) collection
{
    NuMongoDBCursor *cursor = [self find:query inCollection:collection];
    return [cursor arrayValue];
}

- (NSMutableArray *) findArray:(id) query inCollection:(NSString *) collection returningFields:(id) fields numberToReturn:(int) nToReturn numberToSkip:(int) nToSkip
{
    NuMongoDBCursor *cursor = [self find:query inCollection:collection returningFields:fields numberToReturn:nToReturn numberToSkip:nToSkip];
    return [cursor arrayValueWithLimit:nToReturn];
}

- (NSMutableDictionary *) findOne:(id) query inCollection:(NSString *) collection
{
    bson *b = bson_for_object(query);
    bson bsonResult;
    bson_bool_t result = mongo_find_one(conn, [collection cStringUsingEncoding:NSUTF8StringEncoding], b, 0, &bsonResult);
    return result ? [[[[NuBSON alloc] initWithBSON:bsonResult] autorelease] dictionaryValue] : nil;
}

- (void) insertObject:(id) insert intoCollection:(NSString *) collection
{
    bson *b = bson_for_object(insert);
    if (b) {
        mongo_insert(conn, [collection cStringUsingEncoding:NSUTF8StringEncoding], b);
    }
    else {
        NSLog(@"incomplete insert: insert must not be nil.");
    }
}

- (void) updateObject:(id) update inCollection:(NSString *) collection
withCondition:(id) condition insertIfNecessary:(BOOL) insertIfNecessary updateMultipleEntries:(BOOL) updateMultipleEntries
{
    bson *bupdate = bson_for_object(update);
    bson *bcondition = bson_for_object(condition);
    if (bupdate && bcondition) {
        mongo_update(conn, [collection cStringUsingEncoding:NSUTF8StringEncoding],
            bcondition,
            bupdate,
            (insertIfNecessary ? MONGO_UPDATE_UPSERT : 0) + (updateMultipleEntries ? MONGO_UPDATE_MULTI : 0));
    }
    else {
        NSLog(@"incomplete update: update and condition must not be nil.");
    }
}

- (void) removeWithCondition:(id) condition fromCollection:(NSString *) collection
{
    bson *bcondition = bson_for_object(condition);
    mongo_remove(conn, [collection cStringUsingEncoding:NSUTF8StringEncoding], bcondition);
}

- (int) countWithCondition:(id) condition inCollection:(NSString *) collection inDatabase:(NSString *) database
{
    bson *bcondition = bson_for_object(condition);
    return mongo_count(conn, [database cStringUsingEncoding:NSUTF8StringEncoding], [collection cStringUsingEncoding:NSUTF8StringEncoding], bcondition);
}

- (id) runCommand:(id) command inDatabase:(NSString *) database
{
    bson *bcommand = bson_for_object(command);
    bson bsonResult;
    bson_bool_t result = mongo_run_command(conn, [database cStringUsingEncoding:NSUTF8StringEncoding], bcommand, &bsonResult);
    return result ? [[[[NuBSON alloc] initWithBSON:bsonResult] autorelease] dictionaryValue] : nil;
}

- (BOOL) dropCollection:(NSString *) collection inDatabase:(NSString *) database
{
    return mongo_cmd_drop_collection(conn,
        [database cStringUsingEncoding:NSUTF8StringEncoding],
        [collection cStringUsingEncoding:NSUTF8StringEncoding],
        NULL);
}

- (BOOL) ensureCollection:(NSString *) collection hasIndex:(NSObject *) key withOptions:(int) options
{
    bson output;
    return mongo_create_index(conn,
        [collection cStringUsingEncoding:NSUTF8StringEncoding],
        bson_for_object(key),
        options,
        &output);
}

- (void) close
{
    mongo_destroy(conn );
}

@end
