//
//  UIButton+Dagger.h
//  WQClient
//
//  Created by 慕桥(黄玉坤) on 14-3-27.
//  Copyright (c) 2014年 Alibaba. All rights reserved.
//

#import <UIKit/UIKit.h>

/// 你的工具函数够通用、够实用、够轻量就往这里放

@interface UIButton (Dagger)
- (void)setBackgroundColor:(UIColor *)aColor forState:(UIControlState)aState;
@end
