//
//  Log.h
//  Pods
//
//  Created by tanhui on 2017/9/1.
//
//

#import <Foundation/Foundation.h>

@interface Log : NSObject

/**
 清除暂存log
 */
+ (void)clearTempLog ;

/**
 保存log

 @param filename 文件名
 */
+ (void)saveLogFile:(NSString*)filename;

/**
 添加log 信息

 @param midiEventChannel midi通道
 @param midiEventNote note值
 @param midiEventVelocity 速度
 @param tick 时间
 @param remark 文字
 */
+ (void)writefile:(int)midiEventChannel note:(int)midiEventNote velocity:(int)midiEventVelocity tick:(double)tick remark:(NSString*)remark;
@end
