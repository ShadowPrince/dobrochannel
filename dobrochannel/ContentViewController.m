//
//  BoardViewController.m
//  dobrochannel
//
//  Created by shdwprince on 7/19/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "ContentViewController.h"
#import "PostViewController.h"

@interface ContentViewController ()
@property NSMutableArray<NSManagedObject *> *threads;
@property BoardMarkupParser *markupParser;
@property NSMutableArray<PostViewController *> *postPopups;

// table loading
@property NSMutableArray<UITableViewCell *> *preparedTableCells;
@property NSInteger tableLoadedRows;
@property BOOL viewChangedSize;
@property PostTableViewCell *cachedPostCell;
@property ThreadTableViewCell *cachedThreadView;
@property NSMutableDictionary<NSIndexPath *, NSNumber *> *rowHeightCache;
//---
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@end @implementation ContentViewController
@synthesize api, context;
@synthesize board;
@synthesize cachedPostCell, cachedThreadView, threads, tableLoadedRows, rowHeightCache, viewChangedSize;

- (instancetype) initWithCoder:(nonnull NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    self.api = [[BoardAPI alloc] init];

    UIColor *quoteColor = [UIColor colorWithRed:120.f/255.f green:153.f/255.f blue:34.f/255.f alpha:1.f];

    self.markupParser = [[BoardMarkupParser alloc] initWithAttributes:
                         @{
                           @BoardMarkupParserTagBold: @{NSFontAttributeName:[UIFont boldSystemFontOfSize:12.f], },
                            @BoardMarkupParserTagBold: @{},
                            @BoardMarkupParserTagItalic: @{NSFontAttributeName:[UIFont italicSystemFontOfSize:12.f], },
                            @BoardMarkupParserTagItalic: @{ },
                            @BoardMarkupParserTagBoldItalic: @{NSFontAttributeName:[UIFont fontWithName:@"Georgia-BoldItalic" size:12.f], },
                            @BoardMarkupParserTagSpoiler: @{NSForegroundColorAttributeName: [UIColor grayColor],
                                                            NSBackgroundColorAttributeName: [UIColor blackColor], },
                            @BoardMarkupParserWeblink: @{},
                            @BoardMarkupParserBoardlink: @{},
                            @BoardMarkupParserQuote: @{NSForegroundColorAttributeName: quoteColor, },


                            }];

    progressCallback = ^void(long long completed, long long total) {
        if (total == 0) {
            self.progressView.progress = 0.6f;
            [self.progressView setHidden:NO];
        } else if (completed == total) {
            [self.progressView setHidden:YES];
        } else {
            self.progressView.progress = (CGFloat) completed / (CGFloat) total;
            [self.progressView setHidden:NO];
        }
    };

    [self resetReuseProperties];
    return self;
}

- (void) resetReuseProperties { // @TODO: find a not-4-am method name
    [self.api cancelRequest];

    self.viewChangedSize = YES;
    self.preparedTableCells = [NSMutableArray new];
    self.threads = [NSMutableArray new];
    self.rowHeightCache = [NSMutableDictionary dictionary];
    self.tableLoadedRows = 0;
    [self.tableView reloadData];

    self.context = [self createContext];
    self.context.delegate = self;
    self.api.delegate = self.context;

    for (PostViewController *popup in self.postPopups) {
        [popup.view removeFromSuperview];
    }

    self.postPopups = [NSMutableArray new];
}

- (void) reset {
    NSLog(@"cleared");
    [self.context clearPersistentStorage];
    [self resetReuseProperties];
}

- (NSManagedObjectContext *) createContext {
    return [[BoardManagedObjectContext alloc] init];
}

- (void) startedRequest {
    self.progressView.progress = 0.f;
    self.progressView.hidden = NO;
}

- (void) didScrollToBottom {

}

- (void) scrollTo:(NSManagedObject *) object animated:(BOOL) animated {
    [self scrollToObjectAt:[self.threads indexOfObject:object] animated:animated];
}


- (void) scrollToObjectAt:(NSUInteger) pos animated:(BOOL) animated {
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:pos inSection:0]
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:animated];
}

- (UIView *) superviewIn:(UIView *) view atPosition:(NSUInteger) pos {
    for (; pos != 0; pos--)
        view = view.superview;

    return view;
}

# pragma mark actions

- (void) prepareForSegue:(nonnull UIStoryboardSegue *)segue sender:(nullable id)sender {
    [super prepareForSegue:segue sender:sender];

    if ([segue.identifier isEqualToString:@"2showAttachmentsController"]) {
        ShowAttachmentsViewController *controller = segue.destinationViewController;
        controller.attachments = sender[0];
        controller.index = ((NSNumber *) sender[1]).integerValue;
    }
}

- (IBAction)threadHeaderTouch:(UIButton *)sender {
    ThreadTableViewCell *cell = (ThreadTableViewCell *) [self superviewIn:sender atPosition:2];

    [self performSegueWithIdentifier:@"2threadController" sender:[cell.thread valueForKey:@"display_identifier"]];
}

