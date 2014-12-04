//
//  ViewController.m
//  ImagesPickerDemo
//
//  Created by 慕桥(黄玉坤) on 7/29/14.
//  Copyright (c) 2014 Alibaba. All rights reserved.
//

#import "ViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import "ImagesPickerKit.h"

#define currentSystemVersion [[UIDevice currentDevice] systemVersion]
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([currentSystemVersion compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)openPicker
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
    {
        if ( [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusDenied )
        {
            AlbumImagePicker *picker = [[AlbumImagePicker alloc] initWithQuery:nil query:nil];

            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:picker];
            [self.navigationController presentViewController:nav animated:YES completion:^{ }];
            
            [picker setCancledBlock:^{
                NSLog(@"Cancle button clicked.");
            }];
            
            return;
        }
    }
    
    AlbumImagePickerDoneBlock doneBlock = ^(NSArray *imagesPicked){

        NSMutableArray *orgImagesPicked = [NSMutableArray array];
        for (NSDictionary *imageInfo in imagesPicked)
        {
            UIImage *originImage = imageInfo[@"originImage"];
            [orgImagesPicked addObject:originImage];
        }
    };
    
    AlbumGroupPicker *groupPicker = [[AlbumGroupPicker alloc] initWithNibName:nil bundle:nil];
    [groupPicker setSltedBlock:^(AlbumImagePicker *picker) {
        [picker setDoneBlock:doneBlock];
    }];
    [groupPicker setCancelBlock:^{
        NSLog(@"Cancle button clicked.");
    }];
    
    AlbumImagePicker *picker = [[AlbumImagePicker alloc] initWithQuery:nil query:nil];
    
    [picker setDoneBlock:doneBlock];
    [picker setCancledBlock:^{
        NSLog(@"Cancle button clicked.");
    }];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:groupPicker];

    [self presentViewController:nav animated:NO completion:^{
        [nav pushViewController:picker animated:YES];
    }];
}

@end
