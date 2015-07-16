// TRFavoriteController.m
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
#import "TRUtility.h"
#import "TRFavoriteController.h"

#import <AVOSCloud/AVOSCloud.h>

// 電台資料載入狀態
typedef NS_ENUM(NSUInteger, TRFavoriteDataStatus) {
    TRFavoriteDataStatusLoading, // 載入中
    TRFavoriteDataStatusSucceed, // 成功
    TRFavoriteDataStatusEmpty,   // 成功但是無資料
    TRFavoriteDataStatusError    // 錯誤
};


@interface TRFavoriteController ()

// 電台資料載入狀態
@property (nonatomic, assign) TRFavoriteDataStatus dataStatus;

// 電台資料
@property (nonatomic, strong) NSMutableArray *dataSource;

@end


@implementation TRFavoriteController

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
        _dataSource = nil;
        self.view   = nil;
        
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
    
    if(self.navigationController.tabBarItem.badgeValue || !_dataSource)
    {
        self.navigationController.tabBarItem.badgeValue = nil;
        
        [self __downloadData:nil];
    }
    else
    {
        [self __shouldReloadTableView:nil];
    }
}

#pragma mark - Properties Setter
- (void)setDataStatus:(TRFavoriteDataStatus)dataStatus
{
    NSString *title = NSLocalizedString(@"Reload", nil);
    
    UIBarButtonItem *rightItem =
      [[UIBarButtonItem alloc]initWithTitle:title
                                      style:UIBarButtonItemStyleDone
                                     target:self
                                     action:@selector(__downloadData:)];
    
    UILabel *statusLabel = ^{
        UILabel *label      = [[UILabel alloc]init];
        label.textColor     = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font          = [UIFont boldSystemFontOfSize:22.0];
        label.numberOfLines = 0;
        
        return label;
    }();
    
    if(dataStatus == TRFavoriteDataStatusLoading)
    {
        rightItem.customView = ^{
            UIActivityIndicatorView *view =
              [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:
               UIActivityIndicatorViewStyleWhite];
            
            [view startAnimating];
            
            return view;
        }();
        
        statusLabel.text = NSLocalizedString(@"Data-Loading", nil);
    }
    else if(dataStatus == TRFavoriteDataStatusSucceed)
    {
        // 下載電台成功了, backgroundView 應該為 nil.
        statusLabel = nil;
    }
    else if(dataStatus == TRFavoriteDataStatusEmpty)
    {
        statusLabel.text = NSLocalizedString(@"Data-Empty", nil);
    }
    else if(dataStatus == TRFavoriteDataStatusError)
    {
        statusLabel.text = NSLocalizedString(@"Data-Error", nil);
    }
    
    self.navigationItem.rightBarButtonItem = rightItem;
    self.tableView.backgroundView          = statusLabel;
    
    [self __shouldReloadTableView:nil];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AVObject *radio   = _dataSource[indexPath.row];
    NSString *radioId = radio[@"radioId"];
    
    UITableViewCell *cell = ^{
        UITableViewCell *aCell    = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
        aCell.imageView.tintColor = [UIColor whiteColor];
        aCell.textLabel.text      = radio[@"name"];
        aCell.accessoryView       = [self __favoriteButtonWithHighlight:YES atRow:indexPath.row];
        
        return aCell;
    }();
    
    if([radioId isEqualToString:[TRRadio singleton].radioId])
    {
        cell.imageView.tintColor = [TRRadio singleton].statusColor;
        
        if([TRRadio singleton].radioStatus == TRRaidoStatusBuffer)
        {
            UIActivityIndicatorView *loading =
              [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:
               UIActivityIndicatorViewStyleWhite];
            
            [loading startAnimating];
            
            cell.accessoryView = loading;
        }
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TRRadio *radio     = [TRRadio singleton];
    AVObject *selected = _dataSource[indexPath.row];
    NSString *radioId  = selected[@"radioId"];
    
    // 點到目前正在播放的電台
    if([radioId isEqualToString:radio.radioId] && radio.isPlaying)
    {
        [radio pause];
        
        return;
    }
    
    [TRRadio singleton].radioTitle = selected[@"name"];
    [TRRadio singleton].radioId    = radioId;
}

#pragma mark - Private
#pragma mark 初始設置
- (void)__setup
{
    self.tableView.tableFooterView = [[UIView alloc]init];
    
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
    if(!_dataSource.count)
    {
        return;
    }
    
    [self.tableView reloadData];
}

#pragma mark 下載電台資料
- (void)__downloadData:(UIBarButtonItem *)sender
{
    _dataSource = nil;
    
    [self.tableView reloadData];
 
    NSArray *favorite = [[NSUserDefaults standardUserDefaults]objectForKey:@"favorite"];
    
    if(!favorite.count)
    {
        self.dataStatus = TRFavoriteDataStatusEmpty;
        
        return;
    }

    self.dataStatus   = TRFavoriteDataStatusLoading;
    AVQuery *query    = [AVQuery queryWithClassName:@"Radio"];
    query.limit       = 1000;
    query.cachePolicy = kAVCachePolicyCacheElseNetwork;
    
    [query orderByAscending:@"name"];
    [query whereKey:@"radioId" containedIn:favorite];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(error)
            {
                self.dataStatus = TRFavoriteDataStatusError;
            }
            else if(objects.count)
            {
                _dataSource     = [NSMutableArray arrayWithArray:objects];
                self.dataStatus = TRFavoriteDataStatusSucceed;
            }
            else
            {
                self.dataStatus = TRFavoriteDataStatusEmpty;
            }
        });
    }];
}

#pragma mark 返回收藏按鈕
- (UIButton *)__favoriteButtonWithHighlight:(BOOL)flag atRow:(NSUInteger)row
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.tag       = row;
    button.frame     = CGRectMake(0, 0, 30, 30);
    button.tintColor = flag ? [UIColor magentaColor] : [UIColor whiteColor];
    
    [button setImage:[UIImage imageNamed:@"icon-tab2"] forState:UIControlStateNormal];
    
    [button addTarget:self
               action:@selector(__favoriteButtonClicked:)
     forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

#pragma mark 收藏按鈕 action
- (void)__favoriteButtonClicked:(UIButton *)button
{
    NSUInteger row             = button.tag;
    AVObject *radio            = _dataSource[row];
    NSString *radioId          = radio[@"radioId"];
    
    [TRUtility removeRadioIdFromFavorites:radioId];
    [_dataSource removeObjectAtIndex:row];
    [self.tableView reloadData];
    
    if(!_dataSource.count)
    {
        self.dataStatus = TRFavoriteDataStatusEmpty;
    }
}

@end