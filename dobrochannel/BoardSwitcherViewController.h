//
//  BoardSwitcherViewController.h
//  dobrochannel
//
//  Created by shdwprince on 7/23/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BoardAPI.h"

#import "BoardViewController.h"

@class BoardViewController;

@interface BoardSwitcherViewController : UICollectionViewController <UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak) BoardViewController *controller;


@end