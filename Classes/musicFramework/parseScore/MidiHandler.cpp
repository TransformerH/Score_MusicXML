//
//  MidiHandler.cpp
//  musicxml
//
//  Created by tanhui on 2017/7/26.
//  Copyright © 2017年 ci123. All rights reserved.
//

#include "MidiHandler.h"
#include <stdlib.h>
#include <iostream>
#include "../mx/xml/XDoc.h"
#include "../mx/xml/XFactory.h"
#include "../mx/core/Document.h"

using namespace mx::core;
using namespace std;


#pragma mark MidiPart
MidiPart::MidiPart(int staff,int channel, int program,MidiFile* handler){
    this->mStaffs = staff;
    this->mChannel = channel;
    this->mProgram = program;
    this->mFileHandler = handler;
    this->mDivision = 0;
}

void MidiPart::addPatches(double ticks) {
    for (int index = 1; index <= this->mStaffs; index++) {
        this->mFileHandler->addPatchChange(this->mStartTrack+index, ticks, this->mChannel, this->mProgram);
    }
}

MidiPart:: ~MidiPart(){
}
#pragma mark MidiInfo
MidiInfo::MidiInfo(){
    this->mPrefixBeat = 0;
    this->mPrefixBeatType = 0 ;
    this->mTempo = 0;
    this->mPlayMode = MidiPlayerMode_Listen;
}




#pragma mark MidiHandler
MidiHandler::MidiHandler(string filePath) {
    this->init();
    mx::core::DocumentPtr mxDoc = mx::core::makeDocument();
    mx::xml::XDocPtr xmlDoc = mx::xml::XFactory::makeXDoc();
    // read a MusicXML file into the XML DOM structure
    xmlDoc->loadFile( filePath );
    // create an ostream to receive any parsing messages
    std::stringstream parseMessages;
    // convert the XML DOM into MusicXML Classes
    bool isSuccess = mxDoc->fromXDoc( parseMessages, *xmlDoc );
    if( !isSuccess )
    {
        std::cout << "Parsing of the MusicXML document failed with the following message(s):" << std::endl;
        std::cout << parseMessages.str() << std::endl;
    }
    // maybe the document was timewise document. if so, convert it to partwise
    if( mxDoc->getChoice() == mx::core::DocumentChoice::timewise )
    {
        mxDoc->convertContents();
    }
    // get the root
    auto scorePartwise = mxDoc->getScorePartwise();
    this->mScore = scorePartwise;
}

MidiHandler::MidiHandler(mx::core::ScorePartwisePtr score) {
    this->init();
    this->mScore = score;
}

void MidiHandler::init() {
    this->mMidifile = new MidiFile();
    this->mTicks = 0;
    this->mTpq = 480;
    this->mMidifile->absoluteTicks();
    this->mMidifile->setTicksPerQuarterNote(this->mTpq);
    this->mTempoPercent = 1.0;
    this->mTempo = 120;
    this->mAdjustTempo = 0;
    this->mLoadingAccom = false;
    this->mBeginTicks = 0;
    this->mHasTempo = false;
    this->midiInfo = new MidiInfo();
    this->mHasPrefixAccom = false;
    this->mLastUnChordDuration = 0;
}

void MidiHandler::setTempoPercent(double percent){
    if (percent > 1.0 || percent <=0 ){
        return;
    }
    this->mTempoPercent = percent;
}

void MidiHandler::setTempoValue(int tempoValue){
    if (tempoValue >= 30 && tempoValue <= 120 ){
        this->mAdjustTempo = tempoValue;
        this->mTempo = tempoValue;
    }
}

MidiInfo* MidiHandler::save(string path,MidiPlayerMode mode){
    this->mPlayMode = mode;
    this->mMidifile->clear();
    this->parse(this->mScore,mode);
    this->processCNotePtrs();// 解析notes
    this->addNoteToMidi();
    this->addCnotePtrs();
    this->mMidifile->sortTracks();
    this->mMidifile->write(path);
    return this->getMidiInfo();
}

