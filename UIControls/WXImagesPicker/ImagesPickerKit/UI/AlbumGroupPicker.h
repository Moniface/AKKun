//
//  AlbumGroupPicker.h
//  WQClient
//
//  Created by 慕桥(黄玉坤) on 6/25/14.
//  Copyright (c) 2014 Alibaba. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "AlbumImagePicker.h"

/// 相册分组选择回调Block，这里会自动弹出照片选择器
typedef void (^AlbumGroupPickerSltedBlock) (AlbumImagePicker *picker);
/// 相册分组取消回调Block
typedef void (^AlbumGroupPickerCancelBlock) ();

/// 相册分组选择器
@interface AlbumGroupPicker : UIViewController
/// 相册分组列表
@property (nonatomic, strong) NSMutableArray *assetsGroup;

@property (nonatomic, copy) AlbumGroupPickerSltedBlock sltedBlock;
@property (nonatomic, copy) AlbumGroupPickerCancelBlock cancelBlock;

- (void)setSltedBlock:(AlbumGroupPickerSltedBlock)sltedBlock;
- (void)setCancelBlock:(AlbumGroupPickerCancelBlock)cancelBlock;
@end
