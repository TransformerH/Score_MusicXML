//
//  DrawableNoteM.h
//  iOSMusic
//
//  Created by tanhui on 2017/7/13.
//  Copyright © 2017年 tanhui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DrawableProtocol.h"
@class MeasureM;
@class MeasureAttributeM;
@interface DrawableNoteM : NSObject<DrawableProtocol>

@property(nonatomic, assign)NSInteger mStaffth;
@property(nonatomic, assign)double mDuration;
@property(nonatomic, assign)double mStartTime;
@property(nonatomic, assign)double mDefaultX;

@property(nonatomic, assign)double mAjustDuration;

@property(nonatomic, weak)MeasureM* mMeasure;

//@property(nonatomic, assign)BOOL mNoPrintObject;
//@property(nonatomic, strong)ClefM *mCurrentClef;
@property(nonatomic, strong)MeasureAttributeM * mCurrentAttr;

@end
