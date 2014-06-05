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

typedef NS_ENUM(NSUInteger, DragToRefreshPosition) {
    DragToRefreshPositionTop = 0,
    DragToRefreshPositionBottom,
};

- (void)addDragToRefreshWithActionHandler:(void (^)(void))actionHandler
                                 position:(DragToRefreshPosition)position;

- (void)triggerPullToRefreshWithPosition:(DragToRefreshPosition)position;

- (void)showsPullToRefresh:(BOOL)showsPullToRefresh position:(DragToRefreshPosition)position;

- (void)lockPullToRefresh:(BOOL)lock position:(DragToRefreshPosition)position;

@property (nonatomic, strong) Drag2RefreshView *btmDrag2RefreshView;
@property (nonatomic, strong) Drag2RefreshView *topDrag2RefreshView;
@end

typedef NS_ENUM(NSUInteger, DragToRefreshState) {
    DragToRefreshStateStopped = 0, 
    DragToRefreshStateTriggered,
    DragToRefreshStateLoading,
    DragToRefreshStateLocked,
};

@interface Drag2RefreshView : UIView

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;

@property (nonatomic, assign) DragToRefreshState state;
@property (nonatomic, assign) DragToRefreshPosition position;

- (void)setTitle:(NSString *)title forState:(DragToRefreshState)state;
- (void)setSubtitle:(NSString *)subtitle forState:(DragToRefreshState)state;
- (void)setCustomView:(UIView *)view forState:(DragToRefreshState)state;

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