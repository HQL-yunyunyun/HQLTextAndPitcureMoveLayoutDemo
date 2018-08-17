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

@property (nonatomic, strong) HQLCollectionModel *model;

@property (nonatomic, assign) NSInteger currentItem;
@property (nonatomic, assign) NSInteger lastItem;

@end
