//
//  BoardRequestDelegate.h
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BoardRequestParserDelegate <NSObject>

- (void) didParsedThread:(NSDictionary *) thread;
- (void) didParsedPost:(NSDictionary *) post;

@end

@interface BoardRequestParser : NSObject <NSURLSessionDataDelegate>
@property (assign) int64_t received, total;

- (instancetype) initWithDelegate:(id<BoardRequestParserDelegate>) delegate;
@end
