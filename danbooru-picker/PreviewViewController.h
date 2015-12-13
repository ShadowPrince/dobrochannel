//
//  DanbooruPickerPreviewViewController.h
//  dobrochannel
//
//  Created by shdwprince on 12/11/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PreviewViewControllerDelegate <NSObject>

- (void) didCancelled:(NSObject *) context;
- (void) didAttached:(NSObject *) context;

@end

@interface PreviewViewController : UIViewController<UIScrollViewDelegate>
@property (weak) NSObject<PreviewViewControllerDelegate> *delegate;
@property NSObject *context;
@property UIImage *image;

@end
