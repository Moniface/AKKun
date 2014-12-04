//
//  AlbumImagePicker.m
//  WQClient
//
//  Created by 慕桥(黄玉坤) on 14/6/19.
//  Copyright (c) 2014年 Alibaba. All rights reserved.
//

#import "AlbumImagePicker.h"
#import "AlbumGroupPicker.h"
#import "AlbumImageItemView.h"

#import "WQNoDataView.h"
#import "UIControl+MTControl.h"

#import <AssetsLibrary/AssetsLibrary.h>

#define kCOLOR_COM_CYAN_LIGHT   [UIColor colorWithRed:83/255.f green:184/255.f blue:192/255.f alpha:1.0]

NSString * const kQueryKeyAssetsGroup = @"kQueryKeyAssetsGroup";
NSString * const kQueryKeyMaxCount2Pick = @"kQueryKeyMaxCount2Pick";

#pragma mark - AlbumImageItem
@interface AlbumImageItem : NSObject
@property (nonatomic, strong) UIImage *thumbnail;
@property (nonatomic, strong) UIImage *originImage;
@property (nonatomic, strong) ALAsset *asset;
@property (nonatomic, strong) NSString *assetUrl;
@property (nonatomic, assign) BOOL selected;
@end

@implementation AlbumImageItem
- (UIImage *)thumbnail
{
    if ( _thumbnail ) return _thumbnail;
    if ( !_asset.thumbnail ) return nil;
    
    return [UIImage imageWithCGImage:_asset.thumbnail];
}

- (UIImage *)originImage
{
    if ( _originImage ) return _originImage;
    if ( !_asset ) return nil;
    
    return [self originImageFromALAsset:_asset];
}

- (NSString *)assetUrl
{
    if ( _asset == nil ) return nil;
    NSDictionary *urls = [_asset valueForProperty:ALAssetPropertyURLs];
    NSString *key = [[urls allKeys] firstObject];
    if ( key.length == 0 ) return nil;
    
    NSURL *url = [urls objectForKey:key];
    return [url absoluteString];
}

- (UIImage *)originImageFromALAsset:(ALAsset *)asset
{
    ALAssetRepresentation *assetRep = [asset defaultRepresentation];
    CGImageRef imgRef = [assetRep fullScreenImage];
    
    UIImage *image = [UIImage imageWithCGImage:imgRef];
    NSData *compressedDate = UIImageJPEGRepresentation(image, 0.8);
    
    if ( compressedDate.length > (1024 * 200) ) // 限制200K以下
    {
        compressedDate = UIImageJPEGRepresentation(image, 0.5);
    }
    
    return [UIImage imageWithData:compressedDate];
}

@end

#pragma mark - AlbumImagePicker

#define ItemCountPerLine        4
#define ShelfViewHeight         60
#define MaxCount2PickDefault    6

#define BottomViewHeight    50
#define CountLabelViewTag   8900
#define CountBubbleViewTag  8988
#define DoneButtonViewTag   9000
#define PreviewBtnViewTag   9800

@interface AlbumImagePicker ()<UITableViewDelegate, UITableViewDataSource,
UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong) UITableView           *tableView;

@property (nonatomic, strong) ALAssetsLibrary       *assetsLibrary;
@property (nonatomic, strong) ALAssetsGroup         *assetsGroup;

@property (nonatomic, strong) NSMutableArray        *imageItemList;
@property (nonatomic, strong) NSMutableArray        *imageItemSltedList;

/// 底部已选中图片展示控件
//@property (nonatomic, strong) WQShelfView           *shelfView;
@property (nonatomic, strong) UIView                *bottomView;
@end

@implementation AlbumImagePicker

