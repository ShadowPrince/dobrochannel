//
//  ThreadAttachmentsViewController.m
//  dobrochannel
//
//  Created by shdwprince on 12/13/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "ThreadAttachmentsViewController.h"

@interface ThreadAttachmentsViewController ()
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property NSMutableDictionary<NSNumber *, NSURLSessionTask *> *cellTasks;
@property NSMutableDictionary<NSNumber *, NSNumber *> *cellTasksTokens;
@property NSMutableDictionary<NSIndexPath *, NSNumber *> *cachedRatings;
@property NSUInteger ratingMax;
@property float ratingMedium, ratingTop;
@property NSUInteger blockSizeMax;
@property CGFloat blockSize;
@end@implementation ThreadAttachmentsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSMutableArray *filteredAttachments = [NSMutableArray new];
    for (NSManagedObject *attachment in self.attachments) {
        if ([[attachment valueForKey:@"type"] isEqualToString:@"image"])
            [filteredAttachments addObject:attachment];
    }

    self.attachments = filteredAttachments;

    NSUInteger totalRating = 0;
    for (NSManagedObject *attachment in self.attachments) {
        if ([[attachment valueForKeyPath:@"post.is_op"] isEqualToNumber:@1])
            continue;

        NSUInteger rating = [[attachment valueForKeyPath:@"post.answers"] componentsSeparatedByString:@","].count;
        totalRating += rating;
        if (rating > self.ratingMax)
            self.ratingMax = rating;
    }

    self.ratingMedium = (float) totalRating / self.attachments.count;
    self.ratingTop = self.ratingMedium + (float) self.ratingMax / 3;

    self.title = [NSString stringWithFormat:@"Attachments (%lu)", (unsigned long) self.attachments.count];
    self.cellTasks = [NSMutableDictionary new];
    self.cellTasksTokens = [NSMutableDictionary new];
}


- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    float blockSizeCoef = 0, blockSizeMax = 1;
    CGFloat width = self.view.frame.size.width;
    if (width >= 1024) {
        blockSizeCoef = 8;
        blockSizeMax = 5;
    } else if (width >= 512) {
        blockSizeCoef = 6;
        blockSizeMax = 5;
    } else {
        blockSizeCoef = 4;
        blockSizeMax = 4;
    }

    CGFloat size = self.collectionView.frame.size.width / blockSizeCoef;
    self.blockSize = size;
    self.blockSizeMax = blockSizeMax;

    RFQuiltLayout *layout = (RFQuiltLayout *) self.collectionView.collectionViewLayout;
    layout.delegate = self;
    layout.blockPixels = CGSizeMake(size, size);
}

- (void) manageTopbarOnScrollingPosition:(CGFloat) top {
    if (top <= 0.f) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    } else {
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }
}

#pragma mark - actions
- (void) prepareForSegue:(nonnull UIStoryboardSegue *)segue sender:(nullable id)sender {
    if ([segue.identifier isEqualToString:@"2showAttachmentsController"]) {
        ShowAttachmentsViewController *controller = segue.destinationViewController;
        controller.attachments = self.attachments;
        controller.index = ((NSNumber *) sender).integerValue;
    } else {
        [super prepareForSegue:segue sender:sender];
    }
}

