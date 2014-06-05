//
//  WXRadioItemView.m
//  WQClient
//
//  Created by 慕桥(黄玉坤) on 14-4-15.
//  Copyright (c) 2014年 Alibaba. All rights reserved.
//

#import "WXRadioItemView.h"

@implementation WXRadioItemView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel = [[UILabel alloc] init];
        _titleLabel.frame = CGRectMake(24, 0, 214, 24);
        _titleLabel.centerY = floorf(self.height / 2);
        _titleLabel.font = [UIFont systemFontOfSize:15];
        [self addSubview:_titleLabel];
        
        self.statusImageView = [[UIImageView alloc] init];
        _statusImageView.frame = CGRectMake(0, 0, 16, 16);
        _statusImageView.centerY = floorf(self.height / 2);
        
        [self addSubview:_statusImageView];
        
        self.dottedLine = [[UIImageView alloc] initWithImage:ImageNamed(@"dotted_line")];
        [self addSubview:_dottedLine];

        [self setNeedsLayout];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if ( _isSelected )
    {
        _titleLabel.textColor = RGBCOLOR(83, 184, 192);
        [_statusImageView setImage:ImageNamed(@"single_section_pressed")];
    }
    else
    {
        _titleLabel.textColor = RGBCOLOR(102, 102, 102);
        [_statusImageView setImage:ImageNamed(@"single_section_normal")];
    }
    
    _titleLabel.frame = CGRectMake(24, 0, 214, 24);
    _titleLabel.centerY = floorf(self.height / 2);
    
    _statusImageView.frame = CGRectMake(0, 0, 16, 16);
    _statusImageView.centerY = floorf(self.height / 2);
    
    CGFloat lineHeight = 1/[UIScreen mainScreen].scale;
    _dottedLine.frame = CGRectMake(0, CGRectGetHeight(self.bounds)-lineHeight,
                                   CGRectGetWidth(self.bounds), lineHeight);
}

#pragma mark - getter & setter
- (void)setIsSelected:(BOOL)selected
{
    _isSelected = selected;
    [self setNeedsLayout];
}

@end
