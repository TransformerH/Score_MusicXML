//
//  DrawableNoteM.m
//  iOSMusic
//
//  Created by tanhui on 2017/7/13.
//  Copyright © 2017年 tanhui. All rights reserved.
//

#import "DrawableNoteM.h"
#import "MeasureM.h"
#import "Constants.h"

@implementation DrawableNoteM

-(void)drawRect:(CGRect)rect{}

-(double)drawWidth{
    return 0;
}


//-(void)setMStartTime:(double)mStartTime{
//    _mStartTime = floor(mStartTime + 0.5);
//}

-(double)mDefaultX{
    if (self.mMeasure && self.mMeasure.mWidthRatio) {
        return _mDefaultX * self.mMeasure.mWidthRatio ;
    }else{
        return _mDefaultX;
    }
}
-(double)mAjustDuration{
    if (self.mMeasure && self.mMeasure.mWidthRatio) {
        return self.mMeasure.mWidthRatio*_mAjustDuration;
    }else{
        return _mAjustDuration;
    }
}
@end
