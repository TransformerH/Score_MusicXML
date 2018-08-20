//
//  xml_midiFile.h
//  iOSMusic
//
//  Created by tanhui on 2017/7/10.
//  Copyright © 2017年 tanhui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScoreM.h"
@class MidiOption;
@class MeasureTimeM;

@interface xml_midiFile : NSObject

@property(nonatomic, strong) ScoreM* mScore;

/**
 初始化方法

 @param option 播放信息
 @param size 乐谱页面大小
 @return instance
 */
-(instancetype)initWithOption:(MidiOption*)option sheetSize:(CGSize)size;

@end
