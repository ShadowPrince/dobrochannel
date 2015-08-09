//
//  BoardManagedObjectContext.m
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "BoardManagedObjectContext.h"

//@TODO: postIds state restoration

@interface BoardManagedObjectContext ()
@property NSDictionary *ongoingThreadData;
@property NSManagedObject *ongoingThread;
@property NSMutableDictionary<NSNumber *, NSManagedObjectID *> *postIds;
@end @implementation BoardManagedObjectContext
@synthesize ongoingThread, ongoingThreadData;
@synthesize postIds;

- (instancetype) initWithPersistentPath:(NSString *) filePath {
    self = [super init];

    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Board" withExtension:@"momd"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

    NSError *error;
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

    NSArray *documentDirectories =
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                        NSUserDomainMask,
                                        YES);
    NSString *path = [[documentDirectories firstObject] stringByAppendingPathComponent:filePath];
    [coordinator addPersistentStoreWithType:NSSQLiteStoreType
                              configuration:nil
                                        URL:[NSURL fileURLWithPath:path]
                                    options:nil
                                      error:&error];

    self.persistentStoreCoordinator = coordinator;

    self.postIds = [NSMutableDictionary new];

    return self;
}

- (instancetype) init {
    return [self initWithPersistentPath:@"store.data"];
}

- (void) clearPersistentStorage {
    NSURL *dbUrl = [[[self.persistentStoreCoordinator persistentStores] firstObject] URL];
    NSError *e;

    for (NSString *suff in @[@"", @"-shm", @"-wal"]) {
        NSString *path = [[dbUrl path] stringByAppendingString:suff];

        [[NSFileManager defaultManager] removeItemAtPath:path error:&e];
        if (e) @throw [NSException exceptionWithName:@"clearPersistentStorage error" reason:[e description] userInfo:nil];
    }
}

- (void) didReceivedThread:(NSDictionary *)thread {
    self.ongoingThreadData = thread;
    self.ongoingThread = nil;
}

- (void) didReceivedPost:(NSDictionary *) _post {
    NSManagedObject *threadObject = self.ongoingThread;
    BOOL setupOpPost = NO;

    if (!threadObject) {
        NSDictionary *thread = self.ongoingThreadData;
        threadObject = [NSEntityDescription insertNewObjectForEntityForName:@"Thread" inManagedObjectContext:self];

        [threadObject setValue:thread[@"display_id"] forKey:@"identifier"];
        [threadObject setValue:thread[@"title"] forKey:@"title"];
        [threadObject setValue:thread[@"last_modified"] forKey:@"date"];
        [threadObject setValue:thread[@"display_id"] forKey:@"display_identifier"];

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

        [attachment setValue:attachData[@"type"] forKey:@"type"];
        [attachment setValue:attachData[@"size"] forKey:@"weight"];
        [attachment setValue:attachData[@"thumb"] forKey:@"thumb_src"];


        CGSize thumb_size = CGSizeMake(((NSNumber *) attachData[@"thumb_width"]).integerValue,
                                       ((NSNumber *) attachData[@"thumb_height"]).integerValue);

        [attachment setValue:[NSValue valueWithCGSize:thumb_size]
                      forKey:@"thumb_size"];

        if ([attachData[@"type"] isEqualToString:@"image"]) {
            CGSize meta_size = CGSizeMake(((NSNumber *) attachData[@"metadata"][@"width"]).integerValue,
                                          ((NSNumber *) attachData[@"metadata"][@"height"]).integerValue);

            [attachment setValue:[NSValue valueWithCGSize:meta_size]
                          forKey:@"size"];
        }

        NSArray *ratingsList = [[BoardAPI api] ratingsList];

        if ([ratingsList containsObject:attachData[@"rating"]])
            rating_int = [ratingsList indexOfObject:attachData[@"rating"]];
        [attachment setValue:[NSNumber numberWithInt:rating_int]
                      forKey:@"rating"];
        [attachment setValue:attachData[@"src"] forKey:@"src"];
        [attachment setValue:object forKey:@"post"];

        if (attachment && rating_int <= [UserDefaults maxRating] && ([UserDefaults showUnrated] || rating_int != -1)) {
            //@TODO: move it into attachmentscontroller
        }
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

- (NSManagedObject *) postObjectForDisplayId:(NSNumber *)_id {
    NSManagedObjectID *i = self.postIds[_id];
    if (i) {
        return [self objectWithID:i];
    } else {
        return nil;
    }
}

@end
