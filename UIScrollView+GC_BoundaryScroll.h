//
//  UIScrollView+BoundaryScroll.h
//  HQLTextAndPitcureMoveLayoutDemo
//
//  Created by 何启亮 on 2018/8/28.
//  Copyright © 2018年 hql_personal_team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CADisplayLink+GC_userInfo.h"

CG_INLINE CGPoint GC_CGPointAdd(CGPoint point1, CGPoint point2) {
    return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}

CG_INLINE CGPoint GC_CGPointSubtract(CGPoint point1, CGPoint point2) {
    return CGPointMake(point1.x - point2.x, point1.y - point2.y);
}

typedef NS_ENUM(NSInteger, GCScrollingDirection) {
    GCScrollingDirectionUnknow = 0,
    GCScrollingDirectionUp,
    GCScrollingDirectionDown,
    GCScrollingDirectionLeft,
    GCScrollingDirectionRight,
};

static NSString * const kGCScrollDirectionHorizontal = @"kGCScrollDirectionHorizontal";
static NSString * const kGCScrollDirectionVertical = @"kGCScrollDirectionVertical";

/**
 到边界的时候滚动
 */
@interface UIScrollView (GC_BoundaryScroll)

/**
 滚动速度
 */
@property (nonatomic, assign) CGFloat gc_scrollingSpeed;

/**
 触发滚动的范围
 */
@property (nonatomic, assign) UIEdgeInsets gc_scrollingTriggerEdgeInsets;

@property (strong, nonatomic) CADisplayLink *gc_displayLink;

/**
 在边界移动时的回调
 */
@property (nonatomic, copy) void(^gc_boundaryScrollHandle)(CGPoint scrollDistancePoint, GCScrollingDirection scrollingDirection);

/**
 根据currentPoint来判定是否需要滚动
 
 * scrollDirction ---> GCScrollDirectionHorizontal/GCScrollDirectionVertical
 
 */
- (void)gc_boundaryScrollWithCurrentPoint:(CGPoint)currentPoint scrollDirection:(NSString *)scrollDirction;

/**
 取消displayLink
 */
- (void)gc_invalidatesScrollTimer;

/**
 设置滚动的displayLink
 */
- (void)gc_setupScrollTimerInDirection:(GCScrollingDirection)scrollingDirection;

/**
 displayLink的滚动处理方法
 */
- (void)gc_handleScroll:(CADisplayLink *)displayLink;

@end