MidiInfo* MidiHandler::getMidiInfo() {
    MidiInfo* info = new MidiInfo();
    info->mTempo = this->getTempo();
    info->mPlayMode = this->mPlayMode;
    info->mPrefixBeat = this->midiInfo->mPrefixBeat;
    info->mPrefixBeatType = this->midiInfo->mPrefixBeatType;
    info->mComparePool = new ComparePooling(this->mCnotes, CompareTheta);
    return info;
}

void MidiHandler::reset () {
    this->mTicks = this->mBeginTicks;
}

/* add midi track */
void MidiHandler::addTrack() {
    this->mMidifile->addTracks(1);
}

void MidiHandler::parse(mx::core::ScorePartwisePtr scorePartwise,MidiPlayerMode mode){
    this->parseScoreHeader(scorePartwise);
    
    if(MidiPlayerMode_MainWithAccomp == mode ||
       MidiPlayerMode_Accompany == mode){
        this->addFrontAccompany(0, 0, 0);
        this->addLeftAccompany(0);
    }
    
    this->parsePartList(scorePartwise);
    this->addTempo(0,0,this->mTempo);
}


void MidiHandler::parseScoreHeader(mx::core::ScorePartwisePtr scorePartwise){
    // Add another one track to the MIDI file
    auto workTitle = scorePartwise->getScoreHeaderGroup()->getWork()->getWorkTitle()->getValue().getValue();
    this->mMidifile->setFilename(workTitle);
    
    this->addTrack();
    // 添加第一个part
    auto partlist = scorePartwise->getScoreHeaderGroup()->getPartList();
    auto name = partlist->getScorePart()->getPartName()->getValue().getValue();
    auto partid = partlist->getScorePart()->getAttributes()->id.getValue();
    int channel = 1;
    if (partlist->getScorePart()->getMidiDeviceInstrumentGroupSet().size()) {
        auto instrument = *(partlist->getScorePart()->getMidiDeviceInstrumentGroupSet().rbegin());
        if (instrument->getHasMidiInstrument()) {
            channel = instrument->getMidiInstrument()->getMidiChannel()->getValue().getValue();
            auto program = instrument->getMidiInstrument()->getMidiProgram()->getValue().getValue();
            this->mParts.push_back(new MidiPart(1,channel,program,this->mMidifile));
        }
    }else if(partlist->getScorePart()->getScoreInstrumentSet().size()){
        this->mParts.push_back(new MidiPart(1,1,1,this->mMidifile));
    }
    
    // 添加剩余part
    for (auto partname_it = partlist->getPartGroupOrScorePartSet().rbegin(); partname_it != partlist->getPartGroupOrScorePartSet().rend(); partname_it++) {
        this->addTrack();
        auto choice = (*partname_it)->getChoice();
        if (choice == PartGroupOrScorePart::Choice::partGroup) {
        }else if(choice == PartGroupOrScorePart::Choice::scorePart){
            int program = 1;
            if ((*partname_it)->getScorePart()->getMidiDeviceInstrumentGroupSet().size()) {
                auto instrument2 = *((*partname_it)->getScorePart()->getMidiDeviceInstrumentGroupSet().rbegin());
                channel = instrument2->getMidiInstrument()->getMidiChannel()->getValue().getValue();
                program = instrument2->getMidiInstrument()->getMidiProgram()->getValue().getValue();
            }else{
                channel++;
            }
            this->mParts.push_back(new MidiPart(1,channel,program,this->mMidifile));
        }
    }
    int partIndex = 0 ;
    
    auto firstpart = *(scorePartwise->getPartwisePartSet().cbegin());
    
    this->mMeasureSize = (int)firstpart->getPartwiseMeasureSet().size();
    for (auto part_it = scorePartwise->getPartwisePartSet().cbegin(); part_it != scorePartwise->getPartwisePartSet().cend(); partIndex++, part_it++) {
        auto partwise = (*part_it);
        MidiPart* part = this->mParts[partIndex];
        for (auto measure_it = partwise->getPartwiseMeasureSet().cbegin();measure_it != partwise->getPartwiseMeasureSet().cend(); measure_it++) {
            MusicDataChoiceSet groupSetPtr = (*measure_it)->getMusicDataGroup()->getMusicDataChoiceSet();
            for (auto choice_it = groupSetPtr.cbegin() ; choice_it != groupSetPtr.cend() ; choice_it ++) {
                auto dataChoice = *choice_it;
                auto choiceType = dataChoice->getChoice();
                if (choiceType == MusicDataChoice::Choice::properties) {
                    auto property = dataChoice->getProperties();
                    if (property->getHasDivisions()){
                        // 暂不处理 使用 默认的 120
                        auto divisions = property->getDivisions()->getValue().getValue();
                        part->mDivision = (int)divisions;
                    }
                    if (property->getHasStaves()) {
                        auto staff = property->getStaves()->getValue().getValue();
                        // 判断staff
                        if (staff > 1) {
                            part->mStaffs = staff;
                            this->addTrack();
                        }
                    }
                    if (property->getTimeSet().size()){
                        TimePtr time  = *(property->getTimeSet().cbegin());
                        TimeChoice::Choice choice = time->getTimeChoice()->getChoice();
                        if (!(int)choice && this->midiInfo->mPrefixBeat == 0){
                            TimeSignatureGroupPtr timeSignaturePtr = *(time->getTimeChoice()->getTimeSignatureGroupSet().cbegin());
                            std::string beats = timeSignaturePtr->getBeats()->getValue().getValue();
                            std::string beat_types = timeSignaturePtr->getBeatType()->getValue().getValue();
                            int beat = atoi(beats.c_str());
                            int beatType = atoi(beat_types.c_str());
                            this->midiInfo->mPrefixBeat = beat;
                            this->midiInfo->mPrefixBeatType = beatType;
                        }
                    }
                }
            }
        }
        int track =  0 ;
        if (partIndex != 0) {
            MidiPart* prePart = this->mParts[partIndex-1];
            track += prePart->mStaffs;
        }
        part->mStartTrack = track;
        part->addPatches(0);
    }
}

