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
#import "UserDefaults.h"

@protocol BoardManagedObjectContextDelegate <NSObject>

- (void) context:(NSManagedObjectContext *) context didInsertedObject:(NSManagedObject *) object;

@end

@interface BoardManagedObjectContext : NSManagedObjectContext <BoardDelegate>
@property (weak) id<BoardManagedObjectContextDelegate> delegate;

- (instancetype) initWithPersistentPath:(NSString *) filePath;

- (NSManagedObject *) postObjectForDisplayId:(NSNumber *) _id;
- (void) clearPersistentStorage;
@end
