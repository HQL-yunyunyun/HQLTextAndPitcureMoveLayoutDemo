//
//  GCTextAndPitcureMoveLayout.m
//  HQLTextAndPitcureMoveLayoutDemo
//
//  Created by 何启亮 on 2018/8/14.
//  Copyright © 2018年 hql_personal_team. All rights reserved.
//

#import "GCTextAndPictureMoveLayout.h"
#import "GCTimeAndLengthRatio.h"
#import <objc/runtime.h>

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

static NSString *const kGCScrollingDirectionKey = @"GCScrollingDirection";
static NSString *const kGCCollectionViewKeyPath = @"collectionView";

static CGFloat kAnimationDuration = 0.3f;

@interface CADisplayLink (GC_userInfo)
@property (nonatomic, copy) NSDictionary *GC_userInfo;
@end

@implementation CADisplayLink (GC_userInfo)

- (void)setGC_userInfo:(NSDictionary *)GC_userInfo {
    objc_setAssociatedObject(self, "GC_userInfo", GC_userInfo, OBJC_ASSOCIATION_COPY);
}

- (NSDictionary *)GC_userInfo {
    return objc_getAssociatedObject(self, "GC_userInfo");
}

@end

@interface UICollectionViewCell (GCTextAndPictureMoveLayout)

/**
 将cell截图
 */
- (UIView *)GC_snapshotView;

/**
 cell截图 --- 去掉两边的button
 */
- (UIView *)GC_snapshotViewOnlyValueWithClipWidth:(CGFloat)width;

@end

@implementation UICollectionViewCell (GCTextAndPictureMoveLayout)

- (UIView *)GC_snapshotView {
    if ([self respondsToSelector:@selector(snapshotViewAfterScreenUpdates:)]) {
        return [self snapshotViewAfterScreenUpdates:YES];
    }
    
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0f);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [[UIImageView alloc] initWithImage:image];
}

- (UIView *)GC_snapshotViewOnlyValueWithClipWidth:(CGFloat)width {
    if ([self respondsToSelector:@selector(resizableSnapshotViewFromRect:afterScreenUpdates:withCapInsets:)]) {
        return [self resizableSnapshotViewFromRect:CGRectMake(width, 0, self.bounds.size.width - 2 * width, self.bounds.size.height) afterScreenUpdates:YES withCapInsets:UIEdgeInsetsZero];
    }
    
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0f);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRef sourceImage = [image CGImage];
    CGImageRef newImage = CGImageCreateWithImageInRect(sourceImage, CGRectMake(width, 0, self.bounds.size.width - 2 * width, self.bounds.size.height));
    UIImage *new = [[UIImage alloc] initWithCGImage:newImage];
    
    CGImageRelease(sourceImage);
    CGImageRelease(newImage);
    
    return [[UIImageView alloc] initWithImage:new];
}

@end

@interface GCTextAndPictureMoveLayout ()

/**
 总时长
 */
@property (nonatomic, assign) CMTimeRange timeLineRange;

@property (strong, nonatomic) NSIndexPath *selectedItemIndexPath;
@property (strong, nonatomic) UIView *currentView;

/**
 记录原本的fakeView的center
 */
@property (assign, nonatomic) CGPoint currentViewCenter;
@property (strong, nonatomic) CADisplayLink *displayLink;

@property (assign, nonatomic) CGPoint panMoveInCollectionView;
@property (nonatomic, assign) CGPoint panLastLocationInCollectionView;

@property (nonatomic, weak, readonly) id<GCTextAndPictureMoveLayoutDataSource> dataSource;
@property (nonatomic, weak, readonly) id<GCTextAndPictureMoveLayoutDelegate> delegate;

/**
 单个Item的高 --- 算上Item本身的height和上下两个margin
 */
@property (nonatomic, assign, readonly) CGFloat itemTotalHeight;

@end

@implementation GCTextAndPictureMoveLayout {
    double _timeLineLength; // 总长度
    CMTime _timeLineDuration; // 总时长
    GCTimeAndLengthRatio *_timeLengthRatio; // 换算
    CGFloat _itemHeight; // cell的高度
    CGFloat _itemMargin; // cell之间的margin
    CGFloat _itemSupernumeraryButtonWidth; // cell两侧额外的button的宽度
    
    NSMutableArray *_insertArray;
    NSMutableArray *_deleteArray;
}

#pragma mark - initialize method

