//
//  main.m
//  test2
//
//  Created by Paul Melnikow on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BSONArchiver.h"
#import "BSONDocument.h"

int main (int argc, const char * argv[])
{

    @autoreleasepool {
        NSDictionary *sample = [NSDictionary dictionaryWithObjectsAndKeys:
                     [NSNumber numberWithInt:1], @"one",
                     [NSNumber numberWithDouble:2.0], @"two",
                     @"3", @"three",
                     [NSArray arrayWithObjects:@"zero", @"one", @"two", @"three", nil], @"four",
                     nil];
        
        BSONArchiver *archiver = [BSONArchiver archiver];
        [sample encodeWithCoder:archiver];
        
        BSONDocument *document = [archiver BSONDocument];
        [document dump];
    }
    return 0;
}

