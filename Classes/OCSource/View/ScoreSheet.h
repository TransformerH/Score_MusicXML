//
//  ScoreSheet.h
//  iOSMusic
//
//  Created by tanhui on 2017/7/11.
//  Copyright © 2017年 tanhui. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MidiPlayer.h"
#import "ScoreSheetViewModel.h"
#import "ResultOutlineModel.h"
#import "MidiOption.h"

#ifdef __cplusplus
class ComparePooling;
#endif

//declare obj-c impl
#ifdef __OBJC__
#ifndef __cplusplus
typedef void ComparePooling;
#endif
#endif

typedef enum : NSUInteger {
    EPlayStateNone,
    EPlayStatePlaying,
    EPlayState_Pause,
    EPlayState_Stop,
} EPlayState;

@class ScoreM;

@interface MidiResult : NSObject
@property(nonatomic, assign) NSInteger totalNotes;
@end



@protocol ShowResultDelegate <NSObject>

/**
 是否正在 录制
 @return Bool
 */
-(BOOL)playerIsRecording;

/**
 结束播放（录制）

 @param result 录制结果
 */
-(void)playerDidFinishWithResult:(MidiResult*)result;

/**
 结束状态

 @return 当前状态
 */
-(EPlayState)playerState;

/**
 停止播放
 */
-(void)stop;

/**
 获取演奏模式

 @return 演奏模式
 */
-(CIMidiPlayerMode)getMidiPlayMode;

/**
 播放进度

 @param ms 当前毫秒
 @param totalms 总毫秒
 */
-(void)playerDidPlayAt:(int)ms total:(int)totalms;

/**
 重置乐谱
 */
-(void)resetSheet;

/**
 获取速度 （tempo）

 @return fd
 */
-(NSInteger)getTempo ;
@end


@interface ScoreSheet : UIView
@property(nonatomic, weak) MidiOption* mOption;// 乐谱参数
@property(nonatomic, weak) id<ShowResultDelegate> resultDelegate;// 弹奏结果
@property(nonatomic, strong) MidiPlayer* mPlayer;// Midi播放器
@property(nonatomic, assign)double midiSecondOffset;// 播放的偏移量
@property(nonatomic, strong) ScoreSheetViewModel* mScoreSheetViewModel;

/**
 设置乐谱比较的对象

 @param pool 比较池
 */
-(void)setPool:(ComparePooling*)pool;

/**
 初始化方法

 @param frame frame
 @param score 乐谱对象
 @return self
 */
-(instancetype)initWithFrame:(CGRect)frame score:(ScoreM*)score;

/**
 显示结果
 */
-(void)showResults;

/**
 准备录制
 */
-(void)prepareRecording;


/**
 开始录制
 */
-(void)beginRecording;

/**
 停止录制
 */
-(void)stopRecording;

/**
 继续录制
 */
-(void)resumeRecording;

/**
 重置
 */
-(void)reset;

/**
 清除结果显示
 */
-(void)clearResult;

/**
 显示结果详情
 */
-(void)showDetailResult;
@end
