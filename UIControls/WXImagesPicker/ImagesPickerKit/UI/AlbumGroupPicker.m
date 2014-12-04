//
//  AlbumGroupPicker.m
//  WQClient
//
//  Created by 慕桥(黄玉坤) on 6/25/14.
//  Copyright (c) 2014 Alibaba. All rights reserved.
//

#import "AlbumGroupPicker.h"
#import "AlbumGroupCell.h"
#import "WQNoDataView.h"

#import "AlbumImagePicker.h"

#define currentSystemVersion [[UIDevice currentDevice] systemVersion]
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([currentSystemVersion compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface AssetsGroupItem : NSObject

@end

@interface AlbumGroupPicker ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) ALAssetsLibrary       *assetsLibrary;
@property (nonatomic, strong) UITableView           *tableView;
@end

@implementation AlbumGroupPicker

- (id)initWithQuery:(NSString *)path query:(NSDictionary *)query
{
    if ( self = [self initWithNibName:nil bundle:nil] )
    {
        
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        self.title = @"照片";
        
        UIButton *customView = [UIButton buttonWithType:UIButtonTypeCustom];
        [customView setTitle:@"取消" forState:UIControlStateNormal];
        [customView setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [customView addTarget:self action:@selector(onCanclePickButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [customView setFrame:CGRectMake(0, 0, 48, 24)];
        
        UIBarButtonItem *btnItem = [[UIBarButtonItem alloc] initWithCustomView:customView];
        self.navigationItem.rightBarButtonItem = btnItem;
        
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self createTableView];
    [self loadAlbumGroup];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - action
- (void)onCanclePickButtonClicked
{
    if ( self.cancelBlock ) { self.cancelBlock(); }
    [self popViewController];
}

#pragma mark -
- (void)loadAlbumGroup
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
    {
        if ( [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusDenied )
        {
            return [self tip2Authorize];
        }
    }
    
    self.assetsLibrary = _assetsLibrary ?: [[ALAssetsLibrary alloc] init];
    self.assetsGroup = [NSMutableArray array];
    
    @autoreleasepool
    {
        ALAssetsLibraryGroupsEnumerationResultsBlock resultBlock = ^(ALAssetsGroup *group, BOOL *stop){
            if ( group == nil ) return;
            [self.assetsGroup addObject:group];
            [self.tableView reloadData];
        };
        
        [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:resultBlock failureBlock:^(NSError *error) {
            /// [UIUtil showHint:@"相册列表加载失败"];
            NSLog(@"相册列表加载失败");
        }];
    }
}

- (void)tip2Authorize
{
    WQNoDataView *nodataView = [WQNoDataView noDataViewWithStyle:WQNoDataShowStyleNormal];
    nodataView.textLabel.text = @"请在iPhone的”设置-隐私-照片“选项中，允许旺起访问你的手机相册。";
    nodataView.frame = self.view.bounds;
    
    [self.view addSubview:nodataView];
}

- (void)createTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.backgroundColor = [UIColor whiteColor];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    
    [self.view addSubview:_tableView];
}

- (void)popViewController
{
    [self.navigationController dismissViewControllerAnimated:YES completion:^{ }];
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return AlbumGroupCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ALAssetsGroup *assetsGroup = [self.assetsGroup objectAtIndex:indexPath.row];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if ( assetsGroup == nil ) return;
    
    NSDictionary *params = @{kQueryKeyAssetsGroup:assetsGroup};
    AlbumImagePicker *imagePicker = [[AlbumImagePicker alloc] initWithQuery:nil query:params];
    [self.navigationController pushViewController:imagePicker animated:YES];
    
    if ( self.sltedBlock ) { self.sltedBlock((AlbumImagePicker *)imagePicker); }
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.assetsGroup.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"AlbumGroupCell";
    AlbumGroupCell *cell = (AlbumGroupCell *)[tableView dequeueReusableCellWithIdentifier:cellId];
    if ( cell == nil )
    {
        cell = [[AlbumGroupCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    ALAssetsGroup *group = [self.assetsGroup objectAtIndex:indexPath.row];
    NSInteger assetsCount = [group numberOfAssets];
    NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
    UIImage *poster = [UIImage imageWithCGImage:group.posterImage];
    
    [cell updateCellWithPoster:poster name:name count:assetsCount];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

@end
