//
//  ShowAttachmentsViewController.m
//  dobrochannel
//
//  Created by shdwprince on 7/22/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "ShowAttachmentsViewController.h"

@interface ShowAttachmentsViewController ()
@property NSMutableArray *zoomingImages;
@property NSInteger page, prev_page;
//---
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@end @implementation ShowAttachmentsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.zoomingImages = [NSMutableArray new];
    for (int i = 0; i < self.attachments.count; i++) {
        [self.zoomingImages addObject:[NSNull null]];
    }

    [self centerAtIndex:self.index];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupContentSize];
    [self loadCurrentPage];
}

- (void) viewWillLayoutSubviews {
    // during orientation change scrollview getting scroll action, so self.page's
    // getting wrong number
    self.prev_page = self.page;
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    [self setupContentSize];
    int i = 0;
    for (DetailedAttachmentViewController *c in self.zoomingImages) {
        if ((id) c != [NSNull null]) {
            CGFloat baseOffset = i * [self pageWidth];
            c.view.frame = CGRectMake(baseOffset,
                                      0,
                                      [self pageWidth],
                                      [self pageHeight]);
        }

        i++;
    }

    [self centerAtIndex:self.prev_page];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (IBAction)swipeAway:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark paging

- (void) scrollViewDidScroll:(nonnull UIScrollView *)scrollView {
    if (self.isViewLoaded)
        [self loadCurrentPage];
}

- (void) loadPage:(NSInteger) page at:(CGFloat) offset {
    if (page < 0 || page > self.attachments.count - 1)
        return;

    if (self.zoomingImages[page] == [NSNull null]) {
        DetailedAttachmentViewController *img = [[DetailedAttachmentViewController alloc]
                                                 initWithAttachment:self.attachments[page]
                                                 frame:CGRectMake(offset,
                                                                  0,
                                                                  [self pageWidth],
                                                                  [self pageHeight])];

        [self.scrollView addSubview:img.view];
        self.zoomingImages[page] = img;
    }
}

- (void) loadCurrentPage {
    self.page = (NSInteger) floor(self.scrollView.contentOffset.x / [self pageWidth]);
    CGFloat baseOffset = self.page * [self pageWidth];

    [self loadPage:self.page - 1 at:baseOffset - [self pageWidth]];
    [self loadPage:self.page at:baseOffset];
    [self loadPage:self.page + 1 at:baseOffset + [self pageWidth]];

    if (self.page >= 0 && self.page < self.attachments.count) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.zoomingImages[self.page] didCenter];
        }];
    }
}

//

- (void) setupContentSize {
    self.scrollView.contentSize = CGSizeMake([self pageWidth] * self.attachments.count,
                                             [self pageHeight]);
}

- (void) centerAtIndex:(NSInteger) index {
    self.scrollView.contentOffset = CGPointMake(index * [self pageWidth],
                                                0);
    self.page = index;
}

//

- (CGFloat) pageWidth {
    CGFloat imageWidth = self.view.frame.size.width;
    return imageWidth;
}

- (CGFloat) pageHeight {
    return self.view.frame.size.height;
}

@end