- (id)initWithQuery:(NSString *)path query:(NSDictionary *)query
{
    if ( self = [super initWithNibName:nil bundle:nil] )
    {
        NSNumber *maxCount2Pick = query[kQueryKeyMaxCount2Pick];
        self.maxCount2Pick = maxCount2Pick ? [maxCount2Pick unsignedIntValue]:MaxCount2PickDefault;
        self.assetsGroup = query[kQueryKeyAssetsGroup];
        
        if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending )
        {
            if ( [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusDenied )
            {
                [self tip2Authorize];
                
                // 未授权访问，关闭相册列表入口
                self.navigationItem.leftBarButtonItems = nil;
            }
            else
            {
                if ( self.assetsGroup == nil )
                {
                    [self loadSavedPhotosAssetsGroup];
                }
                else
                {
                    [self loadPhotosFromAssetsGroup];
                }
            }
        }
        else
        {
            if ( self.assetsGroup == nil )
            {
                [self loadSavedPhotosAssetsGroup];
            }
            else
            {
                [self loadPhotosFromAssetsGroup];
            }
            
        }
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupNavBar];
    [self createTableView];
    [self createBottomView];
    
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup
- (void)setupNavBar
{
    UIButton *customView = [UIButton buttonWithType:UIButtonTypeCustom];
    [customView setTitle:@"取消" forState:UIControlStateNormal];
    [customView setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [customView addTarget:self action:@selector(onCancelButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [customView setFrame:CGRectMake(0, 0, 48, 24)];
    
    UIBarButtonItem *btnItem = [[UIBarButtonItem alloc] initWithCustomView:customView];
    self.navigationItem.rightBarButtonItem = btnItem;
}

#pragma mark - Action

- (void)onCancelButtonClicked
{
    if ( self.cancledBlock ) { self.cancledBlock(); }
    
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void)onDoneButtonClicked
{
//    UIViewController *topVC = [sharedNavigator topViewController];
//    [UIUtil showIndicatorWithMask:YES forView:topVC.view withText:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray *imagesPicked = [NSMutableArray array];
        for (AlbumImageItem *imageItem in self.imageItemSltedList)
        {
            @autoreleasepool {
                NSMutableDictionary *imageInfo = [NSMutableDictionary dictionary];
                if ( imageItem.thumbnail ) { imageInfo[@"thumbnail"] = imageItem.thumbnail; }
                
                UIImage *originImage = imageItem.originImage;
                if ( originImage ) { imageInfo[@"originImage"] = originImage; }
                
                [imagesPicked addObject:imageInfo];
            }
        }
        
//        [UIUtil showIndicatorWithMask:NO forView:topVC.view withText:nil];
        if ( self.doneBlock ) { self.doneBlock(imagesPicked); self.doneBlock = nil;}
        [self.navigationController dismissModalViewControllerAnimated:YES];
    });
}

- (void)onAlbumImageItemViewClicked:(AlbumImageItemView *)imageItemView event:(UIEvent *)event;
{
    UITouch *touch = [event.allTouches anyObject];
    CGPoint touchPoint = [touch locationInView:self.tableView];
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchPoint];
    if ( indexPath == nil ) return;
    
    NSInteger index = indexPath.row * ItemCountPerLine + floor(touchPoint.x / AlbumImageItemViewWidth);
    if ( index >= self.imageItemList.count ) return;
    
    if ( !imageItemView.checked && self.imageItemSltedList.count >= self.maxCount2Pick )
    {
//        [UIUtil showHint:[NSString stringWithFormat:@"最多可以添加%d张图片", self.maxCount2Pick]];
        return;
    }

    AlbumImageItem *imageItem = self.imageItemList[index];
    
    touchPoint = [touch locationInView:imageItemView];
//    CGRect flagArea = CGRectInset(imageItemView.checkedFlag.frame, -2, -2);
//    if ( CGRectContainsPoint(flagArea, touchPoint) )
//    {
        imageItem.selected = !imageItemView.checked;
        imageItemView.checked = imageItem.selected;
        
        if ( imageItem.selected )
        {
            [self addShelfItem:imageItem];
        }
        else
        {
            [self removeShelfItem:imageItem];
        }
    
        [self updateBottomView];
//    }
//    else
//    {
////        [self previewPhotoAtIndex:index];
//    }
}

- (void)onOpenCamera2PickImage
{
    // 调用系统的camera
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        UIImagePickerController* photoLibraryPicker = [[UIImagePickerController alloc] init];
        photoLibraryPicker.delegate = self;
        photoLibraryPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        photoLibraryPicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        photoLibraryPicker.allowsEditing = YES;
//        [CustomUIStyle enableCustomUIStyle:CustomUIStyleTypeNavigationBar enable:NO];
        [self presentModalViewController:photoLibraryPicker animated:YES];
    }
    else
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"设备不支持"
                                                       delegate:nil cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];
        [alert show];
        
    }
}

