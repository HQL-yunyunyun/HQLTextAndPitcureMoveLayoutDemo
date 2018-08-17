//
//  ViewController.m
//  HQLTextAndPitcureMoveLayoutDemo
//
//  Created by 何启亮 on 2018/8/14.
//  Copyright © 2018年 hql_personal_team. All rights reserved.
//

#import "ViewController.h"

#import "GCTextAndPictureMoveLayout.h"
#import "GCTimeAndLengthRatio.h"
#import "GCTextAndPictureMoveCell.h"

#import <Masonry.h>

typedef NS_ENUM(NSInteger, GCScrollDirection) {
    GCScrollDirectionNone = 0,
    GCScrollDirectionUnDefine,
    GCScrollDirectionHorizontal, // 水平移动
    GCScrollDirectionVertical, // 垂直移动
};

@interface ViewController () <UICollectionViewDelegate, UICollectionViewDataSource, GCTextAndPictureMoveLayoutDataSource, UIScrollViewDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) GCTimeAndLengthRatio *currentRatio;

@property (nonatomic, strong) NSMutableArray *dataSource;

@property (nonatomic, assign) CGPoint beforeDraggingContentOffset;
@property (nonatomic, assign) GCScrollDirection direction;
@property (nonatomic, assign) CGPoint beginContentOffset;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self bulidData];
    [self prepareUI];
}

- (void)bulidData {
    
    self.currentRatio = [[GCTimeAndLengthRatio alloc] initWithTimeDuration:CMTimeMakeWithSeconds(1, 600) lengthPerTimeDuration:50];
    
    self.dataSource = [NSMutableArray array];
    
    for (int i = 0; i < 100; i++) {
        HQLCollectionModel *model = [[HQLCollectionModel alloc] init];
        CMTime duration = CMTimeMakeWithSeconds(1, 600);
        CMTime start = CMTimeMultiply(duration, i);
        model.timeRange = CMTimeRangeMake(start, duration);
        [self.dataSource addObject:model];
    }
}

- (void)prepareUI {
    GCTextAndPictureMoveLayout *layout = [[GCTextAndPictureMoveLayout alloc] init];
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    [collectionView registerClass:[GCTextAndPictureMoveCell class] forCellWithReuseIdentifier:@"cellReuseId"];
    collectionView.delegate = self;
    collectionView.dataSource = self;
    [self.view addSubview:collectionView];
    self.collectionView = collectionView;
    collectionView.contentInset = UIEdgeInsetsMake(0, self.view.frame.size.width * 0.5, 0, self.view.frame.size.width * 0.5);
    [collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view);
        make.height.equalTo(self.view).multipliedBy(0.5);
        make.centerX.centerY.equalTo(self.view);
    }];
    collectionView.directionalLockEnabled = YES;
    collectionView.bounces = NO;
    
    UIView *lineView = [[UIView alloc] init];
    [lineView setBackgroundColor:[UIColor orangeColor]];
    [self.view addSubview:lineView];
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(collectionView.mas_top).offset(-20);
        make.bottom.equalTo(collectionView.mas_bottom).offset(20);
        make.width.mas_equalTo(1);
    }];
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button1 setTitle:@"水平移动" forState:UIControlStateNormal];
    [button1 addTarget:self action:@selector(buttonEvent:) forControlEvents:UIControlEventTouchUpInside];
    [button1 setTag:0];
    [self.view addSubview:button1];
    [button1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(collectionView.mas_bottom).offset(20);
        make.left.equalTo(self.view).offset(10);
        make.height.mas_equalTo(30);
        make.width.mas_equalTo(70);
    }];
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button2 setTitle:@"垂直移动" forState:UIControlStateNormal];
    [button2 addTarget:self action:@selector(buttonEvent:) forControlEvents:UIControlEventTouchUpInside];
    [button2 setTag:1];
    [self.view addSubview:button2];
    [button2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(collectionView.mas_bottom).offset(20);
        make.left.equalTo(button1.mas_right).offset(10);
        make.height.mas_equalTo(30);
        make.width.mas_equalTo(70);
    }];
}

