//
//  WXNavigator.m
//  Messenger
//
//  Created by 慕桥(黄玉坤) on 13-12-6.
//
//

#import "WXNavigator.h"

#define kPushAnimationTimeInterval  0.64

@interface WXNavigateNode : NSObject
@property (nonatomic, strong) NSString *className;
@property (nonatomic, strong) WXNavigateOptions *options;
@end

@implementation WXNavigateNode
@end

@interface WXNavigator()
@property (nonatomic, strong) NSMutableDictionary *urlMap;
@end

@implementation WXNavigator

@synthesize topViewController = _topViewController;

- (id)init
{
    self = [super init];
    if (self) {
        self.urlMap = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - setter & getter

- (void)setRootViewController:(UIViewController *)newRootViewController
{
    if ( _rootViewController == newRootViewController ) return;

    [_rootViewController.view removeFromSuperview];

    _rootViewController = newRootViewController;
    
    UINavigationController *navigationController = nil;
    if ([_rootViewController isKindOfClass:[UINavigationController class]]) {
        navigationController = (UINavigationController *)_rootViewController;
    } else {
        navigationController = [[UINavigationController alloc] initWithRootViewController:_rootViewController];
    }
    
    [self.window addSubview:navigationController.view];
    [self.window setRootViewController:navigationController];
}

- (UINavigationController *)rootNavigationController
{
    if ([_rootViewController isKindOfClass:[UINavigationController class]]) {
        return (UINavigationController *)_rootViewController;
    } else {
        return _rootViewController.navigationController;
    }
}

- (UIViewController *)topViewController
{
    UIViewController *rootVC = self.rootNavigationController;
    UIViewController *topVC = _topViewController;
    
    while (1) {
        topVC = rootVC.modalViewController; /* 是否有present出来的modalViewController */
        
        if (topVC == nil) {
            if ([rootVC isKindOfClass:[UITabBarController class]]) {
                topVC = ((UITabBarController *)rootVC).selectedViewController; /* tabBar当前选中的viewController */
            } else if ([rootVC isKindOfClass:[UINavigationController class]]) {
                topVC = ((UINavigationController *)rootVC).topViewController; /* navigation当前stack最上面的viewController */
            } else {
                topVC = nil; /* 当前rootVC不是一个container，即不是tabBar或者navigation这类可以装载viewController的容器，即找到了 */
            }
        }
        
        if (topVC != nil) {
            if (topVC == rootVC) { /* 竟然可以出现topVC等于rootVC的情况，再玩下去就死循环了 */
                _topViewController = topVC;
                break;
            } else {
                rootVC = topVC; /* 以当前topVC为rootVC，再去探寻是否有基于之上的topVC */
            }
        } else {
            /* topVC为nil表示当前rootVC是UIViewController，并且不是tabBar或navgation */
            topVC = rootVC;
            _topViewController = topVC;
            break;
        }
    }
    
    return _topViewController;
}

#pragma mark - parent viewController

- (UIViewController *)parentForController:(UIViewController *)controller
{
    UIViewController *parentViewController = nil;
    
    if (_rootViewController == nil) {
        UINavigationController *navigationController = [[UINavigationController alloc] init];
        [self setRootViewController:navigationController];
        
    }
    
    UIViewController *topVC = self.topViewController;
    if (controller != _rootViewController && controller != topVC) {
        parentViewController = topVC;
    }
    
    return parentViewController;
}

#pragma mark - Public Inteface
- (void)map:(NSString *)url toViewController:(Class)controllerClass
{
    [self map:url toViewController:controllerClass withOptions:nil];
}

- (void)map:(NSString *)url toModalViewController:(Class)controllerClass
{
    WXNavigateOptions *options = [[WXNavigateOptions alloc] init];
    options.mode = WXNavigationModeModal;
    
    
    [self map:url toViewController:controllerClass withOptions:options];
}

- (void)map:(NSString *)url toViewController:(Class)controllerClass withOptions:(WXNavigateOptions *)options
{
    if ( url.length == 0 ) return;
    if ( controllerClass == nil ) return;
    
    WXNavigateNode *node = [[WXNavigateNode alloc] init];
    node.className = NSStringFromClass(controllerClass);
    node.options = options;
    
    [self.urlMap setObject:node forKey:url];
}

- (UIViewController *)open:(NSString *)url
{
    if ( url.length == 0 ) return nil;
    
    WXNavigateNode *node = [self.urlMap objectForKey:url];
    if ( node == nil ) return nil;
    
    return [self open:url withOptions:node.options];
}

- (UIViewController *)open:(NSString *)url withAnimated:(BOOL)animated
{
    WXNavigateNode *node = [self.urlMap objectForKey:url];
    WXNavigateOptions *options = [WXNavigateOptions duplicateNavigateOptions:node.options];
    if (options == nil) {
        options = [WXNavigateOptions defaultNavigateOptions];
    }
    
    options.animated = animated;
    
    return [self open:url withOptions:options];
}

- (UIViewController *)open:(NSString *)url withParams:(NSDictionary *)params
{
    WXNavigateNode *node = [self.urlMap objectForKey:url];
    WXNavigateOptions *options = [WXNavigateOptions duplicateNavigateOptions:node.options];
    if (options == nil) {
        options = [WXNavigateOptions defaultNavigateOptions];
    }

    if ( [params count] > 0 )
    {
        NSMutableDictionary *allParams = [NSMutableDictionary dictionaryWithDictionary:params];
        if ( [options.params count] > 0 ) { [allParams addEntriesFromDictionary:options.params]; }
        options.params = allParams;
    }
    
    return [self open:url withOptions:options];
}

- (UIViewController *)open:(NSString *)url withOptions:(WXNavigateOptions *)options
{
    NSLog(@"start open url:%@", url);
    
    if ( url.length == 0 ) return nil;
    
    NSURL *urlObj = [NSURL URLWithString:url];
    if ( urlObj == nil ) return nil;
    
    // 代理回调
    id<WXNavigatorDelegate> delegate = self.delegate;
    if ( [delegate respondsToSelector:@selector(navigator:shouldOpenURL:)]
        && ![delegate navigator:self shouldOpenURL:urlObj])
    {
        return nil;
    }
    
    WXNavigateNode *node = [self.urlMap objectForKey:url];
    if ( node == nil ) {
        return nil;
    }
    
    WXNavigateOptions *options2Apply = options;
    if ( options2Apply == nil )
    {
        options2Apply = node.options;
    }
    
    if ( options2Apply == nil )
    {
        options2Apply = [WXNavigateOptions defaultNavigateOptions];
    }
    
    // 代理回调
    if ( [delegate respondsToSelector:@selector(navigator:willOpenURL:)] )
    {
        [delegate navigator:self willOpenURL:urlObj];
    }
    
    UIViewController *controller = [self viewControllerForURL:url params:options2Apply.params];
    if ( controller == nil ) return controller;
    
    static NSTimeInterval lastPushAnimatedTime = 0.0;
    static NSMutableArray *pushBlockCached = nil;
    if ( pushBlockCached == nil )
    {
        pushBlockCached = [NSMutableArray array];
    }
    
    NSTimeInterval (^presentBlock)() = ^{
        [self presentController:controller options:options2Apply];
        
        // 代理回调
        if ( [delegate respondsToSelector:@selector(navigator:didOpenURL:)] )
        {
            [delegate navigator:self didOpenURL:urlObj];
        }
        
        if ( options2Apply.animated == YES )
        {
            lastPushAnimatedTime = [[NSProcessInfo processInfo] systemUptime];
            return kPushAnimationTimeInterval;
        }
        
        return 0.0;
    };
    
    if ( [pushBlockCached count] > 0 ) // 还有等待压栈的界面，插到队列后面
    {
        [pushBlockCached addObject:[presentBlock copy]];
    }
    else
    {
        NSTimeInterval now = [[NSProcessInfo processInfo] systemUptime];
        if ( now - lastPushAnimatedTime > kPushAnimationTimeInterval )
        {
            presentBlock();
        }
        else    // 距离前一个压栈动画间隔时间过短不允许压栈
        {
            [pushBlockCached addObject:[presentBlock copy]];
            NSTimeInterval interval = kPushAnimationTimeInterval - ( now - lastPushAnimatedTime );
            [self pushControllerCached:pushBlockCached timeInterval:interval];
        }
    }
    
    NSLog(@"end open url:%@", url);
 
    return controller;
}

- (void)pushControllerCached:(NSMutableArray *)pushBlockCached timeInterval:(NSTimeInterval)interval
{
    if ( [pushBlockCached count] > 0 )
    {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            NSTimeInterval (^presentBlock)() = [pushBlockCached firstObject];
            NSTimeInterval intervalNext = kPushAnimationTimeInterval;
            if ( presentBlock ) { intervalNext = presentBlock(); }
            [pushBlockCached removeObjectAtIndex:0];
            [self pushControllerCached:pushBlockCached timeInterval:intervalNext];
        });
    }
}

