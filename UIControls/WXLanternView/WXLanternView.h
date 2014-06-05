//
//  WXLanternView.h
//  Messenger
//
//  Created by 慕桥(黄玉坤) on 13-12-3.
//
//

#import <UIKit/UIKit.h>

typedef enum {
    WXLanternShowTypeLoop,
    WXLanternShowTypeSwing,
}WXLanternShowType;

@class WXLanternView;

@protocol WXLanternViewDelegate <NSObject>
- (void)lanternView:(WXLanternView *)lanternView animationDidStop:(BOOL)finished;
@end

@interface WXLanternView : UIView
// 该view为走马灯展示内容。
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, weak) id<WXLanternViewDelegate> delegate;
@property (nonatomic, assign) WXLanternShowType showType;
@property (nonatomic, assign) NSUInteger lanternAnimationRepeatCount;
@end