- (instancetype)init {
    if (self = [super init]) {
        [self configLayout];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self configLayout];
    }
    return self;
}

- (void)configLayout {
    [self setDefaults];
    [self addObserver:self forKeyPath:kGCCollectionViewKeyPath options:NSKeyValueObservingOptionNew context:nil];
}

- (void)dealloc {
    
    [self invalidatesScrollTimer];
    [self tearDownCollectionView];
    [self removeObserver:self forKeyPath:kGCCollectionViewKeyPath context:nil];
    
    NSLog(@"dealloc ---> %@", NSStringFromClass([self class]));
}

#pragma mark - private method

- (void)setupScrollTimerInDirection:(GCScrollingDirection)scrollingDirection {
    if (!self.displayLink.paused) {
        GCScrollingDirection oldDirection = [self.displayLink.GC_userInfo[kGCScrollingDirectionKey] integerValue];
        
        if (scrollingDirection == oldDirection) {
            return;
        }
    }
    
    [self invalidatesScrollTimer];
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleScroll:)];
    self.displayLink.GC_userInfo = @{kGCScrollingDirectionKey : @(scrollingDirection)};
    
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)setDefaults {
    _scrollingSpeed = 100.0f;
    _scrollingTriggerEdgeInsets = UIEdgeInsetsMake(50.0, 50.0, 50.0, 50.0);
}

- (void)setupCollectionView {
    // 设置手势
    // 长按手势
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    _longPressGestureRecognizer.delegate = self;
    // 将collectionView的长按手势让步_longPressGestureRecognizer
    for (UIGestureRecognizer *gesture in self.collectionView.gestureRecognizers) {
        if ([gesture isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [gesture requireGestureRecognizerToFail:_longPressGestureRecognizer];
        }
    }
    [self.collectionView addGestureRecognizer:_longPressGestureRecognizer];
    
    // pan手势
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    _panGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:_panGestureRecognizer];
    
    // Useful in multiple scenarios: one common scenario being when the Notification Center drawer is pulled down
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillResignActive:) name: UIApplicationWillResignActiveNotification object:nil];
}

