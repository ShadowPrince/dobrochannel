//
//  SafariAttachmentViewController.m
//  dobrochannel
//
//  Created by shdwprince on 2/19/16.
//  Copyright © 2016 Vasiliy Horbachenko. All rights reserved.
//

#import "SafariAttachmentViewController.h"

@interface SafariAttachmentViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *srcLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property NSURLSessionTask *task;

@end

@implementation SafariAttachmentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.webView.scrollView.bounces = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) viewWillAppear:(BOOL)animated {
    NSString *src = [self.attachment valueForKey:@"src"];
    self.nameLabel.text = [src lastPathComponent];
    self.srcLabel.text = src;

    __weak SafariAttachmentViewController *_self = self;
    self.task = [[BoardAPI api] requestImage:[self.attachment valueForKey:@"thumb_src"]
                               stateCallback:nil
                              finishCallback:^(UIImage *i) {
                                  _self.imageView.image = i;
                              }];
}

- (void) viewDidDisappear:(BOOL)animated {
    if (self.task) {
        [[BoardAPI api] cancelRequest:self.task];
        self.task = nil;
    }
}

- (void) didCenter {
    NSURL *fullUrl = [[BoardAPI api] urlFor:[self.attachment valueForKey:@"src"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:fullUrl];
    [self.webView loadRequest:request];
}

@end
