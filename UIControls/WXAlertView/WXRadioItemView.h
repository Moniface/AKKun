//
//  WXRadioItemView.h
//  WQClient
//
//  Created by 慕桥(黄玉坤) on 14-4-15.
//  Copyright (c) 2014年 Alibaba. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WXRadioItemView : UIControl
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *statusImageView;
@property (nonatomic, strong) UIImageView *dottedLine;
@property (nonatomic, assign) BOOL isSelected;
@end
