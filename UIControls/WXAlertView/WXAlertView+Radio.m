//
//  WXAlertView+Radio.m
//  WQClient
//
//  Created by 慕桥(黄玉坤) on 14-4-15.
//  Copyright (c) 2014年 Alibaba. All rights reserved.
//

#import "WXAlertView+Radio.h"
#import "WXRadioItemView.h"

#define RadioItemHeight 50

@interface WXRadioTrunkView : UIView
@property (nonatomic, strong) NSMutableArray *radioItems;
@end

@implementation WXRadioTrunkView
- (instancetype)init
{
    if (self = [super init])
    {
        self.radioItems = [NSMutableArray array];
    }
    
    return self;
}

- (void)radioItemClicked:(WXRadioItemView *)radioItem
{
    for (WXRadioItemView *radioItem in _radioItems)
    {
        radioItem.isSelected = NO;
    }
    
    radioItem.isSelected = YES;
    
    [self layoutIfNeeded];
}

@end

@implementation WXAlertView (Radio)
- (void)showWithTitle:(NSString *)title
           radioNames:(NSArray *)radioNames
           radioIndex:(NSInteger)radioIndex
          clickAction:(WXAlertClickAction)clickAction
             maskType:(WXAlertViewMaskType)maskType
    cancelButtonTitle:(NSString *)cancelButtonTitle
    otherButtonTitles:(NSArray *)otherButtonTitles
{
    WXRadioTrunkView *trunkView = [[WXRadioTrunkView alloc] init];
    
    CGFloat startoffY = 0.0f;
    NSInteger sltedIndex = (radioIndex < radioNames.count)?radioIndex:0;
    
    for (NSString *name in radioNames)
    {
        startoffY += RadioItemHeight;
        
        CGRect itemFrame = CGRectMake(0, startoffY - RadioItemHeight, 240, RadioItemHeight);
        WXRadioItemView *radioItem = [[WXRadioItemView alloc] initWithFrame:itemFrame];
        radioItem.isSelected = [radioNames indexOfObject:name] == sltedIndex;
        radioItem.titleLabel.text = name;
        
        [radioItem addTarget:trunkView action:@selector(radioItemClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        [trunkView addSubview:radioItem];
        [trunkView.radioItems addObject:radioItem];
    }
    
    trunkView.frame = CGRectMake(0, 0, 240, startoffY);
    
    [self showWithTitle:title trunkView:trunkView clickAction:^(NSUInteger buttonIndex) {
        NSInteger sltedRadioIndex = 0;
        for (WXRadioItemView *radioItem in [trunkView subviews])
        {
            if ( !radioItem.isSelected ) continue;
            sltedRadioIndex = [radioNames indexOfObject:radioItem.titleLabel.text];
            break;
        }
        clickAction(buttonIndex, sltedRadioIndex);
    } maskType:maskType userInfo:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitles];
}

@end
