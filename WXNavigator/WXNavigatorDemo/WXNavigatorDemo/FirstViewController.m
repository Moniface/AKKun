//
//  FirstViewController.m
//  WXNavigatorDemo
//
//  Created by 慕桥(黄玉坤) on 7/29/14.
//  Copyright (c) 2014 Alibaba. All rights reserved.
//

#import "FirstViewController.h"
#import "WXNavigatorManager.h"

@interface FirstViewController ()

@end

@implementation FirstViewController

- (id)initWithQuery:(NSString*)path query:(NSDictionary*)query
{
    if ( [self initWithNibName:nil bundle:nil] )
    {
        NSLog(@"Get it!");
        
        // iOS7上防止tableView被遮盖
        if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
            self.edgesForExtendedLayout = UIRectEdgeNone;
        }
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"Root VC";
    
    // Just do this once
    [sharedNavigator map:@"demo1" toViewController:NSClassFromString(@"Demo1ViewController")];
    [sharedNavigator map:@"demo2" toModalViewController:NSClassFromString(@"Demo2ViewController")];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Action
- (IBAction)onPushVC
{
    [sharedNavigator open:@"demo1" withAnimated:NO];
}

- (IBAction)onPushModalVC
{
    [sharedNavigator open:@"demo2" withAnimated:YES];
}

- (IBAction)onPushVCAnimated
{
    [sharedNavigator open:@"demo1" withAnimated:YES];
}

@end
