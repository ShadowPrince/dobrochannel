//
//  BoardViewController.m
//  dobrochannel
//
//  Created by shdwprince on 7/19/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "ContentViewController.h"
#import "PostViewController.h"
#import "ThreadViewController.h"
#import "NewPostViewController.h"

@interface ContentViewController ()
@property NSMutableArray *postPopups;
@property int numberOfTouches;

// table loading
@property NSMutableArray *preparedTableCells;
@property NSInteger tableLoadedRows;
@property BOOL viewChangedSize;
@property NSIndexPath *viewChangedSizeScrollTo;
@property NSMutableDictionary *rowHeightCache;
//---
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hidedProgressViewWidth;
@property (weak, nonatomic) IBOutlet UIView *hidedProgressView;
@end @implementation ContentViewController
@synthesize api, context, threads;
@synthesize board;
@synthesize cachedPostCell, cachedThreadView, tableLoadedRows, rowHeightCache, viewChangedSize;

- (instancetype) initWithCoder:(nonnull NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    self.api = [[BoardAPI alloc] init];
    [self resetReuseProperties];
    return self;
}

- (void) resetReuseProperties {
    [self.api cancelRequest];

    self.viewChangedSize = NO;
    self.preparedTableCells = [NSMutableArray new];
    self.threads = [NSMutableArray new];
    self.rowHeightCache = [NSMutableDictionary dictionary];
    self.tableLoadedRows = 0;
    [self reloadData];

    self.context = [self createContext];
    self.context.delegate = self;
    self.api.delegate = self.context;

    for (PostViewController *popup in self.postPopups) {
        [popup.view removeFromSuperview];
    }

    self.postPopups = [NSMutableArray new];
}

- (void) reset {
    [self.context clearPersistentStorage];
    [self resetReuseProperties];
}

- (NSManagedObjectContext *) createContext {
    return [[BoardManagedObjectContext alloc] initWithPersistentPath:@"store.data"];
}

- (void) startedRequest {
    self.progressView.progress = 0.001f;
    self.progressView.hidden = NO;
}

- (void) didScrollToBottom {

}

- (void) scrollTo:(NSManagedObject *) object animated:(BOOL) animated {
    [self scrollToObjectAt:[self.threads indexOfObject:object] animated:animated];
}

- (void) scrollToObjectAt:(NSUInteger)pos animated:(BOOL)animated {
    [self scrollToObjectAt:pos position:UITableViewScrollPositionTop animated:animated];
}

- (void) scrollToObjectAt:(NSUInteger) pos
                 position:(UITableViewScrollPosition) scrollPosition
                 animated:(BOOL) animated {
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:pos inSection:0]
                          atScrollPosition:scrollPosition
                                  animated:animated];
}

- (UIView *) superviewIn:(UIView *) view atPosition:(NSUInteger) pos {
    for (; pos != 0; pos--)
        view = view.superview;

    return view;
}

# pragma mark - actions

- (void) prepareForSegue:(nonnull UIStoryboardSegue *)segue sender:(nullable id)sender {
    [super prepareForSegue:segue sender:sender];

    if ([segue.identifier isEqualToString:@"2showAttachmentsController"]) {
        ShowAttachmentsViewController *controller = segue.destinationViewController;
        controller.attachments = sender[0];
        controller.index = ((NSNumber *) sender[1]).integerValue;
    }

    if ([segue.identifier isEqualToString:@"2threadController"]) {
        ThreadViewController *controller = segue.destinationViewController;

        controller.identifier = sender;
        controller.board = self.board;
    }

    if ([segue.identifier isEqualToString:@"2newPost"]) {
        NewPostViewController *controller = segue.destinationViewController;
        NSManagedObject *post = (NSManagedObject *) sender;

        controller.board = self.board;
        controller.thread_internal_identifier = [[post valueForKey:@"thread"] valueForKey:@"identifier"];
        controller.thread_identifier = [[post valueForKey:@"thread"] valueForKey:@"display_identifier"];
        controller.inReplyToIdentifier = [post valueForKey:@"display_identifier"];
        controller.inReplyToMessage = [post valueForKey:@"attributedMessage"];
    }
}