void MidiHandler::addFrontAccompany(int beat,int beatType,int trackIndex){
    
    int tick = 0;
//    double step = 4/this->midiInfo->mPrefixBeatType * this->mTpq;
    double step = this->mTpq;
    this->mMidifile->addPatchChange(0, 0, 0, 114);
//    for (int i = 0;i < this->midiInfo->mPrefixBeat ;i++){
    for (int i = 0;i < DotNumber ;i++){
        this->mMidifile->addNoteOn(trackIndex, tick, 0, 64, 90);
        tick += step;
        this->mMidifile->addNoteOff(trackIndex, tick-1, 0, 64, 90);
    }
    //保存前奏的ticks 时长
    this->mHasPrefixAccom = true;
    this->mBeginTicks = tick;
}


void MidiHandler::addLeftAccompany(int trackIndex){
    int tick = this->mBeginTicks;
    double step = 4/this->midiInfo->mPrefixBeatType * this->mTpq;
    double totalTick = this->mMeasureSize * step * this->midiInfo->mPrefixBeat  + tick;
    while (tick < totalTick){
        this->mMidifile->addNoteOn(trackIndex, tick, 0, 64, 90);
        tick += step;
        this->mMidifile->addNoteOff(trackIndex, tick-1, 0, 64, 90);
    }
}

