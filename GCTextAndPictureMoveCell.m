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
    
    [self setBackgroundColor:[UIColor redColor]];
}

#pragma mark - event

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