- (IBAction)attachmentTouch:(NSArray *)sender {
    NSNumber *index = [sender lastObject];
    NSArray *attachments = [sender subarrayWithRange:NSMakeRange(0, [sender count] - 1)];
    [self performSegueWithIdentifier:@"2showAttachmentsController" sender:@[attachments,
                                                                            index]];
}

- (IBAction)popPopup:(id)sender {
    PostViewController *c = self.postPopups.lastObject;
    [c.view removeFromSuperview];
    [c.api cancelRequest];

    [self.postPopups removeLastObject];
}

- (IBAction)popAllPopups:(id)sender {
    while (self.postPopups.count)
        [self popPopup:nil];
}

- (IBAction) boardlinkTouch:(NSString *)identifier
                    context:(NSManagedObject *) contextObject {
    if ([contextObject.entity.name isEqualToString:@"Thread"]) {
        [self performSegueWithIdentifier:@"2threadController" sender:[NSNumber numberWithInteger:identifier.integerValue]];
    } else {
        PostViewController *pv = [[PostViewController alloc] init];
        pv.supercontroller = self;

        NSNumber *idNumber = [NSNumber numberWithInteger:identifier.integerValue];
        pv.targetObject = [self.context postObjectForDisplayId:idNumber];
        pv.board = self.board;
        pv.identifier = idNumber;

        CGFloat width = self.view.frame.size.width / 1.5;
        CGFloat max_x_offset = self.view.frame.size.width - width;
        CGFloat max_y_offset = self.view.frame.size.height - 100.f;
        CGFloat initial_x_offset = 10.f;
        CGFloat initial_y_offset = self.view.frame.size.height / 2 - 50.f;

        CGFloat x_offset = initial_x_offset + 30.f * self.postPopups.count,
        y_offset = initial_y_offset + 30.f * self.postPopups.count;

        BOOL right_direction = YES;
        while (x_offset > max_x_offset) {
            x_offset -= max_x_offset;
            right_direction = !right_direction;
        }

        while (y_offset > max_y_offset) {
            y_offset -= max_y_offset;
        }

        if (y_offset < initial_y_offset)
            y_offset = initial_y_offset;

        if (!right_direction) {
            x_offset = max_x_offset - x_offset;
        }

        pv.maxHeight = self.view.frame.size.height - y_offset;
        pv.view.frame = CGRectMake(x_offset, y_offset, width, 30.f);
        
        [self.view addSubview:pv.view];
        [self.postPopups addObject:pv];
    }
}

- (BOOL) gestureRecognizerShouldBegin:(nonnull UIGestureRecognizer *)gestureRecognizer {
    return self.postPopups.count != 0;
}

