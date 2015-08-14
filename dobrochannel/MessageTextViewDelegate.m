//
//  PostTextView.m
//  dobrochannel
//
//  Created by shdwprince on 7/30/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "MessageTextViewDelegate.h"

@interface MessageTextViewDelegate ()
@property (weak) id target;
@property SEL action;
@end @implementation MessageTextViewDelegate
@synthesize contextObject;

- (instancetype) initWithTarget:(id) target
                         action:(nullable SEL)action {
    self = [super init];
    self.target = target;
    self.action = action;

    return self;
}

- (BOOL) textView:(nonnull UITextView *)textView shouldInteractWithURL:(nonnull NSURL *)URL inRange:(NSRange)characterRange {
    NSString *internal_protocol = @"dobrochannel://";
    if ([[[URL absoluteString] substringToIndex:internal_protocol.length] isEqualToString:internal_protocol]) {
        [self.target performSelector:self.action
                          withObject:[[URL absoluteString] substringFromIndex:internal_protocol.length]
                          withObject:self.contextObject];

        return NO;
    } else {
        return YES;
    }
}

@end