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
#import "BoardPostResponseParser.h"

#define BoardPostSuccess 0

typedef void (^BoardAPIFinishCallback) (NSData *);
typedef void (^BoardAPIProgressCallback) (long long, long long);
typedef void (^BoardImageDownloadFinishCallback) (UIImage *);
typedef void (^BoardPostFinishCallback) (NSArray *);
typedef void (^BoardSessionFinishCallback) (NSArray *);

@protocol BoardDelegate <NSObject>
- (void) didReceivedThread:(NSDictionary *) thread;
- (void) didReceivedPost:(NSDictionary *) post;
- (void) didFinishedReceiving;
@end

@interface BoardAPI : NSObject <BoardRequestParserDelegate>
@property (weak, nonatomic) id<BoardDelegate> delegate;

+ (instancetype) api;

- (NSDictionary *) boardsList;
- (NSArray *) ratingsList;
- (NSURL *) urlFor:(NSString *) relative;

- (void) cancelRequest:(NSURLSessionTask *) task;
- (void) cancelRequest;
- (BOOL) isRequesting;

- (void) requestThreadsFrom:(NSString *) board
                       page:(NSNumber *) page
              stateCallback: (BoardAPIProgressCallback) callback;
- (void) requestThread:(NSNumber *) threadId
                  from:(NSString *) board
         stateCallback: (BoardAPIProgressCallback) callback;
- (void) requestNewPostsFrom:(NSNumber *) thread
                          at:(NSString *) board
                       after:(NSNumber *) postId
               stateCallback: (BoardAPIProgressCallback) callback;
- (void) requestPost:(NSNumber *) postId
                from:(NSNumber *) threadId
                  at:(NSString *) board
       stateCallback: (BoardAPIProgressCallback) callback;

- (NSURLSessionDataTask *) requestImage:(NSString *) path
        stateCallback: (BoardAPIProgressCallback) stateCallback
       finishCallback: (BoardImageDownloadFinishCallback) finishCallback;

- (NSURLSessionTask *) requestCaptchaAt:(NSString *) board
                         finishCallback:(BoardImageDownloadFinishCallback)finishCallback;

- (void) requestSessionInfoWithFinishCallback:(BoardSessionFinishCallback) finishCallback;

- (void) postInto:(NSNumber *) threadId
               at:(NSString *) board
             data:(NSDictionary *) data
   finishCallback:(BoardPostFinishCallback) callback;

@end