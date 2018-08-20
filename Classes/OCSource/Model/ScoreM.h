//
//  ScoreM.h
//  iOSMusic
//
//  Created by tanhui on 2017/7/11.
//  Copyright © 2017年 tanhui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PartM.h"
@class DrawableNoteM;

@interface ScoreHeaderM : NSObject
@property(nonatomic, strong ,readonly) NSString* mWorkTitle;
@property(nonatomic, strong ,readonly) NSString* mWorkNumber;
-(instancetype)initWithTitle:(NSString*) title workNumber:(NSString*)workNumber;
@end

@interface ScoreM : NSObject
@property(nonatomic, strong) NSString* mTitle;
@property(nonatomic, strong) NSArray* mParts;
@property(nonatomic, assign) double mWidth;
@property(nonatomic, assign) NSInteger mLines;
@property(nonatomic, assign) NSInteger mPartLineHeight;
@property(nonatomic, assign) NSInteger mTotalHeight;
@property(nonatomic, assign,readonly) NSInteger mTempo;
-(instancetype)initWithTitle:(NSString *)title tempo:(NSInteger)tempo parts:(NSArray *)parts;

/**
 通过时间获取最近的 音符

 @param currentTick 当前时间
 @return 音符
 */
-(DrawableNoteM *)getLatestNoteByTicks:(double)currentTick ;
/**
 通过时间获取当前的 音符集合
 
 @param currentTick 当前时间
 @return 音符集合
 */
-(NSMutableArray *)getNotesByStartTime:(double)startTime ;
@end
