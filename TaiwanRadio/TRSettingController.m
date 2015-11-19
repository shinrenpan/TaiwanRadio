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

// TableView Section 類型
typedef NS_ENUM(NSUInteger, TableSectionType) {
    TableSectionTypePlayer = 0,     // 播放 / 暫停的 section
    TableSectionTypeAdvertising = 1 // 廣告 section
};


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
        [[NSNotificationCenter defaultCenter]removeObserver:self];
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
                title = NSLocalizedString(@"Radio-Playing", nil);
                break;
        
            case TRRaidoStatusError:
                title = NSLocalizedString(@"Radio-Error", nil);
                break;
                
            case TRRaidoStatusBuffer:
                title = NSLocalizedString(@"Radio-Buffering", nil);
                break;
                
            case TRRaidoStatusPaused:
                title = NSLocalizedString(@"Radio-Paused", nil);
                break;
                
            default:
                title = NSLocalizedString(@"Radio-Unselected", nil);
                break;
        }
        
        NSString *sub = [TRRadio singleton].radioTitle ? : @"";
        
        cell.textLabel.text       = title;
        cell.detailTextLabel.text = sub;
    }
    
    else if(indexPath.section == TableSectionTypeAdvertising)
    {
        cell.accessoryView = [self __switchForAdvertisingDisable];
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

#pragma mark 返回展示廣告的 UISwitch
- (UISwitch *)__switchForAdvertisingDisable
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    BOOL advertisingDisable     = [userDefault boolForKey:@"advertisingDisable"];
    
    UISwitch *result = [[UISwitch alloc]init];
    result.on = !advertisingDisable;
    
    [result addTarget:self action:@selector(__switchValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    return result;
}

#pragma mark UISwitch on / off handle
- (void)__switchValueChanged:(UISwitch *)sender
{
    BOOL advertisingDisable = !sender.on;
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    
    [userDefault setBool:advertisingDisable forKey:@"advertisingDisable"];
    [userDefault synchronize];
}

@end
