//
//  BoardViewController.m
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "BoardViewController.h"

@interface BoardViewController ()
@property NSMutableArray *pageCounts;
@end @implementation BoardViewController

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (!self.board) {
        self.board = @"b";
    }
}

- (void) reset {
    self.pageCounts = [NSMutableArray new];
    [super reset];
}

#pragma mark actions

- (IBAction)nextPageAction:(id)sender {
    [self.api requestThreadsFrom:self.board page:[NSNumber numberWithInteger:++self.page] stateCallback:progressCallback];
    [self updateNavigationItem:self.board page:self.page];
}

- (void) didScrollToBottom {
    [self.api requestThreadsFrom:self.board page:[NSNumber numberWithInteger:++self.page] stateCallback:progressCallback];
    [self updateNavigationItem:self.board page:self.page];

    [super didScrollToBottom];
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    BoardTableViewCell *cell = [[self.tableView visibleCells] firstObject];
    
    if (cell) {
        NSUInteger position = [self.threads indexOfObject:cell.object];

        NSUInteger i = 0;
        NSUInteger count = 0;
        for (i = 0; i < self.pageCounts.count; i++) {
            NSNumber *object = self.pageCounts[i];
            count += object.integerValue;
            if (count >= position)
                break;
        }

        [self updateNavigationItem:self.board page:i];
    }
}

- (void) context:(NSManagedObjectContext *)context didFinishedLoading:(NSError *)error {
    [super context:context didFinishedLoading:error];

    [self.pageCounts addObject:[NSNumber numberWithInteger:self.threads.count]];
}

#pragma mark helper

- (void) setBoard:(NSString *)board {
    [super setBoard:board];
    self.page = 0;

    [self reset];

    [self.api requestThreadsFrom:self.board page:@0 stateCallback:progressCallback];
    [self updateNavigationItem:self.board page:self.page];
}

- (void) updateNavigationItem:(NSString *) board page:(NSUInteger) page {
    self.navigationItem.title = [NSString stringWithFormat:@"/%@/%lu", board, (unsigned long) page];
}

- (void) prepareCell:(BoardTableViewCell *) cell {
    [super prepareCell:cell];
    
    if ([cell isKindOfClass:[ThreadTableViewCell class]]) {
        // NSSelectorFromString used for supressing compiler warning
        [(ThreadTableViewCell *) cell setThreadHeaderTouchTarget:self action:NSSelectorFromString(@"threadHeaderTouch:")];
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

- (IBAction) unwindFromSettings:(UIStoryboardSegue *)sender {
    [self reloadData];
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

    [self updateNavigationItem:self.board page:self.page];
    progressCallback(1, 1);
}

@end