- (UIViewController*)viewControllerForURL:(NSString*)url
{
    return [self viewControllerForURL:url params:nil];
}

- (UIViewController*)viewControllerForURL:(NSString*)url params:(NSDictionary*)params
{
    if ( url.length == 0 ) return nil;
    
    WXNavigateNode *node = [self.urlMap objectForKey:url];
    if ( node == nil ) return nil;
    if ( node.className == nil ) return nil;
    
    Class controllerClass = NSClassFromString(node.className);
    
    SEL selector = @selector(initWithQuery:query:);
    if ( [controllerClass instancesRespondToSelector:selector] )
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSDictionary *queryParams = params ? params : node.options.params;
        id instanse = [[controllerClass alloc] performSelector:selector
                                                    withObject:url
                                                    withObject:queryParams];
#pragma clang diagnostic pop
        if ( [instanse isKindOfClass:[UIViewController class]] ) return instanse;
    }
    
    return nil;
}

- (WXNavigateOptions *)navigateOptionsRegistedForUrl:(NSString *)url
{
    WXNavigateNode *node = [self.urlMap objectForKey:url];
    return node.options;
}

#pragma mark - Present 

- (void)presentController:(UIViewController *)controller options:(WXNavigateOptions *)options
{
    if ( self.rootViewController == nil )
    {
        [self setRootViewController:controller];
        return;
    }
    
    switch (options.mode)
    {
        case WXNavigationModeModal:
        {
            [self presentModeController:controller options:options];
            break;
        }
            
        default:
        {
            [self presentNormalController:controller options:options];
            break;
        }
    }
}

