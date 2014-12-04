//
//  WQNoDataView.h
//  WQClient
//
//  Created by shili.nzy on 14-4-3.
//  Copyright (c) 2014年 Alibaba. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, WQNoDataShowStyle)
{
    WQNoDataShowStyleNormal,
    WQNoDataShowStyleShowGuide,
};


@interface WQNoDataView : UIView

@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;
@property (nonatomic, weak) IBOutlet UIImageView *guideImageView;
@property (nonatomic, weak) IBOutlet UILabel *textLabel;

@property (nonatomic, assign) WQNoDataShowStyle style;


+ (WQNoDataView *)noDataViewWithStyle:(WQNoDataShowStyle)style;

@end
