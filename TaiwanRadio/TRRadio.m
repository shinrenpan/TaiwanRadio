//
//  TRRadio.m
//  TaiwanRadio
//
//  Created by Shinren Pan on 2015/4/24.
//  Copyright (c) 2015年 Shinren Pan. All rights reserved.
//

#import "TRRadio.h"

#import <AVOSCloud/AVOSCloud.h>
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCallCenter.h>

// 電台狀態改變 Notification
NSString * const TRRaidoStatusChangedNotification = @"radio_status_changed";


@interface TRRadio ()

// 電話 handle
@property (nonatomic, strong) CTCallCenter *callCenter;

// 是否來電
@property (nonatomic, assign) BOOL callComing;

// 電台狀態
@property (nonatomic, assign) TRRaidoStatus radioStatus;

// 是否使用 CloudCode
@property (nonatomic, readonly) BOOL useCloudCode;

@end


@implementation TRRadio

#pragma mark - LifeCycle
+ (instancetype)singleton
{
    static dispatch_once_t onceToken;
    static TRRadio *_radio;
    
    dispatch_once(&onceToken, ^{
        _radio = [[TRRadio alloc]init];
    });
    
    return _radio;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self removeObserver:self forKeyPath:@"currentItem.status"];
}

- (instancetype)init
{
    self = [super init];
    
    if(self)
    {
        [self __setup];
    }
    
    return self;
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    switch (self.currentItem.status)
    {
        case AVPlayerItemStatusReadyToPlay:
        {
            if(self.radioStatus == TRRaidoStatusPaused)
            {
                // 當在前景暫停電台後, 退到背景, 再從背景回到前景, 會自動播放.
                // 解決自動播放問題, 讓 User 手動再點播放, 不然會跟 hichannel 不同步.
                break;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self play];
            });
        }
            break;
            
        case AVPlayerItemStatusFailed:
            self.radioStatus = TRRaidoStatusError;
            break;
            
        default:
            break;
    }
}

#pragma mark - Properties Getter
- (BOOL)useCloudCode
{
    return [[AVAnalytics getConfigParams:@"cloudCode"]boolValue];
}

- (BOOL)isPlaying
{
    return self.rate > 0.0;
}

- (UIColor *)statusColor
{
    UIColor *color;
    
    switch (_radioStatus)
    {
        case TRRaidoStatusPlaying:
            color = [UIColor greenColor];
            break;
        
        case TRRaidoStatusPaused:
            color = [UIColor yellowColor];
            break;
            
        case TRRaidoStatusError:
            color = [UIColor redColor];
            break;
            
        default:
            color = [UIColor whiteColor];
            break;
    }
    
    return color;
}

#pragma mark - Properties Setter
- (void)setRadioTitle:(NSString *)radioTitle
{
    _radioTitle = radioTitle;
    
    MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
    
    NSDictionary *info;
    
    if(_radioTitle.length)
    {
        info = @{MPMediaItemPropertyTitle : radioTitle,
                 MPMediaItemPropertyAlbumTitle : @"TaiwanRadio"};
    }
    
    center.nowPlayingInfo = info;
}

- (void)setRate:(float)rate
{
    [super setRate:rate];
    
    if(rate > 0.0)
    {
        self.radioStatus = TRRaidoStatusPlaying;
    }
    else
    {
        self.radioStatus = TRRaidoStatusPaused;
    }
}

- (void)setRadioStatus:(TRRaidoStatus)radioStatus
{
    _radioStatus = radioStatus;
    
    if([UIApplication sharedApplication].applicationState != UIApplicationStateActive)
    {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        
        [center postNotificationName:TRRaidoStatusChangedNotification
                              object:@(_radioStatus)];
    });
}

- (void)setRadioId:(NSString *)radioId
{
    [self pause];
    
    _radioId = radioId;
    
    self.radioStatus = TRRaidoStatusBuffer;
    
    if(self.useCloudCode)
    {
        [self __playRadioWithCloudCode];
    }
    else
    {
        [self __playRadioWithHichannelAPI];
    }
}

#pragma mark - Public
#pragma mark 繼續播放
- (void)resume
{
    if(_radioId)
    {
        self.radioId = _radioId;
    }
}

#pragma mark - Private
#pragma mark 初始設置
- (void)__setup
{
    [self __setupCallCenter];
    
    AVAudioSession *session      = [AVAudioSession sharedInstance];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [session setActive:YES error:nil];
    
    [center addObserver:self
               selector:@selector(__audioSessionInterruptionNotification:)
                   name:AVAudioSessionInterruptionNotification
                 object:nil];
    
    [self addObserver:self
           forKeyPath:@"currentItem.status"
              options:NSKeyValueObservingOptionNew
              context:nil];
    

}

