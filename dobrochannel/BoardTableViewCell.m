//
//  BoardTableViewCell.m
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "BoardTableViewCell.h"

@interface BoardTableViewCell ()

@end @implementation BoardTableViewCell

- (void) populate:(NSDictionary *)data {

}


- (NSInteger) positionOfAttachmentView:(UIView *) view {
    for (int i = 0; i < [self.attachmentsControllers count]; i++) {
        AttachmentViewController *controller = self.attachmentsControllers[i];

        if (controller.view == view)
            return i;
    }

    return -1;
}

# pragma mark action handling

- (void) setAttachmentTouchTarget:(id) target
                           action:(SEL) action {
    for (AttachmentViewController *controller in self.attachmentsControllers) {
        [controller setImageTouchTarget:target action:action];
    }
}

# pragma mark height calculation

- (void) populateForHeightCalculation:(NSManagedObject *)object {
    [self.dynamicStackView removeAllControllers];
    self.dynamicStackView.translatesAutoresizingMaskIntoConstraints = NO;

    NSArray *attachments = [object valueForKey:@"attachments"];
    self.attachmentsCount = [attachments count];
    self.dynamicTextView.text = [object valueForKey:@"message"];

    if (self.attachmentsCount) {
        self.firstAttachment = [[AttachmentViewController alloc] initWithAttachment:attachments[0]];

        self.dynamicStackViewScrollWidthConstraint.constant = self.dynamicLeftOffset;
        self.dynamicStackView.viewWidth = self.dynamicLeftOffset;
    } else {
        self.firstAttachment = nil;
        self.dynamicStackViewScrollWidthConstraint.constant = 0.f;
        self.dynamicStackView.viewWidth = 0.f;
    }
}


- (CGFloat) calculatedHeight:(CGSize) parentSize {
    // dynamic text view height
    CGFloat width = parentSize.width - self.dynamicTextViewCombinedOffsets - self.dynamicStackViewScrollWidthConstraint.constant;
    CGSize size = [self.dynamicTextView sizeThatFits:CGSizeMake(width, FLT_MAX)];
    CGFloat messageExpandHeight = self.frame.size.height - self.dynamicTextView.frame.size.height + size.height;

    // dynamic stack view height
    CGFloat attachmentExpandHeight = 0;
    if (self.attachmentsCount)
        attachmentExpandHeight = self.frame.size.height -
        self.dynamicStackView.frame.size.height +
        [self.firstAttachment calculatedHeight:CGSizeMake(self.dynamicStackViewScrollWidthConstraint.constant, MAXFLOAT)];

    if (self.attachmentsCount > 1)
        attachmentExpandHeight += 20.f;

    return MAX(messageExpandHeight, attachmentExpandHeight);
}

@end
