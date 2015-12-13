//
//  UIView+ChainAnimations.m
//  dobrochannel
//
//  Created by shdwprince on 12/12/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "SPAnimationChain.h"

typedef void(^SPAnimationChainAnimationRunner)(void);

@interface SPAnimationChain ()
@property NSMutableArray *runners;
@property BOOL isDebug;
@end @implementation SPAnimationChain

- (instancetype) init {
    self = [super init];
    self.runners = [NSMutableArray new];
    return self;
}

- (SPAnimationChain *) animate:(SPAnimationChainAnimation)anim
                  withDuration:(CGFloat)duration
                         delay:(CGFloat)delay
                       damping:(CGFloat)damping
                      velocity:(CGFloat)velo
                       options:(UIViewAnimationOptions)opts {
    SPAnimationChainAnimationRunner runner = ^void(void) {
        [UIView animateWithDuration:duration
                              delay:delay
             usingSpringWithDamping:damping
              initialSpringVelocity:velo
                            options:opts
                         animations:anim
                         completion:^(BOOL finished) {
                             [self run];
                         }];
    };

    [self.runners addObject:runner];

    return self;
}

- (SPAnimationChain *) animate:(SPAnimationChainAnimation)anim
                  withDuration:(CGFloat)duration
                         delay:(CGFloat)delay
                       damping:(CGFloat)damping
                      velocity:(CGFloat)velo {
    return [self animate:anim
            withDuration:duration
                   delay:delay
                 damping:damping
                velocity:velo
                 options:0];
}

- (SPAnimationChain *) animate:(SPAnimationChainAnimation)anim withDuration:(CGFloat)duration damping:(CGFloat)damping velocity:(CGFloat)velo {
    return [self animate:anim withDuration:duration delay:0.f damping:damping velocity:velo];
}

- (SPAnimationChain *) animate:(SPAnimationChainAnimation)anim withDuration:(CGFloat)duration damping:(CGFloat)damping velocity:(CGFloat)velo options:(UIViewAnimationOptions)opts {
    return [self animate:anim withDuration:duration delay:0.f damping:damping velocity:velo options:opts];
}

- (SPAnimationChain *) animate:(SPAnimationChainAnimation)anim
                  withDuration:(CGFloat)duration
                         delay:(CGFloat)delay
                       options:(UIViewAnimationOptions)opts {
    SPAnimationChainAnimationRunner runner = ^void(void) {
        [UIView animateWithDuration:duration
                              delay:delay
                            options:opts
                         animations:anim
                         completion:^(BOOL finished) {
                             [self run];
                         }];
    };

    [self.runners addObject:runner];
    return self;
}

- (SPAnimationChain *) animate:(SPAnimationChainAnimation)anim withDuration:(CGFloat)duration {
    return [self animate:anim withDuration:duration delay:0.f options:0];
}

- (SPAnimationChain *) animate:(SPAnimationChainAnimation)anim withDuration:(CGFloat)duration delay:(CGFloat)delay {
    return [self animate:anim withDuration:duration delay:delay options:0];
}

- (SPAnimationChain *) animate:(SPAnimationChainAnimation)anim withDuration:(CGFloat)duration options:(UIViewAnimationOptions)opts {
    return [self animate:anim withDuration:duration delay:0.f options:opts];
}

- (SPAnimationChain *) call:(SPAnimationChainAnimation)cb {
    SPAnimationChainAnimationRunner runner = ^void(void) {
        cb();
        [self run];
    };

    [self.runners addObject:runner];
    return self;
}

- (SPAnimationChain *) backgroundCall:(SPAnimationChainAnimation)cb {
    SPAnimationChainAnimationRunner runner = ^void(void) {
        [[NSOperationQueue new] addOperationWithBlock:^{
            cb();

            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self run];
            }];
        }];
    };

    [self.runners addObject:runner];
    return self;
}

- (SPAnimationChain *) run {
    SPAnimationChainAnimationRunner r = (SPAnimationChainAnimationRunner) [self.runners firstObject];
    if (r) {
        [self.runners removeObjectAtIndex:0];
        if (self.isDebug)
            NSLog(@"running next animation. %d left", self.runners.count);
        r();
    } else {
        if (self.isDebug)
            NSLog(@"no animations left");
    }

    return self;
}

- (SPAnimationChain *) run:(SPAnimationChainAnimation) finishCallback {
    [self call:finishCallback];
    return [self run];
}

- (SPAnimationChain *) debug {
    self.isDebug = YES;
    return [self run];
}

@end
