//
//  FavoritesViewController.h
//  dobrochannel
//
//  Created by shdwprince on 12/11/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BoardContextualNavigationViewController.h"
#import "BoardViewController.h"

@interface FavoritesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

+ (BOOL) checkThreadFavorited:(NSNumber *) thread_id;
+ (void) favoriteThread:(NSNumber *) thread_id
                  board:(NSString *) board
                  title:(NSString *) title;
@end
