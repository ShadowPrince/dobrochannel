//
//  ShowAttachmentsViewController.h
//  dobrochannel
//
//  Created by shdwprince on 7/22/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "DetailedAttachmentViewController.h"
#import "BoardAPI.h"
#import "UserDefaults.h"

@interface ShowAttachmentsViewController : UIViewController <UIScrollViewDelegate>
@property NSMutableArray *attachments;
@property NSInteger index;

@end