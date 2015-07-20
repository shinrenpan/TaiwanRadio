// AppDelegate.m
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
#import "AppDelegate.h"

#import <iAd/iAd.h>
#import <AVOSCloud/AVOSCloud.h>

#error Replace your LeanCloud AppId and ClientKey
static NSString * const LeanCloudId  = @"LeanCloud AppId";
static NSString * const LeanCloudKey = @"LeanCloud ClientKey";


@implementation AppDelegate

#pragma mark - LifeCycle
- (BOOL)application:(UIApplication *)application
  didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [UIViewController prepareInterstitialAds];
    [self __setupRemoteControl];
    [self __setupUIAppearance];
    [AVOSCloud setApplicationId:LeanCloudId clientKey:LeanCliudKey];
    
    return YES;
}

#pragma mark - Private
#pragma 設置 Remote Control
- (void)__setupRemoteControl
{
    MPRemoteCommandCenter *center = [MPRemoteCommandCenter sharedCommandCenter];
    
    // 耳機線控 play / pause
    [center.togglePlayPauseCommand addTargetWithHandler:
     ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
         if([TRRadio singleton].isPlaying)
         {
             [[TRRadio singleton]pause];
         }
         else
         {
             [[TRRadio singleton]resume];
         }
        
         return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    // 控制面板 play
    [center.playCommand addTargetWithHandler:^(MPRemoteCommandEvent *event) {
        [[TRRadio singleton]resume];
        
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    // 控制面板 pause
    [center.pauseCommand addTargetWithHandler:^(MPRemoteCommandEvent *event) {
        [[TRRadio singleton]pause];
        
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    // 控制面板 stop
    [center.stopCommand addTargetWithHandler:^(MPRemoteCommandEvent *event) {
        [[TRRadio singleton]pause];
        
        return MPRemoteCommandHandlerStatusSuccess;
    }];
}

#pragma mark 設置 UIAppearance
- (void)__setupUIAppearance
{
    [[UITabBar appearance]setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance]setTintColor:[UIColor whiteColor]];
}

@end
