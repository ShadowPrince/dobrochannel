//
//  BoardViewController.m
//  dobrochannel
//
//  Created by shdwprince on 7/19/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "ContentViewController.h"

@interface ContentViewController ()
@property BoardManagedObjectContext *context;
@property NSMutableArray<NSManagedObject *> *threads;
@property BoardMarkupParser *markupParser;

// table loading
@property NSMutableArray<UITableViewCell *> *preparedTableCells;
@property NSInteger tableLoadedRows;
@property PostTableViewCell *cachedPostCell;
@property ThreadTableViewCell *cachedThreadView;
@property NSMutableDictionary<NSIndexPath *, NSNumber *> *rowHeightCache;
//---
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@end @implementation ContentViewController
@synthesize api, context;
@synthesize cachedPostCell, cachedThreadView, threads, tableLoadedRows, rowHeightCache;

- (instancetype) initWithCoder:(nonnull NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    self.api = [[BoardAPI alloc] init];
    self.markupParser = [[BoardMarkupParser alloc] initWithAttributes:
                         @{
                           @BoardMarkupParserTagBold: @{NSFontAttributeName:[UIFont boldSystemFontOfSize:12.f], },
                            @BoardMarkupParserTagItalic: @{NSFontAttributeName:[UIFont italicSystemFontOfSize:12.f], },
                            @BoardMarkupParserTagBoldItalic: @{NSFontAttributeName:[UIFont fontWithName:@"Georgia-BoldItalic" size:12.f], },
                            @BoardMarkupParserTagSpoiler: @{NSForegroundColorAttributeName: [UIColor grayColor],
                                                            NSBackgroundColorAttributeName: [UIColor blackColor], },
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

    [self reset];

    return self;
}

- (void) reset { // @TODO: find a not-4-am method name
    [self.api cancelRequest];

    self.preparedTableCells = [NSMutableArray new];
    self.threads = [NSMutableArray new];
    self.rowHeightCache = [NSMutableDictionary dictionary];
    self.tableLoadedRows = 0;
    [self.tableView reloadData];

    self.context = [[BoardManagedObjectContext alloc] init];
    self.api.delegate = self.context;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newObjectInContext:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:self.context];
}

- (void) didScrollToBottom {

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

    [self performSegueWithIdentifier:@"2threadController" sender:cell.identifier];
}

- (IBAction)attachmentTouch:(NSArray *)sender {
    NSNumber *index = [sender lastObject];
    NSArray *attachments = [sender subarrayWithRange:NSMakeRange(0, [sender count] - 1)];
    [self performSegueWithIdentifier:@"2showAttachmentsController" sender:@[attachments,
                                                                            index]];
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
            [self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:YES];
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
            [self.tableView scrollToRowAtIndexPath:index atScrollPosition:UITableViewScrollPositionTop animated:YES];
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
    self.rowHeightCache = [NSMutableDictionary dictionary];
    [self.tableView reloadData];
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

- (void) newObjectInContext:(NSNotification *) not {
    for (NSManagedObject *object in not.userInfo[@"inserted"]) {
        if (![object.entity.name isEqualToString:@"Post"] && ![object.entity.name isEqualToString:@"Thread"])
            continue;

        if ([object.entity.name isEqual:@"Post"] && [[object valueForKey:@"is_op"] isEqual:@YES])
            continue;

//        if ([self.threads count] < 1)
            [self.threads addObject:object];
    }

    [self insertNewRows];
 }

- (void) insertNewRows {
    NSMutableArray<NSIndexPath *> *indexes = [NSMutableArray array];
    for (int i = self.tableLoadedRows; i < [self.threads count] ; i++) {
        [indexes addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }

    self.tableLoadedRows = [self.threads count];
    [self.tableView insertRowsAtIndexPaths:indexes
                          withRowAnimation:UITableViewRowAnimationNone];
}

# pragma mark table

- (void) prepareCell:(BoardTableViewCell *) cell {
    [cell setAttachmentTouchTarget:self action:@selector(attachmentTouch:)];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSManagedObject *entry = self.threads[indexPath.row];
    BoardTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"%@View", entry.entity.name]];

    [cell setupAttachmentOffsetFor:tableView.frame.size];
    [cell populate:entry markupParser:self.markupParser];
    [self prepareCell:cell];

    if (![self.api isRequesting] && indexPath.row == [self.threads count] - 1) {
        [self didScrollToBottom];
    }

    return cell;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableLoadedRows;
}

- (CGFloat) tableView:(nonnull UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (self.rowHeightCache[indexPath]) {
        return self.rowHeightCache[indexPath].floatValue;
    } else {
        NSManagedObject *entry = self.threads[indexPath.row];
        CGFloat height = 0.f;

        BoardTableViewCell *cell;
        if ([entry.entity.name isEqual:@"Thread"]) {
            cell = self.cachedThreadView;
        } else {
            cell = self.cachedPostCell;
        }

        [cell setupAttachmentOffsetFor:tableView.frame.size];
        [cell populateForHeightCalculation:entry];
        height = [cell calculatedHeight:tableView.frame.size];
        self.rowHeightCache[indexPath] = [NSNumber numberWithFloat:height];

        return height;
    }
}

@end
