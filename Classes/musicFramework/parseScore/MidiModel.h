//
//  MidiModel.hpp
//  musicxml
//
//  Created by tanhui on 2017/11/7.
//  Copyright © 2017年 ci123. All rights reserved.
//

#ifndef MidiModel_hpp
#define MidiModel_hpp

#include <stdio.h>
#include <vector>
using namespace std;
const int StepMap[7] = {9,11,0,2,4,5,7};

enum CNoteChoice {
    normal_,
    grace,
    rest
};

enum CNotationChoice {
    articulations,
    slur,
    tie,
    none,
};
enum CAriculateChoice {
    staccato
};
enum CLineType {
    start,
    stop
};
class CArticulatePtr {
public :
    CAriculateChoice mChoice;
};
class CSlurPtr {
public :
    CLineType mLineType;
    int mNumber;
};
class CTiePtr {
public :
    CLineType mLineType;
    int mNumber;
};
class CNotationPtr {
public :
    CNotationPtr();
    ~CNotationPtr();
    CNotationChoice mChoice;
    CSlurPtr* mSlur;
    CTiePtr* mTie;
    std::vector<CArticulatePtr*> mArticulates;
};

class CNotePtr {
    int mOctave;
    int mStep;
    int mAlter;
    int mStaff;
    double mDuration;
    int mPartIndex;
    int mMeasureIndex;
    double mStartTime;
    CNoteChoice mChoice;
    
public:
    CNotePtr();
    ~CNotePtr();
    void setValue(int octave, int step, int alter, double duration, int staff, int partIndex, int measureIndex);
    void setStartTime(double startTime);
    void addDuration(double duration);
    void setNoteChoice(CNoteChoice choice);
    double getDuration();
    int getNoteNumber();
    int getPartIndex();
    int getStaff();
    double getStartTime();
    double getEndTime();
    int getMeasureIndex();
    CNoteChoice getChoice();
    
    CNotePtr* mNext;
    bool mShouldIgnore;
    bool mHasJump;// 是否有跳音
    std::vector<CNotationPtr*> mNotationPtrs;
    bool mInCompare;
    bool mInMidi;
};

#endif /* MidiModel_hpp */
