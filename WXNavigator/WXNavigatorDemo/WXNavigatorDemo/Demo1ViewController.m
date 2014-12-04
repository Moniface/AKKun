//
//  Demo1ViewController.m
//  WXNavigatorDemo
//
//  Created by 慕桥(黄玉坤) on 7/29/14.
//  Copyright (c) 2014 Alibaba. All rights reserved.
//

#import "Demo1ViewController.h"

@interface Demo1ViewController ()

@end

@implementation Demo1ViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Demo1";
        
        UIButton *customView = [UIButton buttonWithType:UIButtonTypeCustom];
        [customView setTitle:@"返回" forState:UIControlStateNormal];
        [customView setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [customView addTarget:self action:@selector(onBackClicked) forControlEvents:UIControlEventTouchUpInside];
        [customView setFrame:CGRectMake(0, 0, 48, 24)];
        
        UIBarButtonItem *btnItem = [[UIBarButtonItem alloc] initWithCustomView:customView];
//        self.navigationItem.leftBarButtonItem = btnItem;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Action
- (void)onBackClicked
{
    [self.navigationController popViewControllerAnimated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
