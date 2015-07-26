//
//  ThreadViewController.m
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "ThreadViewController.h"

@interface ThreadViewController ()
@end @implementation ThreadViewController
@synthesize identifier, board;

- (void) viewDidLoad {
    [super viewDidLoad];
    [self.api requestThread:self.identifier from:self.board stateCallback:progressCallback];
}

@end
