//
//  ContentViewController+Popups.m
//  
//
//  Created by shdwprince on 8/27/15.
//
//

#import "UIViewController+Popups.h"

@interface UIViewController ()
@property NSMutableArray *postPopups;
@property int numberOfTouches;
@end

@implementation UIViewController (Popups)

- (void) popPopup {
    UIViewController<ViewControllerPopup> *c = self.postPopups.lastObject;
    [c.view removeFromSuperview];
    [self.postPopups removeLastObject];
}

- (void) popAllPopups {
    while (self.postPopups.count)
        [self popPopup];
}

- (void) pushPopup:(UIViewController<ViewControllerPopup> *) pv {
    CGFloat width = self.view.frame.size.width / 1.5;
    CGFloat max_x_offset = self.view.frame.size.width - width;
    CGFloat max_y_offset = self.view.frame.size.height - 100.f;
    CGFloat initial_x_offset = 10.f;
    CGFloat initial_y_offset = self.view.frame.size.height / 2 - 50.f;

    CGFloat x_offset = initial_x_offset + 30.f * self.postPopups.count,
    y_offset = initial_y_offset + 30.f * self.postPopups.count;

    BOOL right_direction = YES;
    while (x_offset > max_x_offset) {
        x_offset -= max_x_offset;
        right_direction = !right_direction;
    }

    while (y_offset > max_y_offset) {
        y_offset -= max_y_offset;
    }

    if (y_offset < initial_y_offset)
        y_offset = initial_y_offset;

    if (!right_direction) {
        x_offset = max_x_offset - x_offset;
    }

    pv.maxHeight = self.view.frame.size.height - y_offset - 10.f;
    pv.view.frame = CGRectMake(x_offset, y_offset, width, 30.f);

    [self.view addSubview:pv.view];
    [self.postPopups addObject:pv];
}

- (IBAction) panPopups:(UIPanGestureRecognizer *)sender {
    if (self.postPopups.count) {
        if (sender.state == UIGestureRecognizerStateBegan) {
            self.numberOfTouches = sender.numberOfTouches;
        }

        if (self.numberOfTouches <= 1) {
            [[self.postPopups lastObject] panGesture:sender];
        } else {
            NSArray *popups = [self.postPopups copy];
            // we copy postPopups since it'll be modifier during obj's panGesture:
            [popups enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [obj panGesture:sender];
            }];
        }
    }
}

@end