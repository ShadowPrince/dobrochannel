//
//  AttachmentViewController.m
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "AttachmentViewController.h"

@interface AttachmentViewController ()
//---
@property (weak, nonatomic) IBOutlet UILabel *paramsLabel;
@property (weak, nonatomic) IBOutlet UIButton *imageViewButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@end @implementation AttachmentViewController

- (instancetype) initWithAttachment:(id)object {
    self = [super init];
    self.attachment = object;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated {
    CGSize size = ((NSValue *) [self.attachment valueForKey:@"size"]).CGSizeValue;
    NSNumber *weight = [self.attachment valueForKey:@"weight"];

    self.paramsLabel.text = [NSString stringWithFormat:@"%@, %dx%d",
                             [NSByteCountFormatter stringFromByteCount:weight.longLongValue countStyle:NSByteCountFormatterCountStyleFile],
                             (int) size.width,
                             (int) size.height];

    [[BoardAPI api] requestImage:[self.attachment valueForKey:@"thumb_src"]
                   stateCallback:^(NSUInteger processed, NSUInteger total) {

                   } finishCallback:^(UIImage *i) {
                       self.imageView.image = i;
                       [self.loadingIndicator stopAnimating];
                   }];
}

- (void) setImageTouchTarget:(id) target
                      action:(SEL) action {
    [self.imageViewButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGFloat) calculatedHeight:(CGSize)parentSize {
    CGSize size = ((NSValue *) [self.attachment valueForKey:@"thumb_size"]).CGSizeValue;
    CGFloat ratio = parentSize.width / size.width;

    return size.height * ratio + 10.f;
}

@end
