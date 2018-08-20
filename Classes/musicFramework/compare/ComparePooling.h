//
//  ComparePooling.hpp
//  musicXML
//
//  Created by tanhui on 2017/8/24.
//  Copyright © 2017年 tanhui. All rights reserved.
//

#ifndef ComparePooling_hpp
#define ComparePooling_hpp

#include <stdio.h>
#include <iostream>
#include <vector>
#include <cmath>

enum ECNoteResultType{
    ECNoteResultTypeNone = 0,
    ECNoteResultTypeOn,
    ECNoteResultTypeOff,
    ECNoteResultTypeShort,
    ECNoteResultTypeTimeout,
    ECNoteResultTypeError,
    ECNoteResultTypeLost,
};

enum EMidiSignalType{
    EMidiSignalTypeOn = 1,
    EMidiSignalTypeOff,
    
};

class MidiSignal{
public:
    double mTimeStamp;
    int mChannel;
    int mNoteNumber;
    EMidiSignalType mType;
    /**
     * channel 对应staff 双排键{0127->1,34->2,56->3} 钢琴{1->1,2->2}
     * noteNumber 音符对应数字
     * timeStamp 信号的时间(以tick 为单位)
     * type 信号的类型
     */
    MidiSignal(int channel, double timeStamp, int noteNumber, EMidiSignalType type);
private:
    
};

class CNote{
public:
    double mDuration;
    int mPartIndex;
    int mStaffIndex;
    int mNoteNumber;
    int mErrorNumber;
    int mMeasureIndex;
    double mStartTime;
    double mErrorStartTime;
    ECNoteResultType mType;
    /**
     * partIndex 对应part索引
     * staffIndex 对应staff索引
     * measureIndex 对应measure索引
     * noteNumber 音符对应数字
     * startTime 音符的开始时间(以tick 为单位)
     * duration 音符持续时长(以tick为单位)
     */
    CNote(int partIndex,int staffIndex,int measureIndex, int noteNumber,  double startTime, double duration);
    
};


class CResult {
public:
    CResult();
    ~CResult();
    int mTotalNotes;
    
    std::vector<CNote*> mResultNotes;
};

enum EInstrumentMode{
    InstrumentMode_Other = 0,
    InstrumentMode_Piano,
    InstrumentMode_DoubleKey_YMH , //双排键 雅马哈
    InstrumentMode_DoubleKey_YF , //双排键 吟飞
};

class ComparePooling {
public:
    ComparePooling(std::vector<CNote*> notes, double theta);
    ~ComparePooling();
    // 定时调用此方法
    std::vector<CNote*> receiveMidiSignals(std::vector<MidiSignal*> notes, double currentTime);
    CResult* getFinalResult();
    void setMode(EInstrumentMode mode);
    void resetPool();// for development
private:
    CNote* getNearestCNote(MidiSignal* signal) ;
    CNote* getErrorCNote(MidiSignal* signal);
    CNote* getCNoteBy(int channel,int notenumber, int time );
    int getStaffIndexByChannel(int channel);
    
    std::vector<CNote*> mNotes;
    std::vector<MidiSignal*> mTempSignals; // 存放传过来的midi信号，处理完相应node后移除
    double mTheta;
    EInstrumentMode mMode;
};


#endif /* ComparePooling_hpp */


