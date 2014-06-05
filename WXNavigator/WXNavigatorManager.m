//
//  WXNavigatorManager.m
//  Messenger
//
//  Created by 慕桥(黄玉坤) on 13-12-7.
//
//

#import "WXNavigatorManager.h"

@interface WXNavigatorManager()<WXNavigatorDelegate>
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) WXNavigator *topNavigator;
@end

@implementation WXNavigatorManager

IMPLEMENT_SINGLETON_FOR_CLASS(WXNavigatorManager)
//@synthesize appRootContainer = _appRootContainer;
@synthesize navigator = _navigator;

- (void)setupWithWindow:(UIWindow *)aWindow
{
    self.window = aWindow;
}

- (WXNavigator *)navigator
{
    if ( self.window == nil ) return nil;
    
    if ( _navigator == nil )
    {
        _navigator = [[WXNavigator alloc] init];
        _navigator.window = self.window;
//        _navigator.rootContainer = [self appRootContainer];
        _navigator.delegate = self;
    }
    
    return _navigator;
}

//- (UIView *)appRootContainer
//{
//    if ( self.window == nil ) return nil;
//    
//    if ( _appRootContainer == nil )
//    {
//        _appRootContainer = [[UIView alloc] init];
//        _appRootContainer.backgroundColor = [UIColor clearColor];
//        _appRootContainer.size = [UIScreen mainScreen].bounds.size;
//        
//        [self.window addSubview:_appRootContainer];
//    }
//    
//    return _appRootContainer;
//}

#pragma mark - WXNavigatorDelegate
- (BOOL)navigator:(WXNavigator *)navigator shouldOpenURL:(NSURL*)URL
{
//    if ( navigator && ![self.topNavigator isEqual:navigator] )
//    {
//        [self.appRootContainer bringSubviewToFront:navigator.rootViewController.view];
//    }
    
    self.topNavigator = navigator;
    
    return YES;
}

- (void)navigator:(WXNavigator *)navigator willOpenURL:(NSURL*)URL
{
    
}

- (void)navigator:(WXNavigator *)navigator didOpenURL:(NSURL*)URL
{
    
}

@end
