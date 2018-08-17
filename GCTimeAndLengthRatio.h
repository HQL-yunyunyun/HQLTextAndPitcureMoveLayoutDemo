//
//  GCTimeAndLengthRatio.h
//  GoCreate
//
//  Created by 何启亮 on 2018/8/14.
//  Copyright © 2018年 BiWan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreMedia/CoreMedia.h>

/**
 记录时间轴显示时间的 时间 和 长度的比例
 例: 1秒的长度为100px
 */

@interface GCTimeAndLengthRatio : NSObject

/**
 时间长度
 */
@property (nonatomic, assign, readonly) CMTime timeDuration;

/**
 每一个时间长度代表的length --- 一旦生成了就不能改变
 */
@property (nonatomic, assign, readonly) double lengthPerTimeDuration;

- (instancetype)initWithTimeDuration:(CMTime)timeDuration lengthPerTimeDuration:(double)lengthPerTimeDuration;

/**
 更新 timeDuration属性
 */
- (void)updateTimeDuration:(CMTime)duration;

/**
 根据time来计算length
 */
- (double)calculateLengthWithTime:(CMTime)time;

/**
 根据length来计算time
 */
- (CMTime)calculateTimeWithLength:(double)length;

@end
