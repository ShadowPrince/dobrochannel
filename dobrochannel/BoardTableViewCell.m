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
      attachments:(NSArray *)attachments
     markupParser:(BoardMarkupParser *)parser {
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

    //@TODO: figure out why this isn't working in XIB
    self.dynamicTableView.separatorStyle = UITableViewCellSeparatorStyleNone;

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

    self.dynamicTextView.text = self.dynamicText;
}


- (CGFloat) calculatedHeight:(CGSize) parentSize {
    CGFloat width = parentSize.width - self.dynamicTextViewCombinedOffsets - self.dynamicStackViewScrollWidthConstraint.constant;

    // dynamic text height
    CGSize size = [self.dynamicText boundingRectWithSize:CGSizeMake(width - 18, MAXFLOAT)
                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                              attributes:nil
                                                 context:nil].size;
    CGFloat messageExpandHeight = self.frame.size.height - self.dynamicTextView.frame.size.height + 20 + size.height;

    // dynamic stack view height
    CGFloat attachmentExpandHeight = self.frame.size.height -
    self.dynamicTableView.frame.size.height +
    [self.dynamicTableDelegate calculatedWidth];
    
    return MAX(messageExpandHeight, attachmentExpandHeight);
}

@end