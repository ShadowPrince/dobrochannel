//
//  BoardPostResponseParser.m
//  dobrochannel
//
//  Created by shdwprince on 8/12/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "BoardWebResponseParser.h"

@implementation BoardWebResponseParser

+ (NSArray *) parseErrorsFromPostData:(NSData *) data {
    NSRegularExpression *expr = [NSRegularExpression regularExpressionWithPattern:@"class='post-error'>([^<\n]*)"
                                                                          options:0
                                                                            error:nil];

    NSString *contents = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *results = [expr matchesInString:contents options:0 range:NSMakeRange(0, contents.length)];

    NSMutableArray *returnResult = [NSMutableArray new];
    for (NSTextCheckingResult *result in results) {
        [returnResult addObject:[contents substringWithRange:[result rangeAtIndex:1]]];
    }

    return returnResult;
}

+ (NSArray *) parseErrorsFromDeleteData:(NSData *) data {
    NSRegularExpression *expr = [NSRegularExpression regularExpressionWithPattern:@"<center><h2>([^<\n]*)"
                                                                          options:0
                                                                            error:nil];

    NSString *contents = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *results = [expr matchesInString:contents options:0 range:NSMakeRange(0, contents.length)];

    NSMutableArray *returnResult = [NSMutableArray new];
    for (NSTextCheckingResult *result in results) {
        [returnResult addObject:[contents substringWithRange:[result rangeAtIndex:1]]];
    }

    return returnResult;
}
@end