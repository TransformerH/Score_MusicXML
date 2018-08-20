//
//  MeasureAttributeM.h
//  iOSMusic
//
//  Created by tanhui on 2017/7/13.
//  Copyright © 2017年 tanhui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DrawableNoteM.h"

 //??????????????????????????????????????????????
typedef NS_ENUM(NSInteger, EKeyMode) {
    EKeyMode_MAJOR  = 0,
    EKeyMode_MINOR  = 1,
    EKeyMode_DORIAN  = 2,
    EKeyMode_PHRYGIAN  = 3,
    EKeyMode_LYDIAN  = 4,
    EKeyMode_MIXOLYDIAN  = 5,
    EKeyMode_AEOLIAN  = 6,
    EKeyMode_IONIAN  = 7,
    EKeyMode_LOCRIAN  = 8,
    EKeyMode_NONE  = 9,
    EKeyMode_OTHER  = 10
    
};
//??????????????????????????????????????????????

typedef NS_ENUM(NSInteger, EClef) {
    EClef_BASS = 0,
    EClef_TREBLE,
    EClef_None,
};


@interface MeasureTimeM : NSObject
@property(nonatomic, copy) NSNumber *mBeates;
@property(nonatomic, assign) NSNumber * mBeateType;
@end

@interface ClefM : NSObject
@property(nonatomic, assign)EClef mValue;

@end

@interface MeasureKeyM : NSObject

-(instancetype)initWithFifth:(NSNumber*)fifth mode:(EKeyMode)mode;
@end

@interface MeasureAttributeM : DrawableNoteM
@property(nonatomic, strong) MeasureAttributeM* mPrevious;
@property(nonatomic, assign) BOOL mHasTime;
@property(nonatomic, strong) MeasureTimeM *mTime;
@property(nonatomic, assign) BOOL mHasKey;
@property(nonatomic, strong) MeasureKeyM *mKey;
@property(nonatomic, strong) ClefM *mClef;

-(void)drawRectWithoutTime:(CGRect)rect;
@end
