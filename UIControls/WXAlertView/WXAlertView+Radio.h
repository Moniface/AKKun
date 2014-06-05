//
//  WXAlertView+Radio.h
//  WQClient
//
//  Created by 慕桥(黄玉坤) on 14-4-15.
//  Copyright (c) 2014年 Alibaba. All rights reserved.
//

#import "WXAlertView.h"

typedef void (^WXAlertClickAction)(NSUInteger buttonIndex, NSInteger radioIndex);

@interface WXAlertView (Radio)
- (void)showWithTitle:(NSString *)title
           radioNames:(NSArray *)radioNames
           radioIndex:(NSInteger)radioIndex
          clickAction:(WXAlertClickAction)clickAction
             maskType:(WXAlertViewMaskType)maskType
    cancelButtonTitle:(NSString *)cancelButtonTitle
    otherButtonTitles:(NSArray *)otherButtonTitles;
@end
