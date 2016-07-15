//
//  ThreadTableViewCell.m
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "ThreadTableViewCell.h"

@interface ThreadTableViewCell ()
@property NSDateFormatter *dateFormatter;
//---
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollViewWidthConstraint;
@property (weak, nonatomic) IBOutlet UITableView *attachmentsView;
@property (weak, nonatomic) IBOutlet UIButton *replyButton;
@end @implementation ThreadTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void) awakeFromNib {
    self.titleButton.titleLabel.backgroundColor = [UIColor whiteColor];
    
    self.dynamicTextView = self.messageTextView;

    self.dynamicTableDelegate = [[AttachmentsTableDelegate alloc] init];
    self.dynamicTableView = self.attachmentsView;

    self.dynamicStackViewScrollWidthConstraint = self.scrollViewWidthConstraint;
    self.dynamicTextViewCombinedOffsets = 3.f; // message view margin

    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterShortStyle;
    self.dateFormatter.timeStyle = NSDateFormatterShortStyle;


    UIFont *font = [UserDefaults textFont];
    self.dateLabel.font = font;
    self.idLabel.font = font;
    self.titleButton.titleLabel.font = font;
    self.statusLabel.font = font;

    self.messageTextView.translatesAutoresizingMaskIntoConstraints = YES;
    self.titleButton.translatesAutoresizingMaskIntoConstraints = YES;
    self.dateLabel.translatesAutoresizingMaskIntoConstraints = YES;
    self.idLabel.translatesAutoresizingMaskIntoConstraints = YES;
    self.replyButton.translatesAutoresizingMaskIntoConstraints = YES;
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = YES;
    self.translatesAutoresizingMaskIntoConstraints = YES;
    self.attachmentsView.translatesAutoresizingMaskIntoConstraints = YES;

    [super awakeFromNib];
}

- (void) layoutSubviews {
    CGFloat left = 3.f;
    CGFloat top = 28.f;
    CGFloat height = self.frame.size.height - top - self.statusLabel.frame.size.height;
    if (self.attachmentsCount) {
        self.messageTextView.frame = CGRectMake(self.dynamicLeftOffset + left, top, self.frame.size.width - self.dynamicLeftOffset - left, height);
        self.attachmentsView.frame = CGRectMake(left, top, self.dynamicLeftOffset, height + self.statusLabel.frame.size.height);
    } else {
        self.messageTextView.frame = CGRectMake(left, top, self.frame.size.width - left, height);
        self.attachmentsView.frame = CGRectMake(0, 0, 0, 0);
    }

    self.dateLabel.frame = CGRectMake(self.messageTextView.frame.origin.x,
                                      top + self.messageTextView.frame.size.height,
                                      floorf(self.messageTextView.frame.size.width - self.messageTextView.frame.size.width / 4),
                                      self.dateLabel.frame.size.height);
    self.statusLabel.frame = CGRectMake(self.messageTextView.frame.origin.x + self.dateLabel.frame.size.width,
                                        top + self.messageTextView.frame.size.height,
                                        self.frame.size.width - self.messageTextView.frame.origin.x - self.dateLabel.frame.size.width - 3.f,
                                        self.statusLabel.frame.size.height);

    CGRect frame = self.replyButton.frame;
    frame.origin.x = self.frame.size.width - frame.size.width;
    self.replyButton.frame = frame;

    CGFloat idWidth = [@"#1234567" boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT)
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                             attributes:@{NSFontAttributeName: [UserDefaults textFont], }
                                                context:nil].size.width;
    frame = self.idLabel.frame;
    frame.origin.x = self.frame.size.width - self.replyButton.frame.size.width - idWidth;
    frame.size.width = self.frame.size.width - frame.origin.x - 23.f;
    self.idLabel.frame = frame;

    frame = self.titleButton.frame;
    frame.size.width = self.idLabel.frame.origin.x;
    self.titleButton.frame = frame;

    [super layoutSubviews];
}

- (void) populate:(NSManagedObject *)data
      attachments:(NSArray *)attachments {
    [super populate:data attachments:attachments];

    self.idLabel.text = [NSString stringWithFormat:@"#%@", [data valueForKey:@"display_identifier"]];
    [UIView performWithoutAnimation:^{
        NSMutableString *filler = [NSMutableString new];
        for (int i = 0; i < 3000; i++)
            [filler appendString:@"."];

        NSString *title = [[data valueForKey:@"title"] stringByAppendingString:filler];
        [self.titleButton setTitle:title forState:UIControlStateNormal];
    }];

    long postsCount = [(NSNumber *) [data valueForKey:@"posts_count"] longValue] - 10;
    if (postsCount > 0) {
        self.statusLabel.text = [NSString stringWithFormat:@"%ld post%@ hidden", postsCount, postsCount == 1 ? @"" : @"s"];
    } else {
        self.statusLabel.text = @"no posts hidden";
    }

    self.dateLabel.text = [self.dateFormatter stringFromDate:[data valueForKeyPath:@"op_post.date"]];
    self.messageTextView.attributedText = self.dynamicText;
    [self.attachmentsView reloadData];
}

- (void) populateForHeightCalculation:(NSManagedObject *)object
                          attachments:(NSArray *)attachments {
    self.dynamicText = [[object valueForKey:@"op_post"] valueForKey:@"attributedMessage"];

    [super populateForHeightCalculation:[object valueForKey:@"op_post"]
                            attachments:attachments];
}

- (void) setupAttachmentOffsetFor:(CGSize) parentSize {
    self.dynamicLeftOffset = floorf(parentSize.width / 3.7);
}

- (void) setThreadHeaderTouchTarget:(id) target
                             action:(SEL) action {
    [self.titleButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (void) setBoardlinkTouchTarget:(id) target
                          action:(SEL) action {
    self.textViewDelegate = [[MessageTextViewDelegate alloc] initWithTarget:target action:action];
    self.textViewDelegate.contextObject = self.object;
    self.dynamicTextView.delegate = self.textViewDelegate;
}

- (void) setReplyTouchTarget:(id) target
                       action:(SEL) action {
    [self.replyButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

@end