/* parse score parts */
void MidiHandler::parsePartList(mx::core::ScorePartwisePtr scorePartwise){
    int partIndex = 0;
    for (auto part_it = scorePartwise->getPartwisePartSet().cbegin(); part_it != scorePartwise->getPartwisePartSet().cend(); partIndex++, part_it++) {
        this->reset();
        auto partwise = (*part_it);
        int measureIndex = 0;
        for (auto measure_it = partwise->getPartwiseMeasureSet().cbegin();measure_it != partwise->getPartwiseMeasureSet().cend(); measure_it++,measureIndex++) {
            MusicDataChoiceSet groupSetPtr = (*measure_it)->getMusicDataGroup()->getMusicDataChoiceSet();
            for (auto choice_it = groupSetPtr.cbegin() ; choice_it != groupSetPtr.cend() ; choice_it ++) {
                this->parseDataChoice(*choice_it,partIndex,measureIndex);
            }
        }
    }
}

/* parse measure data */
void MidiHandler::parseDataChoice(MusicDataChoicePtr dataChoice, int partIndex, int measureIndex){
    auto choiceType = dataChoice->getChoice();
    MidiPart* part = this->mParts[partIndex];
    
    if (choiceType == MusicDataChoice::Choice::properties) {
        auto choiceMeasureAttr = dataChoice->getProperties();
        this->parseProperties(choiceMeasureAttr,partIndex);
    }else if (choiceType == MusicDataChoice::Choice::note) {
        auto choiceNote = dataChoice->getNote();
        auto normalChoice =  choiceNote->getNoteChoice()->getChoice();
        bool printObject = true;
        if (choiceNote->getAttributes()->hasPrintObject &&
            choiceNote->getAttributes()->printObject == YesNo::no){
            printObject = false;
        }
        // 过滤 grace cur
        if (normalChoice == NoteChoice::Choice::normal){
            this->parseNote(choiceNote, partIndex, measureIndex,printObject);
        } else if (normalChoice == NoteChoice::Choice::grace) {
            this->parseGraceNote(choiceNote, partIndex, measureIndex);
        }
    }else if (choiceType == MusicDataChoice::Choice::forward) {
        auto duration = dataChoice->getForward()->getDuration()->getValue().getValue();
        this->addForward(duration,partIndex);
    }else if (choiceType == MusicDataChoice::Choice::backup) {
        int duration = dataChoice->getBackup()->getDuration()->getValue().getValue();
        this->addBackup(duration,partIndex);
    }else if (choiceType == MusicDataChoice::Choice::sound) {
        if (dataChoice->getSound()->getAttributes()->hasTempo) {
            auto tempo = dataChoice->getSound()->getAttributes()->tempo.getValue();
            this->addTempo(part->mStartTrack,0,tempo);
        }
    }else if (choiceType == MusicDataChoice::Choice::direction) {
        if (dataChoice->getDirection()->getSound()->getAttributes()->hasTempo) {
            auto tempo = dataChoice->getDirection()->getSound()->getAttributes()->tempo.getValue();
            this->addTempo(part->mStartTrack,0,tempo);
        }
    }
}

void MidiHandler::parseGraceNote(mx::core::NotePtr notePtr,int partIndex, int measureIndex) {
    auto grace = notePtr->getNoteChoice()->getGraceNoteGroup();
    if (grace->getFullNoteGroup()->getFullNoteTypeChoice()->getChoice() == FullNoteTypeChoice::Choice::pitch) {
        auto pitch = grace->getFullNoteGroup()->getFullNoteTypeChoice()->getPitch();
        auto step = pitch->getStep()->getValue();
        auto octave = pitch->getOctave()->getValue().getValue();
        auto staff = notePtr->getHasStaff()? notePtr->getStaff()->getValue().getValue() : 1;
        int alter = pitch->getHasAlter() ? pitch->getAlter()->getValue().getValue() : 0;
        this->addPitchBend((int)step, octave, alter, staff, partIndex, measureIndex);
    }
}