- (IBAction)threadHeaderTouch:(UIButton *)sender {
    ThreadTableViewCell *cell = (ThreadTableViewCell *) [self superviewIn:sender atPosition:2];

    [self performSegueWithIdentifier:@"2threadController" sender:[cell.object valueForKey:@"display_identifier"]];
}

- (IBAction)threadReplyTouch:(UIButton *)sender {
    ThreadTableViewCell *cell = (ThreadTableViewCell *) [self superviewIn:sender atPosition:2];

    [self performSegueWithIdentifier:@"2newPost" sender:[cell.object valueForKey:@"op_post"]];
}

- (IBAction)postReplyTouch:(UIButton *)sender {
    PostTableViewCell *cell = (PostTableViewCell *) [self superviewIn:sender atPosition:2];

    [self performSegueWithIdentifier:@"2newPost" sender:cell.object];
}

- (IBAction)attachmentTouch:(NSArray *)sender {
    NSNumber *index = [sender lastObject];
    NSArray *attachments = [sender subarrayWithRange:NSMakeRange(0, [sender count] - 1)];
    [self performSegueWithIdentifier:@"2showAttachmentsController" sender:@[attachments,
                                                                            index]];
}

- (IBAction) boardlinkTouch:(NSString *)identifier
                    context:(NSManagedObject *) contextObject {
    // @TODO: figure it out right way
    if ([contextObject.entity.name isEqualToString:@"Thread"]) {
        ThreadViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"threadViewController"];

        NSNumber *targetNumber;
        NSString *targetBoard;
        if ([identifier containsString:@"/"]) {
            NSArray *components = [identifier componentsSeparatedByString:@"/"];
            targetBoard = [components firstObject];
            targetNumber = [NSNumber numberWithInteger:[(NSString *) components.lastObject integerValue]];
        } else {
            targetBoard = self.board;
            targetNumber = [NSNumber numberWithInteger:identifier.integerValue];
        }
        controller.identifier = targetNumber;
        controller.board = targetBoard;

        [self.navigationController pushViewController:controller animated:YES];
    } else {
        PostViewController *pv = [[PostViewController alloc] init];
        pv.supercontroller = self;

        NSNumber *idNumber = [NSNumber numberWithInteger:identifier.integerValue];
        if ([idNumber isEqualToNumber:@0])
            return;
        
        pv.targetObject = [self.context postObjectForDisplayId:idNumber];
        pv.board = self.board;
        pv.identifier = idNumber;

        [self pushPopup:pv];
    }
}

- (BOOL) gestureRecognizerShouldBegin:(nonnull UIGestureRecognizer *)gestureRecognizer {
    return self.postPopups.count != 0;
}

