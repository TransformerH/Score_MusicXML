//
//  DrawableProtocol.h
//  iOSMusic
//
//  Created by tanhui on 2017/7/12.
//  Copyright © 2017年 tanhui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class NoteGroupM;
@protocol DrawableProtocol <NSObject>

/**
 绘制

 @param rect
 */
-(void)drawRect:(CGRect)rect;

@optional

/**
 绘制宽度

 @return double
 */
-(double)drawWidth;

/**
 在某个音符中绘制

 @param note 音符
 */
-(void)drawInNote:(NoteGroupM*)note;

@end