- (void)tearDownCollectionView {
    // Tear down long press gesture
    if (_longPressGestureRecognizer) {
        UIView *view = _longPressGestureRecognizer.view;
        if (view) {
            [view removeGestureRecognizer:_longPressGestureRecognizer];
        }
        _longPressGestureRecognizer.delegate = nil;
        _longPressGestureRecognizer = nil;
    }
    
    // Tear down pan gesture
    if (_panGestureRecognizer) {
        UIView *view = _panGestureRecognizer.view;
        if (view) {
            [view removeGestureRecognizer:_panGestureRecognizer];
        }
        _panGestureRecognizer.delegate = nil;
        _panGestureRecognizer = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

/**
 设置layoutAttributes --- 如果是选中的attributes ---> 隐藏
 */
- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    if (layoutAttributes.representedElementCategory == UICollectionElementCategoryCell &&
        [layoutAttributes.indexPath isEqual:self.selectedItemIndexPath]) {
        layoutAttributes.alpha = 0.0;
    }
}

/**
 取消定时器
 */
- (void)invalidatesScrollTimer {
    if (!self.displayLink.paused) {
        [self.displayLink invalidate];
    }
    self.displayLink = nil;
}

/**
 处理view 的移动
 */
- (void)invalidateLayoutIfNecessaryWithMovePoint:(CGPoint)point {
    
    CGPoint movePoint = GC_CGPointAdd(self.currentViewCenter, point);
    
    // 不能同时移动行和移动x --- 只有在确定行不能移动的情况下可以移动x
    __weak typeof(self) _self = self;
    [self invalidateLineMoveIfNecessaryWithMovePoint:movePoint afterCannotMoveHandle:^{
        [_self invalidateItemStartTimeIfNecessaryWithMovePoint:movePoint];
    }];
    
    self.currentViewCenter = movePoint;
}

/**
 移动Item的x
 */
- (void)invalidateItemStartTimeIfNecessaryWithMovePoint:(CGPoint)movePoint {
    
    BOOL canTimeMove = NO;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(collectionView:layout:canTimeMoveItemAtIndexPath:)]) {
        canTimeMove = [self.dataSource collectionView:self.collectionView layout:self canTimeMoveItemAtIndexPath:self.selectedItemIndexPath];
    }
    if (!canTimeMove) {
        return;
    }
    
    CGFloat horizontalDistance = movePoint.x - self.currentView.center.x;
    // 获取当前的时间
    CGFloat itemX = self.currentView.frame.origin.x + horizontalDistance;
    // horizontalDistance 需要更改
    if (itemX < 0) { // 超出范围 --- 将x设置到最小
        horizontalDistance += fabs(itemX - 0);
        itemX = 0;
    }
    if ((itemX + self.currentView.frame.size.width) > _timeLineLength) { // 超出范围 --- 将x设置为最大
        horizontalDistance -= fabs((itemX + self.currentView.frame.size.width) - _timeLineLength);
        itemX = _timeLineLength - self.currentView.frame.size.width;
    }
    
    if ((self.currentView.frame.origin.x <= 0 && itemX == 0) || (CGRectGetMaxX(self.currentView.frame) >= _timeLineLength && itemX == _timeLineLength - self.currentView.frame.size.width)) {
        return;
    }
    
    // 根据ItemX计算出时间
    CMTime toTime = [_timeLengthRatio calculateTimeWithLength:itemX];
    BOOL canMove = NO;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(collectionView:layout:itemAtIndexPath:canMoveToTime:)]) {
        canMove = [self.dataSource collectionView:self.collectionView layout:self itemAtIndexPath:self.selectedItemIndexPath canMoveToTime:toTime];
    }
    if (!canMove) {
        return;
    }
    
    // 移动
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(collectionView:layout:itemAtIndexPath:willMoveToTime:)]) {
        [self.dataSource collectionView:self.collectionView layout:self itemAtIndexPath:self.selectedItemIndexPath willMoveToTime:toTime];
    } else {
        NSAssert(NO, @"%s %d %@", __func__, __LINE__, @"Must implementation [collectionView:layout:itemAtIndexPath:willMoveToTime:]");
    }

    // 移动
    @try {
        
        __weak typeof(self) _self = self;
        [self.collectionView performBatchUpdates:^{
            [_self.collectionView reloadItemsAtIndexPaths:@[_self.selectedItemIndexPath]];
        } completion:^(BOOL finished) {
            if (_self.dataSource && [_self.dataSource respondsToSelector:@selector(collectionView:layout:itemAtIndexPath:didMoveToTime:)]) {
                [_self.dataSource collectionView:_self.collectionView layout:_self itemAtIndexPath:_self.selectedItemIndexPath didMoveToTime:toTime];
            }
        }];
        
        // 直接更新fakeView
        self.currentView.center = CGPointMake(self.currentView.center.x + horizontalDistance, self.currentView.center.y);
        
    } @catch (NSException *exception) {
        NSAssert(NO, @"%s %d %@", __func__, __LINE__, exception);
    }
}

/**
 移动行
 */
