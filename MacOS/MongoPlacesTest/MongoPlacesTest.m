#import <Foundation/Foundation.h>
#import <NuMongoDB/NuMongoDB.h>

static BOOL always_rebuild = YES;

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NuMongoDB *mongo = [NuMongoDB new];
    
    // connect to a local database
    NSDictionary *HOSTINFO = [NSDictionary dictionary];
    [mongo connectWithOptions:HOSTINFO];
      
    int count = [mongo countWithCondition:nil
                             inCollection:@"places" 
                               inDatabase:@"sample"];
    
    NSLog(@"number of places in database: %d", count);
    
    if ((count == 0) || always_rebuild) {
        NSLog(@"rebuilding");
        // rebuild the place database
        [mongo dropCollection:@"places" inDatabase:@"sample"];
        const int N = 500;
        for (int i = 0; i < N; i++) {
            for (int j = 0; j < N; j++) {
                float latitude = (random() % 180000) / 1000.0;
                float longitude = (random() % 180000) / 1000.0;
                NSMutableDictionary *place = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                              [NSString stringWithFormat:@"location-%d-%d", i, j], @"name",
                                              [NSDictionary dictionaryWithObjectsAndKeys:
                                               [NSNumber numberWithFloat:latitude], @"latitude",
                                               [NSNumber numberWithFloat:longitude], @"longitude",
                                               nil], @"location",
                                              nil];
                [mongo insertObject:place intoCollection:@"sample.places"];
            }
        }
        count = [mongo countWithCondition:nil
                             inCollection:@"places" 
                               inDatabase:@"sample"];
        
        NSLog(@"number of places in database: %d", count);
    }
    
    [mongo ensureCollection:@"sample.places" 
                   hasIndex:[NSDictionary dictionaryWithObjectsAndKeys:
                             @"2d", @"location",
                             nil]
                withOptions:0];
    
    // search the place database
    NSLog(@"querying");    
    NuMongoDBCursor *cursor = [mongo find:
                               [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithFloat:90.0], @"latitude",
                                  [NSNumber numberWithFloat:90.0], @"longitude",
                                  nil], @"$near",
                                 nil], @"location",
                                nil]
                             inCollection:@"sample.places"];
    int i = 0;
    while ([cursor next] && (i < 3)) {
        id object = [cursor currentObject];
        NSLog(@"%@", [object description]);
        i++;
    }
    
    [pool drain];
    return 0;
}
