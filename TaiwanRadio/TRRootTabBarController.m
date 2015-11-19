// TRRootTabBarController.m
// 
// Created By Shinren Pan <shinnren.pan@gmail.com> on 2015/11/19.
// Copyright (c) 2015年 Shinren Pan. All rights reserved.

#import "TRRootTabBarController.h"
#import <iAd/iAd.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface TRRootTabBarController ()<UITabBarControllerDelegate, GADInterstitialDelegate>

// 廣告是否已經呈現過
@property (nonatomic, assign) BOOL advertisingPresented;

// admob 插頁式廣告
@property (nonatomic, strong) GADInterstitial *admob;

@end


@implementation TRRootTabBarController

#pragma mark - LifeCycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self __presentAdvertising];
}

#pragma mark - UITabBarControllerDelegate
- (void)tabBarController:(UITabBarController *)tabBarController
 didSelectViewController:(UIViewController *)viewController
{
    [self __presentAdvertising];
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController
shouldSelectViewController:(UIViewController *)viewController
{
    if(self.selectedViewController == viewController)
    {
        // 如果在相同的 Tab 裡, 再點一次 Tab 將會捲動到 Top
        
        UINavigationController *navigationController = self.selectedViewController;
        
        if([navigationController.topViewController isKindOfClass:[UITableViewController class]])
        {
            UITableViewController *tableViewController =
            (UITableViewController *)navigationController.topViewController;
            
            NSIndexPath *top = [NSIndexPath indexPathForRow:0 inSection:0];
            
            [tableViewController.tableView scrollToRowAtIndexPath:top
                                                 atScrollPosition:UITableViewScrollPositionNone
                                                         animated:YES];
        }

        return NO;
    }
    
    return YES;
}

#pragma mark - GADInterstitialDelegate
- (void)interstitialDidReceiveAd:(GADInterstitial *)ad
{
    _advertisingPresented = YES;
    
    [[UIApplication sharedApplication]setStatusBarHidden:YES];
    [ad presentFromRootViewController:self];
}

- (void)interstitial:(GADInterstitial *)ad didFailToReceiveAdWithError:(GADRequestError *)error
{
    [[UIApplication sharedApplication]setStatusBarHidden:NO];
    
    _admob.delegate = nil;
    _admob          = nil;
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)ad
{
    [[UIApplication sharedApplication]setStatusBarHidden:NO];
    
    _admob.delegate = nil;
    _admob          = nil;
}

- (void)interstitialWillLeaveApplication:(GADInterstitial *)ad
{
    [[UIApplication sharedApplication]setStatusBarHidden:NO];
    
    _admob.delegate = nil;
    _admob          = nil;
}

#pragma mark - Private
- (void)__presentAdvertising
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    
    // User 取消展示廣告 -> return
    
    if([userDefault boolForKey:@"advertisingDisable"]) { return; }
    
    // 廣告已經展示過一次 -> return
    if(_advertisingPresented) { return; }
    
    // Show iAd 失敗 -> show Admob
    if(![self requestInterstitialAdPresentation])
    {
        NSString *admobId = @"ca-app-pub-9003896396180654/4023970191";
        _admob            = [[GADInterstitial alloc]initWithAdUnitID:admobId];
        _admob.delegate   = self;

        GADRequest *request = [GADRequest request];
        request.testDevices = @[ kGADSimulatorID ];
        
        [_admob loadRequest:request];
    }
    else
    {
        _advertisingPresented = YES;
        _admob.delegate = nil;
        _admob = nil;
    }
}

@end
