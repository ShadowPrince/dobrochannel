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
@property (weak, nonatomic) IBOutlet UITableView *attachmentsView;
@end @implementation PostTableViewCell

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

    self.idLabel.text = [NSString stringWithFormat:@"#%@", [data valueForKey:@"display_identifier"]];
    self.dateLabel.text = [data valueForKey:@"date"];
    self.messageTextView.attributedText = [parser parse:self.dynamicText];
}

- (void) populateForHeightCalculation:(NSManagedObject *)object {
    self.dynamicText = [object valueForKey:@"message"];

    [super populateForHeightCalculation:object];
}

- (void) setupAttachmentOffsetFor:(CGSize) parentSize {
    self.dynamicLeftOffset = parentSize.width / 3.5;
}

@end
