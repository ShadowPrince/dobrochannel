//
//  BoardTableViewCell.h
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "AttachmentViewController.h"
#import "AutoLayoutStackView.h"

@interface BoardTableViewCell : UITableViewCell
@property NSMutableArray<AttachmentViewController *> *attachmentsControllers;
@property AttachmentViewController *firstAttachment;
@property NSUInteger attachmentsCount;

@property (weak) UITextView *dynamicTextView;
@property (weak) AutoLayoutStackView *dynamicStackView;
@property (weak) NSLayoutConstraint *dynamicStackViewScrollWidthConstraint;
@property (assign) CGFloat dynamicTextViewCombinedOffsets;
@property (assign) CGFloat dynamicLeftOffset;

- (void) setAttachmentTouchTarget:(id) target
                           action:(SEL) action;
- (NSInteger) positionOfAttachmentView:(UIView *) view;

- (void) populate:(NSManagedObject *) object;
- (void) populateForHeightCalculation:(NSManagedObject *) object;
- (void) setupAttachmentOffsetFor:(CGSize) parentSize;
- (CGFloat) calculatedHeight:(CGSize) parentSize;

@end
