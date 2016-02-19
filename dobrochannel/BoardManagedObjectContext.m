//
//  BoardManagedObjectContext.m
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "BoardManagedObjectContext.h"

@interface BoardManagedObjectContext ()
@property NSDictionary *ongoingThreadData;
@property NSManagedObject *ongoingThread;
@property NSDateFormatter *dateFormatter;

@property NSMutableDictionary *postIds;
@property NSString *persistentPath;
@end @implementation BoardManagedObjectContext
@synthesize ongoingThread, ongoingThreadData;
@synthesize postIds;

- (instancetype) initWithPersistentPath:(NSString *) filePath {
    self = [super init];

    self.persistentPath = filePath;
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Board" withExtension:@"momd"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSError *e;
    [self addPersistentStore:&e];
    if (e) {
        [self clearPersistentStorage];
        [self addPersistentStore:&e];
    }

    self.postIds = [NSMutableDictionary new];
    self.parser = [BoardMarkupParser defaultParser];
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    return self;
}

- (void) addPersistentStore:(NSError **) e {
    NSArray *documentDirectories =
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                        NSUserDomainMask,
                                        YES);

    NSString *path = [[documentDirectories firstObject] stringByAppendingPathComponent:self.persistentPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:[NSData data] attributes:nil];
    }
    
    [self.persistentStoreCoordinator addPersistentStoreWithType:NSBinaryStoreType
                                                  configuration:nil
                                                            URL:[NSURL fileURLWithPath:path]
                                                        options:nil
                                                          error:e];

}

- (void) clearPersistentStorage {
    NSArray *entities = @[@"Thread", @"Post", @"Attachment", ];
    for (NSString *entity in entities) {
        for (NSManagedObject *o in [self requestEntity:entity using:nil]) {
            [self deleteObject:o];
        }
    }
    [self save:nil];
    return;
    
    NSArray *documentDirectories =
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                        NSUserDomainMask,
                                        YES);

    NSString *basePath = [[documentDirectories firstObject] stringByAppendingPathComponent:self.persistentPath];
    NSError *e;

    NSArray *suffixes = @[@"", ];
    if ([(NSPersistentStore *)[self.persistentStoreCoordinator.persistentStores firstObject] type] == NSSQLiteStoreType) {
        suffixes = @[@"", @"-shm", @"-wal"];
    }

    for (NSString *suffix in suffixes) {
        NSString *path = [basePath stringByAppendingString:suffix];

        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[NSFileManager defaultManager] removeItemAtPath:path error:&e];
        }

        [[NSFileManager defaultManager] createFileAtPath:path contents:[NSData data] attributes:nil];
    }

    if (e) @throw [NSException exceptionWithName:@"clearPersistentStorage error" reason:[e description] userInfo:nil];
}

- (NSString *) description {
    return [NSString stringWithFormat:@"%@(%@)", [super description], self.persistentPath];
}

- (void) didReceivedThread:(NSDictionary *)thread {
    if (thread[@"code"])
        return;

    self.ongoingThreadData = thread;
    self.ongoingThread = nil;
}

