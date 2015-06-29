// TRSettingController.m
//
// Copyright (c) 2015年 Shinren Pan
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "TRRadio.h"
#import "TRSettingController.h"

#import <iAd/iAd.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

// TableView Section 類型
typedef NS_ENUM(NSUInteger, TableSectionType) {
    TableSectionTypePlayer = 0,     // 播放 / 暫停的 section
    TableSectionTypeAdvertising = 1 // 廣告 section
};


@interface TRSettingController ()<GADInterstitialDelegate>

// admob 插頁式廣告
@property (nonatomic, strong) GADInterstitial *admob;

@end


@implementation TRSettingController

#pragma mark - LifeCycle
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if([self isViewLoaded] && self.view.window == nil)
    {
        // maybe 正在看廣告
        [self dismissViewControllerAnimated:NO completion:nil];
        [[NSNotificationCenter defaultCenter]removeObserver:self];
        
        _admob.delegate = nil;
        _admob          = nil;
        self.view       = nil;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self __setup];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self __shouldReloadTableView:nil];
}

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    if(indexPath.section == TableSectionTypePlayer)
    {
        NSString *title;
        
        switch ([TRRadio singleton].radioStatus)
        {
            case TRRaidoStatusPlaying:
                title = @"播放中...";
                break;
        
            case TRRaidoStatusError:
                title = @"播放失敗";
                break;
                
            case TRRaidoStatusBuffer:
                title = @"緩衝中...";
                break;
                
            case TRRaidoStatusPaused:
                title = @"暫停中";
                break;
                
            default:
                title = @"未選擇電台";
                break;
        }
        
        NSString *sub = [TRRadio singleton].radioTitle ? : @"";
        
        cell.textLabel.text       = title;
        cell.detailTextLabel.text = sub;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView
  willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // Header 文字為白色
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    [header.textLabel setTextColor:[UIColor whiteColor]];
}

- (void)tableView:(UITableView *)tableView
  willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    // Footer 文字為白色
    UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
    
    [footer.textLabel setTextColor:[UIColor whiteColor]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == TableSectionTypePlayer)
    {
        if([TRRadio singleton].isPlaying)
        {
            [[TRRadio singleton]pause];
        }
        else
        {
            [[TRRadio singleton]resume];
        }
    }
    else if(indexPath.section == TableSectionTypeAdvertising)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self __presentAdvertising];
    }
}

#pragma mark - GADInterstitialDelegate
- (void)interstitialDidReceiveAd:(GADInterstitial *)ad
{
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
#pragma mark 初始設置
- (void)__setup
{
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(__shouldReloadTableView:)
                                                name:TRRaidoStatusChangedNotification
                                              object:nil];
    
    // 當從背景回到前景, User 可能在控制面板或是線控播放或暫停
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(__shouldReloadTableView:)
                                                name:UIApplicationDidBecomeActiveNotification
                                              object:nil];
}

#pragma mark 更新 UITableView
- (void)__shouldReloadTableView:(NSNotification *)sender
{
    // 只 Relaod 第一個 Section
    NSIndexSet *section = [NSIndexSet indexSetWithIndex:TableSectionTypePlayer];
    
    [self.tableView reloadSections:section
                  withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark 開啟插頁式廣告
- (void)__presentAdvertising
{
    if(![self requestInterstitialAdPresentation])
    {
        NSString *admobId = @"ca-app-pub-9003896396180654/4023970191";
        _admob            = [[GADInterstitial alloc]initWithAdUnitID:admobId];
        _admob.delegate   = self;
        
        [_admob loadRequest:[GADRequest request]];
    }
}

@end
