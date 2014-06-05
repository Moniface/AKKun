//
//  NavigateTitleView.m
//  Messenger
//
//  Created by 慕桥(黄玉坤) Moniface on 12-8-30.
//  Copyright (c) 2012年 Ali. All rights reserved.
//

#import "NavigateTitleView.h"

@implementation NavigateTitleView
@synthesize leftAcceView = __leftAcceView;
@synthesize rightAcceView = __rightAcceView;
@synthesize lbTitle = __lbTitle;
@synthesize title;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeScaleAspectFit;
        
        __lbTitle = [[UILabel alloc] initWithFrame:frame]; 
       
        __lbTitle.font = kFONT_Navigation_TitleFont;
        __lbTitle.textColor = kCOLOR_Navigation_TitleColor;
        __lbTitle.contentMode = UIViewContentModeScaleAspectFit;
//        __lbTitle.shadowColor = [UIColor blackColor];
        __lbTitle.shadowOffset = CGSizeMake(0, -1);
        __lbTitle.textAlignment = UITextAlignmentCenter;
        __lbTitle.backgroundColor = [UIColor clearColor];
        
        [self addSubview:__lbTitle];
    }
    return self;
}

- (void)awakeFromNib
{
    self.backgroundColor = [UIColor clearColor];
    self.contentMode = UIViewContentModeScaleAspectFit;
    
    __lbTitle = [[UILabel alloc] initWithFrame:self.bounds];
    
    __lbTitle.font = kFONT_Navigation_TitleFont;
    __lbTitle.textColor = kCOLOR_Navigation_TitleColor;
    __lbTitle.contentMode = UIViewContentModeScaleAspectFit;
//    __lbTitle.shadowColor = [UIColor blackColor];
    __lbTitle.shadowOffset = CGSizeMake(0, -1);
    __lbTitle.textAlignment = UITextAlignmentCenter;
    __lbTitle.backgroundColor = [UIColor clearColor];
    
    [self addSubview:__lbTitle];
}

- (void)setTitle:(NSString *)navTitle
{
    __lbTitle.text = navTitle;
    CGSize fitSize = [__lbTitle sizeThatFits:CGSizeZero];
    CGRect frame = __lbTitle.frame;
    frame.origin.x += (frame.size.width - fitSize.width)/2;
    frame.origin.y += (frame.size.height - fitSize.height)/2;
    frame.size = fitSize;
    
    __lbTitle.frame = frame;
    
    [self setNeedsLayout];
}

- (NSString *)title
{
    return __lbTitle.text;
}

- (void)setLeftAcceView:(UIView *)leftAcceView
{
    if (![__leftAcceView isEqual:leftAcceView]) {
        [__leftAcceView removeFromSuperview];
        
        
        __leftAcceView = leftAcceView;
        [self addSubview:__leftAcceView];
    }
    
    [self setNeedsLayout];
}

- (void)setRightAcceView:(UIView *)rightAcceView
{
    if (![__rightAcceView isEqual:rightAcceView]) {
        [__rightAcceView removeFromSuperview];
        
        
        __rightAcceView = rightAcceView;
        [self addSubview:__rightAcceView];
    }
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (__leftAcceView && __rightAcceView) 
    {
        CGFloat widthTotal = __leftAcceView.frame.size.width
        + __lbTitle.frame.size.width + __rightAcceView.frame.size.width;
        
        CGFloat spaceSide = (self.frame.size.width - widthTotal) / 2;
        
        CGPoint leftCenter = CGPointMake(spaceSide + __leftAcceView.frame.size.width / 2, 
                                         self.frame.size.height / 2);
        
        __leftAcceView.center = leftCenter;
        
        CGPoint midCenter = CGPointMake(spaceSide + __leftAcceView.frame.size.width + __lbTitle.frame.size.width / 2, 
                                         self.frame.size.height / 2);
        
        __lbTitle.center = midCenter;
        
        CGPoint rightCenter = CGPointMake(self.frame.size.width - spaceSide - __rightAcceView.frame.size.width / 2, 
                                        self.frame.size.height / 2);
        
        __rightAcceView.center = rightCenter;
    } 
    else if (__leftAcceView && !__rightAcceView) 
    {
        CGFloat widthTotal = __leftAcceView.frame.size.width + __lbTitle.frame.size.width;
        CGFloat spaceSide = (self.frame.size.width - widthTotal) / 2;
        
        CGPoint leftCenter = CGPointMake(spaceSide + __leftAcceView.frame.size.width / 2, 
                                         self.frame.size.height / 2);
        
        __leftAcceView.center = leftCenter;
        
        CGPoint midCenter = CGPointMake(spaceSide + __leftAcceView.frame.size.width + __lbTitle.frame.size.width / 2, 
                                        self.frame.size.height / 2);
        
        __lbTitle.center = midCenter;
    }
    else if (!__leftAcceView && __rightAcceView)
    {
        CGFloat widthTotal = __lbTitle.frame.size.width + __rightAcceView.frame.size.width;
        CGFloat spaceSide = (self.frame.size.width - widthTotal) / 2;
        
        CGPoint midCenter = CGPointMake(spaceSide + __lbTitle.frame.size.width / 2, 
                                        self.frame.size.height / 2);
        
        __lbTitle.center = midCenter;
        
        CGPoint rightCenter = CGPointMake(self.frame.size.width - spaceSide - __rightAcceView.frame.size.width / 2, 
                                          self.frame.size.height / 2);
        
        __rightAcceView.center = rightCenter;
    }
    else if (!__leftAcceView && !__rightAcceView)
    {
        CGFloat spaceSide = (self.frame.size.width -__lbTitle.frame.size.width) / 2;
        CGPoint midCenter = CGPointMake(spaceSide + __lbTitle.frame.size.width / 2, 
                                        self.frame.size.height / 2);
        
        __lbTitle.center = midCenter;
    }
}

@end
