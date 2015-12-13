//
//  BoardPostRequestDelegate.m
//  dobrochannel
//
//  Created by shdwprince on 12/12/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "BoardRequestProgressConnectionDelegate.h"

@interface BoardRequestProgressConnectionDelegate ()
@property NSURLResponse *response;
@property NSMutableData *data;

@end @implementation BoardRequestProgressConnectionDelegate

- (instancetype) init {
    self = [super init];
    self.data = [NSMutableData new];
    return self;
}

- (void) connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    if (self.uploadCallback) {
        self.uploadCallback(totalBytesWritten, totalBytesExpectedToWrite);
    }
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
    if (self.finishCallback) {
        self.finishCallback(self.response, (NSData *) self.data);
    }
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.data appendData:data];
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.response = response;

    if (self.responseCallback) {
        self.responseCallback(self.response);
    }
}

@end