#pragma mark -
- (void)createTableView
{
    CGRect tableFrame = self.view.bounds;
    tableFrame.size.height -= BottomViewHeight;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.backgroundColor = [UIColor whiteColor];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    
    [self.view addSubview:_tableView];
}

- (void)createBottomView
{
    __weak typeof (self) weakRef = self;
    
    CGRect btmFrame = CGRectMake(0, self.view.frame.size.height - BottomViewHeight,
                              self.view.frame.size.width, BottomViewHeight);
    
    UIView *bottomView = [[UIView alloc] initWithFrame:btmFrame];
    bottomView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    bottomView.backgroundColor = [UIColor colorWithRed:37/255.f green:43/255.f blue:43/255.f alpha:1.0];
    
//    CGRect preFrame = CGRectMake(10, 10, 50, 30);
//    UIButton *previewButton = [[UIButton alloc] initWithFrame:preFrame];
//
//    [previewButton setBackgroundColor:kCOLOR_COM_GRAY_LIGHT forState:UIControlStateNormal];
//    [previewButton setBackgroundColor:kCOLOR_COM_GRAY_LIGHT forState:UIControlStateHighlighted];
//    [previewButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//    [previewButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
//    [previewButton setTitle:@"预览" forState:UIControlStateNormal];
//    
//    [previewButton touchUpInside:^(UIEvent *event) {
//        [weakRef previewPhotosSelected];
//    }];
//    
//    [previewButton setTag:PreviewBtnViewTag];
//    [bottomView addSubview:previewButton];
    
    CGRect doneFrame = CGRectMake(260, 10, 50, 30);
    UIButton *doneButton = [[UIButton alloc] initWithFrame:doneFrame];
    [doneButton setTitle:@"完成" forState:UIControlStateNormal];
    [doneButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
    [doneButton.titleLabel setTextColor:[UIColor whiteColor]];
    [doneButton setBackgroundColor:kCOLOR_COM_CYAN_LIGHT];
    
    [doneButton touchUpInside:^(UIEvent *event) {
        [weakRef onDoneButtonClicked];
    }];
    
    [doneButton setTag:DoneButtonViewTag];
    [bottomView addSubview:doneButton];
    
    CGRect bubbleFrame = CGRectMake(doneButton.frame.origin.x - 9, 1, 18, 18);
    UIImageView *countBubbleView = [[UIImageView  alloc] initWithFrame:bubbleFrame];
    countBubbleView.image = [UIImage imageNamed:@"news_background"];
    countBubbleView.tag = CountBubbleViewTag;
    
    UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 18, 18)];
    countLabel.backgroundColor = [UIColor clearColor];
    countLabel.textAlignment = NSTextAlignmentCenter;
    countLabel.font = [UIFont systemFontOfSize:11];
    countLabel.textColor = [UIColor whiteColor];
    countLabel.tag = CountLabelViewTag;
    
    [countBubbleView addSubview:countLabel];
    [bottomView addSubview:countBubbleView];
    
    [self.view addSubview:bottomView];
    
    self.bottomView = bottomView;
    
    [self updateBottomView];
}

- (void)loadPhotosFromAssetsGroup
{
    self.imageItemList = [[NSMutableArray alloc] init];
    self.imageItemSltedList = [[NSMutableArray alloc] init];
    
    @autoreleasepool
    {
//        [UIUtil showIndicatorWithMask:YES forView:self.view withText:nil];
        
        self.title = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.assetsGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if ( result ) {
                    AlbumImageItem *item = [[AlbumImageItem alloc] init];
                    item.asset = result; [self.imageItemList addObject:item];
                }
            }];
            
//            [UIUtil showIndicatorWithMask:NO forView:self.view withText:nil];
            
            [self.tableView reloadData];
            [self scrollTableView:self.tableView toBottom:NO];
        });
    }
}