#pragma mark - collection view

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    [self manageTopbarOnScrollingPosition:scrollView.contentOffset.y];

    for (NSIndexPath *path in self.collectionView.indexPathsForVisibleItems) {
        UICollectionViewLayoutAttributes *layoutAttrs = [self.collectionView layoutAttributesForItemAtIndexPath:path];

        CGRect position = [self.collectionView convertRect:layoutAttrs.frame toView:self.view];
        CGFloat height = position.size.height;
        CGFloat offset = position.origin.y + height;
        CGFloat offset_max = self.view.frame.size.height + height;

        // bottom - offset=0
        // top - offset=offset_max

        CGFloat px_total_offset = 50.f;
        CGFloat n = (offset / offset_max) * px_total_offset;

        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:path];
        CGRect frame = [[cell viewWithTag:100] frame];
        frame.origin.y = n - px_total_offset;
        [[cell viewWithTag:100] setFrame:frame];
    }
}

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.attachments.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    NSManagedObject *attachment = self.attachments[indexPath.row];
    UIImageView *iv = (UIImageView *) [cell viewWithTag:100];
    iv.image = nil;

    NSURLSessionTask *previousTask;
    if ((previousTask = self.cellTasks[[self taskKeyForCell:cell]])) {
        [previousTask cancel];
    }
    
    NSNumber *token = [NSNumber numberWithDouble:CFAbsoluteTimeGetCurrent()];
    self.cellTasksTokens[[self taskKeyForCell:cell]] = token;
    __weak ThreadAttachmentsViewController *_self = self;

    NSString *src = [attachment valueForKey:@"thumb_src"];
    NSNumber *weight = [attachment valueForKey:@"weight"];
    BOOL weight_lesser_limit = weight.integerValue <= [UserDefaults contentReaderLoadFullMaxSize] * 1024;

    CGSize attachS = [(NSValue *) [attachment valueForKey:@"thumb_size"] CGSizeValue];
    CGSize s = [self blockSizeForItemAtIndexPath:indexPath];
    CGFloat width_ratio = s.width * self.blockSize / attachS.width;
    CGFloat height_ratio = s.height * self.blockSize / attachS.height;

    if (weight_lesser_limit && [UserDefaults attachmentsViewLoadFull] && (width_ratio >= 1.3f || height_ratio >= 1.3f)) {
        src = [attachment valueForKey:@"src"];
    }

    NSURLSessionTask *task = [[BoardAPI api] requestImage:src
                                            stateCallback:nil
                                           finishCallback:^(UIImage *img) {
                                               if ([_self.cellTasksTokens[[_self taskKeyForCell:cell]] isEqual:token])
                                                   iv.image = img;
                                           }];
    self.cellTasks[[NSNumber numberWithLongLong:(long long) cell]] = task;

    UISegmentedControl *info = (UISegmentedControl *) [cell viewWithTag:101];
    NSString *fullSrc = [[[attachment valueForKey:@"src"] componentsSeparatedByString:@"."] lastObject];
    [info setTitle:fullSrc.length <= 4 ? fullSrc : @"?" forSegmentAtIndex:0];

    NSString *weightStr = [NSByteCountFormatter stringFromByteCount:[(NSNumber *) [attachment valueForKey:@"weight"] longLongValue]
                                                      countStyle:NSByteCountFormatterCountStyleFile];
    [info setTitle:weightStr forSegmentAtIndex:1];
    return cell;
}

- (NSNumber *) taskKeyForCell:(UICollectionViewCell *) cell {
    return [NSNumber numberWithLongLong:(long long) cell];
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout blockSizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self blockSizeForItemAtIndexPath:indexPath];
}

- (CGSize) blockSizeForItemAtIndexPath:(NSIndexPath *) indexPath {
    NSNumber *cachedRating = self.cachedRatings[indexPath];

    if (!cachedRating) {
        NSManagedObject *attachment = self.attachments[indexPath.row];
        NSUInteger rating = [[attachment valueForKeyPath:@"post.answers"] componentsSeparatedByString:@","].count - 1;
        
        float ratingRel = (float) rating / self.ratingTop;
        if (ratingRel > 1.f)
            ratingRel = 1.f;
        
        float n = 1 + (ratingRel * (self.blockSizeMax - 1));
        cachedRating = [NSNumber numberWithFloat:n];
        self.cachedRatings[indexPath] = cachedRating;
    }

    return CGSizeMake(cachedRating.integerValue, cachedRating.integerValue);
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"2showAttachmentsController" sender:[NSNumber numberWithInteger:indexPath.row]];
}

@end
