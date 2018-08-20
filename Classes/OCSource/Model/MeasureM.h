//
//  PartWiseMeasure.h
//  iOSMusic
//
//  Created by tanhui on 2017/7/11.
//  Copyright © 2017年 tanhui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DrawableNoteM.h"
#import "DrawableProtocol.h"
@interface MeasureM : NSObject<DrawableProtocol>
@property(nonatomic, assign)NSInteger mPartIndex;
@property(nonatomic, assign)int mLine;
@property(nonatomic, assign)double mWidthRatio;
@property(nonatomic, assign)double mWidth;
@property(nonatomic, assign)double mStartTime;
@property(nonatomic, assign)double mStartX;
@property(nonatomic, assign)NSInteger mStavesNum;
@property(nonatomic, strong, readonly) NSArray< DrawableNoteM*>* mMeasureDatas;
@property(nonatomic, assign)NSInteger mMeasureIndex;
@property(nonatomic, weak)MeasureM* mNextMeasure;
@property(nonatomic, assign)BOOL mLineFirst;
-(void)setMeasureDatas:(NSArray< DrawableNoteM*>*)measureDatas;
-(instancetype)initWithWidth:(float)width musicDataGroup:(NSArray< DrawableNoteM*>*)musicDataGroup staves:(NSInteger)staff;
//-(void)sortMeasureDatas;
@end
