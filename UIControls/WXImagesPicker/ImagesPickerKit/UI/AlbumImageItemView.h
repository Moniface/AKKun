//
//  AlbumImageItemView.h
//  WQClient
//
//  Created by 慕桥(黄玉坤) on 14/6/19.
//  Copyright (c) 2014年 Alibaba. All rights reserved.
//

#import <UIKit/UIKit.h>

#define AlbumImageItemViewHeight    80
#define AlbumImageItemViewWidth     80

@interface AlbumImageItemView : UIControl
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *checkedFlag;
@property (nonatomic, strong) UIControl *checkTouchArea;
@property (nonatomic, assign) BOOL checked;
@end
