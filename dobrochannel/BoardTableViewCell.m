
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "BoardTableViewCell.h"

@interface BoardTableViewCell ()
@property CGFloat autolayoutOffset;
@property CGFloat attachmentsOffset;
@end @implementation BoardTableViewCell

- (void) awakeFromNib {
    self.dynamicTableView.delegate = self.dynamicTableDelegate;
    self.dynamicTableView.dataSource = self.dynamicTableDelegate;
    [self.dynamicTableView registerNib:[UINib nibWithNibName:@"AttachmentTableViewCell" bundle:nil]
                forCellReuseIdentifier:@"Cell"];

    // remove text padding
    self.dynamicTextView.textContainerInset = UIEdgeInsetsZero;
    self.dynamicTextView.textContainer.lineFragmentPadding = 0.f;

    // @TODO: figure out
    if ([UIDevice currentDevice].systemVersion.integerValue == 9) {
        self.autolayoutOffset = 0.f;
    } else {
        self.autolayoutOffset = 0.f;
    }

    [super awakeFromNib];
}

- (void) populate:(NSManagedObject *)object
      attachments:(NSArray *)attachments {
    self.object = object;

    [self populateForHeightCalculation:object
                           attachments:attachments];
}

- (void) setupAttachmentOffsetFor:(CGSize) parentSize {
    @throw [NSException exceptionWithName:@"Abstract method call" reason:@"setupAttachmentOffsetFor: is abstract" userInfo:nil];
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

    CGFloat width = self.attachmentsCount ? self.dynamicLeftOffset : 0.f;
    self.attachmentsOffset = width;

    self.dynamicTableView.contentOffset = CGPointMake(0, 0);
    self.dynamicTableDelegate.objects = attachments;
    self.dynamicTableDelegate.parentSize = CGSizeMake(width, MAXFLOAT);
}

- (CGFloat) messageExpandHeight:(CGSize) parentSize {
    CGFloat combined_offsets = self.dynamicTextViewCombinedOffsets + self.autolayoutOffset;

    CGFloat width = parentSize.width - combined_offsets - self.attachmentsOffset;
    width = roundf(width * 2) / 2; // round it to x.0 or x.5

    // dynamic text height
    CGSize size = [self.dynamicText boundingRectWithSize:CGSizeMake(width, MAXFLOAT)
                                                 options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                                 context:nil].size;
    CGFloat height = size.height;

    CGFloat result = self.frame.size.height - self.dynamicTextView.frame.size.height + height + 1.f;
    return result;
}

- (CGFloat) attachmentExpandHeight {
    CGFloat attachmentExpandHeight = self.frame.size.height -
    self.dynamicTableView.frame.size.height +
    [self.dynamicTableDelegate calculatedWidth];

    return attachmentExpandHeight;
}

- (CGFloat) calculatedHeight:(CGSize) parentSize {
    CGFloat height = MAX([self messageExpandHeight:parentSize], [self attachmentExpandHeight]);
    return height;
}

@end