- (IBAction)nextThreadGesture:(id)sender {
    CGFloat top = self.tableView.contentOffset.y + self.tableView.contentInset.top + 1;

    NSArray *forwardingCells =
    [self.tableView indexPathsForRowsInRect:CGRectMake(0,
                                                       top,
                                                       self.tableView.contentSize.width,
                                                       self.tableView.contentSize.height - top)];

    if (forwardingCells.count == 0)
        return;
    
    NSRange range = NSMakeRange(1, [forwardingCells count] - 1);
    for (NSIndexPath *path in [forwardingCells subarrayWithRange:range]) {
        NSManagedObject *object = self.threads[path.row];

        if ([object.entity.name isEqualToString:@"Thread"]) {
            [self scrollToObjectAt:path.row position:UITableViewScrollPositionTop animated:YES];
            return;
        }
    }

    [self.tableView scrollToRowAtIndexPath:[forwardingCells lastObject] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (IBAction)previousThreadGesture:(id)sender {
    CGFloat top = self.tableView.contentOffset.y + self.tableView.contentInset.top - 1;

    NSArray *backCells = [self.tableView indexPathsForRowsInRect:CGRectMake(0,
                                                                            0,
                                                                            self.tableView.contentSize.width,
                                                                            top)];

    for (int i = (int) [backCells count] - 1; i >= 0; i--) {
        NSIndexPath *index = backCells[i];
        NSManagedObject *object = self.threads[index.row];
        if ([object.entity.name isEqualToString:@"Thread"]) {
            [self scrollToObjectAt:index.row position:UITableViewScrollPositionTop animated:YES];
            break;
        }
    }
}

- (IBAction)threadLastPostGesture:(id)sender {
    CGFloat top = self.tableView.contentOffset.y + self.tableView.contentInset.top + 1;

    NSArray *forwardingCells =
    [self.tableView indexPathsForRowsInRect:CGRectMake(0,
                                                       top,
                                                       self.tableView.contentSize.width,
                                                       self.tableView.contentSize.height - top)];

    if (forwardingCells.count == 0)
        return;

    NSIndexPath *lastPostPath = nil;
    NSRange range = NSMakeRange(1, [forwardingCells count] - 1);
    for (NSIndexPath *path in [forwardingCells subarrayWithRange:range]) {
        NSManagedObject *object = self.threads[path.row];

        if ([object.entity.name isEqualToString:@"Thread"]) {
            break;
        } else {
            lastPostPath = path;
        }
    }

    if (lastPostPath) {
        __weak ContentViewController *_self = self;
        __block PostTableViewCell *cell;
        [_self scrollToObjectAt:lastPostPath.row position:UITableViewScrollPositionBottom animated:YES];

        /*
        [[[[[[SPAnimationChain new]
             backgroundCall:^{
                 while (!cell) {
                     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                         cell = (PostTableViewCell *) [_self.tableView cellForRowAtIndexPath:lastPostPath];
                     }];
                     
                     [NSThread sleepForTimeInterval:0.1f];
                 }
             }]
            call:^{
                NSLog(@"%@", cell);
                //[cell setOpacity:YES];
            }]
           animate:^{
               cell.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
           } withDuration:0.2 damping:1.f velocity:5.f]
          animate:^{
              cell.backgroundColor = [UIColor whiteColor];
          } withDuration:5.f damping:8.f velocity:2.f options:UIViewAnimationOptionAllowUserInteraction]
         run];
         */
    }
}

# pragma mark - view

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.progressView) {
        id topGuide = self.topLayoutGuide;
        [self.view addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat: @"V:[topGuide]-0-[pv]"
                                                 options: 0
                                                 metrics: nil
                                                   views: @{@"topGuide": topGuide, @"pv": self.progressView}]];
    }

    [self.tableView registerNib:[UINib nibWithNibName:@"ThreadTableViewCell" bundle:nil]
         forCellReuseIdentifier:@"ThreadView"];
    [self.tableView registerNib:[UINib nibWithNibName:@"PostTableViewCell" bundle:nil]
         forCellReuseIdentifier:@"PostView"];

    self.cachedPostCell = [self.tableView dequeueReusableCellWithIdentifier:@"PostView"];
    self.cachedThreadView = [self.tableView dequeueReusableCellWithIdentifier:@"ThreadView"];

    UIProgressView *pv = self.progressView;
    UIView *hpv = self.hidedProgressView;
    NSLayoutConstraint *hpvwc = self.hidedProgressViewWidth;
    __weak ContentViewController *_self = self;
    progressCallback = ^void(long long completed, long long total) {
        if (total == 0) {
            pv.progress = 0.6f;
            [pv setHidden:NO];
            [hpv setHidden:NO];
        } else if (completed == -1 && total == completed) {
            [pv setHidden:YES];
            [hpv setHidden:YES];
        } else if (completed == total) {
            pv.progress = 1.f;
            [[NSOperationQueue new] addOperationWithBlock:^{
                [NSThread sleepForTimeInterval:1.5f];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [pv setHidden:YES];
                    [hpv setHidden:YES];
                }];
            }];
        } else {
            NSUInteger hided = [ThreadHiderViewController totalHidedObjects];
            CGFloat n = (float) hided / (_self.threads.count + hided);
            if (!isfinite(n))
                n = 0;

            if (!isnan(n))
                hpvwc.constant = n * _self.view.frame.size.width;

            [UIView animateWithDuration:1.f animations:^{
                [_self.view layoutIfNeeded];
            }];
            [hpv setHidden:NO];

            pv.progress = (CGFloat) completed / (CGFloat) total;
            [pv setHidden:NO];
        }
    };
}