- (void) didReceivedPost:(NSDictionary *) _post {
    NSMutableDictionary *post = [_post mutableCopy];

    if (_post[@"code"]) {
        NSManagedObject *errorMessage = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:self];
        [errorMessage setValue:[self.parser parse:_post[@"message"]] forKey:@"attributedMessage"];
        [self.delegate context:self didInsertedObject:errorMessage];
        return;
    } else if ([[UserDefaults listOfBannedPosts] containsObject:_post[@"display_id"]]) {
        return;
    } else if ([[UserDefaults listOfBannedPosts] containsObject:self.ongoingThreadData[@"display_id"]]) {
        return;
    }

    NSManagedObject *threadObject = self.ongoingThread;
    BOOL setupOpPost = NO;

    if (!threadObject && self.ongoingThreadData) {
        NSDictionary *thread = self.ongoingThreadData;
        threadObject = [NSEntityDescription insertNewObjectForEntityForName:@"Thread" inManagedObjectContext:self];

        [threadObject setValuesForKeysWithDictionary:@{
                                                       @"identifier": thread[@"thread_id"],
                                                       @"display_identifier": thread[@"display_id"],
                                                       @"date": thread[@"last_modified"],
                                                       @"title": thread[@"title"],
                                                       @"posts_count": thread[@"posts_count"] ? thread[@"posts_count"] : @0,
                                                       }];

        self.ongoingThread = threadObject;
        setupOpPost = YES;
    }


    if (post[@"message"] == [NSNull null])
        post[@"message"] = @"";
    // @TODO: appropriate fix

    NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:self];

    [object setValue:@"" forKey:@"answers"];
    NSAttributedString *message = [self.parser parse:post[@"message"]];
    [object setValue:message forKey:@"attributedMessage"];

    if (message.length) {
        NSRange range = NSRangeFromString(message.string);
        NSString *prefix = @"dobrochannel://";
        [[message attributesAtIndex:0 effectiveRange:&range] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if (key == NSLinkAttributeName && [[(NSURL *) obj absoluteString] hasPrefix:prefix]) {
                NSString *absoluteString = [(NSURL *) obj absoluteString];
                NSString *stringIdentifier = [absoluteString substringFromIndex:prefix.length];
                NSNumber *identifier = [NSNumber numberWithInteger:stringIdentifier.integerValue];
                NSManagedObjectID *oid = self.postIds[identifier];

                if (oid) {
                    NSManagedObject *linkedPost = [self objectWithID:oid];
                    NSString *oldString = [linkedPost valueForKey:@"answers"];
                    [linkedPost setValue:[oldString stringByAppendingString:[NSString stringWithFormat:@",%@", post[@"display_id"]]]
                                  forKey:@"answers"];
                }
            }
        }];
    }

    [object setValue:post[@"post_id"] forKey:@"identifier"];
    [object setValue:post[@"display_id"] forKey:@"display_identifier"];
    [object setValue:post[@"post_id"] forKey:@"identifier"];
    [object setValue:[self.dateFormatter dateFromString:post[@"date"]] forKey:@"date"];
    [object setValue:post[@"op"] forKey:@"is_op"];

    for (NSDictionary *attachData in post[@"files"]) {
        NSManagedObject *attachment;
        NSInteger rating_int = -1;

        attachment = [NSEntityDescription insertNewObjectForEntityForName:@"Attachment"
                                                   inManagedObjectContext:self];
        [attachment setValue:object forKey:@"post"];

        // sizes
        CGSize thumb_size = CGSizeMake(((NSNumber *) attachData[@"thumb_width"]).integerValue,
                                       ((NSNumber *) attachData[@"thumb_height"]).integerValue);
        CGSize meta_size = CGSizeMake(0, 0);
        if ([attachData[@"type"] isEqualToString:@"image"]) {
            meta_size = CGSizeMake(((NSNumber *) attachData[@"metadata"][@"width"]).integerValue,
                                          ((NSNumber *) attachData[@"metadata"][@"height"]).integerValue);
        }

        // rating
        NSArray *ratingsList = [[BoardAPI api] ratingsList];
        if ([ratingsList containsObject:attachData[@"rating"]]) {
            rating_int = [ratingsList indexOfObject:attachData[@"rating"]];
        }

        [attachment setValuesForKeysWithDictionary:@{@"type": attachData[@"type"],
                                                     @"weight": attachData[@"size"],
                                                     @"thumb_src": attachData[@"thumb"],
                                                     @"identifier": attachData[@"file_id"],

                                                     @"size": [NSValue valueWithCGSize:meta_size],
                                                     @"rating": [NSNumber numberWithInt:rating_int],
                                                     @"thumb_size": [NSValue valueWithCGSize:thumb_size],
                                                     @"src": attachData[@"src"], }];
    }

    [object setValue:threadObject forKey:@"thread"];

    if (setupOpPost) {
        [threadObject setValue:object forKey:@"op_post"];

        [self.delegate context:self didInsertedObject:threadObject];
    }

    [self.delegate context:self didInsertedObject:object];
    self.postIds[[object valueForKey:@"display_identifier"]] = object.objectID;
}

- (void) didFinishedReceivingWithError:(NSError *)error {
    NSError *e;
    [self save:&e];
    if (e) {
        NSLog(@"%@", e);
    }

    // update postIds cache with permanent objectID's
    NSFetchRequest *r = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
    for (NSManagedObject *post in [self executeFetchRequest:r error:nil]) {
        postIds[[post valueForKey:@"display_identifier"]] = post.objectID;
    }

    [self.delegate context:self didFinishedLoading:error];
}

