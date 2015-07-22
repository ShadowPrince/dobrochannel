//
//  Networking.h
//  dobrochannel
//
//  Created by shdwprince on 7/19/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

#import "BoardRequestParser.h"
#import "BoardImageDownloadDelegate.h"

typedef void (^BoardAPIProgressCallback) (NSUInteger, NSUInteger);
typedef void (^BoardImageDownloadFinishCallback) (UIImage *);


@protocol BoardDelegate <NSObject>
- (void) didReceivedThread:(NSDictionary *) thread;
- (void) didReceivedPost:(NSDictionary *) post;
@end

@interface BoardAPI : NSObject <BoardRequestParserDelegate>
@property (nonatomic) id<BoardDelegate> delegate;

+ (instancetype) api;

- (void) requestThreadsFrom:(NSString *) board
                       page:(NSNumber *) page
              stateCallback: (BoardAPIProgressCallback) callback;

- (void) requestThread:(NSNumber *) threadId
                  from:(NSString *) board
         stateCallback: (BoardAPIProgressCallback) callback;

- (NSURLSessionDataTask *) requestImage:(NSString *) path
        stateCallback: (BoardAPIProgressCallback) stateCallback
       finishCallback: (BoardImageDownloadFinishCallback) finishCallback;

@end
