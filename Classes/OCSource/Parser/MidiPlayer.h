//
//  MidiPlayer.h
//  Pods
//
//  Created by tanhui on 2017/8/3.
//
//

#import <Foundation/Foundation.h>
#import "Constants.h"

#import "fmod_errors.h"
#import "fmod_common.h"
#ifdef __cplusplus
class MidiInfo;
#endif
#ifdef __OBJC__
#ifndef __cplusplus
typedef void MidiInfo;
#endif
#endif



@protocol MidiPlayerDelegate <NSObject>

-(void)midiPlayerDelegateIsPlaying:(BOOL)isplaying currentMS:(int)ms totalMS:(int)lenMs;

@end

@interface MidiInfoRetM:NSObject
@property(nonatomic, assign) NSInteger mPrefixBeat;
@property(nonatomic, assign) NSInteger mPrefixBeatType;
@property(nonatomic, assign) NSInteger mTempo;
@end

@interface MidiPlayer : NSObject

@property(nonatomic, weak) id<MidiPlayerDelegate>delegate;

-(instancetype)initWithFile:(NSString*)path;

/**
 准备播放

 @param mode 模式
 @return 播放信息
 */
-(MidiInfo*)prepareToPlay:(CIMidiPlayerMode)mode;
/**
 准备播放
 
 @param tempo 速度
 @param mode 模式
 @return 播放信息
 */
-(MidiInfo*)prepareToPlay:(NSInteger)tempo mode:(CIMidiPlayerMode)mode;

/**
 播放
 */
-(void)play;

/**
 暂停或继续

 @return 是否暂停
 */
-(BOOL)pauseOrResume;

/**
 停止播放
 */
-(void)stop;

// ms per quarter
-(int)getTempoMPQ;

@end
