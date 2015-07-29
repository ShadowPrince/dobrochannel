//
//  BoardTableViewCell.h
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "BoardMarkupParser.h"

#import "AttachmentsTableDelegate.h"

@interface BoardTableViewCell : UITableViewCell
@property NSUInteger attachmentsCount;

@property (weak) NSString *dynamicText;
@property (weak) UITextView *dynamicTextView;
@property (weak) UITableView *dynamicTableView;
@property AttachmentsTableDelegate *dynamicTableDelegate;
@property (weak) NSLayoutConstraint *dynamicStackViewScrollWidthConstraint;
@property (assign) CGFloat dynamicTextViewCombinedOffsets;
@property (assign) CGFloat dynamicLeftOffset;

- (void) setAttachmentTouchTarget:(id) target
                           action:(SEL) action;

- (void) populate:(NSManagedObject *) object
     markupParser:(BoardMarkupParser *) parser;
- (void) populateForHeightCalculation:(NSManagedObject *) object;
- (void) setupAttachmentOffsetFor:(CGSize) parentSize;
- (CGFloat) calculatedHeight:(CGSize) parentSize;

@end
