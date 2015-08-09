//
//  ThreadViewController.m
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "ThreadViewController.h"

@interface ThreadViewController ()
@property NSManagedObject *lastPost;
@property BOOL scrollToNew;
@property BOOL loadThread;
@end @implementation ThreadViewController
@synthesize identifier;
@synthesize scrollToNew, loadThread;

- (void) viewDidLoad {
    [super viewDidLoad];
    self.loadThread = YES;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.loadThread) {
        [self reset];
        [self.api requestThread:self.identifier from:self.board stateCallback:progressCallback];
        self.loadThread = NO;
    }
}

- (NSManagedObjectContext *) createContext {
    return [[BoardManagedObjectContext alloc] initWithPersistentPath:@"thread.data"];
}

- (void) didInsertObject:(NSManagedObject *)object {
    if ([object.entity.name isEqualToString:@"Thread"]) {
        self.navigationItem.title = [object valueForKey:@"title"];
    } else if ([object.entity.name isEqualToString:@"Post"]) {
        self.lastPost = object;

        if (self.scrollToNew) {
            [self scrollTo:object animated:YES];
            self.scrollToNew = NO;
        }
    }
}

- (BOOL) shouldInsertObject:(NSManagedObject *)object {
    return self.lastPost ? [object.entity.name isEqualToString:@"Post"] : [super shouldInsertObject:object];
}

- (IBAction)refreshAction:(id)sender {
    if (![self.api isRequesting]) {
        [self startedRequest];
        self.scrollToNew = YES;
        [self.api requestNewPostsFrom:self.identifier
                                   at:self.board
                                after:[self.lastPost valueForKey:@"display_identifier"]
                        stateCallback:progressCallback];
    }
}

- (void) decodeRestorableStateWithCoder:(nonnull NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];

    self.board = [coder decodeObjectForKey:@"board"];
    self.identifier = [coder decodeObjectForKey:@"identifier"];
    self.loadThread = NO;
    progressCallback(1, 1);
}

- (void) encodeRestorableStateWithCoder:(nonnull NSCoder *)aCoder {
    [super encodeRestorableStateWithCoder:aCoder];

    [aCoder encodeObject:self.identifier forKey:@"identifier"];
    [aCoder encodeObject:self.board forKey:@"board"];
}

@end
