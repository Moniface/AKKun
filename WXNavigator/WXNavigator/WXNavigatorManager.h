//
//  WXNavigatorManager.h
//  Messenger
//
//  Created by 慕桥(黄玉坤) on 13-12-7.
//
//

#import <Foundation/Foundation.h>
#import "WXNavigateOptions.h"
#import "WXNavigator.h"

#define sharedNavigator [[WXNavigatorManager sharedInstance] navigator]

@interface WXNavigatorManager : NSObject
+ (WXNavigatorManager *)sharedInstance;
- (void)setupWithWindow:(UIWindow *)window;
@property (nonatomic, strong, readonly) WXNavigator *navigator;
//@property (nonatomic, strong, readonly) UIView *appRootContainer;
@end
