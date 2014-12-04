# WXImagesPicker

WXImagesPicker由旺企项目中的多图选择控件重新封装而成，去除了图片预览功能。

工程主要由AlbumGroupPicker和AlbumImagePicker组成：

## AlbumGroupPicker 相册分组选择器

AlbumGroupPicker实现用户相册授权访问，相册分组自动加载及展示。

接口定义如下：

```
/// 相册分组选择回调Block，这里会自动弹出照片选择器
typedef void (^AlbumGroupPickerSltedBlock) (AlbumImagePicker *picker);
/// 相册分组取消回调Block
typedef void (^AlbumGroupPickerCancelBlock) ();

/// 相册分组选择器
@interface AlbumGroupPicker : UIViewController
/// 相册分组列表
@property (nonatomic, strong) NSMutableArray *assetsGroup;
/// 确认选中相册分组回调Block
@property (nonatomic, copy) AlbumGroupPickerSltedBlock sltedBlock;
/// 取消相册分组选择回调Block
@property (nonatomic, copy) AlbumGroupPickerCancelBlock cancelBlock;
@end

```

## AlbumImagePicker 相片选择器

AlbumImagePicker实现相册分组图片多选功能。

接口定义如下：

```
/// 相册多图片选择完成回调Block
typedef void (^AlbumImagePickerDoneBlock) (NSArray *imagesPicked);

/// 相册多图片选择取消回调Block
typedef void (^AlbumImagePickerCanceledBlock) ();

@interface AlbumImagePicker : UIViewController
/// 确认选择图片回调Block
@property (nonatomic, copy) AlbumImagePickerDoneBlock       doneBlock;
/// 取消图片选择回调Block
@property (nonatomic, copy) AlbumImagePickerCanceledBlock   cancledBlock;

/// 照片选择张数上限
@property (nonatomic, assign) NSUInteger                    maxCount2Pick;
@end

```

## 调用方式
使用如下函数进行ViewController的初始化，并通过query给进参数。
如若无需给进参数，请自由选择初始化函数进行调用。

```
/// 初始化函数
- (id)initWithQuery:(NSString *)path query:(NSDictionary *)query;
```

弹出界面调用如下：

```
AlbumGroupPicker *groupPicker = [[AlbumGroupPicker alloc] initWithNibName:nil bundle:nil];
AlbumImagePicker *picker = [[AlbumImagePicker alloc] initWithQuery:nil query:nil];

UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:groupPicker];
[self presentViewController:nav animated:NO completion:^{
    [nav pushViewController:picker animated:YES];
}];
```

iOS6.0下需要检测相册访问授权情况并根据需要做提醒

```
if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
{
    if ( [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusDenied )
    {
        AlbumImagePicker *picker = [[AlbumImagePicker alloc] initWithQuery:nil query:nil];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:picker];
        [self.navigationController presentViewController:nav animated:YES completion:^{ }];
    }
}
```