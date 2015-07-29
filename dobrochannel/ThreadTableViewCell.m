//
//  ThreadTableViewCell.m
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "ThreadTableViewCell.h"

@interface ThreadTableViewCell ()
//---
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollViewWidthConstraint;
@property (weak, nonatomic) IBOutlet UITableView *attachmentsView;
@end @implementation ThreadTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void) awakeFromNib {
    self.dynamicTextView = self.messageTextView;

    self.dynamicTableDelegate = [[AttachmentsTableDelegate alloc] init];
    self.dynamicTableView = self.attachmentsView;

    self.dynamicStackViewScrollWidthConstraint = self.scrollViewWidthConstraint;
    self.dynamicTextViewCombinedOffsets = 8;

    [super awakeFromNib];
}

- (void) populate:(NSManagedObject *)data
     markupParser:(BoardMarkupParser *)parser {
    [self populateForHeightCalculation:data];

    self.identifier = [data valueForKey:@"identifier"];
    self.idLabel.text = [NSString stringWithFormat:@"#%@", [data valueForKey:@"display_identifier"]];
    self.titleLabel.text = [data valueForKey:@"title"];

    self.messageTextView.attributedText = [parser parse:self.dynamicText];
}

- (void) populateForHeightCalculation:(NSManagedObject *)object {
    self.dynamicText = [[object valueForKey:@"op_post"] valueForKey:@"message"];

    [super populateForHeightCalculation:[object valueForKey:@"op_post"]];
}

- (void) setupAttachmentOffsetFor:(CGSize) parentSize {
    self.dynamicLeftOffset = parentSize.width / 3.7;
}

- (void) setThreadHeaderTouchTarget:(id) target
                             action:(SEL) action {
    [self.goToThreadButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}


@end
