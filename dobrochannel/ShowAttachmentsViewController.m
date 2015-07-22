//
//  ShowAttachmentsViewController.m
//  dobrochannel
//
//  Created by shdwprince on 7/22/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "ShowAttachmentsViewController.h"

@interface ShowAttachmentsViewController ()
@property NSData *imageData;
@property NSMutableDictionary<NSNumber *, NSURLSessionTask *> *downloadingTasks;
@property NSMutableDictionary<NSNumber *, UIImage *> *imagesLoaded;
//---
@property (weak, nonatomic) IBOutlet UIImageView *currentImageView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@end @implementation ShowAttachmentsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    self.currentImageView.image = nil;
    self.downloadingTasks = [NSMutableDictionary new];
    self.imagesLoaded = [NSMutableDictionary new];

    [self loadImageAtIndex];
}

- (void) loadImageAt:(NSUInteger) pos {
    [self.progressView setHidden:YES];

    NSManagedObject *attachment = [self.attachments objectAtIndex:pos];
    if (!self.downloadingTasks[[NSNumber numberWithInteger:pos]]) {
        [[BoardAPI api] requestImage:[attachment valueForKey:@"thumb_src"]
                       stateCallback:^(NSUInteger processed, NSUInteger total) {}
                      finishCallback:^(UIImage *image) {
                           if (!self.imagesLoaded[[NSNumber numberWithInteger:pos]]) {
                               self.imagesLoaded[[NSNumber numberWithInteger:pos]] = image;

                               if (self.index == pos)
                                   self.currentImageView.image = image;
                           }
                       }];

        NSURLSessionTask *task = [[BoardAPI api] requestImage:[attachment valueForKey:@"src"]
                                                stateCallback:^(NSUInteger processed, NSUInteger total) {
                                                    if (self.index != pos)
                                                        return;

                                                    if (processed == total) {
                                                        [self.progressView setHidden:YES];
                                                    } else {
                                                        self.progressView.progress = (CGFloat) processed / (CGFloat) total;
                                                        [self.progressView setHidden:NO];
                                                    }
                                                } finishCallback:^(UIImage *image) {
                                                    self.imagesLoaded[[NSNumber numberWithInteger:pos]] = image;

                                                    if (self.index == pos)
                                                        self.currentImageView.image = image;
                                                }];
        
        self.downloadingTasks[[NSNumber numberWithInteger:pos]] = task;
    } else {
        self.currentImageView.image = self.imagesLoaded[[NSNumber numberWithInteger:pos]];
    }
}

- (void) loadImageAtIndex {
    if (self.index < 0) {
        self.index = 0;
    } else if (self.index >= [self.attachments count]) {
        self.index = [self.attachments count] - 1;
    } else {
        [self loadImageAt:self.index];
    }
}

#pragma mark zoom


#pragma mark actions

- (IBAction)swipeAway:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)swipeRight:(id)sender {
    self.index--;
    [self loadImageAtIndex];
}

- (IBAction)swipeLeft:(id)sender {
    self.index++;
    [self loadImageAtIndex];
}

@end