- (void)invalidateLineMoveIfNecessaryWithMovePoint:(CGPoint)movePoint afterCannotMoveHandle:(void(^)(void))cannotMoveHandle {
    
    BOOL canMoveLine = NO;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(collectionView:layout:canLineMoveItemAtIndexPath:)]) {
        canMoveLine = [self.dataSource collectionView:self.collectionView layout:self canLineMoveItemAtIndexPath:self.selectedItemIndexPath];
    }
    if (!canMoveLine) {
        cannotMoveHandle ? cannotMoveHandle() : nil;
        return;
    }
    
    // 判断y是否有移动到别的行上
    // 先判断是否移动到别的行
    CGPoint currentViewPoint = self.currentView.center;
    // 判断移动距离
    CGFloat verticalDistance = movePoint.y - currentViewPoint.y;
    BOOL isMoveLine = NO;
    BOOL isLastLine = NO;
    if (verticalDistance < 0 && fabs(verticalDistance) > (self.itemTotalHeight * 0.5)) {
        // 移到上一行的上半部分
        isMoveLine = YES;
        isLastLine = YES;
    } else if (verticalDistance > 0 && verticalDistance > self.itemTotalHeight) {
        // 移到下一行的下半部分
        isMoveLine = YES;
        isLastLine = NO;
    }
    
    if (!isMoveLine) {
        cannotMoveHandle ? cannotMoveHandle() : nil;
        return;
    }
    
    // 获取移动的目标indexPath
    NSIndexPath * toIndexPath = [self indexPathOfY:movePoint.y];
    if (!toIndexPath || [toIndexPath isEqual:self.selectedItemIndexPath]) {
        // 回调
        cannotMoveHandle ? cannotMoveHandle() : nil;
        return;
    }
    
    NSIndexPath *fromIndexPath = self.selectedItemIndexPath;
    
    // 有值
    BOOL canMove = NO;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(collectionView:layout:itemAtIndexPath:canMoveToIndexPath:)]) {
        canMove = [self.dataSource collectionView:self.collectionView layout:self itemAtIndexPath:fromIndexPath canMoveToIndexPath:toIndexPath];
    }
    if (!canMove) { // 不能移动
        // 回调
        cannotMoveHandle ? cannotMoveHandle() : nil;
        return;
    }
    
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(collectionView:layout:itemAtIndexPath:willMoveToIndexPath:)]) {
        [self.dataSource collectionView:self.collectionView layout:self itemAtIndexPath:fromIndexPath willMoveToIndexPath:toIndexPath];
    } else {
        NSAssert(NO, @"%s %d %@", __func__, __LINE__, @"Must implementation [collectionView:layout:itemAtIndexPath:willMoveToIndexPath:]");
        // 回调
        return;
    }
    
    // 更新
    self.selectedItemIndexPath = toIndexPath;
    // 更新View
    [self.currentView setCenter:CGPointMake(self.currentView.center.x, self.currentView.center.y + (isLastLine ? (-self.itemTotalHeight) : self.itemTotalHeight))];
    @try {
        // 换行
        __weak typeof(self) _self = self;
        [self.collectionView performBatchUpdates:^{
            [_self.collectionView insertItemsAtIndexPaths:@[toIndexPath]];
            [_self.collectionView deleteItemsAtIndexPaths:@[fromIndexPath]];
        } completion:^(BOOL finished) {
            if (_self.dataSource && [_self.dataSource respondsToSelector:@selector(collectionView:layout:itemAtIndexPath:didMoveToIndexPath:)]) {
                [_self.dataSource collectionView:_self.collectionView layout:_self itemAtIndexPath:fromIndexPath didMoveToIndexPath:toIndexPath];
            }
        }];
    } @catch (NSException *exception) {
        NSAssert(NO, @"%s %d %@", __func__, __LINE__, exception);
    }
    
}

/**
 根据y来获取indexPath
 */
- (NSIndexPath *)indexPathOfY:(CGFloat)y {
    if (y < 0) {
        return nil;
    }
    
    NSInteger beginIndex = (y / self.itemTotalHeight);
    if (beginIndex <= 0) {
        beginIndex = 0;
    }
    NSInteger sectionCount = [self.collectionView numberOfSections];
    
    NSInteger index = 0;
    NSIndexPath *beginIndexPath = nil;
    
    for (NSInteger section = 0; section < sectionCount; section++) {
        
        NSInteger sectionItemCount = [self.collectionView numberOfItemsInSection:section];
        if (beginIndex <= (sectionItemCount + index)) {
            // 在这个section的范围内
            beginIndexPath = [NSIndexPath indexPathForItem:(beginIndex - index) inSection:section];
            break;
        }
        
        index += sectionItemCount;
    }
    
    return beginIndexPath;
}

#pragma mark - handle/action

