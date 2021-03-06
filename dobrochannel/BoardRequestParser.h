//
//  BoardRequestDelegate.h
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YAJL.h"

#define BoardRequestParserBoardForm 0
#define BoardRequestParserPostsForm 1
#define BoardRequestParserPostForm 2

@protocol BoardRequestParserDelegate <NSObject>

- (void) didParsedThread:(NSDictionary *) thread;
- (void) didParsedPost:(NSDictionary *) post;
- (void) didFinishedParsingWithError:(NSError *) e;

@end

@interface BoardRequestParser : NSObject <NSURLSessionDataDelegate, YAJLDocumentDelegate>
- (instancetype) initWithDelegate:(id<BoardRequestParserDelegate>) delegate;
- (instancetype) initWithDelegate:(id<BoardRequestParserDelegate>) delegate
                             form:(int) _sf;

@end