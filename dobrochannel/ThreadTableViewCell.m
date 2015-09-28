//
//  ThreadTableViewCell.m
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "ThreadTableViewCell.h"

@interface ThreadTableViewCell ()
@property NSDateFormatter *dateFormatter;
//---
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollViewWidthConstraint;
@property (weak, nonatomic) IBOutlet UITableView *attachmentsView;
@property (weak, nonatomic) IBOutlet UIButton *replyButton;
@end @implementation ThreadTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void) awakeFromNib {
    self.titleButton.titleLabel.backgroundColor = [UIColor whiteColor];
    
    self.dynamicTextView = self.messageTextView;
    self.dynamicTextView.font = [UIFont systemFontOfSize:12.f];

    self.dynamicTableDelegate = [[AttachmentsTableDelegate alloc] init];
    self.dynamicTableView = self.attachmentsView;

    self.dynamicStackViewScrollWidthConstraint = self.scrollViewWidthConstraint;
    self.dynamicTextViewCombinedOffsets = 3.f; // message view margin

    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterShortStyle;
    self.dateFormatter.timeStyle = NSDateFormatterShortStyle;

    [super awakeFromNib];
}

- (void) populate:(NSManagedObject *)data
      attachments:(NSArray *)attachments {
    [super populate:data attachments:attachments];

    self.idLabel.text = [NSString stringWithFormat:@"#%@", [data valueForKey:@"display_identifier"]];
    [UIView performWithoutAnimation:^{
        [self.titleButton setTitle:[data valueForKey:@"title"] forState:UIControlStateNormal];
    }];

    NSNumber *postsCount = [data valueForKey:@"posts_count"];
    self.statusLabel.text = [NSString stringWithFormat:@"%@ post%@", postsCount, [postsCount isEqualToNumber:@1] ? @"" : @"s"];
    self.dateLabel.text = [self.dateFormatter stringFromDate:[data valueForKeyPath:@"op_post.date"]];
    self.messageTextView.attributedText = self.dynamicText;
    [self.attachmentsView reloadData];
}

- (void) populateForHeightCalculation:(NSManagedObject *)object
                          attachments:(NSArray *)attachments {
    self.dynamicText = [[object valueForKey:@"op_post"] valueForKey:@"attributedMessage"];

    [super populateForHeightCalculation:[object valueForKey:@"op_post"]
                            attachments:attachments];
}

- (void) setupAttachmentOffsetFor:(CGSize) parentSize {
    self.dynamicLeftOffset = parentSize.width / 3.7;
}

- (void) setThreadHeaderTouchTarget:(id) target
                             action:(SEL) action {
    [self.titleButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (void) setBoardlinkTouchTarget:(id) target
                          action:(SEL) action {
    self.textViewDelegate = [[MessageTextViewDelegate alloc] initWithTarget:target action:action];
    self.textViewDelegate.contextObject = self.object;
    self.dynamicTextView.delegate = self.textViewDelegate;
}

- (void) setReplyTouchTarget:(id) target
                       action:(SEL) action {
    [self.replyButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

@end