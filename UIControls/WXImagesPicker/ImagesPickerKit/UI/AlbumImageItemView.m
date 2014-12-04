//
//  AlbumImageItemView.m
//  WQClient
//
//  Created by 慕桥(黄玉坤) on 14/6/19.
//  Copyright (c) 2014年 Alibaba. All rights reserved.
//

#import "AlbumImageItemView.h"

#define FlagIconWidth   22
#define FlagIconHeight  22

@implementation AlbumImageItemView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectInset(self.bounds, 1, 1)];
        [self addSubview:self.imageView];
        
        CGRect flagFrame = CGRectMake(52, 5, FlagIconWidth, FlagIconHeight);
        self.checkedFlag = [[UIImageView alloc] initWithFrame:flagFrame];
        [self addSubview:self.checkedFlag];
    }
    return self;
}

#pragma mark - getter & setter
- (void)setChecked:(BOOL)checked
{
    _checked = checked;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark -
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if ( self.checked )
    {
        self.checkedFlag.image = [UIImage imageNamed:@"picture_select"];
    }
    else
    {
        self.checkedFlag.image = [UIImage imageNamed:@"picture_unselect"];
    }
}

@end
