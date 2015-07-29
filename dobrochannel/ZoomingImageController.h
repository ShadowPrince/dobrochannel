//
//  ZoomingImageController.h
//  dobrochannel
//
//  Created by shdwprince on 7/29/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UserDefaults.h"
#import "BoardAPI.h"

@interface ZoomingImageController : UIViewController <UIScrollViewDelegate>
@property (nonatomic) UIImage *image;

- (instancetype) initWithAttachment:(NSManagedObject *) attachment frame:(CGRect) frame;
- (void) didCenter;

@end
