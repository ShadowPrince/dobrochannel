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

    if (!self.board) {
        self.board = @"b";
    }
}

- (IBAction)nextPageAction:(id)sender {
    [self.api requestThreadsFrom:self.board page:[NSNumber numberWithInteger:++self.page] stateCallback:progressCallback];
    [self updateNavigationItem];
}

- (void) setBoard:(NSString *)board {
    _board = board;
    self.page = 0;

    [self reset];

    [self.api requestThreadsFrom:self.board page:@0 stateCallback:progressCallback];
    [self updateNavigationItem];
}

- (void) updateNavigationItem {
    self.navigationItem.title = [NSString stringWithFormat:@"/%@/%lu", self.board, (unsigned long) self.page];
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
        controller.board = self.board;
    }

    if ([segue.identifier isEqualToString:@"2boardSwitcherController"]) {
        BoardSwitcherViewController *controller = segue.destinationViewController;

        controller.controller = self;
    }
}

@end
