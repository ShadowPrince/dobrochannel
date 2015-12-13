    //
//  PostTableViewCell.h
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "BoardMarkupParser.h"

#import "BoardTableViewCell.h"
#import "AnswerCollectionViewCell.h"

@interface PostTableViewCell : BoardTableViewCell <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *idLabel;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;

- (void) setHeaderTouchTarget:(id) target
                       action:(SEL) action;

- (void) setOpacity:(BOOL) op;

@end