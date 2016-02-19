//
//  ZoomingImageController.m
//  dobrochannel
//
//  Created by shdwprince on 7/29/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "DetailedAttachmentViewController.h"

@interface DetailedAttachmentViewController ()
@property NSURLSessionTask *task;
@property BOOL isCentered, didLoadedSource;
//---
@property (weak, nonatomic) IBOutlet YLImageView *imageView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@property (weak, nonatomic) IBOutlet UIView *infoView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *infoViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *infoViewBottomConstraint;
@property (weak, nonatomic) IBOutlet UILabel *sizesLabel;
@property (weak, nonatomic) IBOutlet UILabel *filenameLabel;
@property (weak, nonatomic) IBOutlet UILabel *ratingLabel;

@end @implementation DetailedAttachmentViewController
@synthesize image, attachment;

- (instancetype) initWithAttachment:(id)attach
                              frame:(CGRect) frame {
    self = [super init];
    self.view.frame = frame;
    self.attachment = attach;

    return self;
}

- (void) setImage:(UIImage *)img {
    self.imageView.image = img;
    image = img;
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    NSString *type = [self.attachment valueForKey:@"type"];
    if ([type isEqualToString:@"image"]) {
        [self hideInfoView];
        //@TODO: fix in ipad multitasking
        if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad) {
            self.infoViewBottomConstraint.constant = self.view.frame.size.height - self.infoView.frame.size.height - 8.f;
        }
    } else {
        [self showInfoViewAnimated:YES];
        self.infoViewWidthConstraint.constant = self.view.frame.size.width - 16.f;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    NSString *thumb_src = [self.attachment valueForKey:@"thumb_src"];
    NSString *full_src = [self.attachment valueForKey:@"src"];

    [self request:thumb_src completeWith:^{
        if ([UserDefaults attachmentsViewerLoadFull] && [self shouldLoadFullImage]) {
            self.didLoadedSource = YES;
            [self request:full_src completeWith:nil];
        }
    }];
}

- (void) viewDidDisappear:(BOOL)animated {
    if (self.task) {
        [[BoardAPI api] cancelRequest:self.task];
        self.task = nil;
    }
}

- (void) didCenter {
    self.isCentered = YES;

    if (![UserDefaults attachmentsViewerLoadFull])
        return;

    if ([self shouldLoadFullImage]) {
        self.didLoadedSource = YES;

        NSString *full_src = [self.attachment valueForKey:@"src"];
        [self request:full_src completeWith:nil];
    }
}

- (BOOL) shouldLoadFullImage {
    return !self.didLoadedSource && !self.task && self.isCentered && [[self.attachment valueForKey:@"type"] isEqualToString:@"image"];
}

# pragma mark actions

- (IBAction)tapAction:(id)sender {
    NSString *type = [self.attachment valueForKey:@"type"];

    if ([type isEqualToString:@"image"]) {
        if (!self.task && !self.didLoadedSource) {
            self.progressView.hidden = NO;
            self.progressView.progress = 0.f;
            [self request:[self.attachment valueForKey:@"src"] completeWith:^{
                self.didLoadedSource = YES;
            }];
        }
    } else {
        [self openInBrowser];
    }
}

- (IBAction)longPressAction:(id)sender {
}

- (IBAction)swipeUpAction:(id)sender {
    UIAlertController *c = [UIAlertController alertControllerWithTitle:nil
                                                               message:nil
                                                        preferredStyle:UIAlertControllerStyleActionSheet];
    c.popoverPresentationController.sourceRect = CGRectMake(self.view.frame.size.width - self.infoView.frame.size.width / 2,
                                                            self.view.frame.size.height - self.infoView.frame.size.height - 10.f,
                                                            0,
                                                            0);
    c.popoverPresentationController.sourceView = self.view;

    NSNumber *weight = [attachment valueForKey:@"weight"];
    if ([[attachment valueForKey:@"type"] isEqualToString:@"image"]) {
        CGSize size = ((NSValue *) [attachment valueForKey:@"size"]).CGSizeValue;
        c.title = [NSString stringWithFormat:@"%@, %dx%d",
                   [NSByteCountFormatter stringFromByteCount:weight.longLongValue countStyle:NSByteCountFormatterCountStyleFile],
                   (int) size.width,
                   (int) size.height];
    } else {
        c.title = [NSString stringWithFormat:@"%@, %@",
                   [NSByteCountFormatter stringFromByteCount:weight.longLongValue countStyle:NSByteCountFormatterCountStyleFile],
                   [attachment valueForKey:@"type"]];
    }

    NSNumber *rating = [self.attachment valueForKey:@"rating"];
    if ([rating isEqualToNumber:@-1]) {
        c.message = @"unrated, ";
    } else {
        c.message = [[[BoardAPI api] ratingsList][[rating integerValue]] stringByAppendingString:@", "];
    }
    c.message = [c.message stringByAppendingString:[self.attachment valueForKey:@"src"]];

    [c addAction:[UIAlertAction actionWithTitle:@"Open in Safari"
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * __nonnull action) {
                                            [self hideInfoView];
                                            [self openInBrowser];
                                        }]];
    [c addAction:[UIAlertAction actionWithTitle:@"Copy"
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction *action) {
                                            [self hideInfoView];
                                            NSString *path = [self.attachment valueForKey:@"src"];
                                            NSURL *url = [[BoardAPI api] urlFor:path];
                                            [UIPasteboard generalPasteboard].URL = url;
                                        }]];

    [c addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                          style:UIAlertActionStyleCancel
                                        handler:^(UIAlertAction * __nonnull action) {
                                            [self hideInfoView];
                                            [c removeFromParentViewController];
                                        }]];

    [self showInfoViewAnimated:YES];
    [self presentViewController:c animated:YES completion:nil];
}

- (void) openInBrowser {
    [[UIApplication sharedApplication] openURL:[[BoardAPI api] urlFor:[attachment valueForKey:@"src"]]];
}

#pragma mark helper methods

- (void) showInfoViewAnimated:(BOOL) animated {
    [UIView animateWithDuration:animated ? 0.35 : 0.0 animations:^{
        self.infoView.alpha = 1.f;
    }];
}

- (void) hideInfoView {
    self.infoView.alpha = 0.f;
}

- (void) request:(NSString *) imageUrl
    completeWith:(void (^)()) completeBlock {
    int rating_int = [[self.attachment valueForKey:@"rating"] integerValue];
    if (rating_int > [UserDefaults maxRating] || (![UserDefaults showUnrated] && rating_int == -1)) {
        return;
    }

    __weak DetailedAttachmentViewController *_self = self;
    self.task = [[BoardAPI api] requestData:imageUrl
                               stateCallback:^(long long processed, long long total) {
                                   if (processed == total) {
                                       [_self.progressView setHidden:YES];
                                   } else {
                                       _self.progressView.progress = (CGFloat) processed / (CGFloat) total;
                                       [_self.progressView setHidden:NO];
                                   }
                               }
                              finishCallback:^(NSData *i) {
                                  [[BoardAPI api] cancelRequest:_self.task];
                                  _self.task = nil;

                                  _self.image = [YLGIFImage imageWithData:i];
                                  if (completeBlock) completeBlock();
                              }];

}

# pragma mark scrollview

- (UIView *) viewForZoomingInScrollView:(nonnull UIScrollView *)scrollView {
    return self.imageView;
}

@end