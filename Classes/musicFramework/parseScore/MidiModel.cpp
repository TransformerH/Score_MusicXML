//
//  MidiModel.cpp
//  musicxml
//
//  Created by tanhui on 2017/11/7.
//  Copyright © 2017年 ci123. All rights reserved.
//

#include "MidiModel.h"
#include <cmath>

extern const int StepMap[7];
CNotationPtr::CNotationPtr() {
    this->mSlur = NULL;
    this->mTie = NULL;
    this->mArticulates = std::vector<CArticulatePtr*>();
    this->mChoice = none;
}

CNotationPtr::~CNotationPtr() {
    if (this->mChoice == CNotationChoice::slur) {
        delete this->mSlur;
        this->mSlur = NULL;
    }
    if (this->mChoice == CNotationChoice::tie) {
        delete this->mTie;
        this->mSlur = NULL;
    }
    if (this->mChoice == CNotationChoice::articulations) {
        for(vector<CArticulatePtr *>::iterator it = this->mArticulates.begin(); it != this->mArticulates.end(); it ++){
            if (NULL != *it) {
                delete *it;
                *it = NULL;
            }
        }
    }
}
CNotePtr::CNotePtr() {
    this->mOctave = 0;
    this->mStep = 0;
    this->mAlter = 0;
    this->mStaff = 0;
    this->mDuration = 0;
    this->mPartIndex = 0;
    this->mMeasureIndex = 0;
    this->mStartTime = 0;
    this->mChoice = normal_;
    this->mNext = NULL;
    this->mNotationPtrs = std::vector<CNotationPtr*>();
    this->mShouldIgnore = false;
    this->mHasJump = false;
    this->mInMidi = true;
    this->mInCompare = true;
}

CNotePtr::~CNotePtr(){
    for(vector<CNotationPtr *>::iterator it = this->mNotationPtrs.begin(); it != this->mNotationPtrs.end(); it ++){
        if (NULL != *it) {
            delete *it;
            *it = NULL;
        }
    }
}

void CNotePtr::setValue(int octave, int step, int alter, double duration, int staff, int partIndex, int measureIndex){
    this->mOctave = octave;
    this->mStep = step;
    this->mAlter = alter;
    this->mStaff = staff;
    this->mDuration = duration;
    this->mPartIndex = partIndex;
    this->mMeasureIndex = measureIndex;
}
void CNotePtr::setStartTime(double startTime){
    this->mStartTime = startTime;
}
void CNotePtr::addDuration(double duration){
    this->mDuration = this->mDuration + duration;
}

void CNotePtr::setNoteChoice(CNoteChoice choice){
    this->mChoice = choice;
}
double CNotePtr::getDuration(){
    return this->mDuration;
}
int CNotePtr::getNoteNumber(){
    int value = StepMap[this->mStep] + (this->mOctave + 1) * 12 + this->mAlter;
    return value;
}
int CNotePtr::getPartIndex() {
    return this->mPartIndex;
}
double CNotePtr::getStartTime() {
    return this->mStartTime;
}
double CNotePtr::getEndTime() {
    return this->mStartTime + this->mDuration;
}

int CNotePtr::getMeasureIndex() {
    return this->mMeasureIndex;
}
CNoteChoice CNotePtr::getChoice() {
    return this->mChoice;
}
int CNotePtr::getStaff() {
    return this->mStaff;
}