# pragma mark requests

- (NSArray *) requestEntity:(NSString *) entity using:(NSPredicate *) pred {
    NSFetchRequest *r = [NSFetchRequest fetchRequestWithEntityName:entity];
//    r.returnsObjectsAsFaults = NO;
    r.predicate = pred;

    NSError *e;
    NSArray *result = [self executeFetchRequest:r error:&e];
    if (e) {
        @throw [NSException exceptionWithName:@"context request error" reason:[e description] userInfo:nil];
    }

    return result;
}

- (NSArray *) requestThreads {
    NSArray *result = [self requestEntity:@"Thread" using:nil];
    return [result sortedArrayUsingComparator:^NSComparisonResult(id  obj1, id  obj2) {
        return [[obj2 valueForKey:@"date"] compare:[obj1 valueForKey:@"date"]];
    }];
}

- (NSArray *) requestPostsFrom:(NSManagedObject *)thread {
    NSArray *result = [self requestEntity:@"Post" using:[NSPredicate predicateWithFormat:@"thread == %@", thread]];
    return [result sortedArrayUsingComparator:^NSComparisonResult(id  obj1, id  obj2) {
        return [[obj1 valueForKey:@"date"] compare:[obj2 valueForKey:@"date"]];
    }];
}

- (NSArray *) requestAttachmentsFor:(NSManagedObject *)entry {
    if ([entry.entity.name isEqualToString:@"Thread"])
        entry = [entry valueForKey:@"op_post"];

    NSArray *result = [self requestEntity:@"Attachment" using:[NSPredicate predicateWithFormat:@"post == %@", entry]];
    return [result sortedArrayUsingComparator:^NSComparisonResult(id  obj1, id  obj2) {
        return [[obj1 valueForKey:@"identifier"] compare:[obj2 valueForKey:@"identifier"]];
    }];
}

- (NSArray *) requestAttachmentsForThread:(NSNumber *)display_identifier {
    NSArray *result = [self requestEntity:@"Attachment" using:[NSPredicate predicateWithFormat:@"post.thread.display_identifier == %@", display_identifier]];

    NSMutableArray *uniqueIds = [NSMutableArray new];
    NSMutableArray *uniqueResult = [NSMutableArray new];

    for (NSManagedObject *attachment in result) {
        if (![uniqueIds containsObject:[attachment valueForKey:@"identifier"]]) {
            [uniqueIds addObject:[attachment valueForKey:@"identifier"]];
            [uniqueResult addObject:attachment];
        }
    }

    return [uniqueResult sortedArrayUsingComparator:^NSComparisonResult(id  obj1, id  obj2) {
        return [[obj1 valueForKeyPath:@"post.date"] compare:[obj2 valueForKeyPath:@"post.date"]];
    }];
}

# pragma mark caching & persistance

- (NSManagedObject *) postObjectForDisplayId:(NSNumber *)_id {
    NSManagedObjectID *i = self.postIds[_id];
    if (i) {
        return [self objectWithID:i];
    } else {
        return nil;
    }
}

# pragma mark state restoration

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    NSString *persistentPath = [aDecoder decodeObjectForKey:@"persistentPath"];
    self = [self initWithPersistentPath:persistentPath];

    NSMutableDictionary *postURIs = [aDecoder decodeObjectForKey:@"postURIs"];
    [postURIs enumerateKeysAndObjectsUsingBlock:^(id  key, id  obj, BOOL * stop) {
        NSManagedObjectID *i = [self.persistentStoreCoordinator managedObjectIDForURIRepresentation:obj];
        
        if (i)
            self.postIds[key] = i;
    }];
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    NSMutableDictionary *postIdsURLs = [NSMutableDictionary new];
    [self.postIds enumerateKeysAndObjectsUsingBlock:^(NSNumber * key, NSManagedObjectID * obj, BOOL * stop) {
        postIdsURLs[key] = [obj URIRepresentation];
    }];
    [aCoder encodeObject:postIdsURLs forKey:@"postURIs"];
    [aCoder encodeObject:self.persistentPath forKey:@"persistentPath"];
}

@end