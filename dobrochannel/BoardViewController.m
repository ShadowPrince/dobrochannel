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

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (!self.board) {
        self.board = @"b";
    }
}

#pragma mark actions

- (IBAction)nextPageAction:(id)sender {
    [self.api requestThreadsFrom:self.board page:[NSNumber numberWithInteger:++self.page] stateCallback:progressCallback];
    [self updateNavigationItem];
}

- (void) didScrollToBottom {
    [self.api requestThreadsFrom:self.board page:[NSNumber numberWithInteger:++self.page] stateCallback:progressCallback];
    [self updateNavigationItem];

    [super didScrollToBottom];
}

#pragma mark helper

- (void) setBoard:(NSString *)board {
    [super setBoard:board];
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
        // NSSelectorFromString used for supressing compiler warning
        [((ThreadTableViewCell *) cell).goToThreadButton addTarget:self
                                                            action:NSSelectorFromString(@"threadHeaderTouch:")
                                                  forControlEvents:UIControlEventTouchUpInside];
    }
}

#pragma mark segues

- (void) prepareForSegue:(nonnull UIStoryboardSegue *)segue sender:(nullable id)sender {
    [super prepareForSegue:segue sender:sender];


    if ([segue.identifier isEqualToString:@"2boardSwitcherController"]) {
        BoardSwitcherViewController *controller = segue.destinationViewController;

        controller.controller = self;
    }
}

- (IBAction) unwindFromNewPost:(UIStoryboardSegue *)sender {
    self.page = 0;
    self.board = self.board;
}

#pragma mark state restoration

- (void) encodeRestorableStateWithCoder:(nonnull NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    [coder encodeInteger:self.page forKey:@"page"];
    [coder encodeObject:self.board forKey:@"board"];
}

- (void) decodeRestorableStateWithCoder:(nonnull NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];

    [super setBoard:[coder decodeObjectForKey:@"board"]];
    self.page = [coder decodeIntegerForKey:@"page"];

    [self updateNavigationItem];
    progressCallback(1, 1);
}

@end