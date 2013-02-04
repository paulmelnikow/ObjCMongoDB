//
//  NSData+BSONAdditions.m
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 2/3/13.
//
//

#import "NSData+BSONAdditions.h"

@implementation NSData (BSONAdditions)

+ (NSData *) dataWithNativeBSONObject:(const bson *) bson copy:(BOOL) copy {
    if (!bson) return nil;
    void *bytes = (void *)bson_data(bson);
    int size = bson_size(bson);
    if (copy)
        return [NSData dataWithBytes:bytes length:size];
    else
        return [NSData dataWithBytesNoCopy:bytes length:size freeWhenDone:NO];    
}

@end
