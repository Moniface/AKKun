//
//  WXAlertView.h
//  Messenger
//
//  Created by 慕桥(黄玉坤) on 13-8-6.
//

#import <UIKit/UIKit.h>

#define WXAlertViewCancelButtonIndex NSUIntegerMax

/// AlertView遮罩效果
typedef enum {
    WXAlertViewMaskTypeClear = 0,
    WXAlertViewMaskTypeBlack,
    WXAlertViewMaskTypeWhite,
    WXAlertViewMaskTypeGradient
} WXAlertViewMaskType;

@class WXAlertView;

@protocol WXAlertViewDelegate <NSObject>

-(void)alertView:(WXAlertView *)alertView didSelectButtonAtIndex:(NSUInteger)index;

@end

/// AlertView标题区域
@protocol WXAlertViewHeaderView <NSObject>

@property (nonatomic, strong) NSString *text;
@property (nonatomic, readonly) UILabel *textLabel;

@end

/// AlertView中间内容区域
@protocol WXAlertViewTrunkView <NSObject>
@end

/// AlertView底部按钮区域
@protocol WXAlertViewTailView <NSObject>

@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) NSArray *otherButtons;

@end

@interface WXAlertView : UIView

@property (nonatomic, readonly) UIView<WXAlertViewHeaderView> *headerView;
@property (nonatomic, readonly) UIView<WXAlertViewTailView> *tailView;
@property (nonatomic, readonly) UIView/*<WXAlertViewTrunkView>*/ *trunkView;
@property (nonatomic, readonly) UIButton *cancelButton;
@property (nonatomic, readonly) UIButton *otherButton;
@property (nonatomic, strong) NSDictionary *userInfo;
@property (nonatomic, weak) id<WXAlertViewDelegate>delegate;

+ (void)dismissAllAlertView;

// Common
- (void)showWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle;

- (void)showWithTitle:(NSString *)title
              message:(NSString *)message
             delegate:(id<WXAlertViewDelegate>)delegate
             maskType:(WXAlertViewMaskType)maskType
             userInfo:(NSDictionary *)userInfo
    cancelButtonTitle:(NSString *)cancelButtonTitle
    otherButtonTitles:(NSArray *)otherButtonTitles;

- (void)showWithTitle:(NSString *)title
              message:(NSString *)message
          clickAction:(void (^)(NSUInteger buttonIndex))clickAction
             maskType:(WXAlertViewMaskType)maskType
             userInfo:(NSDictionary *)userInfo
    cancelButtonTitle:(NSString *)cancelButtonTitle
    otherButtonTitles:(NSArray *)otherButtonTitles;

// Custom
- (void)showWithTitle:(NSString *)title
            trunkView:(UIView *)trunk
             delegate:(id<WXAlertViewDelegate>)delegate
             maskType:(WXAlertViewMaskType)maskType
             userInfo:(NSDictionary *)userInfo
    cancelButtonTitle:(NSString *)cancelButtonTitle
    otherButtonTitles:(NSArray *)otherButtonTitles;

- (void)showWithTitle:(NSString *)title
            trunkView:(UIView *)trunk
          clickAction:(void (^)(NSUInteger buttonIndex))clickAction
             maskType:(WXAlertViewMaskType)maskType
             userInfo:(NSDictionary *)userInfo
    cancelButtonTitle:(NSString *)cancelButtonTitle
    otherButtonTitles:(NSArray *)otherButtonTitles;

/// 隐藏弹出AlertView
- (void)dismiss;
- (void)dismissAnimated:(BOOL)animated
             completion:(void (^)(BOOL finished))completion;

/// @brief 改变偏移量。当AlertView包含的输入框弹出键盘，你可能需要调整AlertView的位置
/// @param offset > 0向下偏移，< 0向上偏移
- (void)changeAlertOffset:(NSInteger)offset;

@end
