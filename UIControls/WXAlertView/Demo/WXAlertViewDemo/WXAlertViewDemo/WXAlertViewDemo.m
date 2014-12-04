//
//  WXAlertViewDemo.m
//  WXAlertViewDemo
//
//  Created by 慕桥(黄玉坤) on 7/17/14.
//  Copyright (c) 2014 Alibaba. All rights reserved.
//

#import "WXAlertViewDemo.h"
#import "WXAlertView.h"
#import "WXAlertView+Radio.h"

#pragma mark - DemoItem
typedef void (^DemoPlayBlock) ();
@interface DemoItem : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic,   copy) DemoPlayBlock playBlock;
- (void)setPlayBlock:(DemoPlayBlock)playBlock;
@end

@implementation DemoItem
@end

#pragma mark - WXAlertViewDemo

@interface WXAlertViewDemo ()
@property (nonatomic, strong) NSMutableArray *demoItemList;
@end

@implementation WXAlertViewDemo

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createDemoItems];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)createDemoItems
{
    self.demoItemList = [NSMutableArray array];
    
    DemoItem *singleBtnDemo = [[DemoItem alloc] init];
    singleBtnDemo.name = @"Single Button Alert View";
    [singleBtnDemo setPlayBlock:^{
        [[[WXAlertView alloc] init] showWithTitle:@"提示" message:@"哔哩哔哩..." clickAction:^(NSUInteger buttonIndex) {
        } maskType:WXAlertViewMaskTypeBlack userInfo:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
    }];
    
    [self.demoItemList addObject:singleBtnDemo];
    
    DemoItem *twoBtnDemo = [[DemoItem alloc] init];
    twoBtnDemo.name = @"Two-Button Alert View";
    [twoBtnDemo setPlayBlock:^{
        [[[WXAlertView alloc] init] showWithTitle:@"提示" message:@"哔哩哔哩..." clickAction:^(NSUInteger buttonIndex) {
        } maskType:WXAlertViewMaskTypeBlack userInfo:nil cancelButtonTitle:@"取消" otherButtonTitles:@[@"确定"]];
    }];
    
    [self.demoItemList addObject:twoBtnDemo];
    
    DemoItem *multiBtnDemo = [[DemoItem alloc] init];
    multiBtnDemo.name = @"Multi-Button Alert View";
    [multiBtnDemo setPlayBlock:^{
        [[[WXAlertView alloc] init] showWithTitle:@"提示" message:@"哔哩哔哩..." clickAction:^(NSUInteger buttonIndex) {
        } maskType:WXAlertViewMaskTypeBlack userInfo:nil cancelButtonTitle:@"取消"
                                otherButtonTitles:@[@"按钮1", @"按钮2", @"按钮3", @"按钮4",@"确定"]];
    }];
    
    [self.demoItemList addObject:multiBtnDemo];
    
    DemoItem *pswdDemo = [[DemoItem alloc] init];
    pswdDemo.name = @"Pswd Alert View";
    [pswdDemo setPlayBlock:^{
        [self createPswdAlertView];
    }];
    
    [self.demoItemList addObject:pswdDemo];
    
    DemoItem *radioDemo = [[DemoItem alloc] init];
    radioDemo.name = @"Radio Alert View";
    [radioDemo setPlayBlock:^{
        [[[WXAlertView alloc] init] showWithTitle:nil
                                       radioNames:@[@"选项1", @"选项2", @"选项3"]
                                       radioIndex:1
                                      clickAction:^(NSUInteger buttonIndex, NSInteger radioIndex) {
                                          // 取消
                                          if( buttonIndex == WXAlertViewCancelButtonIndex )
                                              return;
                                          
                                          switch (radioIndex)
                                          {
                                              case 0: {     //接收并推送群消息
                                                  NSLog(@"已选择选项1");
                                              } break;
                                              case 1: {     //接收群消息
                                                  NSLog(@"已选择选项2");
                                              } break;
                                              case 2: {     //关闭
                                                  NSLog(@"已选择选项3");
                                              } break;
                                              default:
                                                  break;
                                          }
                                      }
                                         maskType:WXAlertViewMaskTypeBlack
                                cancelButtonTitle:@"取消"
                                otherButtonTitles:@[@"确定"]];
    }];
 
    [self.demoItemList addObject:radioDemo];
    
    [self.tableView reloadData];
}

- (void)createPswdAlertView
{
    UIView *trunkView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 46)];
    UITextField* textField = [[UITextField alloc] initWithFrame:CGRectMake(6, 6, 268, 34)];
    textField.backgroundColor = [UIColor whiteColor];
    textField.placeholder = @"密码";
//    textField.delegate = self;
    
    trunkView.layer.borderColor = [UIColor grayColor].CGColor;
    trunkView.layer.borderWidth = 1.0f;
    
    [trunkView addSubview:textField];
    
    WXAlertView *alertView = [[WXAlertView alloc] init];
    
    [alertView showWithTitle:nil trunkView:trunkView clickAction:^(NSUInteger buttonIndex) {
        NSString *pswd = textField.text;
        NSLog(@"User input pswd: %@", pswd);
    } maskType:WXAlertViewMaskTypeBlack userInfo:nil cancelButtonTitle:@"取消" otherButtonTitles:@[@"确定"]];
    
    // 调整alertView位置避免被键盘遮挡
//    [alertView changeAlertOffset:-48];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.demoItemList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DemoCell" forIndexPath:indexPath];
    
    if ( cell == nil )
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DemoCell"];
    }
    
    if ( self.demoItemList.count > indexPath.row )
    {
        DemoItem *item = self.demoItemList[indexPath.row];
        [cell.textLabel setText:item.name];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ( self.demoItemList.count > indexPath.row )
    {
        DemoItem *item = self.demoItemList[indexPath.row];
        if ( item.playBlock ) { item.playBlock(); }
    }
}

@end
