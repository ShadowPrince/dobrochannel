//
//  AttachmentViewController.h
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "BoardAPI.h"
#import "AutoLayoutStackView.h"

@interface AttachmentViewController : UIViewController <AutoLayoutStackViewChildController>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property NSManagedObject *attachment;

- (instancetype) initWithAttachment:(NSManagedObject *) object;

- (void) setImageTouchTarget:(id) target
                      action:(SEL) action;

@end
