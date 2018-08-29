//
//  GCTextAndPictureMoveCell.m
//  HQLTextAndPitcureMoveLayoutDemo
//
//  Created by 何启亮 on 2018/8/14.
//  Copyright © 2018年 hql_personal_team. All rights reserved.
//

#import "GCTextAndPictureMoveCell.h"
#import <Masonry.h>

@implementation HQLCollectionModel

@end

/*=========================== cell ===========================*/

@interface GCTextAndPictureMoveCell ()

@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;

// 左边的手势
@property (nonatomic, strong) UIPanGestureRecognizer *leftPanGesture;
// 右边的手势
@property (nonatomic, strong) UIPanGestureRecognizer *rightPanGesture;

@property (nonatomic, assign) BOOL isDurationPanGesture;

@property (nonatomic, assign) CGPoint lastPanPoint;

@end

@implementation GCTextAndPictureMoveCell

#pragma mark - initialize method

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self prepareUI];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"dealloc ---> %@", NSStringFromClass([self class]));
}

#pragma mark - prepareUI

- (void)prepareUI {
    
    self.lastItem = -1;
    self.currentItem = -1;
    
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftButton setBackgroundColor:[UIColor blueColor]];
    [self.contentView addSubview:leftButton];
    self.leftButton = leftButton;
    [leftButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [leftButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(self.contentView);
        make.width.mas_equalTo(30);
    }];
    
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightButton setBackgroundColor:[UIColor blueColor]];
    [self.contentView addSubview:rightButton];
    self.rightButton = rightButton;
    [rightButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [rightButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.top.bottom.equalTo(self.contentView);
        make.width.mas_equalTo(30);
    }];
    
    // 添加手势
    UIPanGestureRecognizer *leftPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureHandle:)];
    self.leftPanGesture = leftPan;
    [leftButton addGestureRecognizer:leftPan];
    
    UIPanGestureRecognizer *rightPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureHandle:)];
    self.rightPanGesture = rightPan;
    [rightButton addGestureRecognizer:rightPan];
    
    [self setBackgroundColor:[UIColor redColor]];
}

#pragma mark - event

#pragma mark - PanGestureHandle

- (void)panGestureHandle:(UIPanGestureRecognizer *)panGesture {
    
    if (!self.superview) {
        return;
    }
    
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan: {
            
            self.isDurationPanGesture = YES;
            
            // begin
            if (panGesture == self.rightPanGesture) {
                [self.leftPanGesture setEnabled:NO];
            } else {
                [self.rightPanGesture setEnabled:NO];
            }
            
            self.lastPanPoint = [panGesture locationInView:self.superview];
            
            if (self.beginMoveHandle) {
                self.beginMoveHandle(self);
            }
            
            break;
        }
        case UIGestureRecognizerStateChanged: {
            
            CGPoint currentPoint = [panGesture locationInView:self.superview];
            CGFloat xDistance = currentPoint.x - self.lastPanPoint.x;
            
            BOOL isChangeStartTime = (panGesture == self.leftPanGesture ? YES : NO);
            
            if (isChangeStartTime) {
                xDistance *= (-1);
            }
            
            if (self.moveHandle) {
                self.moveHandle(self, isChangeStartTime, xDistance);
            }
            
            self.lastPanPoint = currentPoint;
            
            if (self.movingHandle) {
                self.movingHandle(self, self.lastPanPoint);
            }
            
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled: {
            
            self.isDurationPanGesture = NO;
            
            [self.leftPanGesture setEnabled:YES];
            [self.rightPanGesture setEnabled:YES];
            
            if (self.endMoveHandle) {
                self.endMoveHandle(self);
            }
            
            break;
        }
        default: { break; }
    }
    
}

- (void)updateLastMovePoint:(CGPoint)lastMovePoint {
    self.lastPanPoint = lastMovePoint;
}

#pragma mark - setter & getter

- (void)setCurrentItem:(NSInteger)currentItem {
    self.lastItem = _currentItem;
    _currentItem = currentItem;
    [self.leftButton setTitle:[NSString stringWithFormat:@"%ld", currentItem] forState:UIControlStateNormal];
    if (self.lastItem == -1) {
        self.lastItem = currentItem;
    }
    [self.rightButton setTitle:[NSString stringWithFormat:@"%ld", self.lastItem] forState:UIControlStateNormal];
}

@end
