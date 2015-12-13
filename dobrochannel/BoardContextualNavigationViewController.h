//
//  BoardContextualNavigationViewController.h
//  dobrochannel
//
//  Created by shdwprince on 12/11/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BoardViewController;

@interface BoardContextualNavigationViewController : UINavigationController
@property (weak) BoardViewController *boardViewController;
@end
