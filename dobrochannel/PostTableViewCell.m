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

    self.dynamicTableDelegate = [[AttachmentsTableDelegate alloc] init];
    self.dynamicTableView = self.attachmentsView;

    self.dynamicStackViewScrollWidthConstraint = self.scrollViewWidthConstraint;
    self.dynamicTextViewCombinedOffsets = 8;

    [super awakeFromNib];
}

- (void) populate:(NSManagedObject *)data
      attachments:(NSArray *)attachments
     markupParser:(BoardMarkupParser *)parser {
    [self populateForHeightCalculation:data
                           attachments:attachments];

    self.idLabel.text = [NSString stringWithFormat:@"#%@", [data valueForKey:@"display_identifier"]];
    self.dateLabel.text = [data valueForKey:@"date"];
    self.messageTextView.attributedText = [parser parse:self.dynamicText];

    self.post = data;
}

- (void) populateForHeightCalculation:(NSManagedObject *)object
                          attachments:(NSArray *)attachments {
    self.dynamicText = [object valueForKey:@"message"];

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
