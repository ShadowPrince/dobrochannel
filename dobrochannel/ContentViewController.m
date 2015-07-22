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
    self.context = [[BoardManagedObjectContext alloc] init];

    progressCallback = ^void(NSUInteger completed, NSUInteger total) {
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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newObjectInContext:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:self.context];

    self.preparedTableCells = [NSMutableArray new];
    self.threads = [NSMutableArray new];
    self.tableLoadedRows = 0;
    self.rowHeightCache = [NSMutableDictionary dictionary];

    return self;
}

- (UIView *) superviewIn:(UIView *) view atPosition:(NSUInteger) pos {
    for (; pos != 0; pos--)
        view = view.superview;

    return view;
}

# pragma mark actions

- (IBAction)threadHeaderTouch:(UIButton *)sender {
    ThreadTableViewCell *cell = (ThreadTableViewCell *) [self superviewIn:sender atPosition:2];

    [self performSegueWithIdentifier:@"2threadController" sender:cell.identifier];
}

- (IBAction)attachmentTouch:(UIView *)sender {
    BoardTableViewCell *cell = (BoardTableViewCell *) [self superviewIn:sender atPosition:5];
    UIView *imageView = [self superviewIn:sender atPosition:1];

    [self performSegueWithIdentifier:@"2showAttachmentsController" sender:@[cell.attachmentsControllers,
                                                                            [NSNumber numberWithInteger:[cell positionOfAttachmentView:imageView]]]];
}

- (void) prepareForSegue:(nonnull UIStoryboardSegue *)segue sender:(nullable id)sender {
    [super prepareForSegue:segue sender:sender];

    if ([segue.identifier isEqualToString:@"2showAttachmentsController"]) {
        ShowAttachmentsViewController *controller = segue.destinationViewController;

        NSMutableArray<NSManagedObject *> *attachments = [NSMutableArray new];
        for (AttachmentViewController *attachmentController in sender[0])
            [attachments addObject:attachmentController.attachment];

        controller.attachments = attachments;
        controller.index = ((NSNumber *) sender[1]).integerValue;
    }
}

- (IBAction)nextThreadGesture:(id)sender {
    NSInteger row = [[self.tableView indexPathsForVisibleRows] firstObject].row + 2;

    NSRange range = NSMakeRange(row, [self.threads count] - row - 1);
    for (NSManagedObject *object in [self.threads subarrayWithRange:range]) {
        if ([object.entity.name isEqualToString:@"Thread"])
            break;

        row++;
    }

    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (IBAction)previousThreadGesture:(id)sender {
    NSInteger row = [[self.tableView indexPathsForVisibleRows] firstObject].row;

    NSRange range = NSMakeRange(0, row);
    for (int i = range.location + range.length ; i > 0; i--) {
        NSManagedObject *object = self.threads[i];
        if ([object.entity.name isEqualToString:@"Thread"])
            break;

        row--;
    }

    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}


# pragma mark view

- (void)viewDidLoad {
    [super viewDidLoad];

    self.api.delegate = self.context;

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
    //@TODO: is entire reload required?
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

//        if ([self.threads count] < 2)
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
    [cell populate:entry];
    [self prepareCell:cell];
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
