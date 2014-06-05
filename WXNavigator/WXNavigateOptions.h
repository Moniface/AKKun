//
//  WXNavigatorOptions.h
//  Messenger
//
//  Created by 慕桥(黄玉坤) on 13-12-6.
//
//

#import <Foundation/Foundation.h>

typedef enum {
    WXNavigationModeNone,
//    WXNavigationModeCreate,            // a new view controller is created each time
//    WXNavigationModeShare,             // a new view controller is created, cached and re-used
    WXNavigationModeModal,             // a new view controller is created and presented modally
} WXNavigationMode;

@interface WXNavigateOptions : NSObject
+ (WXNavigateOptions *)defaultNavigateOptions;
+ (WXNavigateOptions *)duplicateNavigateOptions:(WXNavigateOptions *)option;
- (WXNavigateOptions *)applyMode:(WXNavigationMode)mode;
- (WXNavigateOptions *)applyPresentationStyle:(UIModalPresentationStyle)style;
- (WXNavigateOptions *)applyTransitionStyle:(UIModalTransitionStyle)style;
- (WXNavigateOptions *)applyAnimationTransition:(UIViewAnimationTransition)style;
- (WXNavigateOptions *)applyParams:(NSDictionary *)queryParams;
- (WXNavigateOptions *)applyAnimated:(BOOL)animated;

@property (nonatomic, assign) WXNavigationMode mode;
@property (nonatomic, assign) UIModalPresentationStyle presentationStyle;
@property (nonatomic, assign) UIModalTransitionStyle transitionStyle;
@property (nonatomic, assign) UIViewAnimationTransition animationTransition;
@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, assign) BOOL animated;
@end
