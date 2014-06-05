//
//  WXNavigatorOptions.m
//  Messenger
//
//  Created by 慕桥(黄玉坤) on 13-12-6.
//
//

#import "WXNavigateOptions.h"

@interface WXNavigateOptions()
@end

@implementation WXNavigateOptions

+ (WXNavigateOptions *)defaultNavigateOptions
{
    WXNavigateOptions *options = [[WXNavigateOptions alloc] init];
    
    return options;
}

+ (WXNavigateOptions *)duplicateNavigateOptions:(WXNavigateOptions *)option
{
    if (option == nil) {
        return nil;
    }
    
    WXNavigateOptions *duplicate = [[WXNavigateOptions alloc] init];
    duplicate.mode = option.mode;
    duplicate.params = option.params;
    duplicate.animated = option.animated;
    duplicate.transitionStyle = option.transitionStyle;
    duplicate.presentationStyle = option.presentationStyle;
    duplicate.animationTransition = option.animationTransition;
    
    return duplicate;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.animated = YES;
        self.mode = WXNavigationModeNone;
    }
    return self;
}

- (WXNavigateOptions *)applyMode:(WXNavigationMode)newMode;
{
    self.mode = newMode;
    return self;
}

- (WXNavigateOptions *)applyPresentationStyle:(UIModalPresentationStyle)style
{
    self.presentationStyle = style;
    return self;
}

- (WXNavigateOptions *)applyTransitionStyle:(UIModalTransitionStyle)style
{
    self.transitionStyle = style;
    return self;
}

- (WXNavigateOptions *)applyAnimationTransition:(UIViewAnimationTransition)style
{
    self.animationTransition = style;
    return self;
}

- (WXNavigateOptions *)applyParams:(NSDictionary *)queryParams
{
    self.params = queryParams;
    return self;
}

- (WXNavigateOptions *)applyAnimated:(BOOL)animated
{
    self.animated = animated;
    return self;
}

@end
