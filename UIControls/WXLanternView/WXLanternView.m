//
//  WXLanternView.m
//  Messenger
//
//  Created by 慕桥(黄玉坤) on 13-12-3.
//
//

#import "WXLanternView.h"
#define kContentViewTag 54100
#define kReplicaViewTag 54200

@implementation WXLanternView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.clipsToBounds = YES;
        self.showType = WXLanternShowTypeSwing;
        self.backgroundColor = [UIColor clearColor];
        self.lanternAnimationRepeatCount = 0;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    UIView *subView = [self viewWithTag:kContentViewTag];
    if ( subView == self.contentView ) return;
    
    [subView removeFromSuperview];
    [[self viewWithTag:kReplicaViewTag] removeFromSuperview];
    
    if ( self.contentView == nil ) return;
    
    self.contentView.top = 0.0f;
    self.contentView.left = 0.0f;
    
    [self addSubview:self.contentView];
    self.contentView.tag = kContentViewTag;
    
    CGFloat motionWidth = self.contentView.width;
    
    // 展示内容小于展示区域默认不开启动画
    if (motionWidth <= self.width)  return;
    
    if ( self.lanternAnimationRepeatCount == 0 ) return;
    
    if ( self.showType == WXLanternShowTypeSwing )
    {
        CGRect frame = self.contentView.frame;
        frame.origin.x = 0;
        self.contentView.frame = frame;
        
        NSTimeInterval duration = 4.0f * (motionWidth < 320 ? 320 : motionWidth) / 320.0;
        
        // 添加走马灯动画
        [UIView beginAnimations:@"lanternAnimation" context:NULL];
        [UIView setAnimationDuration:duration];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationRepeatAutoreverses:YES];
        [UIView setAnimationRepeatCount:self.lanternAnimationRepeatCount];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:)];
        
        frame = self.contentView.frame;
        frame.origin.x = self.width - motionWidth;
        self.contentView.frame = frame;
        
        [UIView commitAnimations];
    }
    else if ( self.showType == WXLanternShowTypeLoop )
    {
        CGRect frame = self.contentView.frame;
        frame.origin.x = 0;
        self.contentView.frame = frame;
        
        NSTimeInterval duration = 4.0f * (motionWidth < 320 ? 320 : motionWidth) / 320.0;
        
        // 添加走马灯动画
        [UIView beginAnimations:@"lanternAnimation" context:NULL];
        [UIView setAnimationDuration:duration];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationRepeatAutoreverses:NO];
        [UIView setAnimationRepeatCount:self.lanternAnimationRepeatCount];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:)];
        
        frame = self.contentView.frame;
        frame.origin.x = self.width - motionWidth;
        self.contentView.frame = frame;
        
        [UIView commitAnimations];
    }
    else
    {
        // 暂不支持其他动画类型
        return;
    }
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if ( [self.delegate respondsToSelector:@selector(lanternView:animationDidStop:)] )
    {
        [self.delegate lanternView:self animationDidStop:flag];
    }
}

@end