/* parse note or rest */
void MidiHandler::parseNote(mx::core::NotePtr note, int partIndex, int measureIndex, bool printObject) {
    auto noteTypeChoice =  note->getNoteChoice()->getNormalNoteGroup()->getFullNoteGroup()->getFullNoteTypeChoice()->getChoice();
    
    auto duration = note->getNoteChoice()->getNormalNoteGroup()->getDuration()->getValue().getValue();
    if (noteTypeChoice == FullNoteTypeChoice::Choice::pitch){
        auto pitch = note->getNoteChoice()->getNormalNoteGroup()->getFullNoteGroup()->getFullNoteTypeChoice()->getPitch();
        auto step = pitch->getStep()->getValue();
        auto actave = pitch->getOctave()->getValue().getValue();
        auto alter = pitch->getHasAlter()? pitch->getAlter()->getValue().getValue() : 0;
        auto staffth = note->getHasStaff()? note->getStaff()->getValue().getValue() : 1;

        if (note->getNoteChoice()->getNormalNoteGroup()->getFullNoteGroup()->getHasChord()) {
            // 如果是chord ，将偏移量减回来
            duration = this->mLastUnChordDuration;
            this->mTicks -= this->getRelativeDuration(duration,partIndex);
        } else {
            this->mLastUnChordDuration = duration;
        }
        vector<CNotationPtr*> notations;
        if (note->getNotationsSet().size() > 0) {
            for (auto notation_it = note->getNotationsSet().cbegin(); notation_it != note->getNotationsSet().cend(); notation_it++) {
                notations =  this->getNotations(notation_it->get());
            }
        }
        this->addNote(note,(int)step ,actave,alter,(int)duration,staffth,partIndex,measureIndex,notations,printObject);
    }else if(noteTypeChoice == FullNoteTypeChoice::Choice::rest){
        this->addRest(duration,partIndex,printObject);
    }
}

vector<CNotationPtr*> MidiHandler::getNotations (Notations* notation) {
    vector<CNotationPtr*> notationPtrs;
    for (auto notationChoice_it = notation->getNotationsChoiceSet().cbegin();notationChoice_it != notation->getNotationsChoiceSet().cend(); notationChoice_it++ ) {
        CNotationPtr* notePtr = new CNotationPtr();
        if ((*notationChoice_it)->getChoice() == NotationsChoice::Choice::slur){
            notePtr->mChoice = CNotationChoice::slur;
            CSlurPtr* slurPtr = new CSlurPtr();
            auto slur = (*notationChoice_it)->getSlur();
            if (slur->getAttributes()->type == StartStopContinue::start ){
                slurPtr->mLineType = CLineType::start;
            }else if(slur->getAttributes()->type == StartStopContinue::stop) {
                slurPtr->mLineType = CLineType::stop;
            }
            slurPtr->mNumber = slur->getAttributes()->number.getValue();
            notePtr->mSlur = slurPtr;
        }else if ((*notationChoice_it)->getChoice() == NotationsChoice::Choice::tied) {
            notePtr->mChoice = CNotationChoice::tie;
            CTiePtr* tiePtr = new CTiePtr();
            auto tie = (*notationChoice_it)->getTied();
            if (tie->getAttributes()->type == StartStopContinue::start) {
                tiePtr->mLineType = CLineType::start;
            } else if (tie->getAttributes()->type == StartStopContinue::stop) {
                tiePtr->mLineType = CLineType::stop;
            }
            tiePtr->mNumber = tie->getAttributes()->number.getValue();
            notePtr->mTie = tiePtr;
        }else if ((*notationChoice_it)->getChoice() == NotationsChoice::Choice::articulations) {
            notePtr->mChoice = CNotationChoice::articulations;
            vector<CArticulatePtr*>articulatePtrs;
            auto articulateSet = (*notationChoice_it)->getArticulations()->getArticulationsChoiceSet();
            if (articulateSet.size() > 0) {
                for (auto arti_iter = articulateSet.cbegin(); arti_iter != articulateSet.cend(); arti_iter++ ) {
                    CArticulatePtr* ptr = new CArticulatePtr();
                    if ((*arti_iter)->getChoice() == ArticulationsChoice::Choice::staccato) {
                        ptr->mChoice = CAriculateChoice::staccato;
                    }
                    articulatePtrs.push_back(ptr);
                }
            }
            notePtr->mArticulates = articulatePtrs;
        }
        notationPtrs.push_back(notePtr);
    }
    return notationPtrs;
}

