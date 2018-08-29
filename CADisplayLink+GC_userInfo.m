//
//  CADisplayLink+GC_userInfo.m
//  HQLVideoItemPanMoveLayoutDemo
//
//  Created by 何启亮 on 2018/8/24.
//  Copyright © 2018年 hql_personal_team. All rights reserved.
//

#import "CADisplayLink+GC_userInfo.h"

#import <objc/runtime.h>

static const void *kUserInfo = @"gc_kUserInfo";

@implementation CADisplayLink (GC_userInfo)

- (void)setGC_userInfo:(NSDictionary *)GC_userInfo {
    objc_setAssociatedObject(self, kUserInfo, GC_userInfo, OBJC_ASSOCIATION_COPY);
}

- (NSDictionary *)GC_userInfo {
    return objc_getAssociatedObject(self, kUserInfo);
}

@end