#pragma mark 設置來電 Handel
- (void)__setupCallCenter
{
    _callComing = NO;
    _callCenter = [[CTCallCenter alloc]init];
    
    __weak typeof(self) weakSelf = self;
    
    _callCenter.callEventHandler = ^(CTCall* call) {
        if([call.callState isEqualToString:CTCallStateIncoming])
        {
            // 當電話進來, 且正在播放才設為 YES
            weakSelf.callComing = weakSelf.radioStatus == TRRaidoStatusPlaying;
        }
    };
}

#pragma mark 播放中斷 Nofification
- (void)__audioSessionInterruptionNotification:(NSNotification *)sender
{
    NSDictionary *info = sender.userInfo;
    NSNumber *flag     = info[AVAudioSessionInterruptionTypeKey];
    
    if([flag unsignedIntegerValue] == AVAudioSessionInterruptionTypeBegan)
    {
        [self pause];
    }
    else if([flag unsignedIntegerValue] == AVAudioSessionInterruptionTypeEnded)
    {
        // 如果是電話造成播放中斷, 就重新播放
        // 其他問題造成的中斷, 讓 User 自己去點擊播放
        if(_callComing)
        {
            _callComing = NO;
            
            [self resume];
        }
    }
}

#pragma mark 使用 CloudCode 播放
- (void)__playRadioWithCloudCode
{
    // 使用 cloudCode 會比較慢一點
    NSURLComponents *component = ^{
        NSString *URL        = @"http://hichannel.hinet.net";
        NSString *path       = @"/radio/index.do";
        NSString *query      = [NSString stringWithFormat:@"id=%@", _radioId];
        NSURLComponents *com = [NSURLComponents componentsWithString:URL];
        com.path             = path;
        com.query            = query;
        
        return com;
    }();
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:component.URL];
    request.timeoutInterval      = 30.0;
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:
     ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
         if(connectionError || !data.length)
         {
            self.radioStatus = TRRaidoStatusError;
         }
         else
         {
            NSDictionary *params = @{@"url" : component.URL.absoluteString,
                                     @"data" : data};
    
            [AVCloud callFunctionInBackground:@"radioURL"
                               withParameters:params
                                        block:
             ^(id object, NSError *error) {
                 if(error)
                 {
                    self.radioStatus = TRRaidoStatusError;
                 }
                 else
                 {
                     [self __replacePlayItemWithURL:object];
                 }
             }];
         }
     }];
}

#pragma mark 使用 hichannel api 播放
- (void)__playRadioWithHichannelAPI
{
    NSURLComponents *component = ^{
        NSString *URL        = @"http://hichannel.hinet.net";
        NSString *path       = @"/radio/schannel.do";
        NSString *query      = [NSString stringWithFormat:@"id=%@", _radioId];
        NSURLComponents *com = [NSURLComponents componentsWithString:URL];
        com.path             = path;
        com.query            = query;
        
        return com;
    }();

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:component.URL];
    request.timeoutInterval      = 30.0;
    
    // hichannel API 需要設 Referer
    [request setValue:component.URL.absoluteString forHTTPHeaderField:@"Referer"];
    
    // 新 API 需要 XuiteAuth
    [request setValue:@"xUite9602@hIchaNnel" forHTTPHeaderField:@"XuiteAuth"];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:
     ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
         if(connectionError)
         {
             self.radioStatus = TRRaidoStatusError;
         }
         else
         {
             id JSON = [NSJSONSerialization JSONObjectWithData:data
                                                       options:NSJSONReadingAllowFragments
                                                         error:&connectionError];
            
             if(![JSON isKindOfClass:[NSDictionary class]])
             {
                 self.radioStatus = TRRaidoStatusError;
                 
                 return ;
             }
             if(!JSON[@"playRadio"])
             {
                 self.radioStatus = TRRaidoStatusError;
                 
                 return;
             }
            
             [self __replacePlayItemWithURL:JSON[@"playRadio"]];
         }
     }];
}

#pragma mark 替換電台
- (void)__replacePlayItemWithURL:(NSString *)radioURL
{
    NSURL *URL         = [NSURL URLWithString:radioURL];
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:URL];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self replaceCurrentItemWithPlayerItem:item];
    });
}

@end
