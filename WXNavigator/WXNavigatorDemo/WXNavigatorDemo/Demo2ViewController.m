//
//  Demo2ViewController.m
//  WXNavigatorDemo
//
//  Created by 慕桥(黄玉坤) on 7/30/14.
//  Copyright (c) 2014 Alibaba. All rights reserved.
//

#import "Demo2ViewController.h"

@interface Demo2ViewController ()

@end

@implementation Demo2ViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Demo2";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UIButton *customView = [UIButton buttonWithType:UIButtonTypeCustom];
    [customView setTitle:@"返回" forState:UIControlStateNormal];
    [customView setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [customView addTarget:self action:@selector(onBackClicked) forControlEvents:UIControlEventTouchUpInside];
    [customView setFrame:CGRectMake(0, 0, 48, 24)];
    
    UIBarButtonItem *btnItem = [[UIBarButtonItem alloc] initWithCustomView:customView];
    self.navigationItem.leftBarButtonItem = btnItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

#pragma mark - Action
- (void)onBackClicked
{
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end
