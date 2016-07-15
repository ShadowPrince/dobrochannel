//
//  BoardViewController.h
//  dobrochannel
//
//  Created by shdwprince on 7/19/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "math.h"

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "BoardAPI.h"
#import "BoardManagedObjectContext.h"
#import "BoardMarkupParser.h"
#import "BoardWebResponseParser.h"

#import "ThreadTableViewCell.h"
#import "PostTableViewCell.h"
#import "ShowAttachmentsViewController.h"

#import "UIViewController+Popups.h"
#import "SPAnimationChain.h"

#define ContentViewControllerModeSingle 0
#define ContentViewControllerModeMultiple 1

@interface ContentViewController : UIViewController <UITableViewDataSource,
UITableViewDelegate,
UIGestureRecognizerDelegate,
BoardManagedObjectContextDelegate> {
    BoardAPIProgressCallback progressCallback;
}

@property BoardAPI *api;
@property BoardManagedObjectContext *context;
@property NSString *board;
@property NSMutableArray *threads;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property PostTableViewCell *cachedPostCell;
@property ThreadTableViewCell *cachedThreadView;

- (void) startedRequest;
- (void) reset;
- (BoardManagedObjectContext *) createContext;

- (void) scrollTo:(NSManagedObject *) object animated:(BOOL) animated;
- (void) scrollToObjectAt:(NSUInteger) pos animated:(BOOL) animated;
- (void) setMode:(NSInteger) mode;

- (void) prepareCell:(BoardTableViewCell *) cell;

- (void) didScrollToBottom;
- (void) didInsertObject:(NSManagedObject *) object;
- (BOOL) shouldInsertObject:(NSManagedObject *) object;

- (void) insetObject:(NSManagedObject *) object;
- (void) insertNewRows;
- (void) reloadData;

- (IBAction)attachmentTouch:(NSArray *)sender;
- (IBAction) boardlinkTouch:(NSString *)identifier
                    context:(NSManagedObject *) contextObject;

- (void) shouldLayoutContent;

@end