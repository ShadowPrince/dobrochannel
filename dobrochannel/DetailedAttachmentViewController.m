//
//  ZoomingImageController.m
//  dobrochannel
//
//  Created by shdwprince on 7/29/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "DetailedAttachmentViewController.h"

@interface DetailedAttachmentViewController ()
@property NSManagedObject *attachment;
@property NSURLSessionTask *task;
@property BOOL isCentered, didLoadedSource;
//---
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
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

    NSNumber *weight = [attachment valueForKey:@"weight"];

    if ([[attachment valueForKey:@"type"] isEqualToString:@"image"]) {
        CGSize size = ((NSValue *) [attachment valueForKey:@"size"]).CGSizeValue;
        self.sizesLabel.text = [NSString stringWithFormat:@"%@, %dx%d",
                                [NSByteCountFormatter stringFromByteCount:weight.longLongValue countStyle:NSByteCountFormatterCountStyleFile],
                                (int) size.width,
                                (int) size.height];
    } else {
        self.sizesLabel.text = [NSString stringWithFormat:@"%@, %@",
                                [NSByteCountFormatter stringFromByteCount:weight.longLongValue countStyle:NSByteCountFormatterCountStyleFile],
                                [attachment valueForKey:@"type"]];
    }
    self.filenameLabel.text = full_src;
    NSNumber *rating = [self.attachment valueForKey:@"rating"];
    if ([rating isEqualToNumber:@-1]) {
        self.ratingLabel.text = @"unrated";
    } else {
        self.ratingLabel.text = [[BoardAPI api] ratingsList][[rating integerValue]];
    }

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
        NSString *full_src = [self.attachment valueForKey:@"src"];
        [self request:full_src completeWith:^{
            self.didLoadedSource = YES;
        }];
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
    self.task = [[BoardAPI api] requestImage:imageUrl
                               stateCallback:^(long long processed, long long total) {
                                   if (processed == total) {
                                       [self.progressView setHidden:YES];
                                   } else {
                                       self.progressView.progress = (CGFloat) processed / (CGFloat) total;
                                       [self.progressView setHidden:NO];
                                   }
                               }
                              finishCallback:^(UIImage *i) {
                                  [[BoardAPI api] cancelRequest:self.task];
                                  self.task = nil;

                                  self.image = i;
                                  if (completeBlock) completeBlock();
                              }];
}

# pragma mark scrollview

- (UIView *) viewForZoomingInScrollView:(nonnull UIScrollView *)scrollView {
    return self.imageView;
}

@end