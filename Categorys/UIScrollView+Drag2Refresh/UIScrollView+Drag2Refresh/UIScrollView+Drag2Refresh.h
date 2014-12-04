//
//  UIScrollView+Drag2Refresh.h
//  WQClient
//
//  Created by 慕桥(黄玉坤) on 14-4-16.
//  Copyright (c) 2014年 Alibaba. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Drag2RefreshView;
@class RotationIndicatorView;

@interface UIScrollView (Drag2Refresh)

typedef NS_ENUM(NSUInteger, Drag2RefreshPosition) {
    Drag2RefreshPositionTop = 0,    // 下拉刷新
    Drag2RefreshPositionBottom,     // 上拉刷新
};

/// @brief 添加上/下拉刷新控件
/// @param actionHandler 触发刷新回调
/// @param position 控件位置(支持同时存在上拉和下拉刷新控件)
- (void)addDrag2RefreshWithActionHandler:(void (^)(void))actionHandler
                                 position:(Drag2RefreshPosition)position;

/// @brief 编码触发上/下拉刷新
/// @param position 控件位置
- (void)triggerPullToRefreshWithPosition:(Drag2RefreshPosition)position;

/// @brief 控制控件显示
/// @param show 是否显示上/下拉刷新控件 YES显示; NO隐藏;
/// @param position 控件位置
- (void)showsPullToRefresh:(BOOL)show position:(Drag2RefreshPosition)position;

/// @brief 锁定控件，锁定后控件固定显示不刷新
/// @param lock 是否锁定
/// @param position 控件位置
- (void)lockPullToRefresh:(BOOL)lock position:(Drag2RefreshPosition)position;

/// 上/下拉刷新控件，使用前调用addDrag2Refresh进行创建。
@property (nonatomic, strong) Drag2RefreshView *btmDrag2RefreshView;
@property (nonatomic, strong) Drag2RefreshView *topDrag2RefreshView;
@end

typedef NS_ENUM(NSUInteger, Drag2RefreshState) {
    Drag2RefreshStateStopped = 0, 
    Drag2RefreshStateTriggered,
    Drag2RefreshStateLoading,
    Drag2RefreshStateLocked,
};

@interface Drag2RefreshView : UIView

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;

@property (nonatomic, assign) Drag2RefreshState state;
@property (nonatomic, assign) Drag2RefreshPosition position;

- (void)setTitle:(NSString *)title forState:(Drag2RefreshState)state;
- (void)setSubtitle:(NSString *)subtitle forState:(Drag2RefreshState)state;
- (void)setCustomView:(UIView *)view forState:(Drag2RefreshState)state;

- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;

// deprecated; use setSubtitle:forState: instead
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) NSDate *lastUpdatedDate;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) RotationIndicatorView *activityIndicatorView;

// deprecated; use [self.scrollView triggerPullToRefresh] instead
- (void)triggerRefresh DEPRECATED_ATTRIBUTE;

@end