//
//  DanbooruPickerViewController.m
//  dobrochannel
//
//  Created by shdwprince on 8/12/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "DanbooruPickerViewController.h"

@interface DanbooruPickerViewController ()
@property (weak) NSObject<DanbooruPickerDelegate> *delegate;
@property DanbooruAPI *api;
@property int page;
@property NSArray *tags;

@property BOOL shouldLoadNextPage;
@property NSObject *loadNextPageMutex;
@property NSInteger requestedImages;
@property NSInteger attachedImages;

@property NSMutableArray *imageInfos;
@property NSMutableDictionary *thumbnailTasks;
@property NSMutableDictionary *imageDownloadingProgress;
@property NSArray *searchTags;
@property NSURLSessionTask *searchTask;
//--
@property (strong, nonatomic) IBOutlet UISearchDisplayController *tagsSearchDisplay;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end @implementation DanbooruPickerViewController

- (instancetype) initWithDelegate:(NSObject<DanbooruPickerDelegate> *) delegate {
    self = [super init];
    self.delegate = delegate;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.api = [[DanbooruAPI alloc] initWithDelegate:self];
    [self.collectionView registerNib:[UINib nibWithNibName:@"ImageCollectionViewCell" bundle:nil]
          forCellWithReuseIdentifier:@"Cell"];

    self.tags = @[];
    [self reset];
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGFloat size = 0;

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        size = self.view.frame.size.width / 9;
    } else {
        size = self.view.frame.size.width / 3;
    }
    [(UICollectionViewFlowLayout *) self.collectionView.collectionViewLayout setItemSize:CGSizeMake(size, size)];
}

- (void) reset {
    self.page = 1;

    self.thumbnailTasks = [NSMutableDictionary new];
    self.imageInfos = [NSMutableArray new];
    self.searchTags = [NSMutableArray new];
    self.imageDownloadingProgress = [NSMutableDictionary new];

    [self.collectionView reloadData];
}

- (void) requestImages {
    [self.activityIndicator startAnimating];
    [self.api requestImagesFor:self.tags page:self.page];
}

- (void) requestNextPage {
    self.page++;
    [self requestImages];
}


- (void) displayErrors:(NSArray *) errors {
    UIAlertController *c = [UIAlertController alertControllerWithTitle:@"Error"
                                                               message:[errors componentsJoinedByString:@"\n"]
                                                        preferredStyle:UIAlertControllerStyleAlert];

    c.popoverPresentationController.sourceRect = self.navigationController.navigationBar.frame;
    c.popoverPresentationController.sourceView = self.view;
    [c addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:c animated:YES completion:nil];
}
//

- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    NSArray *tagsInbound = [searchText componentsSeparatedByString:@" "];
    NSString *lastTag = [tagsInbound lastObject];

    [self.searchTask cancel];
    self.searchTask = [self.api requestTagsMatching:[lastTag stringByAppendingString:@"*"]];

    self.searchTags = @[];
    [self.tagsSearchDisplay.searchResultsTableView reloadData];
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *entry = self.imageInfos[indexPath.row];
    self.requestedImages++;

    [self.api downloadImage:entry finishCallback:^(NSURL *url) {
        [self.delegate danbooruPicker:self didPickImageAt:url];
        self.attachedImages++;
    }];
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    self.tags = [searchBar.text componentsSeparatedByString:@" "];
    [self reset];
    [self requestImages];

    [self.tagsSearchDisplay setActive:NO animated:YES];
}

- (IBAction)doneAction:(id)sender {
    [self.delegate danbooruPicker:self didFinishPicking:self.attachedImages];
}

#pragma mark - api

- (void) didReceiveImage:(NSDictionary *)info {
    [self.imageInfos addObject:info];

    [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.imageInfos.count - 1 inSection:0]]];
}

- (void) didReceiveTags:(NSArray *)array {
    self.searchTags = array;
    [self.tagsSearchDisplay.searchResultsTableView reloadData];
}

- (void) imageDownloadingTask:(NSDictionary *)image
                     progress:(long long)completed
                           of:(long long)total {
    NSValue *value = [NSValue valueWithCGSize:CGSizeMake((CGFloat) completed, (CGFloat) total)];
    self.imageDownloadingProgress[image] = value;
    NSInteger row = [self.imageInfos indexOfObject:image];

    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]]];
}

- (void) didFinishedRequest {
    [self.activityIndicator stopAnimating];

    if (self.shouldLoadNextPage && !self.api.isRequesting) {
        [self requestNextPage];
        self.shouldLoadNextPage = NO;
    }
}

- (void) didFailRequest:(NSString *)msg {
    [self displayErrors:@[msg]];
}

#pragma mark - tag search

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (![tableView dequeueReusableCellWithIdentifier:@"Cell"]) {
        [tableView registerNib:[UINib nibWithNibName:@"SearchSuggestionTableViewCell" bundle:nil]
        forCellReuseIdentifier:@"Cell"];
    }
    return self.searchTags.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SearchSuggestionTableViewCell *cell = (SearchSuggestionTableViewCell *)
    [tableView dequeueReusableCellWithIdentifier:@"Cell"];

    NSDictionary *entry = self.searchTags[indexPath.row];

    cell.nameLabel.text = entry[@"name"];
    cell.countLabel.text = [NSString stringWithFormat:@"%@", entry[@"post_count"]];

    NSArray *colors = @[[UIColor blueColor],
                        [UIColor redColor],
                        [UIColor yellowColor],
                        [UIColor blackColor],
                        [UIColor greenColor], ];

    cell.bulletLabel.textColor = colors[[(NSNumber *) entry[@"category"] integerValue]];

    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *tagsInbound = [self.searchBar.text componentsSeparatedByString:@" "];
    NSArray *tagsInboundNoLast = [tagsInbound subarrayWithRange:NSMakeRange(0, tagsInbound.count - 1)];

    NSDictionary *entry = self.searchTags[indexPath.row];
    self.searchBar.text = [[tagsInboundNoLast componentsJoinedByString:@" "] stringByAppendingString:entry[@"name"]];
}

#pragma mark - colleciton view

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.imageInfos.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.imageInfos.count - 1) {
        if (self.api.isRequesting) {
            self.shouldLoadNextPage = YES;
        } else {
            [self requestNextPage];
            self.shouldLoadNextPage = NO;
        }
    }

    ImageCollectionViewCell *cell = (ImageCollectionViewCell *)
    [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];

    NSDictionary *info = self.imageInfos[indexPath.row];

    [self.thumbnailTasks[indexPath] cancel];
    cell.imageView.image = nil;

    NSURLSessionDataTask *task = [self.api requestThumbnailFor:info finishCallback:^(UIImage *i) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (cell.imageView.image != i)
                cell.imageView.image = i;
        });
    }];

    if (task)
        self.thumbnailTasks[indexPath] = task;

    cell.sizeLabel.text = [NSByteCountFormatter stringFromByteCount:[(NSNumber *) info[@"file_size"] longLongValue] countStyle:NSByteCountFormatterCountStyleFile];

    NSValue *downloadingProgress = self.imageDownloadingProgress[info];
    if (downloadingProgress) {
        CGSize progress = downloadingProgress.CGSizeValue;
        [cell setDownloadingProgress:progress.width of:progress.height];
    } else {
        [cell setDownloadingProgress:0. of:0.];
    }

    return cell;
}

- (void) dealloc {
    NSLog(@"dealloc");
}

@end