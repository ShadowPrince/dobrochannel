//
//  BoardPostRequestDelegate.h
//  dobrochannel
//
//  Created by shdwprince on 12/12/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^BoardRequestProgressConnectionProgressCallback)(NSInteger written, NSInteger excepted);
typedef void (^BoardRequestProgressConnectionResponseCallback)(NSURLResponse *response);
typedef void (^BoardRequestProgressConnectionFinishCallback)(NSURLResponse *response, NSData *data);

@interface BoardRequestProgressConnectionDelegate : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate, NSURLConnectionDownloadDelegate>

@property (strong) BoardRequestProgressConnectionProgressCallback uploadCallback, downloadCallback;
@property (strong) BoardRequestProgressConnectionResponseCallback responseCallback;
@property (strong) BoardRequestProgressConnectionFinishCallback finishCallback;


@end
