//
//  PostViewController.h
//  dobrochannel
//
//  Created by shdwprince on 7/31/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ContentViewController.h"

@interface PostViewController : ContentViewController
@property NSManagedObject *targetObject;
@property NSNumber *identifier;
@property NSNumber *threadIdentifier;
@property CGFloat maxHeight;

@property (weak) ContentViewController *supercontroller;

@end
