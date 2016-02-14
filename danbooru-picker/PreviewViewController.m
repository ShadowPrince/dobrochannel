//
//  DanbooruPickerPreviewViewController.m
//  dobrochannel
//
//  Created by shdwprince on 12/11/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "PreviewViewController.h"

@interface PreviewViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *bottomToolbar;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end@implementation PreviewViewController

- (void)viewDidLoad {
    self.imageView.image = self.image;
    CGFloat minZoom = self.scrollView.frame.size.width / self.image.size.width;
    self.scrollView.minimumZoomScale = minZoom;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
}

- (void)viewDidLayoutSubviews {
    self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, self.bottomToolbar.frame.size.height, 0);
}

- (IBAction)attachAction:(id)sender {
    [self.delegate didAttached:self.context];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancelAction:(id)sender {
    [self.delegate didCancelled:self.context];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void) dealloc {
    NSLog(@"preview dealloc");
}

@end
