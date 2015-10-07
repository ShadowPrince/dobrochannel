//
//  PostViewController.m
//  dobrochannel
//
//  Created by shdwprince on 7/31/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "PostViewController.h"

@interface PostViewController ()
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

@property CGPoint viewOrigin, swipeOrigin;
@property CFAbsoluteTime swipeStart;
@end@implementation PostViewController
@synthesize targetObject;
@synthesize identifier, threadIdentifier, maxHeight;

- (instancetype) init {
    return [self initWithCoder:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setMode:ContentViewControllerModeSingle];
    [self.loadingIndicator startAnimating];

    if (self.targetObject) {
        self.context = self.supercontroller.context;
        [self insetObject:self.targetObject];
        [self insertNewRows];
        [self shouldLayoutContent];
    } else {
        [self.api requestPost:self.identifier
                         from:self.threadIdentifier
                           at:self.board
                stateCallback:nil];
    }
}

- (void) loadView {
    UINib *nib = [UINib nibWithNibName: @"PostViewController" bundle:[NSBundle bundleForClass:[self class]]];
    self.view = [[nib instantiateWithOwner:self options:nil] objectAtIndex:0];
}

- (void) viewWillAppear:(BOOL)animated {
    self.viewOrigin = self.view.frame.origin;
    self.view.alpha = 0.f;
}

- (void) viewDidAppear:(BOOL)animated {
    CGPoint startingPoint = CGPointMake(self.viewOrigin.x, self.viewOrigin.y - 100.f);
    self.view.frame = CGRectMake(startingPoint.x,
                                 startingPoint.y,
                                 self.view.frame.size.width,
                                 self.view.frame.size.height);

    [UIView animateWithDuration:0.2f animations:^{
        self.view.alpha = 1.f;
        self.view.frame = CGRectMake(self.viewOrigin.x,
                                     self.viewOrigin.y,
                                     self.view.frame.size.width,
                                     self.view.frame.size.height);
    }];
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    if (!self.loadingIndicator.isAnimating) {
        [self setHeight:[self tableView:(UITableView *)[NSNull null]
                heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]];
    }
}

///////

- (void) panGesture:(UIGestureRecognizer *) sender {
    CGPoint loc = [sender locationInView:self.supercontroller.view];
    CGFloat x = loc.x - self.swipeOrigin.x;
    CGFloat visible_treshhold = 300.f;
    CGFloat logical_treshhold = 75.f;
    __block CGRect frame = self.view.frame;

    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            self.swipeOrigin = loc;
            self.swipeStart = CFAbsoluteTimeGetCurrent();
            break;
        case UIGestureRecognizerStateChanged:
            frame.origin = CGPointMake(self.viewOrigin.x + x, self.viewOrigin.y);
            self.view.alpha = 1. - fabs(x) / visible_treshhold;
            self.view.frame = frame;
            break;
        case UIGestureRecognizerStateEnded:
            if (fabs(x) < logical_treshhold) {
                [UIView animateWithDuration:0.2f animations:^{
                    self.view.frame = CGRectMake(self.viewOrigin.x,
                                                 self.viewOrigin.y,
                                                 self.view.frame.size.width,
                                                 self.view.frame.size.height);
                    self.view.alpha = 1.f;
                }];
            } else {
                float spd = (CFAbsoluteTimeGetCurrent() - self.swipeStart) / fabs(x);
                CGFloat pixels_to_move = visible_treshhold - fabs(x);

                [UIView animateWithDuration:pixels_to_move * spd animations:^{
                    self.view.frame = CGRectMake(self.viewOrigin.x + (x > 0 ? visible_treshhold : -visible_treshhold),
                                                 self.viewOrigin.y,
                                                 self.view.frame.size.width,
                                                 self.view.frame.size.height);
                    self.view.alpha = 1. - fabs(self.view.frame.origin.x - self.viewOrigin.x) / visible_treshhold;
                } completion:^(BOOL finished) {
                    [self.supercontroller popPopup];
                }];
            }

            break;
        default: break;
    }
}

///////

- (BOOL) shouldInsertObject:(NSManagedObject *)object {
    // skip is_op check
    return [object.entity.name isEqualToString:@"Post"];
}

- (void) didInsertObject:(NSManagedObject *)object {
    [super didInsertObject:object];
    [self.loadingIndicator stopAnimating];
    [self.view setNeedsLayout];
}

- (void) context:(NSManagedObjectContext *)context didInsertedObject:(NSManagedObject *)object {
    [super context:context didInsertedObject:object];
    [self insertNewRows];
}

////

- (void) prepareCell:(BoardTableViewCell *) cell {
    [cell setAttachmentTouchTarget:self.supercontroller action:@selector(attachmentTouch:)];
    [cell setBoardlinkTouchTarget:self.supercontroller action:@selector(boardlinkTouch:context:)];


    if ([cell isKindOfClass:[PostTableViewCell class]]) {
        // NSSelectorFromString used for supressing compiler warning
        [((PostTableViewCell *) cell) setHeaderTouchTarget:self.supercontroller
                                                    action:NSSelectorFromString(@"postReplyTouch:")];
    } else if ([cell isKindOfClass:[ThreadTableViewCell class]]) {
        [(ThreadTableViewCell *) cell setReplyTouchTarget:self.supercontroller
                                                   action:NSSelectorFromString(@"threadReplyTouch:")];
    }

}

- (void) setHeight:(CGFloat) height {
    CGRect frame = self.view.frame;
    if (height > self.maxHeight) {
        frame.size.height = self.maxHeight;
    } else {
        frame.size.height = height + 5.f;
    }
    self.view.frame = frame;
}

- (void) dealloc {
    NSLog(@"DEALLOC");
}

@end