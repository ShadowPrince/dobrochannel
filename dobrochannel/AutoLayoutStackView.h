//
//  AutoLayoutStackView.h
//  dobrochannel
//
//  Created by shdwprince on 7/20/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AutoLayoutStackViewChildController <NSObject>
@property UIView *view;
- (CGFloat) calculatedHeight:(CGSize) parentSize;
@end

@interface AutoLayoutStackView : UIView
@property CGFloat viewWidth;

- (void) addController:(id<AutoLayoutStackViewChildController>)controller
             atXOffset:(CGFloat) xOffset;
- (void) addController:(id<AutoLayoutStackViewChildController>) controller;

- (void) removeAllControllers;

@end