/* parse attributes */
void MidiHandler::parseProperties(mx::core::PropertiesPtr property, int partIndex) {

    MidiPart* part = this->mParts[partIndex];
    if (property->getTimeSet().size()){
        TimePtr time  = *(property->getTimeSet().cbegin());
        TimeChoice::Choice choice = time->getTimeChoice()->getChoice();
        if (!(int)choice){
            TimeSignatureGroupPtr timeSignaturePtr = *(time->getTimeChoice()->getTimeSignatureGroupSet().cbegin());
            std::string beats = timeSignaturePtr->getBeats()->getValue().getValue();
            std::string beat_types = timeSignaturePtr->getBeatType()->getValue().getValue();
            this->mMidifile->addTimeSignature(part->mStartTrack, this->mTicks, atoi(beats.c_str()),atoi(beat_types.c_str()));
        }
    }
}

void MidiHandler::addTempo(int track,int tick ,int tempo) {
    this->mHasTempo = true;
    if (!this->mAdjustTempo){
        this->mTempo = tempo;
    }else{
        // 如果用户手动设置速度，速度则不改变
        this->mTempo = this->mAdjustTempo;
    }
    this->mMidifile->addTempo(track, tick, this->getTempo());
}

void MidiHandler::addPitchBend(int step, int octave, int alter,int staffth, int partIndex, int measureIndex){
    CNotePtr* ptr = new CNotePtr();
//    ptr->setValue(octave, step, alter, 1, staffth, partIndex, measureIndex);
//    ptr->setNoteChoice(CNoteChoice::grace);
//    ptr->setStartTime(this->mTicks);
//    this->mNotePtrs.push_back(ptr);
    ptr->setNoteChoice(CNoteChoice::normal_);
    int relateDivision = this->getRelativeDuration(4,partIndex);
    ptr->setValue(octave, step, alter, relateDivision, staffth, partIndex, measureIndex);
    ptr->setStartTime(this->mTicks );
    this->mNotePtrs.push_back(ptr);
}

/* add real note */
void MidiHandler::addNote(mx::core::NotePtr noteChoice, int step ,int octave,int alter, int duration, int staffth ,int partIndex, int measureIndex, vector<CNotationPtr*> notations, bool printObject) {
    CNotePtr* ptr = new CNotePtr();
    ptr->mNotationPtrs = notations;
    ptr->setNoteChoice(CNoteChoice::normal_);
    int relateDivision = this->getRelativeDuration(duration,partIndex);
    ptr->setValue(octave, step, alter, relateDivision, staffth, partIndex, measureIndex);
    ptr->setStartTime(this->mTicks );
    if(noteChoice->getHasNotehead()){
        auto headType= noteChoice->getNotehead()->getValue();
        if (headType == mx::core::NoteheadValue::x){
            ptr->mInCompare = false;
        }
    }
    if (!printObject){
        ptr->mInCompare = false;
    }
    this->mNotePtrs.push_back(ptr);
    this->mTicks += relateDivision;
}
/* add real rest */
void MidiHandler::addRest(int duration,int partIndex, bool printObject){
    int relativeDuration = this->getRelativeDuration(duration,partIndex);
    this->mTicks += relativeDuration;
}
/* decrease duration */
void MidiHandler::addBackup(int duration,int partIndex) {
    int relativeDuration = this->getRelativeDuration(duration,partIndex);
    this->mTicks -= relativeDuration;
}

