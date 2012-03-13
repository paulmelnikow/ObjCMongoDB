//
//  CDPerson.m
//  ObjCBSONTests
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

#import "CDPerson.h"
#import "CDPerson.h"
#import "BSONEncoder.h"

@implementation CDPerson

@dynamic name;
@dynamic dob;
@dynamic numberOfVisits;
@dynamic children;
@dynamic parent;

// Encodes parent as name
-(void)encodeRelationship:(NSRelationshipDescription *)relationship withEncoder:(id)encoder {
    NSString *key = [relationship name];
    if ([key isEqualToString:@"parent"])
        [encoder encodeString:[self.parent name] forKey:key];
    else
        [super encodeRelationship:relationship withEncoder:encoder];
}

-(void)initializeRelationship:(NSRelationshipDescription *)relationship withDecoder:(BSONDecoder *)decoder {
    if ([[relationship name] isEqualToString:@"parent"]) return;
    [super initializeRelationship:relationship withDecoder:decoder];
}

-(BOOL)isEqualForTesting:(CDPerson *) obj {
    if (![obj isKindOfClass:[CDPerson class]]) return NO;
    
    BOOL equalChildren;
    if ([self.children isEqualTo:obj.children])
        equalChildren = YES;
    else if ([self.children count] != [obj.children count])
        equalChildren = NO;
    else {
        equalChildren = YES;
        for (CDPerson *child1 in self.children) {
            BOOL foundMatch = NO;
            for (CDPerson *child2 in obj.children) {
                if ([child1 isEqualForTesting:child2]) {                    
                    foundMatch = YES;
                    break;
                }
            }
            if (!foundMatch) {
                equalChildren = NO;
                break;
            }
        }
    }

    return ((!self.name && !obj.name) || [self.name isEqualTo:obj.name])
    && ((!self.dob && !obj.dob) || [self.dob isEqualTo:obj.dob])
    && self.numberOfVisits == obj.numberOfVisits
    && equalChildren;
}

//NSString *parentName = [decoder decodeStringForKey:key];
//if (parentName) {
//    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:[[self entity] name]];
//    [req setPredicate:[NSPredicate predicateWithFormat:@"name = %@", parentName]];
//    NSArray *result = [self.managedObjectContext executeFetchRequest:req error:nil];
//    if (result && 1 == result.count)
//        self.parent = [result objectAtIndex:0];
//}

@end
