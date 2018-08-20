//
//  ScoreM.m
//  iOSMusic
//
//  Created by tanhui on 2017/7/11.
//  Copyright © 2017年 tanhui. All rights reserved.
//

#import "ScoreM.h"
#import "MeasureM.h"
#import "DrawableNoteM.h"
#import "NoteM.h"
#import "Constants.h"

@implementation ScoreHeaderM

-(instancetype)initWithTitle:(NSString*) title workNumber:(NSString*)workNumber{
    if ([super init]) {
        _mWorkTitle = title;
        _mWorkNumber = workNumber;
    }
    return self;
}
@end

@implementation ScoreM
#pragma mark lifecycle
-(instancetype)initWithTitle:(NSString *)title  tempo:(NSInteger)tempo parts:(NSArray *)parts{
    if ([super init]) {
        _mParts = parts;
        __weak typeof(self) _weakSelf = self;
        [_mParts enumerateObjectsUsingBlock:^(PartM* part, NSUInteger idx, BOOL * _Nonnull stop) {
            part.mScore = _weakSelf;
        }];
        if (!tempo) {
            tempo = 120;// 默认120
        }
        _mTempo = tempo;
        _mTitle = title;
    }
    return self;
}

-(instancetype)init{
    return nil;
}

-(void)dealloc{
    CILog(@"Score dealloc");
}
#pragma mark -- Public Method

/*
 在乐谱第一个part中找到当前正在播放的measure的下标值measure_index，然后在该乐谱的所有part中寻找拥有相同下标值的小节，然后在这些小节中通过每一个音符所拥有的开始播放时间值，能够获得正在播放的音符，在某一播放时刻，需要标出同一个声部所包含的不同行上正在播放的音符，
 */

-(DrawableNoteM *)getLatestNoteByTicks:(double)currentTick{
    NSInteger selectIndex = -1;
    PartM* firstPart = self.mParts[0];
    for (int measure_index = 0; measure_index < firstPart.mMeasures.count; measure_index ++) {
        MeasureM* measures = firstPart.mMeasures[measure_index];
        if (measure_index == firstPart.mMeasures.count-1) {
            selectIndex = measure_index;
            break;
        }
        MeasureM* nextMeasures = firstPart.mMeasures[measure_index+1];
        if (measures.mStartTime <= currentTick && nextMeasures.mStartTime > currentTick) {
            selectIndex = measure_index;
            break;
        }
    }
    if (selectIndex < 0) {
        return nil;
    }
    double offset = CGFLOAT_MAX;
    DrawableNoteM * select = nil;
    for (NSInteger partIndex = 0; partIndex < self.mParts.count; partIndex++) {
        MeasureM* measure = [self.mParts[partIndex] mMeasures][selectIndex];
        for (DrawableNoteM* note in measure.mMeasureDatas) {
            if (currentTick >= note.mStartTime && currentTick - note.mStartTime < offset ) {
                offset = currentTick - note.mStartTime;
                select = note;
            }
        }
    }
    return select;
}


-(NSMutableArray *)getNotesByStartTime:(double)startTime {
    NSMutableArray *notes = @[].mutableCopy;
    PartM* pianoPart = [self getPianePart];
    MeasureM* select = nil;
    for (int measure_index = 0; measure_index < pianoPart.mMeasures.count; measure_index ++) {
        MeasureM *measures = pianoPart.mMeasures[measure_index];
        if (measure_index == pianoPart.mMeasures.count-1) {
            select = measures;
            break;
        }
        MeasureM *nextMeasures = pianoPart.mMeasures[measure_index+1];
        if (measures.mStartTime <= startTime && nextMeasures.mStartTime > startTime) {
            select = measures;
            break;
        }
    }
    for (DrawableNoteM *note in select.mMeasureDatas) {
        if ([note isKindOfClass:[NoteGroupM class]]) {
            NoteGroupM *noteGroup = (NoteGroupM*)note;
            if (note.mStartTime <= startTime && note.mStartTime + note.mDuration > startTime) {
                
                [notes addObjectsFromArray:[noteGroup notes]];
            }
        }
    }
    return notes;
}
#pragma mark -- Private Method

/**
 获取有效part （钢琴弹奏）

 @return 有效part
 */
-(PartM *)getPianePart {
    for (PartM* part in self.mParts) {
        if (part.mProgram >=1 && part.mProgram <=8) {
            return part;
        }
    }
    return nil;
}

/**
 每行高度 （包括间隙）

 @return 高度
 */
-(NSInteger)mPartLineHeight{
    int staffNum = 0;
    for (PartM *part in self.mParts) {
        staffNum += part.mStavesNum;
    }
    _mPartLineHeight = ((staffNum -1) * PartMarin + staffNum * PartHeight);
    return _mPartLineHeight;
}

/**
 总高度

 @return 总高
 */
-(NSInteger)mTotalHeight{
    return self.mPartLineHeight * self.mLines + PartLineMargin * (self.mLines-1) + Part_Top_Margin * 2;
}

@end
