//
//  BoardRequestDelegate.m
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "BoardRequestParser.h"

@interface BoardRequestParser ()
@property (weak) id<BoardRequestParserDelegate> delegate;
@property YAJLDocument *parser;
@property NSError *parseError;
@property int form;
@end @implementation BoardRequestParser

- (instancetype) initWithDelegate:(id<BoardRequestParserDelegate>) delegate
                             form:(int)_sf {
    self = [super init];
    self.delegate = delegate;
    self.parser = [[YAJLDocument alloc] init];
    self.parser.delegate = self;
    self.form = _sf;
    self.parseError = nil;

    return self;
}

- (instancetype) initWithDelegate:(id<BoardRequestParserDelegate>)delegate {
    return [self initWithDelegate:delegate form:BoardRequestParserBoardForm];
}

- (void) URLSession:(nonnull NSURLSession *)session task:(nonnull NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    [self.delegate didFinishedParsingWithError:self.parseError ? self.parseError : error];
}

- (void) URLSession:(nonnull NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveData:(nonnull NSData *)data {
    if (!self.parseError) {
        NSError *error;
        YAJLParserStatus status = [self.parser parse:data error:&error];
        if (status == YAJLParserStatusError) {
            self.parseError = error;
        }
    }
}

- (void) document:(YAJLDocument *)document didAddDictionary:(NSDictionary *)dict {
    if (self.form == BoardRequestParserPostForm) {
        if ([[dict valueForKey:@"__class__"] isEqualToString:@"Post"]) {
            [self.delegate didParsedPost:dict];
        }
    } else {
        if ([dict.allKeys containsObject:@"posts"]) {
            if (self.form == BoardRequestParserBoardForm) {
                [self.delegate didParsedThread:dict];
            }
            
            for (NSDictionary *post in dict[@"posts"]) {
                [self.delegate didParsedPost:post];
            }
        }
    }
}

@end
