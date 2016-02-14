//
//  BoardSwitcherViewController.m
//  dobrochannel
//
//  Created by shdwprince on 7/23/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "BoardSwitcherViewController.h"

@interface BoardSwitcherViewController ()
@property NSArray *boardsList;
@property NSDictionary *boardsData;
@property NSDictionary *boardsDiff;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@end @implementation BoardSwitcherViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSDictionary *data = [[BoardAPI api] boardsList];

    self.boardsList = data[@"sorted_keys"];
    self.boardsData = data[@"data"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void) viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES];

    __weak BoardSwitcherViewController *_self = self;
    [[BoardAPI api] requestDiffWithFinishCallback:^(NSDictionary *diff) {
        _self.boardsDiff = diff;
        [_self.collectionView reloadData];
    }];
}

# pragma mark actions

- (IBAction)hideControllerGesture:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) collectionView:(nonnull UICollectionView *)collectionView didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSString *key = self.boardsList[indexPath.section][indexPath.row];
    BoardViewController *controller = [(BoardContextualNavigationViewController *) self.navigationController boardViewController];

    controller.page = 0;
    controller.board = key;

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)touchBoardAction:(UIButton *)sender {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *) sender.superview.superview];
    [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
}

- (IBAction) unwindFromSettings:(UIStoryboardSegue *)sender {
    NSLog(@"undinw");
}
# pragma mark data source

- (UICollectionViewCell *) collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];

    NSString *key = self.boardsList[indexPath.section][indexPath.row];
    NSArray *board = self.boardsData[key];

    UIButton *b = (UIButton *) [cell viewWithTag:100];
    NSNumber *diff = self.boardsDiff[key];

    [UIView performWithoutAnimation:^{
        if (diff && ![diff isEqualToNumber:@0]) {
            [b setTitle:[NSString stringWithFormat:@"/%@/ [%@]", key, diff] forState:UIControlStateNormal];
        } else {
            [b setTitle:[NSString stringWithFormat:@"/%@/", key] forState:UIControlStateNormal];
        }
    }];

    UILabel *l = (UILabel *) [cell viewWithTag:102];
    l.text = board[0];

    l = (UILabel *) [cell viewWithTag:101];
    l.text = board[1];

    return cell;
}

- (NSInteger) collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.boardsList[section] count];
}

- (NSInteger) numberOfSectionsInCollectionView:(nonnull UICollectionView *)collectionView {
    return [self.boardsList count];
}

- (UICollectionReusableView *) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Header" forIndexPath:indexPath];
}

@end