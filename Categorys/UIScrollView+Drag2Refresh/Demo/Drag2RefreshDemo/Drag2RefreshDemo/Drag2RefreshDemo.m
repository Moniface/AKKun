//
//  Drag2RefreshDemo.m
//  Drag2RefreshDemo
//
//  Created by 慕桥(黄玉坤) on 7/17/14.
//  Copyright (c) 2014 Alibaba. All rights reserved.
//

#import "Drag2RefreshDemo.h"
#import "UIScrollView+Drag2Refresh.h"

@interface Drag2RefreshDemo ()

@end

@implementation Drag2RefreshDemo

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Drag2Refresh";
    
    __weak typeof (self) weakSelf = self;
    
    [self.tableView addDrag2RefreshWithActionHandler:^{        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf.tableView.btmDrag2RefreshView stopAnimating];
        });
    } position:Drag2RefreshPositionBottom];
    
    [self.tableView addDrag2RefreshWithActionHandler:^{
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf.tableView.topDrag2RefreshView stopAnimating];
        });
    } position:Drag2RefreshPositionTop];
    
    [self.tableView.topDrag2RefreshView setTitle:@"下拉刷新..." forState:Drag2RefreshStateStopped];
    [self.tableView.topDrag2RefreshView setTitle:@"释放开始刷新..." forState:Drag2RefreshStateTriggered];
    [self.tableView.topDrag2RefreshView setTitle:@"刷新中..." forState:Drag2RefreshStateLoading];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"D2RDemoCell"
                                                            forIndexPath:indexPath];
    
    if ( cell == nil )
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"D2RDemoCell"];
    }
    
    // Configure the cell...
    switch (indexPath.row)
    {
        case 0: {
            cell.textLabel.text = @"下拉刷新";
        } break;
        case 1: {
            cell.textLabel.text = @"上拉刷新";
        } break;
        case 2: {
            cell.textLabel.text = @"显示上拉控件";
        } break;
        case 3: {
            cell.textLabel.text = @"隐藏上拉控件";
        } break;
        case 4: {
            cell.textLabel.text = @"锁定上拉控件";
        } break;
        case 5: {
            cell.textLabel.text = @"解锁上拉控件";
        } break;
        default: {
            cell.textLabel.text = [@"Cell" stringByAppendingFormat:@"%d", indexPath.row];
        } break;
    }

    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row)
    {
        case 0: {
            [self.tableView triggerPullToRefreshWithPosition:Drag2RefreshPositionTop];
        } break;
        case 1: {
//            NSIndexPath *lastRow = [NSIndexPath indexPathForRow:5 inSection:0];
//            [self.tableView scrollToRowAtIndexPath:lastRow atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            [self.tableView triggerPullToRefreshWithPosition:Drag2RefreshPositionBottom];
        } break;
        case 2: {
            [self.tableView showsPullToRefresh:YES position:Drag2RefreshPositionTop];
        } break;
        case 3: {
            [self.tableView showsPullToRefresh:NO position:Drag2RefreshPositionTop];
        } break;
        case 4: {
            [self.tableView lockPullToRefresh:YES position:Drag2RefreshPositionTop];
        } break;
        case 5: {
            [self.tableView lockPullToRefresh:NO position:Drag2RefreshPositionTop];
        } break;
        default: {
            
        } break;
    }
}

@end
