//
//  ZoomingImageController.m
//  dobrochannel
//
//  Created by shdwprince on 7/29/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "ZoomingImageController.h"

@interface ZoomingImageController ()
@property NSManagedObject *attachment;
@property NSURLSessionTask *task;
@property BOOL isCentered, didLoadedSource;
//---
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@property (weak, nonatomic) IBOutlet UIView *infoView;
@property (weak, nonatomic) IBOutlet UILabel *sizesLabel;
@property (weak, nonatomic) IBOutlet UILabel *filenameLabel;

@end @implementation ZoomingImageController
@synthesize image, attachment;

- (instancetype) initWithAttachment:(id)attach
                              frame:(CGRect) frame {
    self = [super init];
    self.view.frame = frame;
    self.attachment = attach;
    self.infoView.alpha = [[self.attachment valueForKey:@"type"] isEqualToString:@"image"] ? 0.f : 1.0f;
    return self;
}

- (void) setImage:(UIImage *)img {
    self.imageView.image = img;
    image = img;
}

- (void)viewWillAppear:(BOOL)animated {
    NSString *thumb_src = [self.attachment valueForKey:@"thumb_src"];
    NSString *full_src = [self.attachment valueForKey:@"src"];

    CGSize size = ((NSValue *) [attachment valueForKey:@"size"]).CGSizeValue;
    NSNumber *weight = [attachment valueForKey:@"weight"];
    self.sizesLabel.text = [NSString stringWithFormat:@"%@, %dx%d",
                            [NSByteCountFormatter stringFromByteCount:weight.longLongValue countStyle:NSByteCountFormatterCountStyleFile],
                            (int) size.width,
                            (int) size.height];
    self.filenameLabel.text = full_src;

    [self request:thumb_src completeWith:^{
        if ([UserDefaults attachmentsViewerLoadFull] && [self shouldLoadFullImage]) {
            self.didLoadedSource = YES;
            [self request:full_src completeWith:nil];
        }
    }];
}

- (void) viewDidDisappear:(BOOL)animated {
    if (self.task)
        [[BoardAPI api] cancelRequest:self.task];
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
    [UIView animateWithDuration:0.25 animations:^{
        self.infoView.alpha = self.infoView.alpha == 0.7f ? 0.f : 0.7f;
    }];
}

- (IBAction)longPressAction:(id)sender {
    NSString *type = [self.attachment valueForKey:@"type"];

    if ([type isEqualToString:@"image"]) {
        if (!self.task) {
            self.progressView.hidden = NO;
            self.progressView.progress = 0.f;
            [self request:[self.attachment valueForKey:@"src"] completeWith:nil];
        }
    } else {
        [[UIApplication sharedApplication] openURL:[[BoardAPI api] urlFor:[attachment valueForKey:@"src"]]];
    }
}

#pragma mark helper methods

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
