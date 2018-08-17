//
//  GCTextAndPitcureMoveLayout.h
//  HQLTextAndPitcureMoveLayoutDemo
//
//  Created by 何启亮 on 2018/8/14.
//  Copyright © 2018年 hql_personal_team. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreMedia/CoreMedia.h>

@class GCTimeAndLengthRatio;

/**
 不考虑sectionHeader和sectionFooter
 */

@interface GCTextAndPictureMoveLayout : UICollectionViewLayout <UIGestureRecognizerDelegate>

/**
 滚动速度
 */
@property (nonatomic, assign) CGFloat scrollingSpeed;

/**
 触发滚动的范围
 */
@property (nonatomic, assign) UIEdgeInsets scrollingTriggerEdgeInsets;

/**
 手势的设置是通过KVO监听collectionView来添加手势的
 */

/**
 长按手势
 */
@property (nonatomic, strong, readonly) UILongPressGestureRecognizer *longPressGestureRecognizer;

/**
 移动手势
 */
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;

@end

/**
 主要是移动时需要做的一些数据更换
 */
@protocol GCTextAndPictureMoveLayoutDataSource <UICollectionViewDataSource>

@required

/**
 必要的属性
 */


/**
 获取collectionView要显示的总时长
 */
- (CMTime)collectionViewTotalTime:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout;

/**
 时长的换算
 */
- (GCTimeAndLengthRatio *)collectionViewTimeAndLengthRatio:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout;

/**
 返回ItemHeight
 */
- (CGFloat)collectionViewItemHeight:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout;

/**
 返回ItemMargin
 */
- (CGFloat)collectionViewItemMargin:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout;

/**
 返回Item两侧button的宽度 --- 在算Item位置时，这两个宽度不算进去
 */
- (CGFloat)collectionViewItemSupernumeraryButtonWidth:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout;

/**
 返回每个Item的时间范围 --- 以此来计算Item的rect
 */
- (CMTimeRange)collectionView:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout itemTimeRangeForIndexPath:(NSIndexPath *)indexPath;

@optional

/**
 调用顺序 -> 询问是否可以移动 [collectionView:layout:canMoveItemAtIndexPath:] -> 如果可以根据情况询问是否可以移动到相应的时间或相应的indexPath [collectionView:layout:itemAtIndexPath:canMoveToTime:]/[collectionView:layout:canMoveItemAtIndexPath:] -> 如果可以根据情况调用[willMove] -> [didMove]
 */

/**
 将要移动到相应的time
 */
- (void)collectionView:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout itemAtIndexPath:(NSIndexPath *)indexPath willMoveToTime:(CMTime)time;
/**
 已移动到相应的time
 */
- (void)collectionView:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout itemAtIndexPath:(NSIndexPath *)indexPath didMoveToTime:(CMTime)time;
/**
 将要移动到相应的indexPath
 */
- (void)collectionView:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath;
/**
 已移动到相应的indexPath
 */
- (void)collectionView:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath;

/**
 是否可以换行
 */
- (BOOL)collectionView:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout canLineMoveItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 是否可以改变时间
 */
- (BOOL)collectionView:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout canTimeMoveItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 indexPath的Item是否可以将startTime移动到相应的时间
 */
- (BOOL)collectionView:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout itemAtIndexPath:(NSIndexPath *)indexPath canMoveToTime:(CMTime)time;

/**
 fromItem 是否可以移动到 toItem 的位置
 */
- (BOOL)collectionView:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath;

@end

@protocol GCTextAndPictureMoveLayoutDelegate <UICollectionViewDelegate>

@optional

/**
 准备拖拽
 */
- (void)collectionView:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
/**
 已在拖拽
 */
- (void)collectionView:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
/**
 准备停止拖拽
 */
- (void)collectionView:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
/**
 已经停止拖拽
 */
- (void)collectionView:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath;

@end
