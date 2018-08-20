//
//  MidiHandler.h
//  musicxml
//
//  Created by tanhui on 2017/7/26.
//  Copyright © 2017年 ci123. All rights reserved.
//

#ifndef MidiHandler_h
#define MidiHandler_h

#include <stdio.h>
#include <queue>
#include <vector>
#include "../compare/ComparePooling.h"
#include "./MidiModel.h"
#include "../mx/core/Elements.h"
#include "../mx/midifile/MidiFile.h"
//#include <MusicFramwork/core/Elements.h>
//#include <MusicFramwork/midifile/MidiFile.h>

#define DurationUnit 32.0
#define CompareTheta 16.0
#define DotNumber 4
#define JumpRate 0.2 // 跳音与正常音的比例

enum MidiPlayerMode {
    MidiPlayerMode_Listen = 0, // 主音轨 无前缀
    MidiPlayerMode_MainWithAccomp, // 主音轨 以及 节拍音轨
    MidiPlayerMode_Accompany //  节拍音轨
};

class MidiPart {
    public :
    
    MidiPart(int staff,int channel, int program ,MidiFile* fileHandler);
    ~MidiPart();
    void addPatches(double ticks);
    
    MidiFile* mFileHandler;
    int mStaffs;// default 1
    int mChannel;
    int mProgram;
    int mStartTrack;
    int mDivision;
};

class MidiInfo {
public:
    MidiInfo();
    int mTempo;
    int mPrefixBeat;
    int mPrefixBeatType;
    MidiPlayerMode mPlayMode;
    ComparePooling* mComparePool;
};

class MidiHandler {
public:
    MidiHandler(string filePath);
    MidiHandler(mx::core::ScorePartwisePtr score);
    void setTempoPercent(double percent);
    void setTempoValue(int tempoValue);
    MidiInfo* save(string path,MidiPlayerMode mode);
    ~MidiHandler();
    int  getTempo();
private:
    void init ();
    void reset () ;
    MidiInfo* getMidiInfo();
    void parse(mx::core::ScorePartwisePtr score,MidiPlayerMode mode);
    void parseScoreHeader(mx::core::ScorePartwisePtr score);
    void parseAttribute(mx::core::ScorePartwisePtr score,bool hasPrefix);
    void parsePartList(mx::core::ScorePartwisePtr score);
    void parseDataChoice(mx::core::MusicDataChoicePtr dataChoice, int partIndex, int measureIndex);
    void parseProperties(mx::core::PropertiesPtr property, int partIndex);
    void parseNote(mx::core::NotePtr note, int partIndex, int measureIndex, bool printObject);
    void addNote(mx::core::NotePtr note,int step ,int octave,int alter, int duration,int staffth, int partIndex, int measureIndex ,std::vector<CNotationPtr*> notations, bool printObject);
    void addRest(int duration,int partIndex, bool printObject);
    void addBackup(int duration,int partIndex);
    void addForward(int duration,int partIndex);
    void addTrack();
    int  getRelativeDuration(int duration,int partIndex) ;
    double  getStandartDuration(int duration,int partIndex) ;
    void addTempo(int track,int tick ,int tempo);
    void addFrontAccompany(int beat,int beatType,int trackIndex);
    void addLeftAccompany(int trackIndex);
    void parseGraceNote(mx::core::NotePtr note,int partIndex, int measureIndex);
    void addPitchBend(int step, int octave, int alter,int staff, int partIndex, int measureIndex);
    void addCnotePtrs();
    void processCNotePtrs();
    void addNoteToMidi();
    std::vector<CNotationPtr*> getNotations(mx::core::Notations* notationChoicePtr) ;
protected:
    MidiFile* mMidifile;
    int mTpq;
    int mTicks ;
    std::vector<MidiPart*> mParts;
    double mTempoPercent;
    // 用户手动设置的
    int mAdjustTempo;
    mx::core::ScorePartwisePtr mScore;
    string mOutputPath;
    int mTempo;
    bool mLoadingAccom;
    int mBeginTicks;// 除去前奏的tempo
    MidiInfo* midiInfo;
    bool mHasTempo;
    int mMeasureSize;
    std::vector<CNote*> mCnotes;
    std::vector<CNotePtr*> mNotePtrs;
    bool mHasPrefixAccom;
    MidiPlayerMode mPlayMode;
    int mLastUnChordDuration;
};

#endif /* MidiHandler_h */

