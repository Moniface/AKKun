//
//  UIButton+Dagger.m
//  WQClient
//
//  Created by 慕桥(黄玉坤) on 14-3-27.
//  Copyright (c) 2014年 Alibaba. All rights reserved.
//

#import "UIButton+Dagger.h"
#import "UIImage+Dagger.h"

@implementation UIButton (Dagger)
- (void)setBackgroundColor:(UIColor *)aColor forState:(UIControlState)aState
{
    CGSize bkImgSize = CGSizeMake(2, 2);
    UIEdgeInsets insert = UIEdgeInsetsMake(1, 1, 1, 1);
    
    UIImage *bkImg = [UIImage resizableImage:[UIImage imageWithColor:aColor size:bkImgSize] withCapInsets:insert];
    
    [self setBackgroundImage:bkImg forState:aState];
}
@end
