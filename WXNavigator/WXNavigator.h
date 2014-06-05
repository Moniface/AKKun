//
//  WXNavigator.h
//  Messenger
//
//  Created by 慕桥(黄玉坤) on 13-12-6.
//
//

#import <Foundation/Foundation.h>
#import "WXNavigateOptions.h"
#import "UIViewController+WXNavigator.h"

typedef enum {
    WXNavigatorPersistenceModeNone,  // no persistence
    WXNavigatorPersistenceModeTop,   // persists only the top-level controller
    WXNavigatorPersistenceModeAll,   // persists all navigation paths
} WXNavigatorPersistenceMode;

@class WXNavigator;
@protocol WXNavigatorDelegate <NSObject>
- (BOOL)navigator:(WXNavigator *)navigator shouldOpenURL:(NSURL*)URL;
- (void)navigator:(WXNavigator *)navigator willOpenURL:(NSURL*)URL;
- (void)navigator:(WXNavigator *)navigator didOpenURL:(NSURL*)URL;
@end

@interface WXNavigator : NSObject

@property (nonatomic, strong) UIWindow *window;
//@property (nonatomic, strong) UIView *rootContainer; // 顶层视图
@property (nonatomic, weak, readonly) UIViewController* topViewController;
@property (nonatomic, strong, readonly) UIViewController* rootViewController;
@property (nonatomic, readonly) UINavigationController *rootNavigationController;
@property (nonatomic, weak) id<WXNavigatorDelegate> delegate;
@property (nonatomic, assign) WXNavigatorPersistenceMode persistenceMode;

- (void)map:(NSString *)url toViewController:(Class)controllerClass;
- (void)map:(NSString *)url toModalViewController:(Class)controllerClass;
- (void)map:(NSString *)url toViewController:(Class)controllerClass withOptions:(WXNavigateOptions *)options;

- (UIViewController *)open:(NSString *)url;
- (UIViewController *)open:(NSString *)url withAnimated:(BOOL)animated;
- (UIViewController *)open:(NSString *)url withParams:(NSDictionary *)params;
- (UIViewController *)open:(NSString *)url withOptions:(WXNavigateOptions *)options;

- (UIViewController*)viewControllerForURL:(NSString*)url;
- (UIViewController*)viewControllerForURL:(NSString*)url params:(NSDictionary*)params;

- (WXNavigateOptions *)navigateOptionsRegistedForUrl:(NSString *)url;

@end