- (IBAction)nextThreadGesture:(id)sender {
    CGFloat top = self.tableView.contentOffset.y + self.tableView.contentInset.top + 1;

    NSArray<NSIndexPath *> *forwardingCells =
    [self.tableView indexPathsForRowsInRect:CGRectMake(0,
                                                       top,
                                                       self.tableView.contentSize.width,
                                                       self.tableView.contentSize.height - top)];

    NSRange range = NSMakeRange(1, [forwardingCells count] - 1);
    for (NSIndexPath *path in [forwardingCells subarrayWithRange:range]) {
        NSManagedObject *object = self.threads[path.row];

        if ([object.entity.name isEqualToString:@"Thread"]) {
            [self scrollToObjectAt:path.row animated:YES];
            return;
        }
    }

    [self.tableView scrollToRowAtIndexPath:[forwardingCells lastObject] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (IBAction)previousThreadGesture:(id)sender {
    CGFloat top = self.tableView.contentOffset.y + self.tableView.contentInset.top - 1;

    NSArray<NSIndexPath *> *backCells = [self.tableView indexPathsForRowsInRect:CGRectMake(0,
                                                                                           0,
                                                                                           self.tableView.contentSize.width,
                                                                                           top)];

    for (int i = [backCells count] - 1; i >= 0; i--) {
        NSIndexPath *index = backCells[i];
        NSManagedObject *object = self.threads[index.row];
        if ([object.entity.name isEqualToString:@"Thread"]) {
            [self scrollToObjectAt:index.row animated:YES];
            break;
        }
    }
}

# pragma mark view

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerNib:[UINib nibWithNibName:@"ThreadTableViewCell" bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:@"ThreadView"];
    [self.tableView registerNib:[UINib nibWithNibName:@"PostTableViewCell" bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:@"PostView"];

    self.cachedPostCell = [self.tableView dequeueReusableCellWithIdentifier:@"PostView"];
    self.cachedThreadView = [self.tableView dequeueReusableCellWithIdentifier:@"ThreadView"];
}

- (void) viewDidLayoutSubviews {
    if (viewChangedSize) {
        self.rowHeightCache = [NSMutableDictionary dictionary];
        [self.tableView reloadData];
        self.viewChangedSize = NO;
    }
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator {
    self.viewChangedSize = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) loadView {
    UINib *nib = [UINib nibWithNibName: @"ContentViewController" bundle:[NSBundle bundleForClass:[self class]]];
    self.view = [[nib instantiateWithOwner:self options:nil] objectAtIndex:0];
}

# pragma mark context

- (void) context:(NSManagedObjectContext *)context didInsertedObject:(NSManagedObject *)object {
    [self insetObject:object];
    [self insertNewRows];
}

- (void) insertNewRows {
    NSMutableArray<NSIndexPath *> *indexes = [NSMutableArray array];
    NSInteger oldLoadedRows = self.tableLoadedRows;

    for (int i = self.tableLoadedRows; i < [self.threads count] ; i++) {
        [indexes addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }

    self.tableLoadedRows = [self.threads count];
    [self.tableView insertRowsAtIndexPaths:indexes
                          withRowAnimation:UITableViewRowAnimationNone];

    for (int i = oldLoadedRows; i < [self.threads count]; i++) {
        [self didInsertObject:self.threads[i]];
    }
}

- (void) insetObject:(NSManagedObject *) object {
    if ([self shouldInsertObject:object]) {
        [self.threads addObject:object];
    }
}

- (void) didInsertObject:(NSManagedObject *) object {

}

- (BOOL) shouldInsertObject:(NSManagedObject *) object {
    if (![object.entity.name isEqualToString:@"Post"] && ![object.entity.name isEqualToString:@"Thread"])
        return NO;

    if ([object.entity.name isEqual:@"Post"] && [[object valueForKey:@"is_op"] isEqual:@YES])
        return NO;

    return YES;
}

# pragma mark table

- (void) prepareCell:(BoardTableViewCell *) cell {
    [cell setAttachmentTouchTarget:self action:@selector(attachmentTouch:)];
    [cell setBoardlinkTouchTarget:self action:@selector(boardlinkTouch:context:)];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSManagedObject *entry = self.threads[indexPath.row];
    BoardTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"%@View", entry.entity.name]];

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Attachment"];
    if ([cell isKindOfClass:[ThreadTableViewCell class]]) {
        request.predicate = [NSPredicate predicateWithFormat:@"post == %@", [entry valueForKey:@"op_post"]];
    } else {
        request.predicate = [NSPredicate predicateWithFormat:@"post == %@", entry];
    }

    [cell setupAttachmentOffsetFor:tableView.frame.size];
    [cell populate:entry
       attachments:[self.context executeFetchRequest:request error:nil]
      markupParser:self.markupParser];
    [self prepareCell:cell];

    if (![self.api isRequesting] && indexPath.row == [self.threads count] - 1) {
        [self didScrollToBottom];
    }

    return cell;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableLoadedRows;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (self.rowHeightCache[indexPath]) {
        return self.rowHeightCache[indexPath].floatValue;
    } else {
        NSManagedObject *entry = self.threads[indexPath.row];
        CGFloat height = 0.f;
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Attachment"];

        BoardTableViewCell *cell;
        if ([entry.entity.name isEqual:@"Thread"]) {
            cell = self.cachedThreadView;
            request.predicate = [NSPredicate predicateWithFormat:@"post == %@", [entry valueForKey:@"op_post"]];
        } else {
            cell = self.cachedPostCell;
            request.predicate = [NSPredicate predicateWithFormat:@"post == %@", entry];
        }

        [cell setupAttachmentOffsetFor:self.tableView.frame.size];
        [cell populateForHeightCalculation:entry
                               attachments:[self.context executeFetchRequest:request error:nil]];
        height = [cell calculatedHeight:self.tableView.frame.size];
        self.rowHeightCache[indexPath] = [NSNumber numberWithFloat:height];

        return height;
    }
}

- (void) scrollViewDidScroll:(nonnull UIScrollView *)scrollView {
    [self popAllPopups:nil];
}

# pragma mark state restoration

- (void) decodeRestorableStateWithCoder:(nonnull NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];

    // push all of the cached data into table view
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Thread"];
    NSArray *threadsResponse = [self.context executeFetchRequest:request error:nil];
    threadsResponse = [threadsResponse sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [[obj2 valueForKey:@"date"] compare:[obj1 valueForKey:@"date"]];
    }];
    for (NSManagedObject *thread in threadsResponse) {
        [self insetObject:thread];
        [self didInsertObject:thread];

        request = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
        request.predicate = [NSPredicate predicateWithFormat:@"thread == %@", thread];
        NSArray *postsResponse = [[self.context executeFetchRequest:request error:nil] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            return [[obj1 valueForKey:@"date"] compare:[obj2 valueForKey:@"date"]];
        }];

        for (NSManagedObject *post in postsResponse) {
            [self insetObject:post];
            [self didInsertObject:post];
        }
    }

    // actual insert will happen in viewDidLayoutSubviews
    self.tableLoadedRows = [self.threads count];
}

- (NSString *) modelIdentifierForElementAtIndexPath:(nonnull NSIndexPath *)idx inView:(nonnull UIView *)view {
    return [NSString stringWithFormat:@"%llu", (unsigned long long) idx.row];
}

- (NSIndexPath *) indexPathForElementWithModelIdentifier:(nonnull NSString *)identifier inView:(nonnull UIView *)view {
    return [NSIndexPath indexPathForRow:identifier.integerValue inSection:0];
}

@end