- (void) viewDidLayoutSubviews {
    // handles device orientation change
    if (viewChangedSize) {
        [self reloadData];
        self.viewChangedSize = NO;

        if (self.viewChangedSizeScrollTo) {
            if ([self.tableView numberOfRowsInSection:0] > self.viewChangedSizeScrollTo.row)
                [self.tableView scrollToRowAtIndexPath:self.viewChangedSizeScrollTo atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
    }
}

- (void) viewWillDisappear:(BOOL)animated {
//    [self.api cancelRequest];
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator {
    self.viewChangedSize = YES;
    self.viewChangedSizeScrollTo = [[self.tableView indexPathsForVisibleRows] firstObject];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) loadView {
    UINib *nib = [UINib nibWithNibName: @"ContentViewController" bundle:[NSBundle bundleForClass:[self class]]];
    self.view = [[nib instantiateWithOwner:self options:nil] objectAtIndex:0];
}

- (void) shouldLayoutContent {
    self.viewChangedSize = YES;
}

- (void) setMode:(NSInteger)mode {
    switch (mode) {
        case ContentViewControllerModeSingle:
            break;
        case ContentViewControllerModeMultiple:
            break;
        default:
            break;
    }
}

# pragma mark - context

- (void) context:(NSManagedObjectContext *)context didInsertedObject:(NSManagedObject *)object {
    [self insetObject:object];

    if ([object.entity.name isEqual:@"Thread"]) {
        [self insertNewRows];
    }
}

- (void) context:(NSManagedObjectContext *)context didFinishedLoading:(NSError *)error {
    if (error == nil) {
        [self insertNewRows];
        [self reloadData];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error during loading:"
                                                        message:[NSString stringWithFormat:@"%@", error.localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void) insetObject:(NSManagedObject *) object {
    if ([self shouldInsertObject:object]) {
        [self.threads addObject:object];
    }
}

- (void) insertNewRows {
    NSMutableArray *indexes = [NSMutableArray array];
    NSInteger oldLoadedRows = self.tableLoadedRows;

    for (NSInteger i = self.tableLoadedRows; i < [self.threads count] ; i++) {
        [indexes addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }

    self.tableLoadedRows = [self.threads count];
    [self.tableView insertRowsAtIndexPaths:indexes
                          withRowAnimation:UITableViewRowAnimationNone];

    for (NSInteger i = oldLoadedRows; i < [self.threads count]; i++) {
        [self didInsertObject:self.threads[i]];
    }
}

- (void) reloadData {
    self.rowHeightCache = [NSMutableDictionary new];
    [self.tableView reloadData];
}

- (void) didInsertObject:(NSManagedObject *) object {

}

- (BOOL) shouldInsertObject:(NSManagedObject *) object {
    if (![object.entity.name isEqualToString:@"Post"] && ![object.entity.name isEqualToString:@"Thread"])
        return NO;

    if ([object.entity.name isEqual:@"Post"] && [[object valueForKey:@"is_op"] isEqual:@YES])
        return NO;

    /*
    if ([object.entity.name isEqualToString:@"Thread"] && self.threads.count > 2)
        return NO;

     */
    //return self.threads.count < 2;


    /*
    if ([[object valueForKey:@"display_identifier"] isEqualToNumber:@3817474])
        return YES;
    else return NO;
     */

    return YES;
}

# pragma mark table

- (void) prepareCell:(BoardTableViewCell *) cell {
    if (cell.isPrepared) {
        return;
    } else {
        cell.isPrepared = YES;

        [cell setAttachmentTouchTarget:self action:@selector(attachmentTouch:)];
        [cell setBoardlinkTouchTarget:self action:@selector(boardlinkTouch:context:)];
        
        if ([cell isKindOfClass:[PostTableViewCell class]]) {
            // NSSelectorFromString used for supressing compiler warning
            [((PostTableViewCell *) cell) setHeaderTouchTarget:self
                                                        action:NSSelectorFromString(@"postReplyTouch:")];
        } else if ([cell isKindOfClass:[ThreadTableViewCell class]]) {
            [(ThreadTableViewCell *) cell setReplyTouchTarget:self
                                                       action:NSSelectorFromString(@"threadReplyTouch:")];
        }
    }
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSManagedObject *entry = self.threads[indexPath.row];
    BoardTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"%@View", entry.entity.name]];

    if (![self.api isRequesting] && indexPath.row == [self.threads count] - 1) {
        [self didScrollToBottom];
    }

    return cell;
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(BoardTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject *entry = self.threads[indexPath.row];

    NSArray<NSManagedObject *> *attachments = [self.context requestAttachmentsFor:entry];
    [self prepareCell:cell];
    [cell setupAttachmentOffsetFor:tableView.frame.size];
    [cell populate:entry
       attachments:attachments];
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableLoadedRows;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (self.rowHeightCache[indexPath]) {
        return [(NSNumber *) self.rowHeightCache[indexPath] floatValue];
    } else {
        NSManagedObject *entry = self.threads[indexPath.row];
        CGFloat height = 0.f;

        BoardTableViewCell *cell;
        if ([entry.entity.name isEqual:@"Thread"]) {
            cell = self.cachedThreadView;
        } else {
            cell = self.cachedPostCell;
        }

        [cell setupAttachmentOffsetFor:self.tableView.frame.size];
        [cell populateForHeightCalculation:entry
                               attachments:[self.context requestAttachmentsFor:entry]];
        height = [cell calculatedHeight:self.tableView.frame.size];
        self.rowHeightCache[indexPath] = [NSNumber numberWithFloat:height];

        return height;
    }
}

- (void) tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[PostTableViewCell class]]) {
        [(PostTableViewCell *) cell setOpacity:NO];
    }
}

# pragma mark state restoration

- (void) decodeRestorableStateWithCoder:(nonnull NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];

    self.context = [coder decodeObjectForKey:@"context"];
    self.context.delegate = self;
    self.api.delegate = self.context;

    // push all of the cached data into table view
    for (NSManagedObject *thread in [self.context requestThreads]) {
        [self insetObject:thread];
        [self didInsertObject:thread];

        for (NSManagedObject *post in [self.context requestPostsFrom:thread]) {
            [self insetObject:post];
            [self didInsertObject:post];
        }
    }

    // actual insert will happen in viewDidLayoutSubviews
    self.tableLoadedRows = [self.threads count];
    self.viewChangedSizeScrollTo = [coder decodeObjectForKey:@"first_visible_row"];
    self.viewChangedSize = YES;
}

- (void) encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];

    [coder encodeObject:self.context forKey:@"context"];
    [coder encodeObject:[[self.tableView indexPathsForVisibleRows] firstObject] forKey:@"first_visible_row"];
}

- (void) dealloc {
    self.context.delegate = nil;
    [self.api cancelRequest];
}

@end