- (void)handleScroll:(CADisplayLink *)displayLink {
    GCScrollingDirection direction = [displayLink.GC_userInfo[kGCScrollingDirectionKey] integerValue];
    if (direction == GCScrollingDirectionUnknow) {
        return;
    }
    
    CGSize frameSize = self.collectionView.bounds.size;
    CGSize contentSize = self.collectionView.contentSize;
    CGPoint contentOffset = self.collectionView.contentOffset;
    UIEdgeInsets contentInset = self.collectionView.contentInset;
    // Important to have an integer `distance` as the `contentOffset` property automatically gets rounded
    // and it would diverge from the view's center resulting in a "cell is slipping away under finger"-bug.
    CGFloat distance = rint(self.scrollingSpeed * displayLink.duration);
    CGPoint translation = CGPointZero;
    
    switch (direction) {
        case GCScrollingDirectionUp: {
            distance = -distance;
            CGFloat minY = 0.0f - contentInset.top;
            
            if ((contentOffset.y + distance) <= minY) {
                distance = -contentOffset.y - contentInset.top;
            }
            
            translation = CGPointMake(0.0, distance);
            break;
        }
        case GCScrollingDirectionDown: {
            CGFloat maxY = MAX(contentSize.height, frameSize.height) - frameSize.height + contentInset.bottom;
            
            if ((contentOffset.y + distance) >= maxY) {
                distance = maxY - contentOffset.y;
            }
            
            translation = CGPointMake(0.0, distance);
            
            break;
        }
        case GCScrollingDirectionLeft: {
            distance = -distance;
            CGFloat minX = 0.0 - contentInset.left;
            
            if ((contentOffset.x + distance) <= minX) {
                distance = -contentOffset.x - contentInset.left;
            }
            
            translation = CGPointMake(distance, 0.0f);
            break;
        }
        case GCScrollingDirectionRight: {
            CGFloat maxX = MAX(contentSize.width, frameSize.width) - frameSize.width + contentInset.right;
            
            if ((contentOffset.x + distance) >= maxX) {
                distance = maxX - contentOffset.x;
            }
            
            translation = CGPointMake(distance, 0.0);
            
            break;
        }
        default: { break; }
    }
    
    // view的移动
    [self invalidateLayoutIfNecessaryWithMovePoint:translation];
    self.collectionView.contentOffset = GC_CGPointAdd(contentOffset, translation);
    self.panLastLocationInCollectionView = GC_CGPointAdd(self.panLastLocationInCollectionView, translation);
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer {
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            // 获取当前长按位置的cell
            NSIndexPath *currentIndexPath = [self.collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:self.collectionView]];
            // 如果没有
            if (currentIndexPath == nil) {
                return;
            }
            
            BOOL canLineMove = NO;
            BOOL canTimeMove = NO;
            if (self.dataSource) {
                if ([self.dataSource respondsToSelector:@selector(collectionView:layout:canLineMoveItemAtIndexPath:)]) {
                    canLineMove = [self.dataSource collectionView:self.collectionView layout:self canLineMoveItemAtIndexPath:currentIndexPath];
                }
                if ([self.dataSource respondsToSelector:@selector(collectionView:layout:canTimeMoveItemAtIndexPath:)]) {
                    canTimeMove = [self.dataSource collectionView:self.collectionView layout:self canTimeMoveItemAtIndexPath:currentIndexPath];
                }
            }
            // 不能移动
            if (!canTimeMove && !canLineMove) {
                return;
            }
            
            self.selectedItemIndexPath = currentIndexPath;
            
            // willBeginDragging
            if (self.delegate && [self.delegate respondsToSelector:@selector(collectionView:layout:willBeginDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView:self.collectionView layout:self willBeginDraggingItemAtIndexPath:currentIndexPath];
            }
            
            // 获取当前的cell
            UICollectionViewCell *collectionViewCell = [self.collectionView cellForItemAtIndexPath:self.selectedItemIndexPath];
            
            // 这里是减去两端的
            self.currentView = [[UIView alloc] initWithFrame:CGRectMake((collectionViewCell.frame.origin.x + _itemSupernumeraryButtonWidth), collectionViewCell.frame.origin.y, (collectionViewCell.frame.size.width - 2 * _itemSupernumeraryButtonWidth), collectionViewCell.frame.size.height)];
            collectionViewCell.highlighted = YES;
            
            // fake view
            UIView *fakeView = [collectionViewCell GC_snapshotViewOnlyValueWithClipWidth:_itemSupernumeraryButtonWidth];
            fakeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            
            [self.currentView addSubview:fakeView];
            [self.collectionView addSubview:self.currentView];
            
            self.currentViewCenter = self.currentView.center;
            
            // did dragging
            if ([self.delegate respondsToSelector:@selector(collectionView:layout:didBeginDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView:self.collectionView layout:self didBeginDraggingItemAtIndexPath:self.selectedItemIndexPath];
            }
            
            [UIView animateWithDuration:kAnimationDuration animations:^{
               
                // 将currentView的y向上移动
                self.currentView.frame = CGRectMake(self.currentView.frame.origin.x, (self.currentView.frame.origin.y - self->_itemMargin), self.currentView.frame.size.width, self.currentView.frame.size.height);
                self.currentViewCenter = self.currentView.center;
                self.currentView.alpha = 0.6;
                
            } completion:^(BOOL finished) {
                
            }];
            
            [self invalidateLayout]; // 重新布局
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            
            NSIndexPath *currentIndexPath = self.selectedItemIndexPath;
            if (currentIndexPath) {
                // will end dragging
                if ([self.delegate respondsToSelector:@selector(collectionView:layout:willEndDraggingItemAtIndexPath:)]) {
                    [self.delegate collectionView:self.collectionView layout:self willEndDraggingItemAtIndexPath:currentIndexPath];
                }
                
                self.selectedItemIndexPath = nil;
                self.currentViewCenter = CGPointZero;
                
                UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:currentIndexPath];
                
                self.longPressGestureRecognizer.enabled = NO;
                
                __weak typeof(self) _self = self;
                [UIView animateWithDuration:kAnimationDuration animations:^{
                    
                    _self.currentView.alpha = 1.0;
                    _self.currentView.center = attributes.center;
                    
                } completion:^(BOOL finished) {
                    
                    _self.longPressGestureRecognizer.enabled = YES;
                    
                    [_self.currentView removeFromSuperview];
                    _self.currentView = nil;
                    [_self invalidateLayout]; // 刷新
                    
                    if (_self.delegate && [_self.delegate respondsToSelector:@selector(collectionView:layout:didEndDraggingItemAtIndexPath:)]) {
                        [_self.delegate collectionView:_self.collectionView layout:_self didEndDraggingItemAtIndexPath:currentIndexPath];
                    }
                }];
                
            }
            break;
        }
        default: { break; }
    }
    
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            self.panLastLocationInCollectionView = [gestureRecognizer locationInView:self.collectionView];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            
            self.panMoveInCollectionView = GC_CGPointSubtract([gestureRecognizer locationInView:self.collectionView], self.panLastLocationInCollectionView);
            
            [self invalidateLayoutIfNecessaryWithMovePoint:self.panMoveInCollectionView];
            
            self.panLastLocationInCollectionView = [gestureRecognizer locationInView:self.collectionView];
            
            // 四种情况 --- 可以上下移动 --- 可以左右移动 --- 两者皆可 --- 两者都不行
            BOOL canMoveLine = NO;
            BOOL canMoveTime = NO;
            if (self.dataSource && [self.dataSource respondsToSelector:@selector(collectionView:layout:canLineMoveItemAtIndexPath:)]) {
                canMoveLine = [self.dataSource collectionView:self.collectionView layout:self canLineMoveItemAtIndexPath:self.selectedItemIndexPath];
            }
            if (self.dataSource && [self.dataSource respondsToSelector:@selector(collectionView:layout:canTimeMoveItemAtIndexPath:)]) {
                canMoveTime = [self.dataSource collectionView:self.collectionView layout:self canTimeMoveItemAtIndexPath:self.selectedItemIndexPath];
            }
            
            BOOL canScroll = NO;
            UICollectionViewScrollDirection scrollDirection = UICollectionViewScrollDirectionHorizontal;
            
            if (canMoveTime && canMoveLine) { // 两者皆可
                canScroll = YES;
                CGPoint velocity = [gestureRecognizer velocityInView:self.collectionView];
                if (fabs(velocity.x) < fabs(velocity.y)) {
                    scrollDirection = UICollectionViewScrollDirectionVertical;
                }
                
            } else if (canMoveTime) { // 可以水平移动
                canScroll = YES;
                scrollDirection = UICollectionViewScrollDirectionHorizontal;
            } else if (canMoveLine) { // 可以垂直移动
                canScroll = YES;
                scrollDirection = UICollectionViewScrollDirectionVertical;
            } else { // 两个方向都不可以移动
                canScroll = NO;
            }
            
            if (canScroll) {
                
                switch (scrollDirection) {
                    case UICollectionViewScrollDirectionVertical: {
                        if (self.currentViewCenter.y <= (CGRectGetMinY(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.top)) {
                            [self setupScrollTimerInDirection:GCScrollingDirectionUp];
                        } else {
                            if (self.currentViewCenter.y > (CGRectGetMaxY(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.bottom)) {
                                [self setupScrollTimerInDirection:GCScrollingDirectionDown];
                            } else {
                                [self invalidatesScrollTimer];
                            }
                        }
                        break;
                    }
                    case UICollectionViewScrollDirectionHorizontal: {
                        if (self.currentViewCenter.x <= (CGRectGetMinX(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.left)) {
                            [self setupScrollTimerInDirection:GCScrollingDirectionLeft];
                        } else {
                            if (self.currentViewCenter.x > (CGRectGetMaxX(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.right)) {
                                [self setupScrollTimerInDirection:GCScrollingDirectionRight];
                            } else {
                                [self invalidatesScrollTimer];
                            }
                        }
                        break;
                    }
                    default: { break; }
                }
            }
            
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            // 取消Timer
            [self invalidatesScrollTimer];
            break;
        }
        default: { break; }
    }
}

#pragma mark - override method

- (void)prepareLayout {
    [super prepareLayout];
    
    // 获取必要的信息
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(collectionViewTotalTime:layout:)]) {
        _timeLineDuration = [self.dataSource collectionViewTotalTime:self.collectionView layout:self];
    }
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(collectionViewTimeAndLengthRatio:layout:)]) {
        _timeLengthRatio = [self.dataSource collectionViewTimeAndLengthRatio:self.collectionView layout:self];
    }
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(collectionViewItemHeight:layout:)]) {
        _itemHeight = [self.dataSource collectionViewItemHeight:self.collectionView layout:self];
    }
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(collectionViewItemMargin:layout:)]) {
        _itemMargin = [self.dataSource collectionViewItemMargin:self.collectionView layout:self];
    }
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(collectionViewItemSupernumeraryButtonWidth:layout:)]) {
        _itemSupernumeraryButtonWidth = [self.dataSource collectionViewItemSupernumeraryButtonWidth:self.collectionView layout:self];
    }
}

