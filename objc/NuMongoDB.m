#include <stdlib.h>

#define TEST_SERVER "127.0.0.1"

// temporary
const char * col = "c.simple";
const char * ns = "test.c.simple";

#include "bson.h"
#include "mongo.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#import <Foundation/Foundation.h>

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

- (void) dealloc
{
    mongo_cursor_destroy(cursor);
    [super dealloc];
}

@end

@interface NuBSON : NSObject
{
    @public
    bson b;
}

@end

@implementation NuBSON

- (NuBSON *) initWithBSON:(bson) bb
{
    if (self = [super init]) {
        b = bb;
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

- (NuBSON *) initWithObject:(id) object
{
    bson b;
    bson_buffer bb;
    bson_buffer_init(& bb );

    bson_append_new_oid(&bb, "_id" );

    add_object_to_bson_buffer(&bb, @"top", object);

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
    bson_iterator_init(&it, b.data);
    dump_bson_iterator(it, "");
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
			} else if ([object isKindOfClass:[NSArray class]]) {
				[object addObject:value];
			} else {
				NSLog(@"we don't know how to add to %@", object);
			}
		}
    }
}

- (id) objectValue
{
    id object = [NSMutableDictionary dictionary];

    bson_iterator it;
    bson_iterator_init(&it, b.data);
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

- (BOOL) connect
{
    strncpy(opts.host, TEST_SERVER, 255);
    opts.host[254] = '\0';
    opts.port = 27017;

    if (mongo_connect(conn, &opts )) {
        printf("failed to connect\n");
        return NO;
    }
    return YES;
}

- (NuMongoDBCursor *) find
{
    const char * col = "c.simple";
    const char * ns = "test.c.simple";
    bson b;

    mongo_cursor *cursor = mongo_find(conn, ns, bson_empty(&b), 0, 0, 0, 0 );
    return [[[NuMongoDBCursor alloc] initWithCursor:cursor] autorelease];
}

- (BOOL) resetDatabase
{
    /* if the collection doesn't exist dropping it will fail */
    bson b;

    if (!mongo_cmd_drop_collection(conn, "test", col, NULL)
    && mongo_find_one(conn, ns, bson_empty(&b), bson_empty(&b), NULL)) {
        printf("failed to drop collection\n");
        return NO;
    }
    return YES;
}

- (void) loadDB
{
    bson b;

    // add some things to the database
    for(int i=0; i< 5; i++) {

        bson_buffer bb;
        bson_buffer_init(& bb );

        bson_append_new_oid(&bb, "_id" );
        bson_append_double(&bb, "a", i*17 );
        bson_append_int(&bb, "b", i*17 );
        bson_append_string(&bb, "c", "17" );

        {
            bson_buffer * sub = bson_append_start_object( &bb, "d" );
            bson_append_int(sub, "i", i*71 );
            bson_append_int(sub, "j", i*72 );
            bson_append_finish_object(sub);
        }
        {
            bson_buffer * arr = bson_append_start_array( &bb, "e" );
            bson_append_int(arr, "0", i*71 );
            bson_append_string(arr, "1", "71" );
            bson_append_finish_object(arr);
        }

        bson_from_buffer(&b, &bb);

        mongo_insert(conn, ns, &b );

        bson_destroy(&b);
    }

    id object = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"one",
        [NSNumber numberWithFloat:2.0], @"two",
        @"3", @"three",
        [NSArray arrayWithObjects:@"zero", @"one", @"two", nil], @"four",
        nil];

    NuBSON *bson = [[[NuBSON alloc] initWithObject:object] autorelease];
    [bson dump];

    mongo_insert(conn, ns, &(bson->b));

}

- (void) readDB
{
    bson b;

    // read them out of the database
    NuMongoDBCursor *cursor = [self find];

    while ([cursor next]) {
        NuBSON *bson = [[[NuBSON alloc] initWithBSON:[cursor current]] autorelease];
        [bson dump];
        fprintf(stderr, "\n");

		id object = [bson objectValue];
		NSLog(@"%@", object);
    }
}

- (void) close
{
    mongo_destroy(conn );
}

@end
