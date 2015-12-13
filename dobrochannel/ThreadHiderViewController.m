//
//  ThreadHiderViewController.m
//  dobrochannel
//
//  Created by shdwprince on 12/11/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "ThreadHiderViewController.h"

static NSString *const ThreadHiderViewController_DBVersion = @"1";
static NSMutableDictionary *ThreadHiderViewController_HideStatistics = nil;

@interface ThreadHiderViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property NSMutableArray *patterns;
@end@implementation ThreadHiderViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [ThreadHiderViewController firstRunInit];
    self.patterns = [[[NSUserDefaults standardUserDefaults] objectForKey:@"threadhider.patterns"] mutableCopy];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void) save {
    [[NSUserDefaults standardUserDefaults] setObject:self.patterns forKey:@"threadhider.patterns"];
}

#pragma mark - datasource

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    NSString *pattern = self.patterns[indexPath.row];
    NSNumber *n = ThreadHiderViewController_HideStatistics[[NSNumber numberWithInteger:indexPath.row]];

    [(UILabel *) [cell viewWithTag:100] setText:pattern];
    [(UILabel *) [cell viewWithTag:101] setText:[NSString stringWithFormat:@"%d", n.integerValue]];
    return cell;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.patterns.count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

#pragma mark - actions

- (IBAction)addPattern:(id)sender {
    UIAlertController *c = [UIAlertController alertControllerWithTitle:nil
                                                               message:nil
                                                        preferredStyle:UIAlertControllerStyleAlert];
    c.popoverPresentationController.sourceRect = self.navigationController.view.frame;
    c.popoverPresentationController.sourceView = self.view;
    c.title = @"Add pattern:";

    [c addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"exact match string in any case";
    }];

    [c addAction:[UIAlertAction actionWithTitle:@"Add"
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * __nonnull action) {
                                            [self.patterns addObject:c.textFields[0].text];
                                            [self save];
                                            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.patterns.count-1 inSection:0]]
                                                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                                            [c removeFromParentViewController];
                                        }]];

    [c addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                          style:UIAlertActionStyleCancel
                                        handler:^(UIAlertAction * __nonnull action) {
                                            [c removeFromParentViewController];
                                        }]];

    c.view.tintColor = self.view.tintColor;
    [self presentViewController:c animated:YES completion:^{
    }];
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (editingStyle) {
        case UITableViewCellEditingStyleDelete:
            [self.patterns removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath, ] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;

        default:
            break;
    }

    [self save];
}


#pragma mark - static helpers

+ (NSUInteger) totalHidedObjects {
    NSInteger total = 0;
    for (NSNumber *n in ThreadHiderViewController_HideStatistics)
        total += n.unsignedIntegerValue;

    return total;
}

+ (void) resetThreadHiderStatistics {
    ThreadHiderViewController_HideStatistics = [NSMutableDictionary new];
}

+ (void) didHideThreadBasedOnPatternAt:(NSUInteger) idx {
    if (ThreadHiderViewController_HideStatistics == nil)
        ThreadHiderViewController_HideStatistics = [NSMutableDictionary new];

    NSNumber *n = ThreadHiderViewController_HideStatistics[[NSNumber numberWithUnsignedInteger:idx]];
    ThreadHiderViewController_HideStatistics[[NSNumber numberWithUnsignedInteger:idx]] = [NSNumber numberWithInteger:n.integerValue + 1];
}

+ (BOOL) shouldHideThread:(NSManagedObject *)object {
    NSString *title;
    if ([object.entity.name isEqualToString:@"Thread"]) {
        title = [object valueForKey:@"title"];
    } else if ([object.entity.name isEqualToString:@"Post"]) {
        NSManagedObject *thread = [object valueForKeyPath:@"thread"];
        title = [thread valueForKeyPath:@"title"];
    }


    if (title) {
        [ThreadHiderViewController firstRunInit];
        NSMutableArray<NSString *> *patterns = [[NSUserDefaults standardUserDefaults] objectForKey:@"threadhider.patterns"];
        
        for (NSUInteger idx = 0; idx < patterns.count; idx++) {
            NSString *pattern = patterns[idx];
            if ([title.lowercaseString containsString:pattern.lowercaseString]) {
                [self didHideThreadBasedOnPatternAt:idx];
                return YES;
            }
        }
    }

    return NO;
}

+ (void) firstRunInit {
    if (![[[NSUserDefaults standardUserDefaults] valueForKey:@"threadhider.db"] isEqualToString:ThreadHiderViewController_DBVersion]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSMutableArray new] forKey:@"threadhider.patterns"];
        [[NSUserDefaults standardUserDefaults] setObject:ThreadHiderViewController_DBVersion forKey:@"threadhider.db"];
    }
}

@end
