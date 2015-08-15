//
//  ImageCollectionViewCell.m
//  dobrochannel
//
//  Created by shdwprince on 8/12/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "ImageCollectionViewCell.h"

@interface ImageCollectionViewCell ()
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end @implementation ImageCollectionViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void) setDownloadingProgress:(CGFloat)completed of:(CGFloat)total {
    self.progressView.progress = completed / total;

    if (completed == 0 && total == 0) {
        [self.activityIndicator stopAnimating];
        [self.progressView setHidden:YES];
    } else if (completed == total) {
        [self.activityIndicator stopAnimating];
        [self.progressView setHidden:NO];
    } else {
        if (!self.activityIndicator.isAnimating)
            [self.activityIndicator startAnimating];
        
        [self.progressView setHidden:NO];
    }
}

@end