- (CGSize)collectionViewContentSize {
    _timeLineLength = [_timeLengthRatio calculateLengthWithTime:_timeLineDuration];
    NSInteger sectionCount = [self.collectionView numberOfSections];
    NSInteger count = 0;
    for (NSInteger section = 0; section < sectionCount; section++) {
        count += [self.collectionView numberOfItemsInSection:section];
    }
    
    CGFloat height = count * self.itemTotalHeight;
    return CGSizeMake(_timeLineLength, height);
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *attributes = [NSMutableArray array];
    /*
    NSInteger sectionCount = [self.collectionView numberOfSections];
    for (NSInteger section = 0; section < sectionCount; section++) {
        NSInteger numberOfItem = [self.collectionView numberOfItemsInSection:section];
        for (NSInteger item = 0; item < numberOfItem; item++) {
            UICollectionViewLayoutAttributes *attri = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:section]];
            if (attri) {
                [attributes addObject:attri];
            }
        }
    }//*/
    
    // 先计算出可以显示的数量
    ///*
    CGFloat height = rect.size.height;
    CGFloat y = rect.origin.y;
    if (y < 0) {
        height += y;
        y = 0;
    }
    
    // 根据y来找出第一个
    NSIndexPath *beginIndexPath = [self indexPathOfY:y];
    
    if (beginIndexPath) { // 有值的情况
        
        // 总数
        NSInteger count = (height / self.itemTotalHeight) + 1;
        
        NSInteger sectionCount = [self.collectionView numberOfSections];
        NSInteger index = 0;
        NSInteger beginItemIndex = beginIndexPath.item;
        for (NSInteger section = beginIndexPath.section; section < sectionCount; section++) {
            
            BOOL isBreak = NO;
            
            NSInteger itemNumber = [self.collectionView numberOfItemsInSection:section];
            for (NSInteger item = beginItemIndex; item < itemNumber; item++) {
                
                // 不考虑sectionHeader和sectionFooter
                UICollectionViewLayoutAttributes *attri = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:section]];
                if (attri) {
                    [attributes addObject:attri];
                }
                index++;
                
                if (index > count) {
                    isBreak = YES;
                    break;
                }
            }
            
            if (isBreak) {
                break;
            }
            
            beginItemIndex = 0;
        }
    }//*/
    
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attritubes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    
    // 计算位置
    // 获取时间
    CMTimeRange timeRange = kCMTimeRangeInvalid;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(collectionView:layout:itemTimeRangeForIndexPath:)]) {
        timeRange = [self.dataSource collectionView:self.collectionView layout:self itemTimeRangeForIndexPath:indexPath];
    }
    NSAssert(CMTIMERANGE_IS_INVALID(timeRange) != YES, @"%s %d %@ %@", __func__, __LINE__, @"Invalid time range of indexPath", indexPath);
    
    // 计算在这之前的高度
    CGFloat beginY = 0;
    if (indexPath.section != 0) {
        NSInteger beginSection = [self totalCountOfSection:(indexPath.section - 1)];
        beginY = beginSection * self.itemTotalHeight;
    }
    
    // 计算section内的高度
    beginY += indexPath.item * self.itemTotalHeight;
    
    // 计算宽度
    CGFloat width = [_timeLengthRatio calculateLengthWithTime:timeRange.duration];
    CGFloat startX = [_timeLengthRatio calculateLengthWithTime:timeRange.start];
    
    CGFloat centerY = beginY + self.itemTotalHeight * 0.5;
    CGFloat centerX = startX + width * 0.5;
    
    attritubes.center = CGPointMake(centerX, centerY);
    // 这里的width需要再加两个button的宽度
    width += _itemSupernumeraryButtonWidth * 2;
    attritubes.size = CGSizeMake(width, _itemHeight);
    
    // 更新attributes
    [self applyLayoutAttributes:attritubes];
    
    return attritubes;
}

