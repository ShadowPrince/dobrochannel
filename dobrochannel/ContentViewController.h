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
#import "ThreadTableViewCell.h"
#import "PostTableViewCell.h"
#import "BoardManagedObjectContext.h"

#import "ShowAttachmentsViewController.h"

@interface ContentViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    BoardAPIProgressCallback progressCallback;
}
@property BoardAPI *api;

- (void) prepareCell:(BoardTableViewCell *) cell;

@end
