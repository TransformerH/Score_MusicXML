//
//  CIScoreViewController.h
//  musicXML
//
//  Created by tanhui on 2017/9/15.
//  Copyright © 2017年 tanhuiya. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <musicXML/musicXML.h>

@interface ScoreViewController : UIViewController
-(instancetype)initWithOption:(MidiOption *)option;
@property(nonatomic, assign) BOOL mIsRecording;// 是否演奏模式

/**
 重置乐谱（恢复播放前状态）
 */
-(void)resetSheet;

/**
 播放状态

 @return 当前状态
 */
-(EPlayState)playerState;

/**
 是否播放

 @return Bool
 */
-(BOOL)getPlaying;
@end

