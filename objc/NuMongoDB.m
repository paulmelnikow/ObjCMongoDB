#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "bson.h"
#include "mongo.h"

#import <Foundation/Foundation.h>

@interface NuBSON : NSObject
{
    @public
    bson bsonValue;
}

- (NuBSON *) initWithBSON:(bson) bb;
- (NuBSON *) initWithDictionary:(NSDictionary *) dict;
@end

@interface NuMongoDBCursor : NSObject
{
    mongo_cursor *cursor;
}

- (BOOL) next;
- (bson) current;

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

- (NSDictionary *) currentDictionary
{
    return [[self currentBSON] dictionaryValue];
}

- (void) dealloc
{
    mongo_cursor_destroy(cursor);
    [super dealloc];
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
            default:
                bson_append_int(bb, name, [object intValue]);
                break;
        }
    }
    else if ([object isKindOfClass:[NSString class]]) {
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
            case bson_double:
                value = [NSNumber numberWithDouble:bson_iterator_double(&it)];
                break;
            case bson_int:
                value = [NSNumber numberWithInt:bson_iterator_int(&it)];
                break;
            case bson_string:
                value = [[[NSString alloc] initWithCString:bson_iterator_string(&it) encoding:NSUTF8StringEncoding] autorelease];
                break;
            case bson_oid:
                bson_oid_to_string(bson_iterator_oid(&it), hex_oid);
                value = [[[NSString alloc] initWithCString:hex_oid encoding:NSUTF8StringEncoding] autorelease];
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
            default:
                fprintf(stderr, "(type %d)\n", bson_iterator_type(&it));
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
                NSLog(@"we don't know how to add to %@", object);
            }
        }
    }
}

- (id) dictionaryValue
{
    id object = [NSMutableDictionary dictionary];

    bson_iterator it;
    bson_iterator_init(&it, bsonValue.data);
    add_bson_to_object(it, object);
    return object;
}

@end

@interface NuMongoDB : NSObject
{
    mongo_connection conn[1];
    mongo_connection_options opts;
}

@end

@implementation NuMongoDB

- (BOOL) connectWithOptions:(NSDictionary *) options
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

- (NuMongoDBCursor *) find:(NSDictionary *) query inCollection:(NSString *) collection
{
    if (query) {
        NuBSON *queryBSON = [[[NuBSON alloc] initWithDictionary:query] autorelease];
        mongo_cursor *cursor = mongo_find(conn, [collection cStringUsingEncoding:NSUTF8StringEncoding], &(queryBSON->bsonValue), 0, 0, 0, 0 );
        return [[[NuMongoDBCursor alloc] initWithCursor:cursor] autorelease];
    }
    else {
        bson b;
        mongo_cursor *cursor = mongo_find(conn, [collection cStringUsingEncoding:NSUTF8StringEncoding], bson_empty(&b), 0, 0, 0, 0 );
        return [[[NuMongoDBCursor alloc] initWithCursor:cursor] autorelease];
    }
}

- (void) insert:(id) insert intoCollection:(NSString *) collection
{
    bson *b = 0;
    if ([insert isKindOfClass:[NuBSON class]]) {
        b = &(((NuBSON *)insert)->bsonValue);
    }
    else if ([insert isKindOfClass:[NSDictionary class]]) {
        NuBSON *bsonObject = [[[NuBSON alloc] initWithDictionary:insert] autorelease];
        b = &(bsonObject->bsonValue);
    }
    if (b)
        mongo_insert(conn, [collection cStringUsingEncoding:NSUTF8StringEncoding], b);
}

- (void) update:(NuBSON *) bsonObject inCollection:(NSString *) collection withCondition:(NuBSON *) condition
insertIfNecessary:(BOOL) insertIfNecessary updateMultipleEntries:(BOOL) updateMultipleEntries
{
    mongo_update(conn, [collection cStringUsingEncoding:NSUTF8StringEncoding],
        &(condition->bsonValue),
        &(bsonObject->bsonValue),
        (insertIfNecessary ? MONGO_UPDATE_UPSERT : 0) + (updateMultipleEntries ? MONGO_UPDATE_MULTI : 0));
}

- (BOOL) dropCollection:(NSString *) collection inDatabase:(NSString *) database
{
    return mongo_cmd_drop_collection(conn,
        [database cStringUsingEncoding:NSUTF8StringEncoding],
        [collection cStringUsingEncoding:NSUTF8StringEncoding],
        NULL);
}

- (void) close
{
    mongo_destroy(conn );
}

@end
