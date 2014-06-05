//
//  UIImage+Dagger.m
//  WQClient
//
//  Created by 慕桥(黄玉坤) on 14-3-27.
//  Copyright (c) 2014年 Alibaba. All rights reserved.
//

#import "UIImage+Dagger.h"

@implementation UIImage (Dagger)
+ (UIImage *)imageWithColor:(UIColor *)aColor
{
    return [self imageWithColor:aColor size:(CGSize){1,1}];
}

+ (UIImage *)imageWithColor:(UIColor *)aColor size:(CGSize)aSize
{
    CGRect rect = (CGRect){CGPointZero, aSize};
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, aColor.CGColor);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
@end
