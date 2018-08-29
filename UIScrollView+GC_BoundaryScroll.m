//
//  UIScrollView+BoundaryScroll.m
//  HQLTextAndPitcureMoveLayoutDemo
//
//  Created by 何启亮 on 2018/8/28.
//  Copyright © 2018年 hql_personal_team. All rights reserved.
//

#import "UIScrollView+GC_BoundaryScroll.h"

#import <objc/runtime.h>

static NSString *const kGCScrollingDirectionKey = @"GCScrollingDirection";

static const void *kScorllSpeed = @"gc_kScorllSpeed";
static const void *kScrollingTriggerEdgeInsets = @"gc_kScrollingTriggerEdgeInsets";
static const void *kDisplayLink = @"gc_kDisplayLink";
static const void *kBoundaryScrollHandle =  @"kBoundaryScrollHandle";

@implementation UIScrollView (GC_BoundaryScroll)

#pragma mark - Publick event

- (void)gc_boundaryScrollWithCurrentPoint:(CGPoint)currentPoint scrollDirection:(NSString *)scrollDirction {
    
    if ([scrollDirction isEqualToString:kGCScrollDirectionVertical]) { // 垂直移动 --- 垂直判断
        
        if (currentPoint.y <= (CGRectGetMinY(self.bounds) + self.gc_scrollingTriggerEdgeInsets.top)) {
            [self gc_setupScrollTimerInDirection:GCScrollingDirectionUp];
        } else {
            
            if (currentPoint.y >= (CGRectGetMaxY(self.bounds) - self.gc_scrollingTriggerEdgeInsets.bottom)) {
                [self gc_setupScrollTimerInDirection:GCScrollingDirectionDown];
            } else {
                [self gc_invalidatesScrollTimer];
            }
            
        }
        
    } else if ([scrollDirction isEqualToString:kGCScrollDirectionHorizontal]) {
        
        if (currentPoint.x <= (CGRectGetMinX(self.bounds) + self.gc_scrollingTriggerEdgeInsets.left)) {
            [self gc_setupScrollTimerInDirection:GCScrollingDirectionLeft];
        } else {
            if (currentPoint.x >= (CGRectGetMaxX(self.bounds) - self.gc_scrollingTriggerEdgeInsets.right)) {
                [self gc_setupScrollTimerInDirection:GCScrollingDirectionRight];
            } else {
                [self gc_invalidatesScrollTimer];
            }   
        }
        
    } else {
        NSAssert(NO, @"%s %d %@", __func__, __LINE__, @"Unsupport scroll dirction");
        [self gc_invalidatesScrollTimer];
    }
}

