//
//  BoardManagedObjectContext.h
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "BoardAPI.h"


@interface BoardManagedObjectContext : NSManagedObjectContext <BoardDelegate>

@end
