//
//  AnswerCollectionViewCell.m
//  
//
//  Created by shdwprince on 8/23/15.
//
//

#import "AnswerCollectionViewCell.h"

@interface AnswerCollectionViewCell ()
@property (weak, nonatomic) IBOutlet UIButton *button;

@end@implementation AnswerCollectionViewCell
- (void)awakeFromNib {
    //self.button.titleLabel.font = [UserDefaults textFont];
}

- (void) populate:(NSNumber *)postId {
    [UIView performWithoutAnimation:^{
        [self.button setTitle:[NSString stringWithFormat:@">>%@", postId] forState:UIControlStateNormal];
    }];
}

@end
