//
//  GCTimeAndLengthRatio.m
//  GoCreate
//
//  Created by 何启亮 on 2018/8/14.
//  Copyright © 2018年 BiWan. All rights reserved.
//

#import "GCTimeAndLengthRatio.h"

@implementation GCTimeAndLengthRatio {
    CMTime _timeDuration;
    double _lengthPerTimeDuration;
}

- (instancetype)initWithTimeDuration:(CMTime)timeDuration lengthPerTimeDuration:(double)lengthPerTimeDuration {
    if (self = [super init]) {
        _timeDuration = timeDuration;
        _lengthPerTimeDuration = lengthPerTimeDuration;
    }
    return self;
}

- (void)updateTimeDuration:(CMTime)duration {
    if (CMTimeCompare(duration, _timeDuration) == 0) {
        return;
    }
    _timeDuration = duration;
}

- (double)calculateLengthWithTime:(CMTime)time {
    double aTime = CMTimeGetSeconds(time);
    double timeDuration = CMTimeGetSeconds(self.timeDuration);
    return (aTime / timeDuration * self.lengthPerTimeDuration);
}

- (CMTime)calculateTimeWithLength:(double)length {
    double timeDuration = CMTimeGetSeconds(self.timeDuration);
    double time = (length / self.lengthPerTimeDuration * timeDuration);
    return CMTimeMakeWithSeconds(time, 600);
}

#pragma mark -

- (CMTime)timeDuration {
    return _timeDuration;
}

- (double)lengthPerTimeDuration {
    return _lengthPerTimeDuration;
}

@end
