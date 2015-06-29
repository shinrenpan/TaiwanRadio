// TRListViewController.m
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
#import "TRListViewController.h"

#import <AVOSCloud/AVOSCloud.h>

// 電台資料載入狀態
typedef NS_ENUM(NSUInteger, TRListDataStatus) {
    TRListDataStatusLoading, // 載入中
    TRListDataStatusSucceed, // 成功
    TRListDataStatusEmpty,   // 成功但是無資料
    TRListDataStatusError    // 錯誤
};


@interface TRListViewController ()

// 電台資料載入狀態
@property (nonatomic, assign) TRListDataStatus dataStatus;

// 電台資料
@property (nonatomic, strong) NSArray *dataSource;

@end


@implementation TRListViewController

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
    
    // 沒有資料就下載資料.
    if(!_dataSource.count)
    {
        [self __downloadData:nil];
    }
    
    // 有資料就 reload tableView, 因為可能在其他地方點了播放或是暫停.
    else
    {
        [self __shouldReloadTableView:nil];
    }
}

#pragma mark - Properties Setter
- (void)setDataStatus:(TRListDataStatus)dataStatus
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
    
    if(dataStatus == TRListDataStatusLoading)
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
    else if(dataStatus == TRListDataStatusSucceed)
    {
        // 下載電台成功了, backgroundView 應該為 nil.
        statusLabel = nil;
    }
    else if(dataStatus == TRListDataStatusEmpty)
    {
        statusLabel.text = @"(ఠ_ఠ)\n\n找不到資料";
    }
    else if(dataStatus == TRListDataStatusError)
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
    
    AVObject *radio   = _dataSource[indexPath.row];
    NSString *radioId = radio[@"radioId"];
    
    UITableViewRowAction *action;
    
    if([favorite containsObject:radioId])
    {
        action =
          [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault
                                             title:@"取消收藏"
                                           handler:
           ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
               [favorite removeObject:radioId];
               [[NSUserDefaults standardUserDefaults]setObject:favorite forKey:@"favorite"];
               [[NSUserDefaults standardUserDefaults]synchronize];
               [tableView setEditing:NO animated:YES];
            
               // 改變收藏列表 badgeValue
               UIViewController *favorite = self.tabBarController.viewControllers[1];
               favorite.tabBarItem.badgeValue = @"-1";
           }];
    }
    else
    {
        action =
          [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                             title:@"加入收藏"
                                           handler:
           ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
               [favorite addObject:radioId];
               [[NSUserDefaults standardUserDefaults]setObject:favorite forKey:@"favorite"];
               [[NSUserDefaults standardUserDefaults]synchronize];
               [tableView setEditing:NO animated:YES];

               // 改變收藏列表 badgeValue
               UIViewController *favorite = self.tabBarController.viewControllers[1];
               favorite.tabBarItem.badgeValue = @"+1";
            }];
        
        action.backgroundColor = [UIColor blueColor];
    }
    
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
- (void)__shouldReloadTableView:(id)sender
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

    self.dataStatus = TRListDataStatusLoading;
    AVQuery *query  = [AVQuery queryWithClassName:@"Radio"];
    query.limit     = 1000;
    
    [query orderByAscending:@"name"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(error)
            {
                self.dataStatus = TRListDataStatusError;
            }
            else if(objects.count)
            {
                _dataSource     = objects;
                self.dataStatus = TRListDataStatusSucceed;
            }
            else
            {
                self.dataStatus = TRListDataStatusEmpty;
            }
        });
    }];
}

@end
