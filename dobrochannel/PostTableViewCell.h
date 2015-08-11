    //
//  PostTableViewCell.h
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BoardMarkupParser.h"

#import "BoardTableViewCell.h"

@interface PostTableViewCell : BoardTableViewCell
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *idLabel;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;

@property NSManagedObject *post;


- (void) setHeaderTouchTarget:(id) target
                       action:(SEL) action;

@end
