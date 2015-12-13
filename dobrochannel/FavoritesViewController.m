//
//  FavoritesViewController.m
//  dobrochannel
//
//  Created by shdwprince on 12/11/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "FavoritesViewController.h"

static NSString *const FavoritesViewController_DBVersion = @"1";

@interface FavoritesViewController ()
@property NSMutableArray<NSMutableArray<NSDictionary *> *> *favoriteThreads;
@property NSMutableArray<NSString *> *sections;
@property NSDateFormatter *formatter;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end@implementation FavoritesViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.formatter = [NSDateFormatter new];
    self.formatter.dateStyle = NSDateFormatterShortStyle;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];

    [FavoritesViewController firstRunInit];
    self.sections = [[NSUserDefaults standardUserDefaults] valueForKey:@"favorites.sections"];
    self.favoriteThreads = [NSMutableArray new];

    NSArray *favoriteThreads = [[NSUserDefaults standardUserDefaults] valueForKey:@"favorites.threads"];
    for (NSArray *a in favoriteThreads) {
        [self.favoriteThreads addObject:[NSMutableArray new]];

        for (NSDictionary *d in a) {
            [[self.favoriteThreads lastObject] addObject:d];
        }
    }


    self.favoriteThreads[0][0] = @{@"board": @"d",
                                   @"thread_id": [UserDefaults supportThreadNumber],
                                   @"title": @"Dobrochannel",
                                   @"date": [NSDate new], };
    [self.tableView reloadData];
}

- (void) save {
    [[NSUserDefaults standardUserDefaults] setValue:self.favoriteThreads forKey:@"favorites.threads"];
    [[NSUserDefaults standardUserDefaults] setValue:self.sections forKey:@"favorites.sections"];
}

#pragma mark - datasource

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    NSDictionary *fav = self.favoriteThreads[indexPath.section][indexPath.row];

    [(UILabel *) [cell viewWithTag:100] setText:fav[@"title"]];
    [(UILabel *) [cell viewWithTag:101] setText:[NSString stringWithFormat:@">>%@/%@", fav[@"board"], fav[@"thread_id"]]];
    [(UILabel *) [cell viewWithTag:102] setText:[self.formatter stringFromDate:fav[@"date"]]];

    return cell;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.favoriteThreads[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

#pragma mark - delegate

- (IBAction)editAction:(UIBarButtonItem *)sender {
    if (self.tableView.isEditing) {
        [sender setTitle:@"End"];
    } else {
        [sender setTitle:@"Edit"];
    }

    [self.tableView setEditing:!self.tableView.isEditing animated:YES];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *fav = self.favoriteThreads[indexPath.section][indexPath.row];

    BoardViewController *controller = [(BoardContextualNavigationViewController *) self.navigationController boardViewController];
    controller.board = fav[@"board"];
    [controller performSegueWithIdentifier:@"2threadController" sender:fav[@"thread_id"]];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void) tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if (destinationIndexPath.row == 0) {
        [tableView moveRowAtIndexPath:destinationIndexPath toIndexPath:sourceIndexPath];
        [tableView reloadData];
        return;
    }

    NSDictionary *item = self.favoriteThreads[sourceIndexPath.section][sourceIndexPath.row];
    [self.favoriteThreads[sourceIndexPath.section] removeObjectAtIndex:sourceIndexPath.row];
    [self.favoriteThreads[destinationIndexPath.section] insertObject:item atIndex:destinationIndexPath.row];

    [self save];
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (editingStyle) {
        case UITableViewCellEditingStyleDelete:
            [self.favoriteThreads[indexPath.section] removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath, ] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;

        default:
            break;
    }

    [self save];
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row != 0;
}

- (BOOL) tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row != 0;
}

#pragma mark - helper static

+ (BOOL) checkThreadFavorited:(NSNumber *)thread_id {
    [FavoritesViewController firstRunInit];
   
    NSMutableArray *favoriteThreads = [[NSUserDefaults standardUserDefaults] valueForKey:@"favorites.threads"];
    for (NSMutableArray *section in favoriteThreads) {
        for (NSDictionary *x in section)
            if ([x[@"thread_id"] isEqualToNumber:thread_id])
                return YES;
    }

    return NO;
}

+ (void) favoriteThread:(NSNumber *) thread_id board:(NSString *) board title:(NSString *) title {
    [FavoritesViewController firstRunInit];
   
    NSMutableArray *favoriteThreads = [[[NSUserDefaults standardUserDefaults] valueForKey:@"favorites.threads"] mutableCopy];
    NSMutableArray *section = [favoriteThreads[0] mutableCopy];
    [section addObject:@{@"title": title,
                         @"board": board,
                         @"thread_id": thread_id,
                         @"date": [NSDate date], }];

    favoriteThreads[0] = section;
    [[NSUserDefaults standardUserDefaults] setValue:favoriteThreads forKey:@"favorites.threads"];
}

+ (void) firstRunInit {
    if (![[[NSUserDefaults standardUserDefaults] valueForKey:@"favorites.db"] isEqualToString:FavoritesViewController_DBVersion]) {
        NSMutableArray *favoriteThreads = [NSMutableArray new];
        NSMutableArray *sections = [NSMutableArray new];
        
        [sections addObject:@"Main"];
        [favoriteThreads addObject:@{@"board": @"d",
                                     @"thread_id": @100500,
                                     @"title": @"Dobrochannel support",
                                     @"date": [NSDate new], }];

        [[NSUserDefaults standardUserDefaults] setValue:@[favoriteThreads, ] forKey:@"favorites.threads"];
        [[NSUserDefaults standardUserDefaults] setValue:sections forKey:@"favorites.sections"];
        [[NSUserDefaults standardUserDefaults] setValue:FavoritesViewController_DBVersion forKey:@"favorites.db"];
    }
}

@end
