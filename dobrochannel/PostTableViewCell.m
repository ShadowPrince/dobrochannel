//
//  PostTableViewCell.m
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "PostTableViewCell.h"

@interface PostTableViewCell ()
//---
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollViewWidthConstraint;
@property (weak, nonatomic) IBOutlet UIButton *headerButton;
@property (weak, nonatomic) IBOutlet UITableView *attachmentsView;
@end @implementation PostTableViewCell
@synthesize post;

- (void) awakeFromNib {

    self.dynamicTextView = self.messageTextView;
    self.dynamicTextView.font = [UIFont systemFontOfSize:12.f];

    self.dynamicTableDelegate = [[AttachmentsTableDelegate alloc] init];
    self.dynamicTableView = self.attachmentsView;

    self.dynamicStackViewScrollWidthConstraint = self.scrollViewWidthConstraint;
    self.dynamicTextViewCombinedOffsets =
    14.f // autolayout padding hardcoded
    + 16.f // post offset
    + 3.f; // message view margin

    self.headerButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.headerButton.titleLabel.backgroundColor = [UIColor whiteColor];

    [super awakeFromNib];
}

- (void) populate:(NSManagedObject *)data
      attachments:(NSArray *)attachments {
    [self populateForHeightCalculation:data
                           attachments:attachments];

    self.idLabel.text = [NSString stringWithFormat:@"#%@", [data valueForKey:@"display_identifier"]];
    self.dateLabel.text = [data valueForKey:@"date"];
    self.messageTextView.attributedText = [data valueForKey:@"attributedMessage"];

    self.post = data;
}

- (void) populateForHeightCalculation:(NSManagedObject *)object
                          attachments:(NSArray *)attachments {
    self.dynamicText = [object valueForKey:@"attributedMessage"];

    [super populateForHeightCalculation:object
                            attachments:attachments];
}

- (void) setupAttachmentOffsetFor:(CGSize) parentSize {
    self.dynamicLeftOffset = parentSize.width / 3.5;
}

- (void) setBoardlinkTouchTarget:(id) target
                          action:(SEL) action {
    self.textViewDelegate = [[MessageTextViewDelegate alloc] initWithTarget:target action:action];
    self.textViewDelegate.contextObject = self.post;
    self.dynamicTextView.delegate = self.textViewDelegate;
}

- (void) setHeaderTouchTarget:(id) target
                       action:(SEL) action {
    [self.headerButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

@end