- (void)gc_setupScrollTimerInDirection:(GCScrollingDirection)scrollingDirection {
    if (!self.gc_displayLink.paused) { // 正在执行中
        GCScrollingDirection oldDirection = [self.gc_displayLink.GC_userInfo[kGCScrollingDirectionKey] integerValue];
        
        if (scrollingDirection == oldDirection) {
            return;
        }
        
    }
    
    [self gc_invalidatesScrollTimer];
    
    self.gc_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(gc_handleScroll:)];
    self.gc_displayLink.GC_userInfo = @{kGCScrollingDirectionKey : @(scrollingDirection)};
    [self.gc_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)gc_handleScroll:(CADisplayLink *)displayLink {
    GCScrollingDirection direction = [displayLink.GC_userInfo[kGCScrollingDirectionKey] integerValue];
    if (direction == GCScrollingDirectionUnknow) {
        [self gc_invalidatesScrollTimer];
        return;
    }
    
    CGSize frameSize = self.bounds.size;
    CGSize contentSize = self.contentSize;
    CGPoint contentOffset = self.contentOffset;
    UIEdgeInsets contentInset = self.contentInset;
    // Important to have an integer `distance` as the `contentOffset` property automatically gets rounded
    // and it would diverge from the view's center resulting in a "cell is slipping away under finger"-bug.
    CGFloat distance = rint(self.gc_scrollingSpeed * displayLink.duration);
    CGPoint translation = CGPointZero;
    
    switch (direction) {
        case GCScrollingDirectionUp: {
            // 因为是向上的移动，所以应该是减少y
            distance = -distance;
            CGFloat minY = 0.0f - contentInset.top;
            if ((contentOffset.y + distance) <= minY) {
                distance = -contentOffset.y - contentInset.top;
            }
            translation = CGPointMake(0.0, distance);
            // 判断是否超出范围
            CGPoint targetContentOffset = GC_CGPointAdd(contentOffset, translation);
            if (targetContentOffset.y <= minY) {
                [self gc_invalidatesScrollTimer];
                return;
            }
        } break;
        case GCScrollingDirectionDown: {
            CGFloat maxY = (contentSize.height + contentInset.bottom) - frameSize.height;
            if ((contentOffset.y + distance) >= maxY) {
                distance = maxY - contentOffset.y;
            }
            // 判断是否超出范围
            CGPoint targetContentOffset = GC_CGPointAdd(contentOffset, translation);
            if (targetContentOffset.y >= maxY) {
                [self gc_invalidatesScrollTimer];
                return;
            }
        } break;
        case GCScrollingDirectionLeft: {
            distance = -distance;
            CGFloat minX = 0.0 - contentInset.left;
            if ((contentOffset.x + distance) <= minX) {
                distance = -contentOffset.x - contentInset.left;
            }
            translation = CGPointMake(distance, 0.0f);
            // 判断是否超出范围
            CGPoint targetContentOffset = GC_CGPointAdd(contentOffset, translation);
            if (targetContentOffset.x <= minX) {
                [self gc_invalidatesScrollTimer];
                return;
            }
        } break;
        case GCScrollingDirectionRight: {
            CGFloat maxX = (contentSize.width + contentInset.right) - frameSize.width;
            if ((contentOffset.x + distance) >= maxX) {
                distance = maxX - contentOffset.x;
            }
            translation = CGPointMake(distance, 0.0);
            // 判断是否超出范围
            CGPoint targetContentOffset = GC_CGPointAdd(contentOffset, translation);
            if (targetContentOffset.x >= maxX) {
                [self gc_invalidatesScrollTimer];
                return;
            }
        } break;
        default: {
            // 返回
            NSAssert(NO, @"%s %d %@", __func__, __LINE__, @"Unsupport direction");
            return;
        } break;
    }
    
    // 回调
    if (self.gc_boundaryScrollHandle) {
        self.gc_boundaryScrollHandle(translation, direction);
    }
    
    // 移动
    self.contentOffset = GC_CGPointAdd(contentOffset, translation);
}

- (void)gc_invalidatesScrollTimer {
    [self.gc_displayLink invalidate];
    self.gc_displayLink = nil;
}

#pragma mark - getter & setter

- (void)setGc_boundaryScrollHandle:(void (^)(CGPoint, GCScrollingDirection))gc_boundaryScrollHandle {
    objc_setAssociatedObject(self, kBoundaryScrollHandle, gc_boundaryScrollHandle, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(CGPoint, GCScrollingDirection))gc_boundaryScrollHandle {
    return objc_getAssociatedObject(self, kBoundaryScrollHandle);
}

- (void)setGc_scrollingTriggerEdgeInsets:(UIEdgeInsets)gc_scrollingTriggerEdgeInsets {
    NSValue *value = [NSValue valueWithUIEdgeInsets:gc_scrollingTriggerEdgeInsets];
    objc_setAssociatedObject(self, kScrollingTriggerEdgeInsets, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)gc_scrollingTriggerEdgeInsets {
    NSValue *value = objc_getAssociatedObject(self, kScrollingTriggerEdgeInsets);
    return [value UIEdgeInsetsValue];
//    return UIEdgeInsetsZero;
}

- (void)setGc_scrollingSpeed:(CGFloat)gc_scrollingSpeed {
    NSNumber *number = [NSNumber numberWithDouble:gc_scrollingSpeed];
    objc_setAssociatedObject(self, kScorllSpeed, number, OBJC_ASSOCIATION_ASSIGN);
}

- (CGFloat)gc_scrollingSpeed {
    NSNumber *number = objc_getAssociatedObject(self, kScorllSpeed);
    return [number doubleValue];
}

- (void)setGc_displayLink:(CADisplayLink *)gc_displayLink {
    objc_setAssociatedObject(self, kDisplayLink, gc_displayLink, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
// 0x1c066f980
- (CADisplayLink *)gc_displayLink {
    return objc_getAssociatedObject(self, kDisplayLink);
}

@end