- (void)scrollTableView:(UITableView *)tableView toBottom:(BOOL)animated
{
    NSUInteger sectionCount = [tableView numberOfSections];
    if (sectionCount)
    {
        NSUInteger rowCount = [tableView numberOfRowsInSection:0];
        if (rowCount)
        {
            NSUInteger ii[2] = {0, rowCount-1};
            NSIndexPath* indexPath = [NSIndexPath indexPathWithIndexes:ii length:2];
            [tableView scrollToRowAtIndexPath:indexPath
                             atScrollPosition:UITableViewScrollPositionBottom
                                     animated:animated];
        }
    }
}

- (void)loadSavedPhotosAssetsGroup
{
    self.assetsLibrary = _assetsLibrary ?: [[ALAssetsLibrary alloc] init];
    
    __weak typeof (self) weakRef = self;
    
    @autoreleasepool
    {
        ALAssetsLibraryGroupsEnumerationResultsBlock resultBlock = ^(ALAssetsGroup *group, BOOL *stop){
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
            
            ALAssetsGroupType groupType =[[group valueForProperty:ALAssetsGroupPropertyType] intValue];
            if ( ALAssetsGroupSavedPhotos == groupType )
            {
                weakRef.assetsGroup = group;
                [weakRef loadPhotosFromAssetsGroup];
            }
            
            [weakRef.tableView reloadData];
        };
        
        [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:resultBlock failureBlock:^(NSError *error) {
//            [UIUtil showHint:@"相册图片加载失败"];
        }];
    }
}

- (void)addShelfItem:(AlbumImageItem *)imageItem
{
    if ( [_imageItemSltedList containsObject:imageItem] ) return;
    
    [self.imageItemSltedList addObject:imageItem];
    
//    CGRect itemFrame = CGRectMake(0, 0, AIShelfItemViewWidth, AIShelfItemViewHeight);
//    AIShelfItemView *itemView = [[AIShelfItemView alloc] initWithFrame:itemFrame];
//    itemView.imageView.image = imageItem.thumbnail;
//    
//    [self.shelfView pushItemView:itemView];
}

- (void)removeShelfItem:(AlbumImageItem *)imageItem
{
    if ( ![_imageItemSltedList containsObject:imageItem] ) return;
    
//    NSUInteger index = [_imageItemSltedList indexOfObject:imageItem];
//    [self.shelfView removeItemViewAlIndex:index];
    
    [_imageItemSltedList removeObject:imageItem];
}

//- (void)previewPhotoAtIndex:(NSUInteger)index
//{
//    NSMutableArray *ibItemList = [NSMutableArray array];
//    NSMutableIndexSet *indexSltedSet = [NSMutableIndexSet indexSet];
//    
//    for ( AlbumImageItem *imageItem in self.imageItemList )
//    {
//        @autoreleasepool {
//            WXImageBrowserItemInfo *ibItemInfo = [[WXImageBrowserItemInfo alloc] init];
//            ibItemInfo.userInfo = @{@"imageItemInfo":imageItem};
//            
//            if ( imageItem.asset != nil )   // 性能优化，lazyload
//            {
//                ibItemInfo.originUrl = imageItem.assetUrl;
//            }
//            else
//            {
//                ibItemInfo.originImage = imageItem.originImage;
//            }
//            
//            if ( imageItem.selected == YES )
//            {
//                [indexSltedSet addIndex:[_imageItemList indexOfObject:imageItem]];
//            }
//            
//            [ibItemList addObject:ibItemInfo];
//        }
//    }
//    
//    NSDictionary* dic = @{kQueryKeyImageDataSource:ibItemList,
//                          kQueryKeyImageSelectIndex:@(index),
//                          kQueryKeyActAsImagePicker:@(YES),
//                          kQueryKeyIndexSltedSet:indexSltedSet,
//                          kQueryKeyMaxCount2Pick:@(self.maxCount2Pick)};
//    
//    UIViewController *vc = [sharedNavigator open:@"WQNavigator://WXImageBrowser" withParams:dic];
//    WXImageBrowserViewController *ibvc = (WXImageBrowserViewController *)vc;
//    
//    [ibvc setDoneBlock:^(NSArray *dataSource, NSIndexSet *indexSet) {
//        [self reloadWithDataSource:dataSource indexSltedSet:indexSet];
//        dispatch_async(dispatch_get_main_queue(), ^{ [self onDoneButtonClicked]; });
//    }];
//    
//    [ibvc setCanceledBlock:^(NSArray *dataSource, NSIndexSet *indexSet) {
//        [self reloadWithDataSource:dataSource indexSltedSet:indexSet];
//    }];
//}

