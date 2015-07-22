//
//  BoardViewController.m
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "BoardViewController.h"

@interface BoardViewController ()
@end @implementation BoardViewController

- (void) viewDidLoad {
    [super viewDidLoad];

    [self.api requestThreadsFrom:@"b" page:@0 stateCallback:progressCallback];
}


- (void) prepareCell:(BoardTableViewCell *) cell {
    [super prepareCell:cell];
    
    if ([cell isKindOfClass:[ThreadTableViewCell class]]) {
        [((ThreadTableViewCell *) cell).goToThreadButton addTarget:self
                                                            action:@selector(threadHeaderTouch:)
                                                  forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void) prepareForSegue:(nonnull UIStoryboardSegue *)segue sender:(nullable id)sender {
    [super prepareForSegue:segue sender:sender];

    if ([segue.identifier isEqualToString:@"2threadController"]) {
        ThreadViewController *controller = segue.destinationViewController;

        controller.identifier = sender;
        controller.board = @"b";
    }
}

@end
