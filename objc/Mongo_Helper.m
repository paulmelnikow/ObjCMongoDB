//
//  Mongo_Helper.m
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Mongo_Helper.h"


NSString * nameOrDescForMongoErrorCode(mongo_error_t err, BOOL description) {
    NSString *name = nil;
    NSString *desc = nil;
    switch(err) {
        case MONGO_CONN_SUCCESS:
            name = @"MONGO_CONN_SUCCESS";
            desc = @"Connection success!";
            break;
        case MONGO_CONN_NO_SOCKET:
            name = @"MONGO_CONN_NO_SOCKET";
            desc = @"Could not create a socket";
            break;
        case MONGO_CONN_FAIL:
            name = @"MONGO_CONN_FAIL";
            desc = @"An error occurred while calling connect()";
            break;
        case MONGO_CONN_ADDR_FAIL:
            name = @"MONGO_CONN_ADDR_FAIL";
            desc = @"An error occured while calling getaddrinfo()";
            break;
        case MONGO_CONN_NOT_MASTER:
            name = @"MONGO_CONN_NOT_MASTER";
            desc = @"Warning: connected to a non-master node (read-only)";
            break;
        case MONGO_CONN_BAD_SET_NAME:
            name = @"MONGO_CONN_BAD_SET_NAME";
            desc = @"Given rs name doesn't match this replica set";
            break;
        case MONGO_CONN_NO_PRIMARY:
            name = @"MONGO_CONN_NO_PRIMARY";
            desc = @"Can't find primary in replica set. Connection closed.";
            break;
        case MONGO_IO_ERROR:
            name = @"MONGO_IO_ERROR";
            desc = @"An error occurred while reading or writing on socket";
            break;
        case MONGO_READ_SIZE_ERROR:
            name = @"MONGO_READ_SIZE_ERROR";
            desc = @"The response is not the expected length";
            break;
        case MONGO_COMMAND_FAILED:
            name = @"MONGO_COMMAND_FAILED";
            desc = @"The command returned with 'ok' value of 0";
            break;
        case MONGO_BSON_INVALID:
            name = @"MONGO_BSON_INVALID";
            desc = @"BSON not valid for the specified op";
            break;
        case MONGO_BSON_NOT_FINISHED:
            name = @"MONGO_BSON_NOT_FINISHED";
            desc = @"BSON object has not been finished";
            break;
    }
    NSString *result = description ? desc : name;
#if __has_feature(objc_arc)
    return result;
#else
    return [result autorelease];
#endif
}

NSString * nameOrDescForMongoCursorErrorCode(mongo_cursor_error_t err, BOOL description) {
    NSString *name = nil;
    NSString *desc = nil;
    switch(err) {
        case MONGO_CURSOR_EXHAUSTED:
            name = @"MONGO_CURSOR_EXHAUSTED";
            desc = @"The cursor has no more results";
            break;
        case MONGO_CURSOR_INVALID:
            name = @"MONGO_CURSOR_INVALID";
            desc = @"The cursor has timed out or is not recognized";
            break;
        case MONGO_CURSOR_PENDING:
            name = @"MONGO_CURSOR_PENDING";
            desc = @"Tailable cursor still alive but no data";
            break;
        case MONGO_CURSOR_QUERY_FAIL:
            name = @"MONGO_CURSOR_QUERY_FAIL";
            desc = @"The server returned an '$err' object, indicating query failure. See conn->lasterrcode and conn->lasterrstr for details.";
            break;
        case MONGO_CURSOR_BSON_ERROR:
            name = @"MONGO_CURSOR_BSON_ERROR";
            desc = @"Something is wrong with the BSON provided. See conn->err for details.";
            break;            
    }
    NSString *result = description ? desc : name;
#if __has_feature(objc_arc)
    return result;
#else
    return [result autorelease];
#endif
}

NSString * NSStringFromMongoErrorCode(mongo_error_t err) {
    return nameOrDescForMongoErrorCode(err, 0);
}

NSString * MongoErrorCodeDescription(mongo_error_t err) {
    return nameOrDescForMongoErrorCode(err, 1);
}

NSString * NSStringFromMongoCursorErrorCode(mongo_cursor_error_t err) {
    return nameOrDescForMongoCursorErrorCode(err, 0);
}

NSString * MongoCursorErrorCodeDescription(mongo_cursor_error_t err) {
    return nameOrDescForMongoCursorErrorCode(err, 1);
}