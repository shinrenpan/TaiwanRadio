//
//  TRRadio.h
//  TaiwanRadio
//
//  Created by Shinren Pan on 2015/4/24.
//  Copyright (c) 2015年 Shinren Pan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

// 電台狀態改變 Notification
extern NSString * const TRRaidoStatusChangedNotification;

// 電台狀態
typedef NS_ENUM(NSUInteger, TRRaidoStatus){
    TRRaidoStatusNormal = 0, // 開始狀態
    TRRaidoStatusBuffer,     // 緩衝
    TRRaidoStatusPlaying,    // 正在播放
    TRRaidoStatusPaused,     // 暫停
    TRRaidoStatusError       // 錯誤
};


/**
 *  Radio Player
 */
@interface TRRadio : AVPlayer


///-----------------------------------------------------------------------------
/// @name Properties
///-----------------------------------------------------------------------------

/**
 *  目前電台名稱
 */
@property (nonatomic, copy) NSString *radioTitle;

/**
 *  目前電台 Id
 */
@property (nonatomic, copy) NSString *radioId;

/**
 *  目前電台狀態
 */
@property (nonatomic, readonly) TRRaidoStatus radioStatus;

/**
 *  是否正在播放
 */
@property (nonatomic, readonly) BOOL isPlaying;

/**
 *  電台狀態顏色
 */
@property (nonatomic, readonly) UIColor *statusColor;


///-----------------------------------------------------------------------------
/// @name Class methods
///-----------------------------------------------------------------------------

/**
 *  返回 singleton 物件
 *
 *  @return 返回 singleton 物件
 */
+ (instancetype)singleton;


///-----------------------------------------------------------------------------
/// @name Public methods
///-----------------------------------------------------------------------------

/**
 *  繼續播放
 */
- (void)resume;

@end
