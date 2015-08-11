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

@property NSMutableDictionary<NSNumber *, NSManagedObjectID *> *postIds;
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
    return self;
}

- (void) addPersistentStore:(NSError **) e {
    NSArray *documentDirectories =
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                        NSUserDomainMask,
                                        YES);

    NSString *path = [[documentDirectories firstObject] stringByAppendingPathComponent:self.persistentPath];
    [self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                  configuration:nil
                                                            URL:[NSURL fileURLWithPath:path]
                                                        options:nil
                                                          error:e];
}

- (instancetype) init {
    return [self initWithPersistentPath:@"store.data"];
}

- (void) didReceivedThread:(NSDictionary *)thread {
    if (thread[@"code"])
        return;

    self.ongoingThreadData = thread;
    self.ongoingThread = nil;
}

- (void) didReceivedPost:(NSDictionary *) _post {
    if (_post[@"code"]) {
        NSManagedObject *errorMessage = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:self];
        [errorMessage setValue:_post[@"message"] forKey:@"message"];
        [self.delegate context:self didInsertedObject:errorMessage];
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

    NSMutableDictionary *post = [_post mutableCopy];

    if (post[@"message"] == [NSNull null])
        post[@"message"] = @"";
    // @TODO: appropriate fix

    NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:self];

    [object setValue:post[@"message"] forKey:@"message"];
    [object setValue:post[@"post_id"] forKey:@"identifier"];
    [object setValue:post[@"display_id"] forKey:@"display_identifier"];
    [object setValue:post[@"post_id"] forKey:@"identifier"];
    [object setValue:post[@"date"] forKey:@"date"];
    [object setValue:post[@"op"] forKey:@"is_op"];

    for (NSDictionary *attachData in post[@"files"]) {
        NSManagedObject *attachment;
        NSInteger rating_int = -1;

        attachment = [NSEntityDescription insertNewObjectForEntityForName:@"Attachment"
                                                   inManagedObjectContext:self];

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
                                                     @"thumb_size": [NSValue valueWithCGSize:thumb_size],
                                                     @"size": [NSValue valueWithCGSize:meta_size],
                                                     @"rating": [NSNumber numberWithInt:rating_int],
                                                     @"src": attachData[@"src"],
                                                     @"post": object, }];
    }

    [object setValue:threadObject forKey:@"thread"];

    if (setupOpPost) {
        [threadObject setValue:object forKey:@"op_post"];

        [self.delegate context:self didInsertedObject:threadObject];
    }

    [self.delegate context:self didInsertedObject:object];
    self.postIds[[object valueForKey:@"display_identifier"]] = object.objectID;
}

- (void) didFinishedReceiving {
    [self save:nil];

    // update postIds cache with permanent objectID's
    NSFetchRequest *r = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
    for (NSManagedObject *post in [self executeFetchRequest:r error:nil]) {
        postIds[[post valueForKey:@"display_identifier"]] = post.objectID;
    }
}

# pragma mark requests

- (NSArray *) requestEntity:(NSString *) entity using:(NSPredicate *) pred {
    NSFetchRequest *r = [NSFetchRequest fetchRequestWithEntityName:entity];
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
    return [result sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [[obj2 valueForKey:@"date"] compare:[obj1 valueForKey:@"date"]];
    }];
}

- (NSArray *) requestPostsFrom:(NSManagedObject *)thread {
    NSArray *result = [self requestEntity:@"Post" using:[NSPredicate predicateWithFormat:@"thread == %@", thread]];
    return [result sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [[obj1 valueForKey:@"date"] compare:[obj2 valueForKey:@"date"]];
    }];
}

- (NSArray *) requestAttachmentsFor:(NSManagedObject *)entry {
    if ([entry.entity.name isEqualToString:@"Thread"])
        entry = [entry valueForKey:@"op_post"];

    NSArray *result = [self requestEntity:@"Attachment" using:[NSPredicate predicateWithFormat:@"post == %@", entry]];
    return [result sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [[obj1 valueForKey:@"identifier"] compare:[obj2 valueForKey:@"identifier"]];
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

- (void) clearPersistentStorage {
    NSArray *documentDirectories =
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                        NSUserDomainMask,
                                        YES);

    NSString *path = [[documentDirectories firstObject] stringByAppendingPathComponent:self.persistentPath];
    NSURL *dbUrl = [NSURL URLWithString:path];
    NSError *e;

    for (NSString *suff in @[@"", @"-shm", @"-wal"]) {
        NSString *path = [[dbUrl path] stringByAppendingString:suff];

        [[NSFileManager defaultManager] removeItemAtPath:path error:&e];
        if (e) @throw [NSException exceptionWithName:@"clearPersistentStorage error" reason:[e description] userInfo:nil];
    }
}

# pragma mark state restoration

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    NSString *persistentPath = [aDecoder decodeObjectForKey:@"persistentPath"];
    self = [self initWithPersistentPath:persistentPath];

    NSMutableDictionary *postURIs = [aDecoder decodeObjectForKey:@"postURIs"];
    [postURIs enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        self.postIds[key] = [self.persistentStoreCoordinator managedObjectIDForURIRepresentation:obj];
    }];
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    NSMutableDictionary<NSNumber *, NSURL *> *postIdsURLs = [NSMutableDictionary new];
    [self.postIds enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSManagedObjectID * _Nonnull obj, BOOL * _Nonnull stop) {
        postIdsURLs[key] = [obj URIRepresentation];
    }];
    [aCoder encodeObject:postIdsURLs forKey:@"postURIs"];
    [aCoder encodeObject:self.persistentPath forKey:@"persistentPath"];
}

@end
