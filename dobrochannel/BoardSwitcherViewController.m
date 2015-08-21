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

# pragma mark actions

- (IBAction)hideControllerGesture:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) collectionView:(nonnull UICollectionView *)collectionView didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSString *key = self.boardsList[indexPath.section][indexPath.row];
    self.controller.page = 0;
    self.controller.board = key;

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)touchBoardAction:(UIButton *)sender {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *) sender.superview.superview];
    [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
}

# pragma mark data source

- (UICollectionViewCell *) collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];

    NSString *key = self.boardsList[indexPath.section][indexPath.row];
    NSArray *board = self.boardsData[key];

    UIButton *b = (UIButton *) [cell viewWithTag:100];
    [UIView performWithoutAnimation:^{
        [b setTitle:[NSString stringWithFormat:@"/%@/", key] forState:UIControlStateNormal];
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