- (void)presentNormalController:(UIViewController *)controller options:(WXNavigateOptions *)options
{
    UIViewController *parentController = [self parentForController:controller];
    if ( parentController == nil ) return;
    
    if ( [parentController isKindOfClass:[UINavigationController class]] )
    {
        UINavigationController *nav = (UINavigationController *)parentController;
        [self navigationController:nav pushViewController:controller withOptions:options];
    }
    else if ( [parentController isKindOfClass:[UITabBarController class]] )
    {
        UITabBarController *tabBar = (UITabBarController *)parentController;
        UIViewController *selectedCtler = tabBar.selectedViewController;
        if ( [selectedCtler isKindOfClass:[UINavigationController class]] )
        {
            UINavigationController *nav = (UINavigationController *)selectedCtler;
            [self navigationController:nav
                    pushViewController:controller
                           withOptions:options];
        }
        else
        {
            [self navigationController:selectedCtler.navigationController
                    pushViewController:controller
                           withOptions:options];
        }
    }
    else
    {
        [self navigationController:parentController.navigationController
                pushViewController:controller
                       withOptions:options];
    }
}

- (void)navigationController:(UINavigationController *)navigation
          pushViewController: (UIViewController*)controller
                 withOptions:(WXNavigateOptions *)options
{
    if ( navigation == nil || controller == nil ) return;

    [navigation pushViewController:controller animated:options.animated];
}

- (void)presentModeController:(UIViewController *)controller options:(WXNavigateOptions *)options
{
    controller.modalTransitionStyle = options.transitionStyle;
    controller.modalPresentationStyle = options.presentationStyle;
    
    UIViewController *parentController = [self parentForController:controller];
    if ( parentController == nil ) return;
    
    if ([controller isKindOfClass:[UINavigationController class]])
    {
        [parentController presentModalViewController:controller animated:options.animated];
    }
    else
    {
        UINavigationController* navController = [[UINavigationController alloc] init];
        navController.modalTransitionStyle = options.transitionStyle;
        navController.modalPresentationStyle = controller.modalPresentationStyle;
        [navController pushViewController: controller animated: NO];
        [parentController presentModalViewController:navController animated:options.animated];
        
    }
}

@end