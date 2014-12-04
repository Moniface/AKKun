//
//  RotationIndicatorView.h
//  WQClient
//
//  Created by qinghua.liqh on 14-3-16.
//  Copyright (c) 2014年 Alibaba. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RotationIndicatorView : UIImageView
{
    @package
    BOOL _animating;
}

- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;
@end
