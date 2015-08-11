//
//  BoardViewController.h
//  dobrochannel
//
//  Created by shdwprince on 7/19/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "BoardAPI.h"
#import "BoardManagedObjectContext.h"
#import "BoardMarkupParser.h"
#import "BoardPostResponseParser.h"

#import "ThreadTableViewCell.h"
#import "PostTableViewCell.h"
#import "ShowAttachmentsViewController.h"

@interface ContentViewController : UIViewController <UITableViewDataSource,
UITableViewDelegate,
UIGestureRecognizerDelegate,
UIDataSourceModelAssociation,
BoardManagedObjectContextDelegate> {
    BoardAPIProgressCallback progressCallback;
}

@property BoardAPI *api;
@property BoardManagedObjectContext *context;
@property NSString *board;

- (void) startedRequest;
- (void) reset;
- (BoardManagedObjectContext *) createContext;

- (void) scrollTo:(NSManagedObject *) object animated:(BOOL) animated;
- (void) scrollToObjectAt:(NSUInteger) pos animated:(BOOL) animated;

- (void) prepareCell:(BoardTableViewCell *) cell;

- (void) didScrollToBottom;
- (void) didInsertObject:(NSManagedObject *) object;
- (BOOL) shouldInsertObject:(NSManagedObject *) object;

- (void) insetObject:(NSManagedObject *) object;
- (void) insertNewRows;

- (IBAction)attachmentTouch:(NSArray *)sender;
- (IBAction) boardlinkTouch:(NSString *)identifier
                    context:(NSManagedObject *) contextObject;

- (void) shouldLayoutContent;

@end
