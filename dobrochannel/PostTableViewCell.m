//
//  PostTableViewCell.m
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "PostTableViewCell.h"

@interface PostTableViewCell ()
@property NSMutableArray *answers;
@property CGFloat answersBaseHeight;
@property NSOperationQueue *queue;
//---
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *answersViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UICollectionView *answersCollectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollViewWidthConstraint;
@property (weak, nonatomic) IBOutlet UIButton *headerButton;
@property (weak, nonatomic) IBOutlet UITableView *attachmentsView;
@end @implementation PostTableViewCell
@synthesize post;

- (void) awakeFromNib {
    self.queue = [NSOperationQueue new];
    self.answers = [NSMutableArray new];

    self.dynamicTextView = self.messageTextView;
    self.dynamicTextView.font = [UIFont systemFontOfSize:12.f];

    self.dynamicTableDelegate = [[AttachmentsTableDelegate alloc] init];
    self.dynamicTableView = self.attachmentsView;

    self.dynamicStackViewScrollWidthConstraint = self.scrollViewWidthConstraint;
    self.dynamicTextViewCombinedOffsets =
    14.f // autolayout padding hardcoded
    + 16.f // post offset
    + 3.f; // message view margin

    self.headerButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.headerButton.titleLabel.backgroundColor = [UIColor whiteColor];

    self.answersBaseHeight = self.answersViewHeightConstraint.constant;
    [self.answersCollectionView registerNib:[UINib nibWithNibName:@"AnswerCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"Cell"];

    [super awakeFromNib];
}

- (void) populate:(NSManagedObject *)data
      attachments:(NSArray *)attachments {
    [self populateForHeightCalculation:data
                           attachments:attachments];

    self.answersViewHeightConstraint.constant = self.answers.count == 0 ? 0.f : self.answersBaseHeight;
    [self.answersCollectionView reloadData];

    self.idLabel.text = [NSString stringWithFormat:@"#%@", [data valueForKey:@"display_identifier"]];
    self.dateLabel.text = [data valueForKey:@"date"];
    self.messageTextView.attributedText = [data valueForKey:@"attributedMessage"];
    [self.attachmentsView reloadData];

    self.post = data;
}

- (void) populateForHeightCalculation:(NSManagedObject *)object
                          attachments:(NSArray *)attachments {
    self.dynamicText = [object valueForKey:@"attributedMessage"];
    self.answers = [NSMutableArray new];

    for (NSString *identifier in [[object valueForKey:@"answers"] componentsSeparatedByString:@","]) {
        if (identifier.length)
            [self.answers addObject:[NSNumber numberWithInteger:identifier.integerValue]];
    }

    [super populateForHeightCalculation:object
                            attachments:attachments];
}

- (void) setupAttachmentOffsetFor:(CGSize) parentSize {
    self.dynamicLeftOffset = parentSize.width / 3.5;
}

- (void) setBoardlinkTouchTarget:(id) target
                          action:(SEL) action {
    self.textViewDelegate = [[MessageTextViewDelegate alloc] initWithTarget:target action:action];
    self.textViewDelegate.contextObject = self.post;
    self.dynamicTextView.delegate = self.textViewDelegate;
}

- (void) setHeaderTouchTarget:(id) target
                       action:(SEL) action {
    [self.headerButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (CGFloat) calculatedHeight:(CGSize)parentSize {
    CGFloat height = [super calculatedHeight:parentSize];
    if (!self.answers.count) {
        height -= self.answersBaseHeight;
    }

    return height;
}

#pragma mark answers collection view

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *identifier = self.answers[indexPath.row];
    [self.textViewDelegate fireActionWith:identifier.stringValue contextObject:self.post];
}

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.answers.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AnswerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    NSNumber *answer = self.answers[indexPath.row];
    [cell populate:answer];
    return cell;
}

@end