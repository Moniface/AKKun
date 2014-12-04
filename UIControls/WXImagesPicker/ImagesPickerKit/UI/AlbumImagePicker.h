//
//  AlbumImagePicker.h
//  WQClient
//
//  Created by 慕桥(黄玉坤) on 14/6/19.
//  Copyright (c) 2014年 Alibaba. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXTERN NSString * const kQueryKeyAssetsGroup;
FOUNDATION_EXTERN NSString * const kQueryKeyMaxCount2Pick;

/// 相册多图片选择完成回调Block
typedef void (^AlbumImagePickerDoneBlock) (NSArray *imagesPicked);

/// 相册多图片选择取消回调Block
typedef void (^AlbumImagePickerCanceledBlock) ();

@interface AlbumImagePicker : UIViewController
@property (nonatomic, copy) AlbumImagePickerDoneBlock       doneBlock;
@property (nonatomic, copy) AlbumImagePickerCanceledBlock   cancledBlock;

/// 照片选择张数上限
@property (nonatomic, assign) NSUInteger                    maxCount2Pick;

/// 初始化函数
- (id)initWithQuery:(NSString *)path query:(NSDictionary *)query;

- (void)setDoneBlock:(AlbumImagePickerDoneBlock)doneBlock;
- (void)setCancledBlock:(AlbumImagePickerCanceledBlock)cancledBlock;
@end
