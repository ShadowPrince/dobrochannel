//
//  ThreadViewController.m
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "ThreadViewController.h"

// @TODO: nested thread view controllers memleak

@interface ThreadViewController ()
@property NSManagedObject *lastPost;
@property BOOL scrollToNew;
@property BOOL loadThread;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *favoriteBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *attachmentsViewBarButtonItem;
@end @implementation ThreadViewController
@synthesize scrollToNew, loadThread;

- (void) viewDidLoad {
    [super viewDidLoad];
    self.loadThread = YES;
    self.favoriteBarButtonItem.enabled = NO;

    if (![[NSUserDefaults standardUserDefaults] valueForKey:@"secret"] && ![UserDefaults enhanced]) {
        self.attachmentsViewBarButtonItem.enabled = NO;
    }
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [ThreadHiderViewController resetThreadHiderStatistics];
    if (self.loadThread) {
        [self reset];
        [self.api requestThread:self.identifier from:self.board stateCallback:progressCallback];
        self.loadThread = NO;
    } else {
    }
}

#pragma mark segues

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"2newPost"] && ![sender isKindOfClass:[NSManagedObject class]]) {
        NewPostViewController *controller = segue.destinationViewController;
        controller.board = self.board;
        controller.thread_identifier = self.identifier;
    } else if ([segue.identifier isEqualToString:@"2attachmentsView"]) {
        ThreadAttachmentsViewController *controller = segue.destinationViewController;
        controller.attachments = [self.context requestAttachmentsForThread:self.identifier];
    } else {
        [super prepareForSegue:segue sender:sender];
    }
}

- (IBAction) unwindFromNewPost:(UIStoryboardSegue *)sender {
    [self refreshAction:nil];
}

# pragma mark context

- (NSManagedObjectContext *) createContext {
    return [[BoardManagedObjectContext alloc] initWithPersistentPath:@"thread.data"];
}

- (void) didInsertObject:(NSManagedObject *)object {
    if ([object.entity.name isEqualToString:@"Thread"]) {
        self.navigationItem.title = [object valueForKey:@"title"];
        self.favoriteBarButtonItem.enabled = ![FavoritesViewController checkThreadFavorited:[object valueForKey:@"display_identifier"]];
    } else if ([object.entity.name isEqualToString:@"Post"]) {
        self.lastPost = object;

        if (self.scrollToNew) {
            [self scrollTo:object animated:YES];
            self.scrollToNew = NO;
        }
    }
}

- (void) insetObject:(NSManagedObject *)object {
    [super insetObject:object];

    [self insertNewRows];
}

# pragma mark actions

- (IBAction)favoriteAction:(id)sender {
    [FavoritesViewController favoriteThread:self.identifier board:self.board title:self.navigationItem.title];
    self.favoriteBarButtonItem.enabled = NO;
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

# pragma mark state restoration

- (void) decodeRestorableStateWithCoder:(nonnull NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];

    self.board = [coder decodeObjectForKey:@"board"];
    self.identifier = [coder decodeObjectForKey:@"identifier"];
    self.loadThread = NO;
    progressCallback(-1, -1);
}

- (void) encodeRestorableStateWithCoder:(nonnull NSCoder *)aCoder {
    [super encodeRestorableStateWithCoder:aCoder];

    [aCoder encodeObject:self.identifier forKey:@"identifier"];
    [aCoder encodeObject:self.board forKey:@"board"];
}

@end