/* forward duration */
void MidiHandler::addForward(int duration,int partIndex) {
    int relativeDuration = this->getRelativeDuration(duration,partIndex);
    this->mTicks += relativeDuration;
}
// 添加节点到midifile
/*
 遍历乐谱所有的音符演奏信息数据模型(CNotePtr)实例，通过实例可获得该音符所在音部的下标，之后可获得所在音部的开始音轨, 音符所在的音轨可以通过开始音轨和该音符所在的该音部的行数之和得到。 在
 */

void MidiHandler::addNoteToMidi(){
    if (this->mPlayMode == MidiPlayerMode_Accompany){
        return;
    }
    for (auto cnotePtr_iter = this->mNotePtrs.cbegin(); cnotePtr_iter != this->mNotePtrs.cend(); cnotePtr_iter++) {
        CNotePtr* ptr = *cnotePtr_iter;
        if (ptr->mShouldIgnore || !ptr->mInMidi)continue;
        MidiPart* part = this->mParts[ptr->getPartIndex()];
        int trackNum = part->mStartTrack + ptr->getStaff();
        if (ptr->getChoice() == CNoteChoice::normal_) {
            this->mMidifile->addNoteOn(trackNum, ptr->getStartTime(), part->mChannel, ptr->getNoteNumber(), 90);
            double endTime = ptr->mHasJump ? ptr->getStartTime()+(ptr->getDuration() * JumpRate) : ptr->getEndTime();
            this->mMidifile->addNoteOff(trackNum, endTime, part->mChannel, ptr->getNoteNumber(), 90);
        } else {
            this->mMidifile->addPitchBend(trackNum, ptr->getStartTime(), part->mChannel, ptr->getNoteNumber());
        }
    }
}

void MidiHandler::addCnotePtrs() {
    for (auto cnotePtr_iter = this->mNotePtrs.cbegin(); cnotePtr_iter != this->mNotePtrs.cend(); cnotePtr_iter++) {
        CNotePtr* ptr = *cnotePtr_iter;
        if (ptr->mShouldIgnore || !ptr->mInCompare)continue;
        MidiPart* part = this->mParts[ptr->getPartIndex()];
        int staffNum = part->mStartTrack + ptr->getStaff();
        double transTick = ptr->getStartTime() / (double)this->mTpq * DurationUnit;
        double compareDuration = this->getStandartDuration(ptr->getDuration(),ptr->getPartIndex()) ;
        if (ptr->mHasJump){
            compareDuration = compareDuration * JumpRate;
        }
        if (part->mProgram <= 8 && part->mProgram > 0){
            CNote* note = new CNote(ptr->getPartIndex(),staffNum, ptr->getMeasureIndex(), ptr->getNoteNumber(), this->mHasPrefixAccom ? transTick - DotNumber * DurationUnit : transTick , compareDuration);
            this->mCnotes.push_back(note);
        }
    }
}