#pragma mark - update

///*
- (void)prepareForCollectionViewUpdates:(NSArray<UICollectionViewUpdateItem *> *)updateItems {
    [super prepareForCollectionViewUpdates:updateItems];
    
    // 暂时只有删除和插入
    _insertArray = [NSMutableArray array];
    _deleteArray = [NSMutableArray array];
    
    for (UICollectionViewUpdateItem *update in updateItems) {
        
        switch (update.updateAction) {
            case UICollectionUpdateActionInsert: {
                [_insertArray addObject:update.indexPathAfterUpdate];
                break;
            }
            case UICollectionUpdateActionDelete: {
                [_deleteArray addObject:update.indexPathBeforeUpdate];
                break;
            }
                // 其他的情况不考虑
            default: { break; }
        }
        
    }
    
}

- (void)finalizeCollectionViewUpdates {
    [super finalizeCollectionViewUpdates];
    
    [_insertArray removeAllObjects];
    _insertArray = nil;
    [_deleteArray removeAllObjects];
    _deleteArray = nil;
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
    UICollectionViewLayoutAttributes *attributes = [super initialLayoutAttributesForAppearingItemAtIndexPath:itemIndexPath];
    if ([_deleteArray containsObject:itemIndexPath] ||
        [_insertArray containsObject:itemIndexPath]) {
        if (!attributes) {
            attributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
        }
        attributes.alpha =0.0;
    }
    return attributes;
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
    UICollectionViewLayoutAttributes *attributes = [super finalLayoutAttributesForDisappearingItemAtIndexPath:itemIndexPath];
    if ([_insertArray containsObject:itemIndexPath] ||
        [_deleteArray containsObject:itemIndexPath]) {
        if (!attributes) {
            attributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
        }
        attributes.alpha = 0.0;
    }
    
    return attributes;
}
 //*/

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    CGRect oldBounds = self.collectionView.bounds;
    if (CGRectGetWidth(newBounds) != CGRectGetWidth(oldBounds)) {
        return YES;
    }
    return NO;
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([self.panGestureRecognizer isEqual:gestureRecognizer]) {
        return (self.selectedItemIndexPath != nil);
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([self.longPressGestureRecognizer isEqual:gestureRecognizer]) {
        return [self.panGestureRecognizer isEqual:otherGestureRecognizer];
    }
    
    if ([self.panGestureRecognizer isEqual:gestureRecognizer]) {
        return [self.longPressGestureRecognizer isEqual:otherGestureRecognizer];
    }
    
    return NO;
}

