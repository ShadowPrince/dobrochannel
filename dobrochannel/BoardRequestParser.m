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
    NSInteger parsingForm;
    NSUInteger f_brackets, brackets, threadStart, postStart;
    BOOL quotes;

    NSInteger f_brackets_post_start, f_brackets_post_end, brackets_post_start, brackets_post_end;
    Byte bracketsMask;
}
@property (weak) id<BoardRequestParserDelegate> delegate;
@end @implementation BoardRequestParser

- (instancetype) initWithDelegate:(id<BoardRequestParserDelegate>) delegate
                             form:(int)_sf {
    self = [super init];
    self.delegate = delegate;

    buffer = [NSMutableString string];
    f_brackets = 0;
    brackets = 0;
    threadStart = postStart = 0;
    quotes = NO;

    parsingForm = _sf;
    switch (_sf) {
        case BoardRequestParserBoardForm:
            f_brackets_post_start = 5;
            f_brackets_post_end = 4;
            brackets_post_start = 2;
            brackets_post_end = 2;
            break;
        case BoardRequestParserPostsForm:
            f_brackets_post_start = 2;
            f_brackets_post_end = 1;
            brackets_post_start = 1;
            brackets_post_end = 1;
            break;
        case BoardRequestParserPostForm:
            f_brackets_post_start = 1;
            f_brackets_post_end = 0;
            brackets_post_start = 0;
            brackets_post_end = 0;
            break;
        default:
            break;
    }

    return self;
}

- (instancetype) initWithDelegate:(id<BoardRequestParserDelegate>)delegate {
    return [self initWithDelegate:delegate form:BoardRequestParserBoardForm];
}

- (void) URLSession:(nonnull NSURLSession *)session task:(nonnull NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    [self.delegate didFinishedParsing];
}

- (void) URLSession:(nonnull NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveData:(nonnull NSData *)data {
    NSUInteger startingPoint = [buffer length];
    NSString *chunk = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [buffer appendString:chunk];
    for (unsigned long i = startingPoint, pi = startingPoint; i < [buffer length]; i++) {
        if (i > startingPoint + 1)
            pi++;

        unichar prech = [buffer characterAtIndex:pi];
        unichar ch = [buffer characterAtIndex:i];

        if (prech == '\\')
            continue;

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
            } else if (parsingForm == BoardRequestParserBoardForm) {
                [self.delegate didParsedThread:thread];
            }
        }

        if (ch == '{' && f_brackets == f_brackets_post_start && brackets == brackets_post_start) {
            // post start
            postStart = i;
        }

        if (ch == '}' && f_brackets == f_brackets_post_end && brackets == brackets_post_end) {
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