//
//  ThreadTableViewCell.h
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BoardMarkupParser.h"

#import "BoardTableViewCell.h"

@interface ThreadTableViewCell : BoardTableViewCell
@property (weak, nonatomic) IBOutlet UIButton *titleButton;
@property (weak, nonatomic) IBOutlet UILabel *idLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;

- (void) setThreadHeaderTouchTarget:(id) target
                             action:(SEL) action;
- (void) setReplyTouchTarget:(id) target
                      action:(SEL) action;

@end