#pragma mark - Key-Value Observing methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:kGCCollectionViewKeyPath]) {
        if (self.collectionView != nil) {
            [self setupCollectionView];
        } else {
            [self invalidatesScrollTimer];
            [self tearDownCollectionView];
        }
    }
}

#pragma mark - event

- (NSInteger)totalCountOfSection:(NSInteger)section {
    if (section < 0 ) {
        return 0;
    }
    
    NSInteger target = 0;
    if (section == 0) {
        target = [self.collectionView numberOfItemsInSection:section];
        return target;
    }
    
    for (NSInteger index = 0; index < section; index++) {
        target += [self.collectionView numberOfItemsInSection:index];
    }
    return target;
}

#pragma mark - Notifications

- (void)handleApplicationWillResignActive:(NSNotification *)notification {
    self.panGestureRecognizer.enabled = NO;
    self.panGestureRecognizer.enabled = YES;
}

#pragma mark - getter

- (CGFloat)itemTotalHeight {
    return _itemHeight + 2 * _itemMargin;
}

- (id<GCTextAndPictureMoveLayoutDataSource>)dataSource {
    return (id<GCTextAndPictureMoveLayoutDataSource>)self.collectionView.dataSource;
}

- (id<GCTextAndPictureMoveLayoutDelegate>)delegate {
    return (id<GCTextAndPictureMoveLayoutDelegate>)self.collectionView.delegate;
}

@end
