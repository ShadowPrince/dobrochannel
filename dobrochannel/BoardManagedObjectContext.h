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
#import "BoardMarkupParser.h"
#import "UserDefaults.h"

@protocol BoardManagedObjectContextDelegate <NSObject>

- (void) context:(NSManagedObjectContext *) context didInsertedObject:(NSManagedObject *) object;

@end

@interface BoardManagedObjectContext : NSManagedObjectContext <BoardDelegate, NSCoding>
@property (weak) id<BoardManagedObjectContextDelegate> delegate;
@property BoardMarkupParser *parser;

- (instancetype) initWithPersistentPath:(NSString *) filePath;

- (NSManagedObject *) postObjectForDisplayId:(NSNumber *) _id;
- (void) clearPersistentStorage;

- (NSArray *) requestAttachmentsFor:(NSManagedObject *) post;
- (NSArray *) requestThreads;
- (NSArray *) requestPostsFrom:(NSManagedObject *) thread;

@end