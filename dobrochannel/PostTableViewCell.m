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
@property (weak, nonatomic) IBOutlet AutoLayoutStackView *attachmentsView;
@end @implementation PostTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) populate:(NSManagedObject *)data
     markupParser:(BoardMarkupParser *)parser {
    [self populateForHeightCalculation:data];

    self.idLabel.text = [NSString stringWithFormat:@"#%@", [data valueForKey:@"display_identifier"]];
    self.dateLabel.text = [data valueForKey:@"date"];
    self.messageTextView.attributedText = [parser parse:self.dynamicText];

    self.attachmentsControllers = [NSMutableArray new];
    for (NSManagedObject *attachment in [data valueForKey:@"attachments"]) {
        AttachmentViewController *attachmentController = [[AttachmentViewController alloc] initWithAttachment:attachment];
        [self.attachmentsView addController:attachmentController];
        [self.attachmentsControllers addObject:attachmentController];
    }
}

- (void) populateForHeightCalculation:(NSManagedObject *)object {
    self.dynamicStackView = self.attachmentsView;
    self.dynamicTextView = self.messageTextView;
    self.dynamicText = [object valueForKey:@"message"];
    self.dynamicStackViewScrollWidthConstraint = self.scrollViewWidthConstraint;
    self.dynamicTextViewCombinedOffsets = 8;

    [super populateForHeightCalculation:object];
}

- (void) setupAttachmentOffsetFor:(CGSize) parentSize {
    self.dynamicLeftOffset = parentSize.width / 4.5;
}

@end
