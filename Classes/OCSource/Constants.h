//
//  Constants.h
//  iOSMusic
//
//  Created by tanhui on 2017/7/12.
//  Copyright © 2017年 tanhui. All rights reserved.
//

#ifndef Constants_h
#define Constants_h

#define Theta 15.0
#define DivisionUnit 32.0

#define Part_Left_Margin 40
#define MeasureAttributeWidth 40
#define Part_Right_Margin 30
#define Part_Top_Margin 80

#define Padding_In_Note 5

#define LineSpace 5.0
#define MIDILineWidth 1.0
#define PartHeight (4*LineSpace+5*MIDILineWidth)
#define NoteHeight (LineSpace+MIDILineWidth)
#define NoteWidth  (3 * LineSpace) / 2.0

#define PaddingInMeasure 8.0
#define Grace_offSet 20.0

#define PartMarin  (PartHeight + 30)

#define ScoreDidReceiveMidiOnNotification @"ScoreDidReceiveMidiOnNotification"
#define ScoreDidReceiveMidiOffNotification @"ScoreDidReceiveMidiOffNotification"

#define kBlueToothStateDidChanged @"kBlueToothStateDidChanged"

#ifdef DEBUG//﻿
#define CILog(format, ...) printf("\n[%s] %s [第%d行] %s\n", __TIME__, __FUNCTION__, __LINE__, [[NSString stringWithFormat:format, ## __VA_ARGS__] UTF8String]);
#else//﻿
#define CILog(...)
#endif


static int PartLineMargin = 60 ; // 换行的行间距

typedef enum : NSUInteger {
    CIMidiPlayerMode_Listen = 0, // 主音轨 无前缀
    CIMidiPlayerMode_MainWithAccompany, // 主音轨 以及 节拍音轨
    CIMidiPlayerMode_Accompany //  节拍音轨
} CIMidiPlayerMode;

#endif /* Constants_h */
