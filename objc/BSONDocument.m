//
//  BSONDocument.m
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BSONDocument.h"
#import "bson.h"

@implementation BSONDocument

-(BSONDocument *)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (BSONDocument *) initWithData:(NSData *)data {
    self = [super init];
    if (self) {
        _source = data;
        bson_init(&bsonValue, (char *) data.bytes, NO);
    }
    return self;
}

- (void) dealloc {
    bson_destroy(&bsonValue);
}

//+ (void) dumpBSONIterator:(bson_iterator)it indent:(const char *)indent {
//    bson_iterator it2;
//    bson subobject;
//    
//    char more_indent[2000];
//    sprintf(more_indent, "  %s", indent);
//    
//    while(bson_iterator_next(&it)) {
//        fprintf(stderr, "%s  %s: ", indent, bson_iterator_key(&it));
//        char hex_oid[25];
//        
//        switch(bson_iterator_type(&it)) {
//            case bson_double:
//                fprintf(stderr, "(double) %e\n", bson_iterator_double(&it));
//                break;
//            case bson_int:
//                fprintf(stderr, "(int) %d\n", bson_iterator_int(&it));
//                break;
//            case bson_string:
//            {                    
//                fprintf(stderr, "(string) \"%s\"\n", bson_iterator_string(&it));
//            }
//                break;
//            case bson_oid:
//                bson_oid_to_string(bson_iterator_oid(&it), hex_oid);
//                fprintf(stderr, "(oid) \"%s\"\n", hex_oid);
//                break;
//            case bson_object:
//                fprintf(stderr, "(subobject) {...}\n");
//                bson_iterator_subobject(&it, &subobject);
//                bson_iterator_init(&it2, subobject.data);
//                [self dumpBSONIterator:it2 indent:more_indent];
//                break;
//            case bson_array:
//                fprintf(stderr, "(array) [...]\n");
//                bson_iterator_subobject(&it, &subobject);
//                bson_iterator_init(&it2, subobject.data);
//                [self dumpBSONIterator:it2 indent:more_indent];
//                break;
//            default:
//                fprintf(stderr, "(type %d)\n", bson_iterator_type(&it));
//                break;
//        }
//    }
//}
//
//- (void) dump {
//    bson_iterator it;
//    bson_iterator_init(&it, bsonValue.data);
//    [BSONDocument dumpBSONIterator:it indent:""];
//    fprintf(stderr, "\n");
//}

- (NSData *) dataValue {
    return [[[NSData alloc]
             initWithBytes:(bsonValue.data)
             length:bson_size(&(bsonValue))] autorelease];
}

- (BOOL) isEqual:(id)object {
    NSData *objectData = nil;
    if ([object isKindOfClass:[NSData class]])
        objectData = object;
    else if ([object isKindOfClass:[BSONDocument class]])
        objectData = [object dataValue];
    return [objectData isEqualToData:[self dataValue]];
}

@end