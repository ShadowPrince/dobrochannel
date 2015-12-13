//
//  UIView+ChainAnimations.h
//  dobrochannel
//
//  Created by shdwprince on 12/12/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


typedef void (^SPAnimationChainAnimation)(void);

@interface SPAnimationChain : NSObject

- (SPAnimationChain *) animate:(SPAnimationChainAnimation) anim
                  withDuration:(CGFloat) duration
                         delay:(CGFloat) delay
                       damping:(CGFloat) damping
                      velocity:(CGFloat) velo
                       options:(UIViewAnimationOptions) opts;

- (SPAnimationChain *) animate:(SPAnimationChainAnimation) anim
                  withDuration:(CGFloat) duration
                         delay:(CGFloat) delay
                       damping:(CGFloat) damping
                      velocity:(CGFloat) velo;

- (SPAnimationChain *) animate:(SPAnimationChainAnimation) anim
                  withDuration:(CGFloat) duration
                       damping:(CGFloat) damping
                      velocity:(CGFloat) velo
                       options:(UIViewAnimationOptions) opts;

- (SPAnimationChain *) animate:(SPAnimationChainAnimation) anim
                  withDuration:(CGFloat) duration
                       damping:(CGFloat) damping
                      velocity:(CGFloat) velo;

- (SPAnimationChain *) animate:(SPAnimationChainAnimation)anim
                  withDuration:(CGFloat)duration
                         delay:(CGFloat)delay
                       options:(UIViewAnimationOptions)opts;

- (SPAnimationChain *) animate:(SPAnimationChainAnimation)anim
                  withDuration:(CGFloat)duration
                       options:(UIViewAnimationOptions)opts;

- (SPAnimationChain *) animate:(SPAnimationChainAnimation)anim
                  withDuration:(CGFloat)duration;

- (SPAnimationChain *) call:(SPAnimationChainAnimation) cb;
- (SPAnimationChain *) backgroundCall:(SPAnimationChainAnimation) cb;

- (SPAnimationChain *) run:(SPAnimationChainAnimation) finishCallback;
- (SPAnimationChain *) run;
- (SPAnimationChain *) debug;

@end