/*
 *  sample.m
 *  NuMongoDB
 *
 *  Created by Tim Burks on 7/3/10.
 *  Copyright 2010 Neon Design Technology, Inc. All rights reserved.
 *
 */
#import <NuMongoDB/NuMongoDB.h>

int main (int argc, const char * argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NuMongoDB *mongo = [NuMongoDB new];
	[mongo connectWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"127.0.0.1", @"host", nil]];
	
	NSString *collection = @"test.sample";
	
	[mongo dropCollection:@"sample" inDatabase:@"test"];
	
	id sample = [NSDictionary dictionaryWithObjectsAndKeys:
				 [NSNumber numberWithInt:1], @"one",
				 [NSNumber numberWithDouble:2.0], @"two",
				 @"3", @"three",
				 [NSArray arrayWithObjects:@"zero", @"one", @"two", @"three", nil], @"four",
				 nil];
	[mongo insertObject:sample intoCollection:collection];	
	
	id first = [mongo findOne:nil inCollection:collection];	
	NSLog(@"%@", first);
	
	for (int i = 0; i < 10; i++) {
		for (int j = 0; j < 10; j++) {
			id object = [NSDictionary dictionaryWithObjectsAndKeys:
						 [NSNumber numberWithInt:i], @"i",
						 [NSNumber numberWithInt:j], @"j",
						 [NSString stringWithFormat:@"mongo-%d-%d", i, j], @"name",
						 sample, [NSString stringWithFormat:@"key-%d-%d", i, j],
						 nil];
			[mongo insertObject:object intoCollection:collection];
		}
	}
	
	int count = [mongo countWithCondition:nil inCollection:@"sample" inDatabase:@"test"];
	NSLog(@"count %d", count);
	
	[mongo dropCollection:@"places" inDatabase:@"geo"];
	int N = 100;
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < N; j++) {
			double latitude = (random() % 180000) / 1000.0;
			double longitude = (random() % 180000) / 1000.0;
			//
			// (set place 
			//      (dict name:(+ "location-" i "-" j)
		    //            location:(dict latitude:latitude 
		    //                           longitude:longitude)))
			//
			id place = [NSDictionary dictionaryWithObjectsAndKeys:
						[NSString stringWithFormat:@"location-%d-%d", i, j], @"name",
						[NSDictionary dictionaryWithObjectsAndKeys:
						 [NSNumber numberWithDouble:latitude], @"latitude",
						 [NSNumber numberWithDouble:longitude], @"longitude",
						 nil], @"location",						
						nil];
			[mongo insertObject:place intoCollection:@"geo.places"];
		}
	}
	//
	// (mongo ensureCollection:"geo.places" 
    //        hasIndex:(dict location:"2d") 
    //        withOptions:0))
	//
	[mongo ensureCollection:@"geo.places" 
				   hasIndex:[NSDictionary dictionaryWithObjectsAndKeys:
							 @"2d", @"location", 
							 nil]
				withOptions:0];
	//
	// (set cursor 
	//      (mongo find:(dict location:(dict $near:(dict latitude:70 
    //                                                   longitude:80)))
    //             inCollection:"geo.places"))
	//
	id cursor = [mongo find:[NSDictionary dictionaryWithObjectsAndKeys:
							 [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSDictionary dictionaryWithObjectsAndKeys:
							   [NSNumber numberWithDouble:70], @"latitude",
							   [NSNumber numberWithDouble:80], @"longitude",
							   nil], @"$near",
							  nil], @"location", 
							 nil]
			   inCollection:@"geo.places"];

	int i = 0;
	while ([cursor next] && (i++ < 10)) {
		id object = [cursor currentObject];
		NSLog(@"%@", object);
	}
	
	[pool drain];
}