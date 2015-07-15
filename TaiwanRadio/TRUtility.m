// TRUtility.m
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

#import "TRUtility.h"

@implementation TRUtility

#pragma mark - Class methods
#pragma mark 收藏一個電台
+ (void)addRadioIdToFavorites:(NSString *)radioId
{
    NSMutableArray *favorite = [self favorites];
    
    if([favorite containsObject:radioId])
    {
        return;
    }
    
    [favorite addObject:radioId];
    [[NSUserDefaults standardUserDefaults]setObject:favorite forKey:@"favorite"];
    [[NSUserDefaults standardUserDefaults]synchronize];
}

#pragma mark 移除一個電台
+ (void)removeRadioIdFromFavorites:(NSString *)radioId
{
    NSMutableArray *favorite = [self favorites];
    
    if(![favorite containsObject:radioId])
    {
        return;
    }
    
    [favorite removeObject:radioId];
    [[NSUserDefaults standardUserDefaults]setObject:favorite forKey:@"favorite"];
    [[NSUserDefaults standardUserDefaults]synchronize];
}

#pragma mark 返回電台是否已加入收藏
+ (BOOL)radioIdInFavorites:(NSString *)radioId
{
    return [[self favorites]containsObject:radioId];
}

#pragma mark 返回收藏列表
+ (NSMutableArray *)favorites
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSArray *temp               = [userDefault objectForKey:@"favorite"];
    NSMutableArray *favorite    = [NSMutableArray arrayWithArray:temp];
    
    if(!favorite)
    {
        favorite = [NSMutableArray array];
    }
    
    return favorite;
}

@end
