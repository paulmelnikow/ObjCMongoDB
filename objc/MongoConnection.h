//
//  MongoDB.h
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

#import <Foundation/Foundation.h>
#import "MongoDBCollection.h"
#import "mongo.h"

extern NSString * const MongoDBObjectIDKey;
extern const char * const MongoDBObjectIDBSONKey;

/**
 Encapsulates a Mongo connection object.
 */
@interface MongoConnection : NSObject {
@private
    mongo *_conn;
}

- (BOOL) connectToServer:(NSString *) hostWithPort error:(NSError **) error;
- (BOOL) connectToReplicaSet:(NSString *) replicaSet seed:(NSArray *) seed error:(NSError **) error;
- (BOOL) checkConnectionWithError:(NSError **) error;
- (BOOL) reconnectWithError:(NSError **) error;
- (void) disconnect;

- (MongoDBCollection *) collection:(NSString *) name;

- (BOOL) dropDatabase:(NSString *) database;
//- (BOOL) dropCollection:(MongoDBNamespace *) collection;

- (NSError *) error;

@end
