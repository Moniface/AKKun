//
//  UIViewController+WXNavigator.h
//  Messenger
//
//  Created by 慕桥(黄玉坤) on 13-12-6.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIViewController (WXNavigator)
- (id)initWithQuery:(NSString*)path query:(NSDictionary*)query;
@end
