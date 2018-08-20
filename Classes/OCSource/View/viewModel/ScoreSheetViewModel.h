//
//  ScoreSheetViewModel.h
//  CIRouter
//
//  Created by tanhui on 2017/10/12.
//

#import <Foundation/Foundation.h>
#include <sys/time.h>

@interface ScoreSheetViewModel : NSObject
@property(nonatomic,assign,readonly)BOOL isConnected;
@property(nonatomic,assign)long startTime;
@property(nonatomic,assign)long pauseTime;
@property(nonatomic,assign)BOOL isPlaying;

/**
 开始记录
 */
-(void)beginRecording;

/**
 准备记录
 */
-(void)prepareRecording;

/**
 暂停记录
 */
-(void)pause;

/**
 继续记录
 */
-(void)resume;
@end
