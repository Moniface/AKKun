//
//  NavigateTitleView.h
//  Messenger
//
//  Created by 慕桥(黄玉坤) Moniface on 12-8-30.
//  Copyright (c) 2012年 Ali. All rights reserved.
//

#import <UIKit/UIKit.h>

#define NavigateTitleFrame CGRectMake(0, 0, 200, 30)

@interface NavigateTitleView : UIView

@property (nonatomic, strong) UIView *leftAcceView;
@property (nonatomic, strong) UIView *rightAcceView;

@property (nonatomic, strong) UILabel   *lbTitle;
@property (nonatomic, strong) NSString  *title;

@end
