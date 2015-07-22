//
//  BoardRequestDelegate.m
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "BoardRequestParser.h"

@interface BoardRequestParser () {
    NSMutableString *buffer;
    NSUInteger f_brackets, brackets, threadStart, postStart;
    BOOL quotes;
}
@property id<BoardRequestParserDelegate> delegate;
@end @implementation BoardRequestParser

- (instancetype) initWithDelegate:(id<BoardRequestParserDelegate>) delegate {
    self = [super init];
    self.delegate = delegate;

    buffer = [NSMutableString string];
    f_brackets = 0;
    brackets = 0;
    threadStart = postStart = 0;
    quotes = NO;

    return self;
}

- (void) URLSession:(nonnull NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveData:(nonnull NSData *)data {
    NSUInteger startingPoint = [buffer length];
    NSString *chunk = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [buffer appendString:chunk];

    for (int i = startingPoint; i < [buffer length]; i++) {
        unichar ch = [buffer characterAtIndex:i];

        if (ch == '"')
            quotes = !quotes;

        if (quotes)
            continue;

        switch (ch) {
            case '{':
                f_brackets++;
                break;
            case '}':
                f_brackets--;
                break;
            case '[':
                brackets++;
                break;
            case ']':
                brackets--;
                break;
        }

        if (ch == '{' && f_brackets == 4 && brackets == 1) {
            // thread start
            threadStart = i;
        }

        if (ch == '[' && f_brackets == 4 && brackets == 2) {
            // thread end
            NSString *threadJson = [[buffer substringWithRange:NSMakeRange(threadStart, i - threadStart)] stringByAppendingString:@"[]}"];
            NSError *e;
            id thread =[NSJSONSerialization JSONObjectWithData:[threadJson dataUsingEncoding:NSUTF8StringEncoding]
                                                       options:0
                                                         error:&e];

            if (!thread) {
                NSLog(@"%@", e);
                NSLog(@"%@", threadJson);
            } else {
                [self.delegate didParsedThread:thread];
            }
        }

        if (ch == '{' && f_brackets == 5 && brackets == 2) {
            // post start
            postStart = i;
        }

        if (ch == '}' && f_brackets == 4 && brackets == 2) {
            // post end
            NSString *postJson = [[buffer substringWithRange:NSMakeRange(postStart, i - postStart)] stringByAppendingString:@"}"];
            NSError *e;
            id post =[NSJSONSerialization JSONObjectWithData:[postJson dataUsingEncoding:NSUTF8StringEncoding]
                                                       options:0
                                                         error:&e];

            if (!post) {
                NSLog(@"%@", e);
                NSLog(@"%@", postJson);
            } else {
                [self.delegate didParsedPost:post];
            }
        }
    }

}

@end
