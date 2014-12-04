//
//  AlbumGroupCell.h
//  WQClient
//
//  Created by 慕桥(黄玉坤) on 6/25/14.
//  Copyright (c) 2014 Alibaba. All rights reserved.
//

#import <UIKit/UIKit.h>

#define AlbumGroupCellHeight 55

@interface AlbumGroupCell : UITableViewCell
/// 相册分组封面图
@property (nonatomic, strong) UIImageView *posterView;
/// 相册分组照片数
@property (nonatomic, strong) UILabel *countLabel;
/// 相册分组名称
@property (nonatomic, strong) UILabel *nameLabel;

- (void)updateCellWithPoster:(UIImage *)poster name:(NSString *)name count:(NSUInteger)count;
@end
