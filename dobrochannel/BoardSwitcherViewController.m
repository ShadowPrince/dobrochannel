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
    [self dismissViewControllerAnimated:YES completion:^{
        NSString *key = self.boardsList[indexPath.row];
        self.controller.board = key;
    }];
}

# pragma mark data source

- (UICollectionViewCell *) collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];

    NSString *key = self.boardsList[indexPath.row];
    NSArray<NSString *> *board = self.boardsData[key];

    UILabel *l = (UILabel *) [cell viewWithTag:100];
    l.text = [NSString stringWithFormat:@"/%@/", key];

    l = (UILabel *) [cell viewWithTag:102];
    l.text = board[0];

    l = (UILabel *) [cell viewWithTag:101];
    l.text = board[1];

    return cell;
}

- (NSInteger) collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.boardsList count];
}

- (NSInteger) numberOfSectionsInCollectionView:(nonnull UICollectionView *)collectionView {
    return 1;
}

@end
