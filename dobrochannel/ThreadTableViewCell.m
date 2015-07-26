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
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet AutoLayoutStackView *attachmentsView;
@end @implementation ThreadTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void) populate:(NSManagedObject *)data
     markupParser:(BoardMarkupParser *)parser {
    [self populateForHeightCalculation:data];

    self.identifier = [data valueForKey:@"identifier"];
    self.idLabel.text = [NSString stringWithFormat:@"#%@", [data valueForKey:@"display_identifier"]];
    self.titleLabel.text = [data valueForKey:@"title"];

    NSManagedObject *op_post = [data valueForKey:@"op_post"];

    self.messageTextView.attributedText = [parser parse:self.dynamicText];

    self.attachmentsControllers = [NSMutableArray new];
    for (NSManagedObject *attachment in [op_post valueForKey:@"attachments"]) {
        AttachmentViewController *attachmentController = [[AttachmentViewController alloc] initWithAttachment:attachment];
        [self.attachmentsView addController:attachmentController];
        [self.attachmentsControllers addObject:attachmentController];
    }
}

- (void) populateForHeightCalculation:(NSManagedObject *)object {
    self.dynamicStackView = self.attachmentsView;
    self.dynamicTextView = self.messageTextView;
    self.dynamicText = [[object valueForKey:@"op_post"] valueForKey:@"message"];
    
    self.dynamicStackViewScrollWidthConstraint = self.scrollViewWidthConstraint;
    self.dynamicTextViewCombinedOffsets = 8;

    [super populateForHeightCalculation:[object valueForKey:@"op_post"]];
}

- (void) setupAttachmentOffsetFor:(CGSize) parentSize {
    self.dynamicLeftOffset = parentSize.width / 3.5;
}

- (void) setThreadHeaderTouchTarget:(id) target
                             action:(SEL) action {
    [self.goToThreadButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}


@end
