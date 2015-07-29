//
//  BoardManagedObjectContext.m
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "BoardManagedObjectContext.h"

@interface BoardManagedObjectContext ()
@property NSDictionary *unfinishedThread;
@end @implementation BoardManagedObjectContext

- (instancetype) init {
    self = [super init];

    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Board" withExtension:@"momd"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

    NSError *error;
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    [coordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
    self.persistentStoreCoordinator = coordinator;

    return self;
}


- (void) didReceivedThread:(NSDictionary *)thread {
    self.unfinishedThread = thread;
}


- (void) didReceivedPost:(NSDictionary *) post {
    NSManagedObject *threadObject;
    if (self.unfinishedThread) {
        NSDictionary *thread = self.unfinishedThread;

        threadObject = [NSEntityDescription insertNewObjectForEntityForName:@"Thread" inManagedObjectContext:self];

        [threadObject setValue:thread[@"display_id"] forKey:@"identifier"];
        [threadObject setValue:thread[@"title"] forKey:@"title"];
        [threadObject setValue:thread[@"date"] forKey:@"date"];
        [threadObject setValue:thread[@"display_id"] forKey:@"display_identifier"];
    }

    NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:self];

    [object setValue:post[@"message"] forKey:@"message"];
    [object setValue:post[@"display_id"] forKey:@"display_identifier"];
    [object setValue:post[@"date"] forKey:@"date"];
    [object setValue:post[@"op"] forKey:@"is_op"];

    if ([post[@"display_id"] isEqualToNumber:[NSNumber numberWithInt:68234]])
        NSLog(@"FUCK YOU\n\n\n");
    NSMutableArray *postAttachments = [NSMutableArray new];
    for (NSDictionary *attachData in post[@"files"]) {
        NSManagedObject *attachment;
        NSInteger rating_int = -1;

        if ([attachData[@"type"] isEqualToString:@"image"]) {
            attachment = [NSEntityDescription insertNewObjectForEntityForName:@"Image"
                                                       inManagedObjectContext:self];

            [attachment setValue:attachData[@"size"] forKey:@"weight"];
            [attachment setValue:attachData[@"thumb"] forKey:@"thumb_src"];


            CGSize thumb_size = CGSizeMake(((NSNumber *) attachData[@"thumb_width"]).integerValue,
                                           ((NSNumber *) attachData[@"thumb_height"]).integerValue);

            CGSize meta_size = CGSizeMake(((NSNumber *) attachData[@"metadata"][@"width"]).integerValue,
                                           ((NSNumber *) attachData[@"metadata"][@"height"]).integerValue);

            [attachment setValue:[NSValue valueWithCGSize:meta_size]
                          forKey:@"size"];
            [attachment setValue:[NSValue valueWithCGSize:thumb_size]
                          forKey:@"thumb_size"];

            NSArray *ratingsList = [[BoardAPI api] ratingsList];

            if ([ratingsList containsObject:attachData[@"rating"]])
                rating_int = [ratingsList indexOfObject:attachData[@"rating"]];
            [attachment setValue:[NSNumber numberWithInt:rating_int]
                          forKey:@"rating"];
        }

        if (attachment && rating_int <= [UserDefaults maxRating] && ([UserDefaults showUnrated] || rating_int != -1)) {
            [attachment setValue:attachData[@"src"] forKey:@"src"];
            [attachment setValue:object forKey:@"post"];

            [postAttachments addObject:attachment];
        }
    }

    [object setValue:postAttachments forKey:@"attachments"];

    if (self.unfinishedThread) {
        [threadObject setValue:object forKey:@"op_post"];

        self.unfinishedThread = nil;
    }

    [self save:nil];
}

@end
