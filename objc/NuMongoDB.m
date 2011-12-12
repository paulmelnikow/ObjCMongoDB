#import "NuMongoDB.h"
#import "NuBSON.h"

@interface NuBSON (Private)
- (NuBSON *) initWithBSON:(bson) b;
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

- (void) finalize
{
    mongo_cursor_destroy(cursor);
    [super finalize];
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

@implementation NuMongoDB

static BOOL enableUpdateTimestamps = NO;

+ (void) setEnableUpdateTimestamps:(BOOL) enable {
	enableUpdateTimestamps = YES;
}

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
    //NSLog(@"connecting to host %s port %d", opts.host, opts.port);
    return mongo_connect(conn, &opts);
}

- (int) connect {
	return [self connectWithOptions:nil];
}

- (void) addUser:(NSString *) user withPassword:(NSString *) password forDatabase:(NSString *) database
{
    mongo_cmd_add_user(conn, [database cStringUsingEncoding:NSUTF8StringEncoding],
        [user cStringUsingEncoding:NSUTF8StringEncoding],
        [password cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (BOOL) authenticateUser:(NSString *) user withPassword:(NSString *) password forDatabase:(NSString *) database
{
    return mongo_cmd_authenticate(conn, [database cStringUsingEncoding:NSUTF8StringEncoding],
        [user cStringUsingEncoding:NSUTF8StringEncoding],
        [password cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (NuMongoDBCursor *) find:(id) query inCollection:(NSString *) collection
{
    bson *b = bson_for_object(query);
    mongo_cursor *cursor = mongo_find(conn, [collection cStringUsingEncoding:NSUTF8StringEncoding], b, 0, 0, 0, 0 );
    bson_destroy(b);
    return [[[NuMongoDBCursor alloc] initWithCursor:cursor] autorelease];
}

- (NuMongoDBCursor *) find:(id) query inCollection:(NSString *) collection returningFields:(id) fields numberToReturn:(int) nToReturn numberToSkip:(int) nToSkip
{
    bson *b = bson_for_object(query);
    bson *f = bson_for_object(fields);
    mongo_cursor *cursor = mongo_find(conn, [collection cStringUsingEncoding:NSUTF8StringEncoding], b, f, nToReturn, nToSkip, 0 );
    bson_destroy(b);
    bson_destroy(f);
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
    bson_destroy(b);
    return result ? [[[[NuBSON alloc] initWithBSON:bsonResult] autorelease] dictionaryValue] : nil;
}

- (NSMutableDictionary *) findAndModify:(id)collection options:(NSDictionary *)options inDatabase:(NSString *)database
{
    NuBSONBuffer *bsonBuffer = [[[NuBSONBuffer alloc] init] autorelease];
    [bsonBuffer addObject:collection withKey:@"findandmodify"];
    id keys = [options allKeys];
    for (int i = 0; i < [keys count]; i++) {
        id key = [keys objectAtIndex:i];
        [bsonBuffer addObject:[options objectForKey:key] withKey:key];
    }

    bson bsonResult;
    bson_bool_t result = mongo_run_command(conn, [database cStringUsingEncoding:NSUTF8StringEncoding], &([bsonBuffer bsonValue]->bsonValue), &bsonResult);
    return result ? [[[[NuBSON alloc] initWithBSON:bsonResult] autorelease] dictionaryValue] : nil;
}

- (id) insertObject:(id) insert intoCollection:(NSString *) collection
{
    if (![insert objectForKey:@"_id"]) {
        insert = [[insert mutableCopy] autorelease];
        [insert setObject:[NuBSONObjectID objectID] forKey:@"_id"];
    }
	if (enableUpdateTimestamps) {
    	[insert setObject:[NSDate date] forKey:@"_up"];
	}
    bson *b = bson_for_object(insert);
    if (b) {
        mongo_insert(conn, [collection cStringUsingEncoding:NSUTF8StringEncoding], b);
        bson_destroy(b);
        return [insert objectForKey:@"_id"];
    }
    else {
        NSLog(@"incomplete insert: insert must not be nil.");
        return nil;
    }
}

- (void) insertObjects:(NSArray *) array intoCollection:(NSString *) collection
{
    int count = [array count];
    bson bArray[count];
    bson *bpArray[count];
    for (int i = 0; i < count; i++) {
        bpArray[i] = &bArray[i];
    }
    
    NSMutableArray *BSONObjects = [NSMutableArray  array];
    for (int i = 0; i < count; i++) {
        id insert = [array objectAtIndex:i];
        if (![insert objectForKey:@"_id"]) {
            insert = [[insert mutableCopy] autorelease];
            [insert setObject:[NuBSONObjectID objectID] forKey:@"_id"];
        }
        NuBSON *bsonObject = [NuBSON bsonWithDictionary:insert];
        [BSONObjects addObject:bsonObject];
        bson_copy(&bArray[i],&bsonObject->bsonValue);
    }
    
    mongo_insert_batch(conn, [collection cStringUsingEncoding:NSUTF8StringEncoding], bpArray, count);
    // Free objects
    for (int i = 0; i < count; i++) {
        bson_destroy(&bArray[i]);
    }
}

- (void) updateObject:(id) update inCollection:(NSString *) collection
withCondition:(id) condition insertIfNecessary:(BOOL) insertIfNecessary updateMultipleEntries:(BOOL) updateMultipleEntries
{
	if (enableUpdateTimestamps) {
    	[update setObject:[NSDate date] forKey:@"_up"];
	}
    bson *bupdate = bson_for_object(update);
    bson *bcondition = bson_for_object(condition);
    if (bupdate && bcondition) {
        mongo_update(conn, [collection cStringUsingEncoding:NSUTF8StringEncoding],
            bcondition,
            bupdate,
            (insertIfNecessary ? MONGO_UPDATE_UPSERT : 0) + (updateMultipleEntries ? MONGO_UPDATE_MULTI : 0));
        bson_destroy(bupdate);
        bson_destroy(bcondition);
    }
    else {
        NSLog(@"incomplete update: update and condition must not be nil.");
    }
}

- (void) removeWithCondition:(id) condition fromCollection:(NSString *) collection
{
    bson *bcondition = bson_for_object(condition);
    mongo_remove(conn, [collection cStringUsingEncoding:NSUTF8StringEncoding], bcondition);
    bson_destroy(bcondition);
}

- (long long) countWithCondition:(id) condition inCollection:(NSString *) collection inDatabase:(NSString *) database
{
    bson *bcondition = bson_for_object(condition);
    return mongo_count(conn, [database cStringUsingEncoding:NSUTF8StringEncoding], [collection cStringUsingEncoding:NSUTF8StringEncoding], bcondition);
}

- (id) runCommand:(id) command inDatabase:(NSString *) database
{
    bson *bcommand = bson_for_object(command);
    bson bsonResult;
    bson_bool_t result = mongo_run_command(conn, [database cStringUsingEncoding:NSUTF8StringEncoding], bcommand, &bsonResult);
    bson_destroy(bcommand);
    return result ? [[[[NuBSON alloc] initWithBSON:bsonResult] autorelease] dictionaryValue] : nil;
}

- (BOOL) dropDatabase:(NSString *) database
{
    return mongo_cmd_drop_db(conn, [database cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (BOOL) dropCollection:(NSString *) collection inDatabase:(NSString *) database
{
    return mongo_cmd_drop_collection(conn,
        [database cStringUsingEncoding:NSUTF8StringEncoding],
        [collection cStringUsingEncoding:NSUTF8StringEncoding],
        NULL);
}

- (id) collectionNamesInDatabase:(NSString *) database
{
    NSArray *names = [self findArray:nil inCollection:[database stringByAppendingString:@".system.namespaces"]];
    NSMutableArray *result = [NSMutableArray array];
    for (int i = 0; i < [names count]; i++) {
        id name = [[[names objectAtIndex:i] objectForKey:@"name"]
            stringByReplacingOccurrencesOfString:[database stringByAppendingString:@"."]
            withString:@""];
        NSRange match = [name rangeOfString:@".$_id_"];
        if (match.location != NSNotFound) {
            continue;
        }
        match = [name rangeOfString:@"system.indexes"];
        if (match.location != NSNotFound) {
            continue;
        }
        [result addObject:name];
    }
    return result;
}

- (id) listDatabases
{
    return [self runCommand:[NSDictionary dictionaryWithObject:@"1" forKey:@"listDatabases"] inDatabase:@"admin"];
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


- (NSMutableDictionary *) writeFile:(NSString *)filePath withMIMEType:(NSString *)type inCollection:(NSString *) collection inDatabase:(NSString *) database
{
    bson output;
    gridfs gfs[1];
 
    gridfs_init(conn, [database cStringUsingEncoding:NSUTF8StringEncoding], [collection cStringUsingEncoding:NSUTF8StringEncoding], gfs);
    output = gridfs_store_file(gfs, [filePath cStringUsingEncoding:NSUTF8StringEncoding], [filePath cStringUsingEncoding:NSUTF8StringEncoding], [type cStringUsingEncoding:NSUTF8StringEncoding]);
    gridfs_destroy(gfs);
    
    return [[[[NuBSON alloc] initWithBSON:output] autorelease] dictionaryValue]; 
}

- (NSMutableDictionary *) writeData:(NSData *)data named:(NSString *)file withMIMEType:(NSString *)type inCollection:(NSString *) collection inDatabase:(NSString *) database
{
    bson output;
    gridfs gfs[1];
    gridfile gfile[1];
    char buffer[1024];
    int n;
    NSUInteger i = 0;
    
    gridfs_init(conn, [database cStringUsingEncoding:NSUTF8StringEncoding], [collection cStringUsingEncoding:NSUTF8StringEncoding], gfs);
    gridfile_writer_init( gfile, gfs, [file cStringUsingEncoding:NSUTF8StringEncoding], [type cStringUsingEncoding:NSUTF8StringEncoding]);
    while(data.length-i > 0) {
        n = MIN(data.length-i,1024);
        [data getBytes:buffer range:NSMakeRange(i,n)];
        gridfile_write_buffer(gfile, buffer, n);
        i += n;
    }
    output = gridfile_writer_done(gfile);
    gridfs_destroy(gfs);
    
    return [[[[NuBSON alloc] initWithBSON:output] autorelease] dictionaryValue];    
}


- (NSData *) retrieveDataforGridFSFile:(NSString *) filePath inCollection:(NSString *) collection inDatabase:(NSString *) database
{
    gridfs gfs[1];
    gridfile gfile[1];
    gridfs_offset length, chunkLength;
    NSUInteger chunkSize, numChunks;
    
    gridfs_init(conn, [database cStringUsingEncoding:NSUTF8StringEncoding], [collection cStringUsingEncoding:NSUTF8StringEncoding], gfs);
    if (gridfs_find_filename(gfs, [filePath cStringUsingEncoding:NSUTF8StringEncoding], gfile)) {
        length = gridfile_get_contentlength(gfile);
        chunkSize = gridfile_get_chunksize(gfile);
        numChunks = gridfile_get_numchunks(gfile);
        NSMutableData *data = [NSMutableData dataWithCapacity:(NSUInteger)length];
        
        char buffer[chunkSize];
        
        for (NSUInteger i = 0; i < numChunks; i++) {
            chunkLength = gridfile_read(gfile, chunkSize, buffer);
            [data appendBytes:buffer length:(NSUInteger)chunkLength];
        }
        gridfs_destroy(gfs);
        
        return data;
    }
    else {
        return nil;
    }
}

-(BOOL) removeFile:(NSString *)filePath inCollection:(NSString *) collection inDatabase:(NSString *) database
{
    gridfs gfs[1];
    gridfs_init(conn, [database cStringUsingEncoding:NSUTF8StringEncoding], [collection cStringUsingEncoding:NSUTF8StringEncoding], gfs);
    gridfs_remove_filename(gfs, [filePath cStringUsingEncoding:NSUTF8StringEncoding]);
    gridfs_destroy(gfs);

    return YES;
}

@end
