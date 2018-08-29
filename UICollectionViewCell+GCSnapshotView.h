//
//  UICollectionViewCell+GCSnapshotView.h
//  HQLVideoItemPanMoveLayoutDemo
//
//  Created by 何启亮 on 2018/8/24.
//  Copyright © 2018年 hql_personal_team. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UICollectionViewCell (GCSnapshotView)

/**
 将cell截图
 */
- (UIView *)GC_snapshotView;

/**
 cell截图 --- 去掉两边的button
 */
- (UIView *)GC_snapshotViewOnlyValueWithClipWidth:(CGFloat)width;

@end
