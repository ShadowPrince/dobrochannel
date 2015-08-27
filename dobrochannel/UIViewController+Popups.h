//
//  ContentViewController+Popups.h
//  
//
//  Created by shdwprince on 8/27/15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol ViewControllerPopup <NSObject>
- (void) setMaxHeight:(CGFloat) height;
- (void) panGesture:(UIPanGestureRecognizer *) sender;
@end

@interface UIViewController (Popups)

- (void) popAllPopups;
- (void) popPopup;
- (void) pushPopup:(UIViewController<ViewControllerPopup> *) pv;
- (void) panPopups:(UIPanGestureRecognizer *) sender;
@end
