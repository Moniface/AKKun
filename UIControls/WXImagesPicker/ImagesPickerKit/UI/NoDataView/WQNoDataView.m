//
//  WQNoDataView.m
//  WQClient
//
//  Created by shili.nzy on 14-4-3.
//  Copyright (c) 2014年 Alibaba. All rights reserved.
//

#import "WQNoDataView.h"

@implementation WQNoDataView

+ (WQNoDataView *)noDataViewWithStyle:(WQNoDataShowStyle)style
{
    WQNoDataView *noDataView = nil;
    NSArray* views = [[NSBundle mainBundle] loadNibNamed:@"WQNoDataView" owner:nil options:nil];
    if( [views count] > 0 )
    {
        noDataView = (WQNoDataView*)views[0];
        noDataView.style = style;
    }
    
    return noDataView;
}

- (void)awakeFromNib
{
    self.style = WQNoDataShowStyleNormal;
    self.backgroundColor = [UIColor colorWithRed:244 green:244 blue:244 alpha:1.0];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)setStyle:(WQNoDataShowStyle)style
{
    _style = style;
    if( style == WQNoDataShowStyleNormal )
    {
        self.guideImageView.hidden = YES;
        self.iconImageView.image = [UIImage imageNamed:@"emptystate_ico"];
    }
    else
    {
        self.guideImageView.hidden = NO;
        self.iconImageView.image = [UIImage imageNamed:@"emptystate_plugin"];
    }
}

@end