- (void)previewPhotosSelected
{
//    NSMutableArray *ibItemList = [NSMutableArray array];
//    NSMutableIndexSet *indexSltedSet = [NSMutableIndexSet indexSet];
//    
//    for ( AlbumImageItem *imageItem in self.imageItemSltedList )
//    {
//        WXImageBrowserItemInfo *ibItemInfo = [[WXImageBrowserItemInfo alloc] init];
//        ibItemInfo.userInfo = @{@"imageItemInfo":imageItem};
//        
//        if ( imageItem.asset != nil )   // 性能优化，lazyload
//        {
//            ibItemInfo.originUrl = imageItem.assetUrl;
//        }
//        else
//        {
//            ibItemInfo.originImage = imageItem.originImage;
//        }
//        
//        [indexSltedSet addIndex:[_imageItemSltedList indexOfObject:imageItem]];
//        
//        [ibItemList addObject:ibItemInfo];
//    }
//    
//    NSDictionary* dic = @{kQueryKeyImageDataSource:ibItemList,
//                          kQueryKeyImageSelectIndex:@(0),
//                          kQueryKeyActAsImagePicker:@(YES),
//                          kQueryKeyIndexSltedSet:indexSltedSet};
//    
//    UIViewController *vc = [sharedNavigator open:@"WQNavigator://WXImageBrowser" withParams:dic];
//    WXImageBrowserViewController *ibvc = (WXImageBrowserViewController *)vc;
//    
//    [ibvc setDoneBlock:^(NSArray *dataSource, NSIndexSet *indexSet) {
//        [self reloadWithDataSource:dataSource indexSltedSet:indexSet];
//        dispatch_async(dispatch_get_main_queue(), ^{ [self onDoneButtonClicked]; });
//    }];
//    
//    [ibvc setCanceledBlock:^(NSArray *dataSource, NSIndexSet *indexSet) {
//        [self reloadWithDataSource:dataSource indexSltedSet:indexSet];
//    }];
}

- (void)updateBottomView
{
    UIButton *doneButton = (UIButton *)[_bottomView viewWithTag:DoneButtonViewTag];
    doneButton.enabled = _imageItemSltedList.count > 0;
    
    UIButton *previewButton = (UIButton *)[_bottomView viewWithTag:PreviewBtnViewTag];
    previewButton.hidden = _imageItemSltedList.count == 0;
    
    UIView *countBubbleView = [_bottomView viewWithTag:CountBubbleViewTag];
    countBubbleView.hidden = _imageItemSltedList.count == 0;;
    
    UILabel *label = (UILabel *)[countBubbleView viewWithTag:CountLabelViewTag];
    [label setText:[NSString stringWithFormat:@"%@", @(_imageItemSltedList.count)]];
}

- (void)tip2Authorize
{
    WQNoDataView *nodataView = [WQNoDataView noDataViewWithStyle:WQNoDataShowStyleNormal];
    nodataView.textLabel.text = @"请在iPhone的”设置-隐私-照片“选项中，允许旺起访问你的手机相册。";
    nodataView.frame = self.view.bounds;
    
    [self.view addSubview:nodataView];
}

//- (void)reloadWithDataSource:(NSArray *)dataSource indexSltedSet:(NSIndexSet *)indexSet
//{
//    for (AlbumImageItem *imageItemSlted in self.imageItemList)
//    {
//        imageItemSlted.selected = NO;
//    }
//    
//    [self.imageItemSltedList removeAllObjects];
//    
//    NSMutableArray *imageItemSltedList = [NSMutableArray array];
//    
//    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
//        WXImageBrowserItemInfo *ibItemInfo = [dataSource objectAtIndex:idx];
//        AlbumImageItem *imageItem = ibItemInfo.userInfo[@"imageItemInfo"];
//        imageItem.selected = YES;
//        
//        [imageItemSltedList addObject:imageItem];
//    }];
//    
//    self.imageItemSltedList = imageItemSltedList;
//    [self.tableView reloadData];
//    [self updateBottomView];
//}


