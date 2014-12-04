//
//  AlbumGroupCell.m
//  WQClient
//
//  Created by 慕桥(黄玉坤) on 6/25/14.
//  Copyright (c) 2014 Alibaba. All rights reserved.
//

#import "AlbumGroupCell.h"

@implementation AlbumGroupCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        CGRect posterFrame = CGRectMake(0, 0, AlbumGroupCellHeight, AlbumGroupCellHeight);
        self.posterView = [[UIImageView alloc] initWithFrame:posterFrame];
        
        CGRect nameFrame = CGRectMake(AlbumGroupCellHeight + 15, 0, 240, AlbumGroupCellHeight);
        self.nameLabel = [[UILabel alloc] initWithFrame:nameFrame];
        self.nameLabel.font = [UIFont systemFontOfSize:15];
        self.nameLabel.textColor = [UIColor colorWithRed:51.f/255.f green:51.f/255.f blue:51.f/255.f alpha:1.0];
        self.nameLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.nameLabel];
        
        self.countLabel = [[UILabel alloc] init];
        self.countLabel.font = [UIFont systemFontOfSize:15];
        self.countLabel.textColor = [UIColor colorWithRed:153.f/255.f green:153.f/255.f blue:153.f/255.f alpha:1.0];
        self.countLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.countLabel];
        
        CGFloat scale = [UIScreen mainScreen].scale;
        CGRect lineFrame = CGRectMake(0, AlbumGroupCellHeight - 1/scale, 320, 1/scale);
        UIView *bottomLine = [[UIView alloc] initWithFrame:lineFrame];
        bottomLine.backgroundColor = [UIColor colorWithRed:204.f/255.f green:204.f/255.f blue:204.f/255.f alpha:1.0];
        [self.contentView addSubview:bottomLine];
        
        /// 放着防止下划线覆盖到头像
        [self.contentView addSubview:self.posterView];
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)updateCellWithPoster:(UIImage *)poster name:(NSString *)name count:(NSUInteger)count
{
    [self.posterView setImage:poster];
    
    self.nameLabel.text = name;
    
    CGRect nameBounds = CGRectMake(0, 0, 240, AlbumGroupCellHeight);
    CGRect fitRect = [_nameLabel textRectForBounds:nameBounds limitedToNumberOfLines:1];
    
    CGRect labelFrame = self.countLabel.frame;
    labelFrame.origin.x = _nameLabel.frame.origin.x + fitRect.size.width;
    labelFrame.size.height = AlbumGroupCellHeight;
    labelFrame.size.width = 68;
    
    self.countLabel.text = [NSString stringWithFormat:@"（%@）", @(count)];
    self.countLabel.frame = labelFrame;
}

@end
