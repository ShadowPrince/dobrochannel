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
@property NSManagedObject *thread;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *idLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet UIButton *goToThreadButton;

- (void) setThreadHeaderTouchTarget:(id) target
                             action:(SEL) action;

@end