- (void)buttonEvent:(UIButton *)button {
    switch (button.tag) {
        case 0: {
            
            [self.collectionView setContentOffset:CGPointMake(self.collectionView.contentOffset.x + 100, self.collectionView.contentOffset.y) animated:YES];
            
            break;
        }
        case 1: {
            
            [self.collectionView setContentOffset:CGPointMake(self.collectionView.contentOffset.x, self.collectionView.contentOffset.y + 100) animated:YES];
            
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    GCTextAndPictureMoveCell *cell = (GCTextAndPictureMoveCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cellReuseId" forIndexPath:indexPath];
    cell.currentItem = indexPath.item;
    return cell;
}

#pragma mark - scroll delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.beginContentOffset = scrollView.contentOffset;
    self.beforeDraggingContentOffset = scrollView.contentOffset;
    self.direction = GCScrollDirectionUnDefine;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (self.direction == GCScrollDirectionUnDefine) {
        GCScrollDirection scrollDirection = GCScrollDirectionNone;
        
        if (self.beginContentOffset.x != scrollView.contentOffset.x &&
            self.beginContentOffset.y != scrollView.contentOffset.y) {
            scrollDirection = GCScrollDirectionHorizontal;
        } else {
            if ((self.beginContentOffset.x > scrollView.contentOffset.x) ||
                (self.beginContentOffset.x < scrollView.contentOffset.x)) {
                scrollDirection = GCScrollDirectionHorizontal;
            } else if ((self.beginContentOffset.y > scrollView.contentOffset.y) ||
                       (self.beginContentOffset.y < scrollView.contentOffset.y)) {
                scrollDirection = GCScrollDirectionVertical;
            } else {
                scrollDirection = GCScrollDirectionVertical;
            }
        }
        self.direction = scrollDirection;
    }
    
    switch (self.direction) {
        case GCScrollDirectionHorizontal: {
            [self.collectionView setContentOffset:CGPointMake(scrollView.contentOffset.x, self.beforeDraggingContentOffset.y)];
            break;
        }
        case GCScrollDirectionVertical: {
            [self.collectionView setContentOffset:CGPointMake(self.beforeDraggingContentOffset.x, scrollView.contentOffset.y)];
            break;
        }
        default: { break; }
    }

}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        self.direction = GCScrollDirectionNone;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.direction = GCScrollDirectionNone;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    self.direction = GCScrollDirectionNone;
}

#pragma mark - GCTextAndPictureMoveLayoutDataSource

/**
 获取collectionView要显示的总时长
 */
- (CMTime)collectionViewTotalTime:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout {
    return CMTimeMakeWithSeconds(100, 600);
}

/**
 时长的换算
 */
- (GCTimeAndLengthRatio *)collectionViewTimeAndLengthRatio:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout {
    return self.currentRatio;
}

/**
 返回ItemHeight
 */
- (CGFloat)collectionViewItemHeight:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout {
    return 30;
}

/**
 返回ItemMargin
 */
- (CGFloat)collectionViewItemMargin:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout {
    return 7.5;
}

/**
 返回Item两侧button的宽度 --- 在算Item位置时，这两个宽度不算进去
 */
- (CGFloat)collectionViewItemSupernumeraryButtonWidth:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout {
    return 30;
}

/**
 返回每个Item的时间范围 --- 以此来计算Item的rect
 */
- (CMTimeRange)collectionView:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout itemTimeRangeForIndexPath:(NSIndexPath *)indexPath {
    HQLCollectionModel *model = self.dataSource[indexPath.item];
    return model.timeRange;
}

/**
 是否可以移动到time
 */
- (BOOL)collectionView:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout itemAtIndexPath:(NSIndexPath *)indexPath canMoveToTime:(CMTime)time {
    HQLCollectionModel *model = self.dataSource[indexPath.item];
    if (!model) {
        return NO;
    }
    // 计算时间
    if (CMTimeGetSeconds(time) < 0) { // 没有0秒之前的
        return NO;
    }
    
    CMTime total = CMTimeMakeWithSeconds(100, 600);
    CMTime newTime = CMTimeAdd(time, model.timeRange.duration);
    if (CMTimeCompare(newTime, total) > 0) {
        // 大于总时长
        return NO;
    }
    
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout canLineMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout canTimeMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath {
    if (toIndexPath.item < 0 || toIndexPath.item >= self.dataSource.count
        || fromIndexPath.item < 0 || fromIndexPath.item >= self.dataSource.count) {
        return NO;
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
    HQLCollectionModel *fromModel = self.dataSource[fromIndexPath.item];
    [self.dataSource removeObject:fromModel];
    [self.dataSource insertObject:fromModel atIndex:toIndexPath.item];
}

- (void)collectionView:(UICollectionView *)collectionView layout:(GCTextAndPictureMoveLayout *)layout itemAtIndexPath:(NSIndexPath *)indexPath willMoveToTime:(CMTime)time {
    // 在这里是一定可以的
    HQLCollectionModel *model = self.dataSource[indexPath.item];
    if (!model) {
        return;
    }
    model.timeRange = CMTimeRangeMake(time, model.timeRange.duration);
}

@end
