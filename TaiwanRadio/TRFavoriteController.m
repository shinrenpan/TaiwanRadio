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
@property (nonatomic, strong) NSArray *dataSource;

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
    
    if(self.navigationController.tabBarItem.badgeValue || !_dataSource.count)
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
    UIBarButtonItem *rightItem =
      [[UIBarButtonItem alloc]initWithTitle:@"Reload"
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
        
        statusLabel.text = @"(ↁ_ↁ)\n\n載入中";
    }
    else if(dataStatus == TRFavoriteDataStatusSucceed)
    {
        // 下載電台成功了, backgroundView 應該為 nil.
        statusLabel = nil;
    }
    else if(dataStatus == TRFavoriteDataStatusEmpty)
    {
        statusLabel.text = @"(ఠ_ఠ)\n\n沒有收藏資料";
    }
    else if(dataStatus == TRFavoriteDataStatusError)
    {
        statusLabel.text = @"(ಥ_ಥ) \n\n錯誤!請檢查網路連線";
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
    BOOL enable       = [radio[@"enable"]boolValue];
    
    UITableViewCell *cell = ^{
        UITableViewCell *aCell          = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
        aCell.imageView.tintColor       = [UIColor whiteColor];
        aCell.accessoryView             = nil;
        aCell.textLabel.text            = radio[@"name"];
        aCell.detailTextLabel.text      = enable ? @"正常" : @"異常";
        aCell.detailTextLabel.textColor = enable ? [UIColor whiteColor] : [UIColor redColor];
        
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

- (void)tableView:(UITableView *)tableView
  commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
  forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return UITableViewRowAction 需要實做這個 method
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TRRadio *radio     = [TRRadio singleton];
    AVObject *selected = _dataSource[indexPath.row];
    NSString *radioId  = selected[@"radioId"];
    BOOL enable        = [selected[@"enable"]boolValue];
    
    if(!enable)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"!!!"
                                                           message:@"該電台異常中."
                                                          delegate:nil
                                                 cancelButtonTitle:@"確定"
                                                 otherButtonTitles:nil];
            
            [alert show];
        });
        
        return;
    }
    
    // 點到目前正在播放的電台
    if([radioId isEqualToString:radio.radioId] && radio.isPlaying)
    {
        [radio pause];
        
        return;
    }
    
    [TRRadio singleton].radioTitle = selected[@"name"];
    [TRRadio singleton].radioId    = radioId;
}

- (NSArray *)tableView:(UITableView *)tableView
  editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSArray *temp               = [userDefault objectForKey:@"favorite"];
    NSMutableArray *favorite    = [NSMutableArray arrayWithArray:temp];

    if(!favorite.count)
    {
        // 基本上不會發生
        return nil;
    }
    
    AVObject *radio   = _dataSource[indexPath.row];
    NSString *radioId = radio[@"radioId"];
    
    UITableViewRowAction *action =
      [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault
                                         title:@"取消收藏"
                                       handler:
       ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
           [favorite removeObject:radioId];
           [[NSUserDefaults standardUserDefaults]setObject:favorite forKey:@"favorite"];
           [[NSUserDefaults standardUserDefaults]synchronize];
           [tableView setEditing:NO animated:YES];
           [self __downloadData:nil];
       }];
    
    return @[action];
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
                _dataSource     = objects;
                self.dataStatus = TRFavoriteDataStatusSucceed;
            }
            else
            {
                self.dataStatus = TRFavoriteDataStatusEmpty;
            }
        });
    }];
}

@end