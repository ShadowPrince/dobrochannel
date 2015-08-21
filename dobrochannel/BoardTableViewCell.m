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

- (void) populate:(NSManagedObject *)object
      attachments:(NSArray *)attachments {
    @throw [NSException exceptionWithName:@"Abstract method call" reason:@"populate:markupParser: is abstract" userInfo:nil];
}

- (void) setupAttachmentOffsetFor:(CGSize) parentSize {
    @throw [NSException exceptionWithName:@"Abstract method call" reason:@"setupAttachmentOffsetFor: is abstract" userInfo:nil];
}

- (void) awakeFromNib {
    self.dynamicTableView.delegate = self.dynamicTableDelegate;
    self.dynamicTableView.dataSource = self.dynamicTableDelegate;
    [self.dynamicTableView registerNib:[UINib nibWithNibName:@"AttachmentTableViewCell" bundle:nil]
                forCellReuseIdentifier:@"Cell"];

    // remove text padding
    self.dynamicTextView.textContainerInset = UIEdgeInsetsZero;
    self.dynamicTextView.textContainer.lineFragmentPadding = 0.f;

    [super awakeFromNib];
}

# pragma mark action handling

- (void) setAttachmentTouchTarget:(id) target
                           action:(SEL) action {
    self.dynamicTableDelegate.target = target;
    self.dynamicTableDelegate.action = action;
}

- (void) setBoardlinkTouchTarget:(id) target
                          action:(SEL) action {
}

# pragma mark height calculation

- (void) populateForHeightCalculation:(NSManagedObject *)object
                          attachments:(NSArray *) attachments {
    self.attachmentsCount = [attachments count];

    if (self.attachmentsCount) {
        self.dynamicStackViewScrollWidthConstraint.constant = self.dynamicLeftOffset;
    } else {
        self.dynamicStackViewScrollWidthConstraint.constant = 0.f;
    }

    self.dynamicTableView.contentOffset = CGPointMake(0, 0);
    self.dynamicTableDelegate.objects = attachments;
    self.dynamicTableDelegate.parentSize = CGSizeMake(self.dynamicStackViewScrollWidthConstraint.constant, MAXFLOAT);
    [self.dynamicTableView reloadData];
}


- (CGFloat) calculatedHeight:(CGSize) parentSize {
    CGFloat width = parentSize.width - self.dynamicTextViewCombinedOffsets - self.dynamicStackViewScrollWidthConstraint.constant;
    width = roundf(width * 2) / 2; // round it to x.0 or x.5

    // dynamic text height
    CGSize size = [self.dynamicText.string boundingRectWithSize:CGSizeMake(width, MAXFLOAT)
                                                        options:NSStringDrawingUsesLineFragmentOrigin
                                                     attributes:@{NSFontAttributeName: self.dynamicTextView.font}
                                                        context:nil].size;
    CGFloat height = size.height;

    CGFloat messageExpandHeight = self.frame.size.height - self.dynamicTextView.frame.size.height + height + 1.f;


    // dynamic stack view height
    CGFloat attachmentExpandHeight = self.frame.size.height -
    self.dynamicTableView.frame.size.height +
    [self.dynamicTableDelegate calculatedWidth];

    return MAX(messageExpandHeight, attachmentExpandHeight);
}

@end