void MidiHandler::processCNotePtrs() {
    for (int i = 0 ;i < this->mNotePtrs.size();i++){
        auto notePtr = this->mNotePtrs[i];
        if (notePtr->mNotationPtrs.size() < 1) {
            continue;
        }
        for (auto notation_iter = notePtr->mNotationPtrs.begin();notation_iter != notePtr->mNotationPtrs.end() ; notation_iter++) {
            auto notationPtr = *notation_iter;
            if (notationPtr->mChoice == CNotationChoice::slur &&
                notationPtr->mSlur != NULL &&
                notationPtr->mSlur->mLineType == CLineType::start ){
                bool isPaired = false;
                for (int j = i+1; j < this->mNotePtrs.size(); j++) {
                    auto nextNotePtr = this->mNotePtrs[j];
                    for (auto next_notation_iter = nextNotePtr->mNotationPtrs.begin();next_notation_iter != nextNotePtr->mNotationPtrs.end() ; next_notation_iter++) {
                        auto nextNotationPtr = *next_notation_iter;
                        if (nextNotationPtr->mChoice == notationPtr->mChoice &&
                            nextNotationPtr->mSlur != NULL &&
                            nextNotationPtr->mSlur->mLineType == CLineType::stop &&
                            nextNotationPtr->mSlur->mNumber == notationPtr->mSlur->mNumber) {
                            // 找到对应slur
                            if(notePtr->getNoteNumber() == nextNotePtr->getNoteNumber()){
                                notePtr->mNext = nextNotePtr;
                            }
                            isPaired = true;
                            break;
                        }
                    }
                    if (isPaired) {
                        break;
                    }
                }
            }else if (notationPtr->mChoice == CNotationChoice::tie &&
                notationPtr->mTie != NULL &&
                notationPtr->mTie->mLineType == CLineType::start ){
                bool isPaired = false;
                for (int j = i+1; j < this->mNotePtrs.size(); j++) {
                    auto nextNotePtr = this->mNotePtrs[j];
                    for (auto next_notation_iter = nextNotePtr->mNotationPtrs.begin();next_notation_iter != nextNotePtr->mNotationPtrs.end() ; next_notation_iter++) {
                        auto nextNotationPtr = *next_notation_iter;
                        if (nextNotationPtr->mChoice == notationPtr->mChoice &&
                            nextNotationPtr->mTie != NULL &&
                            nextNotationPtr->mTie->mLineType == CLineType::stop &&
                            nextNotationPtr->mTie->mNumber == notationPtr->mTie->mNumber) {
                            // 找到对应  Tie
                            if (notePtr->getNoteNumber() == nextNotePtr->getNoteNumber()) {
                                notePtr->mNext = nextNotePtr;
                            }
                            isPaired = true;
                            break;
                        }
                    }
                    if (isPaired) {
                        break;
                    }
                }
            }else if (notationPtr->mChoice == CNotationChoice::articulations){
                auto articulations = notationPtr->mArticulates;
                for (auto articu_iter = articulations.begin(); articu_iter != articulations.end(); articu_iter++) {
                    if ((*articu_iter)->mChoice == CAriculateChoice::staccato){
                        notePtr->mHasJump = true;
                    }
                }
            }
        }
    }
    
    for (auto note_iter = this->mNotePtrs.begin(); note_iter != this->mNotePtrs.end(); note_iter++) {
        auto notePtr = (*note_iter), original = notePtr;
        auto temp_iter = note_iter;
        if (notePtr->mShouldIgnore)continue;
        while (notePtr->mNext != NULL ) {
            for (auto next_note_iter = temp_iter + 1; next_note_iter != this->mNotePtrs.end(); next_note_iter++) {
                auto nextNotePtr = (*next_note_iter);
                original->addDuration(nextNotePtr->getDuration());
                temp_iter++;
                if (notePtr->mNext == nextNotePtr) {
                    nextNotePtr->mShouldIgnore = true;
                    notePtr = nextNotePtr;
                    break;
                }
            }
        }
    }
}
/* 根据比例放大duration */
int MidiHandler::getRelativeDuration(int duration,int partIndex) {
    MidiPart* part = this->mParts[partIndex];
    return  double(this->mTpq)/double(part->mDivision) * duration;
}
/* 根据unitdurantion 获取标准duration */
double MidiHandler::getStandartDuration(int duration,int partIndex) {
    MidiPart* part = this->mParts[partIndex];
    return  duration/double(this->mTpq) * DurationUnit;
}

int MidiHandler::getTempo(){
    return this->mTempo * this->mTempoPercent;
}

MidiHandler::~MidiHandler () {
    if (this->midiInfo != NULL){
        delete this->midiInfo;
    }
    delete this->mMidifile;
    for(vector<MidiPart *>::iterator it = this->mParts.begin(); it != this->mParts.end(); it ++){
        if (NULL != *it) {
            delete *it;
            *it = NULL;
        }
    }
    this->mParts.clear();
    for(vector<CNotePtr *>::iterator it = this->mNotePtrs.begin(); it != this->mNotePtrs.end(); it ++){
        if (NULL != *it) {
            delete *it;
            *it = NULL;
        }
    }
}