#pragma mark -  UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return AlbumImageItemViewHeight;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ceil((float)self.imageItemList.count / ItemCountPerLine);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"AlbumImagesCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if ( cell == nil )
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    [self configTableViewCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)configTableViewCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    for (UIView *subView in [cell.contentView subviews])
    {
        [subView removeFromSuperview];
    }
    
    NSInteger startIndex = indexPath.row * ItemCountPerLine;
    if ( startIndex >= self.imageItemList.count ) return;
    
    NSRange range = NSMakeRange(startIndex, MIN(ItemCountPerLine, _imageItemList.count - startIndex));
    NSArray *assetsSlice = [self.imageItemList subarrayWithRange:range];
    
    if ( assetsSlice.count == 0 ) return;
    
    for ( AlbumImageItem *item in assetsSlice )
    {
        CGRect frame = CGRectMake(0, 0, AlbumImageItemViewWidth, AlbumImageItemViewHeight);
        
        AlbumImageItemView *itemView = [[AlbumImageItemView alloc] initWithFrame:frame];
        [itemView addTarget:self
                     action:@selector(onAlbumImageItemViewClicked:event:)
           forControlEvents:UIControlEventTouchUpInside];
        
        itemView.checked = item.selected;
        
        // 设置默认图片
//        itemView.imageView.image = ImageNamed(@"");
        [itemView.imageView setImage:item.thumbnail];
        
        CGRect itemViewFrame = itemView.frame;
        itemViewFrame.origin.x = [assetsSlice indexOfObject:item] * AlbumImageItemViewWidth;
        itemView.frame = itemViewFrame;
        
        [cell.contentView addSubview:itemView];
    }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *imageSource = nil;
    if ( picker.allowsEditing )
    {
        // 有编辑模式，需要选取编辑后的图片
        imageSource = (UIImage *)[info objectForKey:UIImagePickerControllerEditedImage];
    }
    else
    {
        imageSource = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    if ( imageSource )
    {
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        CGSize realSize = [self getRealSizeFromScreenScaleSize:screenSize];
        
        CGFloat width = imageSource.size.width;
        CGFloat height = imageSource.size.height;
        if (width > realSize.width || height > realSize.height) {
            CGFloat xScale = realSize.width / width;
            CGFloat yScale = realSize.height / height;
            CGFloat minScale = MIN(xScale, yScale);
            
            width *= minScale;
            height *= minScale;
        }
        
        UIGraphicsBeginImageContext(CGSizeMake(floor(width), floor(height)));
        [imageSource drawInRect:CGRectMake(0, 0, width, height)];
        UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        AlbumImageItem *imageItem = [[AlbumImageItem alloc] init];
        imageItem.thumbnail = finalImage;
        imageItem.selected = YES;
        
        [self.imageItemList addObject:imageItem];
//        [self addShelfItem:imageItem];
    }
    
//    [CustomUIStyle enableCustomUIStyle:CustomUIStyleTypeNavigationBar enable:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
//    [CustomUIStyle enableCustomUIStyle:CustomUIStyleTypeNavigationBar enable:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    
    if ([navigationController isKindOfClass:[UIImagePickerController class]] &&
        ((UIImagePickerController *)navigationController).sourceType == UIImagePickerControllerSourceTypeCamera) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    }
}

#pragma mark -
- (CGSize)getRealSizeFromScreenScaleSize:(CGSize)size
{
    CGSize sizeNew = size;
    CGFloat scale = [UIScreen mainScreen].scale;
    if( scale > 1 )
    {
        sizeNew = CGSizeMake((NSInteger)(size.width*scale), (NSInteger)(size.height*scale));
    }
    if( sizeNew.width == 0  )
        sizeNew.width = 1;
    if( sizeNew.height == 0 )
        sizeNew.height = 1;
    
    return sizeNew;
}

@end
