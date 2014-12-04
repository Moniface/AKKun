//
//  RotationIndicatorView.m
//  WQClient
//
//  Created by qinghua.liqh on 14-3-16.
//  Copyright (c) 2014年 Alibaba. All rights reserved.
//

#import "RotationIndicatorView.h"

@interface RotationIndicatorView ()
@property (nonatomic, weak) CAShapeLayer *shapeLayer;
@end

@implementation RotationIndicatorView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


#pragma mark - Notifications
- (void)registerForNotificationCenter {
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [center addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)unregisterFromNotificationCenter {
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center removeObserver:self];
}

- (void)applicationDidEnterBackground:(NSNotificationCenter *)note {
    [self removeAnimation];
}

- (void)applicationWillEnterForeground:(NSNotificationCenter *)note {
    if (self.isAnimating) {
        [self addAnimation];
    }
}

- (void)startAnimating {
    if (_animating) {
        return;
    }
    
    _animating = YES;
    
    [self registerForNotificationCenter];
    
    [self addAnimation];
}

- (void)stopAnimating {
    if (!_animating) {
        return;
    }
    
    _animating = NO;
    
    [self unregisterFromNotificationCenter];
    
    [self removeAnimation];
}

- (BOOL)isAnimating {
    return _animating;
}

#pragma mark - Add and remove animation
- (void)addAnimation {
    CABasicAnimation *spinAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    spinAnimation.toValue        = @(1*2*M_PI);
    spinAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    spinAnimation.duration       = 1.0;
    spinAnimation.repeatCount    = 1;
    spinAnimation.delegate = self;
    [self.layer addAnimation:spinAnimation forKey:@"RotationIndicatorView"];
}

- (void)animationDidStart:(CAAnimation *)anim;
{
   
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (self.isAnimating) {
        if(flag){
            [self addAnimation];
        }else{
            __weak RotationIndicatorView *weakSelf = self;
            //可能是不可见导致, 延迟1秒继续发送
            double delayInSeconds = 1.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                if (weakSelf.isAnimating){
                    [weakSelf addAnimation];
                }
            });
        }
    }
}

- (void)removeAnimation {
    [self.shapeLayer removeAnimationForKey:@"RotationIndicatorView"];
}
@end
