//
//  ScoreSettingView.h
//  Pods
//
//  Created by tanhui on 2017/9/19.
//
//

#import <UIKit/UIKit.h>
#import "musicXML.h"
@class ScoreViewController;

@interface ScoreSettingView : UIImageView

/**
 设置速度

 @param tempo value
 */
-(void)setTempo:(int)tempo;

/**
 获取速度

 @return 速度
 */
-(int)getTempo;

/**
 设置播放状态

 @param state 状态
 */
-(void)setState:(EPlayState)state;

@property(nonatomic,weak)ScoreViewController* mScoreVC;
@end
