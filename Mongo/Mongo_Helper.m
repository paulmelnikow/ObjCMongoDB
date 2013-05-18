//
//  Mongo_Helper.m
//  ObjCMongoDB
//
//  Copyright 2012 Paul Melnikow and other contributors
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "Mongo_Helper.h"
#import "BSON_Helper.h"

#define mongo_error_case(typeParam, descParam) \
    case typeParam: \
        name = NSStringize(typeParam);  \
        desc = descParam; \
    break;

__autoreleasing NSString * nameOrDescForMongoErrorCode(mongo_error_t err, BOOL description);
__autoreleasing NSString * nameOrDescForMongoErrorCode(mongo_error_t err, BOOL description) {
    NSString *name = nil;
    NSString *desc = nil;
    switch(err) {
        mongo_error_case(MONGO_CONN_SUCCESS, @"Connection success!");
        mongo_error_case(MONGO_CONN_NO_SOCKET, @"Could not create a socket");
        mongo_error_case(MONGO_CONN_FAIL, @"An error occurred while calling connect()");
        mongo_error_case(MONGO_CONN_ADDR_FAIL, @"An error occured while calling getaddrinfo()");
        mongo_error_case(MONGO_CONN_NOT_MASTER, @"Warning: connected to a non-master node (read-only)");
        mongo_error_case(MONGO_CONN_BAD_SET_NAME, @"Given rs name doesn't match this replica set");
        mongo_error_case(MONGO_CONN_NO_PRIMARY, @"Can't find primary in replica set. Connection closed.");
        mongo_error_case(MONGO_IO_ERROR, @"An error occurred while reading or writing on socket");
        mongo_error_case(MONGO_SOCKET_ERROR, @"Other socket error");
        mongo_error_case(MONGO_READ_SIZE_ERROR, @"The response is not the expected length");
        mongo_error_case(MONGO_COMMAND_FAILED, @"The command returned with 'ok' value of 0");
        mongo_error_case(MONGO_WRITE_ERROR, @"Write with given write_concern returned an error");
        mongo_error_case(MONGO_NS_INVALID, @"The name for the ns (database or collection) is invalid");
        mongo_error_case(MONGO_BSON_INVALID, @"BSON not valid for the specified op");
        mongo_error_case(MONGO_BSON_NOT_FINISHED, @"BSON object has not been finished");
        mongo_error_case(MONGO_BSON_TOO_LARGE, @"BSON object exceeds max BSON size");
        mongo_error_case(MONGO_WRITE_CONCERN_INVALID, @"Supplied write concern object is invalid");
    }
    NSString *result = description ? desc : name;
    return result;
}
__autoreleasing NSString * nameOrDescForMongoCursorErrorCode(mongo_cursor_error_t err, BOOL description);
__autoreleasing NSString * nameOrDescForMongoCursorErrorCode(mongo_cursor_error_t err, BOOL description) {
    NSString *name = nil;
    NSString *desc = nil;
    switch(err) {
        mongo_error_case(MONGO_CURSOR_EXHAUSTED, @"The cursor has no more results");
        mongo_error_case(MONGO_CURSOR_INVALID, @"The cursor has timed out or is not recognized");
        mongo_error_case(MONGO_CURSOR_PENDING, @"Tailable cursor still alive but no data");
        mongo_error_case(MONGO_CURSOR_QUERY_FAIL, @"The server returned an '$err' object, indicating query failure. See conn->lasterrcode and conn->lasterrstr for details.");
        mongo_error_case(MONGO_CURSOR_BSON_ERROR, @"Something is wrong with the BSON provided. See conn->err for details.");
    }
    NSString *result = description ? desc : name;
    return result;
}

__autoreleasing NSString * NSStringFromMongoErrorCode(mongo_error_t err) {
    return nameOrDescForMongoErrorCode(err, 0);
}

__autoreleasing NSString * MongoErrorCodeDescription(mongo_error_t err) {
    return nameOrDescForMongoErrorCode(err, 1);
}

__autoreleasing NSString * NSStringFromMongoCursorErrorCode(mongo_cursor_error_t err) {
    return nameOrDescForMongoCursorErrorCode(err, 0);
}

__autoreleasing NSString * MongoCursorErrorCodeDescription(mongo_cursor_error_t err) {
    return nameOrDescForMongoCursorErrorCode(err, 1);
}
