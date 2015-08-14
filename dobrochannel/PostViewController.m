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
@end@implementation PostViewController
@synthesize targetObject;
@synthesize identifier, threadIdentifier, maxHeight;

- (instancetype) init {
    return [self initWithCoder:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
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

- (BOOL) shouldInsertObject:(NSManagedObject *)object {
    // skip is_op check
    return [object.entity.name isEqualToString:@"Post"];
}

- (void) didInsertObject:(NSManagedObject *)object {
    [super didInsertObject:object];
    [self.loadingIndicator stopAnimating];
    [self.view setNeedsLayout];
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    if (!self.loadingIndicator.isAnimating) {
        [self setHeight:[self tableView:(UITableView *)[NSNull null]
                heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]]];
    }
}

- (void) prepareCell:(BoardTableViewCell *) cell {
    [cell setAttachmentTouchTarget:self.supercontroller action:@selector(attachmentTouch:)];
    [cell setBoardlinkTouchTarget:self.supercontroller action:@selector(boardlinkTouch:context:)];
}

- (void) setHeight:(CGFloat) height {
    CGRect frame = self.view.frame;
    if (height > self.maxHeight) {
        frame.size.height = self.maxHeight;
    } else {
        frame.size.height = height;
    }
    self.view.frame = frame;
}

- (void) dealloc {
    NSLog(@"DEALLOC");
}

@end
