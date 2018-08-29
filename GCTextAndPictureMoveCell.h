//
//  GCTextAndPictureMoveCell.h
//  HQLTextAndPitcureMoveLayoutDemo
//
//  Created by 何启亮 on 2018/8/14.
//  Copyright © 2018年 hql_personal_team. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreMedia/CoreMedia.h>

@interface HQLCollectionModel : NSObject

@property (nonatomic, assign) CMTimeRange timeRange;

@end

@interface GCTextAndPictureMoveCell : UICollectionViewCell

@property (nonatomic, copy) void(^moveHandle)(GCTextAndPictureMoveCell *aCell, BOOL isChangeStartTime, CGFloat moveDistance);
@property (nonatomic, copy) void(^movingHandle)(GCTextAndPictureMoveCell *aCell, CGPoint currentPoint);
@property (nonatomic, copy) void(^endMoveHandle)(GCTextAndPictureMoveCell *aCell);
@property (nonatomic, copy) void(^beginMoveHandle)(GCTextAndPictureMoveCell *aCell);

@property (nonatomic, strong) NSIndexPath *m_indexPath;

@property (nonatomic, strong) HQLCollectionModel *model;

@property (nonatomic, assign) NSInteger currentItem;
@property (nonatomic, assign) NSInteger lastItem;

@property (nonatomic, assign, readonly) CGPoint lastPanPoint;

/**
 更新最后的手指位置
 */
- (void)updateLastMovePoint:(CGPoint)lastMovePoint;

@end
