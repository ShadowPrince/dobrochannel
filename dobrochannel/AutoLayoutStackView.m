//
//  AutoLayoutStackView.m
//  dobrochannel
//
//  Created by shdwprince on 7/20/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "AutoLayoutStackView.h"

@interface AutoLayoutStackView ()
@property id<AutoLayoutStackViewChildController> prevController, lastController, currentController;
@property NSArray *lastConstraints;
@property NSArray *firstConstraints;
//---
@end @implementation AutoLayoutStackView
@synthesize prevController, lastController, currentController;
@synthesize lastConstraints, firstConstraints;

- (void) addController:(id<AutoLayoutStackViewChildController>)controller
             atXOffset:(CGFloat) xOffset {
    self.currentController = controller;


    CGSize size = CGSizeMake(self.viewWidth - xOffset, MAXFLOAT);

    controller.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:controller.view];

    [self addConstraintsForString:@"H:|-%f-[v(==%f)]|", xOffset, self.viewWidth - xOffset];

    if (!self.lastConstraints) {
        // very first
        self.firstConstraints = [self addConstraintsForString:@"V:|[v(==%f)]|", [controller calculatedHeight:size]];
        self.lastConstraints = @[];
    } else {
        [self removeConstraints:self.lastConstraints];

        if (![self.lastConstraints count]) {
            // second
            [self removeConstraints:self.firstConstraints];
            [self addConstraintsForString:@"V:|[lv(==%f)]", [self.lastController calculatedHeight:size]];
            self.lastConstraints = [self addConstraintsForString:@"V:[lv]-[v(==%f)]|", [controller calculatedHeight:size]];
        } else {
            // others
            [self addConstraintsForString:@"V:[pv]-[lv(==%f)]", [self.lastController calculatedHeight:self.frame.size]];
            // adding missing constraint to last view
            self.lastConstraints = [self addConstraintsForString:@"V:[lv]-[v(==%f)]|", [controller calculatedHeight:size]];
        }
    }

    self.currentController = nil;
    self.prevController = self.lastController;
    self.lastController = controller;
}

- (void) addController:(id<AutoLayoutStackViewChildController>)controller {
    return [self addController:controller atXOffset:0.f];
}

- (void) removeAllControllers {
    for (UIView *subview in self.subviews)
        [subview removeFromSuperview];

    [self removeConstraints:self.constraints];

    self.lastConstraints = nil;
    self.prevController = nil;
    self.lastController = nil;
    self.currentController = nil;
}

#pragma mark private methods

- (NSArray *) addConstraintsForString:(NSString *) format,... {
    va_list args;
    va_start(args, format);
    NSString *formatted = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    NSMutableDictionary *views = [NSMutableDictionary dictionaryWithDictionary:@{@"v": self.currentController.view}];
    if (self.prevController)
        views[@"pv"] = self.prevController.view;
    if (self.lastController)
        views[@"lv"] = self.lastController.view;

    NSArray *constrs = [NSLayoutConstraint constraintsWithVisualFormat:formatted
                                                               options:0
                                                               metrics:nil
                                                                 views:views];
    [self addConstraints:constrs];
    return constrs;
}

@end
