//
//  ThreadViewController.h
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContentViewController.h"

@interface ThreadViewController : ContentViewController
@property (nonatomic) NSString *board;
@property (nonatomic) NSNumber *identifier;

@end
