//
//  xml_midiFile.m
//  iOSMusic
//
//  Created by tanhui on 2017/7/10.
//  Copyright © 2017年 tanhui. All rights reserved.
//

#import "xml_midiFile.h"
#include "../../musicFramework/mx/xml/XDoc.h"
#include "../../musicFramework/mx/api/ApiCommon.h"
#include "../../musicFramework/mx/api/ApiCommon.h"
#include "../../musicFramework/mx/core/Document.h"
#include "../../musicFramework/mx/core/Elements.h"
#include "../../musicFramework/mx/core/Strings.h"
#include "../../musicFramework/mx/utility/Utility.h"
#include "../../musicFramework/mx/xml/XFactory.h"
#include "../../musicFramework/mx/core/Elements.h"

//#include <MusicFramwork/xml/XDoc.h>
//#include <MusicFramwork/api/ApiCommon.h>
//#include <MusicFramwork/api/ApiCommon.h>
//#include <MusicFramwork/core/Document.h>
//#include <MusicFramwork/core/Elements.h>
//#include <MusicFramwork/core/Strings.h>
//#include <MusicFramwork/utility/Utility.h>
//#include <MusicFramwork/xml/XFactory.h>
//#include <MusicFramwork/core/Elements.h>
#include <stdio.h>
#import "musicXML.h"
#import "Constants.h"
#import "RestM.h"
#import "AccidM.h"

using namespace std;
using namespace mx::core;

@interface xml_midiFile ()

@property(nonatomic, strong) NSMutableDictionary* mPartClefs;
@property(nonatomic, strong) MidiOption* mOption;
@property(nonatomic, strong) NoteGroupM* mCurrentNoteGroup;
@property(nonatomic, assign) CGSize mSize;
@end

@implementation xml_midiFile
-(instancetype)initWithOption:(MidiOption*)option sheetSize:(CGSize)size{
    if ([super init]) {
        if (!option.mTempo){
//            option.mTempo =120;
        }
        self.mSize = size;
        self.mOption = option;
        self.mScore = [self parseXml];
    }
    return self;
}

// 解析 Attribute 标签
-(void)parseAttributeByPtr:(PropertiesPtr)choiceMeasureAttr
                              dataChoice:(NSMutableArray*)dataChoices
                                   staff:(int*)staff
                               startTime:(double *)currentStartTime
                                division:(int *)divisions {
    EKeyMode mode_ = EKeyMode::EKeyMode_NONE;
    NSNumber *mBeates = nil , *mBeateType = nil ,*fifth_ = nil;
    
    MeasureKeyM* keyM = nil;
    MeasureTimeM* timeM = nil;
    // 获取divisions
    if (choiceMeasureAttr->getHasDivisions()){
        *divisions = choiceMeasureAttr->getDivisions()->getValue().getValue();
    }
    if (choiceMeasureAttr->getHasStaves()) {
        *staff = choiceMeasureAttr->getStaves()->getValue().getValue();
    }
    if (choiceMeasureAttr->getTimeSet().size()){
        TimePtr time  = *(choiceMeasureAttr->getTimeSet().cbegin());
        TimeChoice::Choice choice = time->getTimeChoice()->getChoice();
        if (!(int)choice){
            TimeSignatureGroupPtr timeSignaturePtr = *(time->getTimeChoice()->getTimeSignatureGroupSet().cbegin());
            std::string beats = timeSignaturePtr->getBeats()->getValue().getValue();
            auto beat_types = timeSignaturePtr->getBeatType()->getValue().getValue();
            NSString *oc_beat = [NSString stringWithCString:beats.c_str() encoding:[NSString defaultCStringEncoding]];
            NSString *oc_beat_type =[NSString stringWithCString:beat_types.c_str() encoding:[NSString defaultCStringEncoding]];
            mBeates = @([oc_beat intValue]);
            mBeateType = @([oc_beat_type intValue]);
            timeM = [[MeasureTimeM alloc ]init];
            timeM.mBeates = mBeates;
            timeM.mBeateType = mBeateType;
        }
    }
    if (choiceMeasureAttr->getKeySet().size()) {
        KeyPtr keyPtr = *(choiceMeasureAttr->getKeySet().cbegin());
        auto fifth = keyPtr->getKeyChoice()->getTraditionalKey()->getFifths()->getValue().getValue();
        auto mode = keyPtr->getKeyChoice()->getTraditionalKey()->getMode()->getValue().getValue();
        fifth_ = @((int)fifth);
        mode_ = (EKeyMode)mode;
        keyM = [[MeasureKeyM alloc]initWithFifth:fifth_ mode:mode_];
    }
    
    // 遍历添加clef
    if (choiceMeasureAttr->getClefSet().size()) {
        int i = 0;
        for (auto clef_it = choiceMeasureAttr->getClefSet().cbegin();i<choiceMeasureAttr->getClefSet().size() && clef_it != choiceMeasureAttr->getClefSet().cend(); clef_it++ ,i++) {
            MeasureAttributeM * attr = [[MeasureAttributeM alloc]init];
            
            ClefPtr clefPtr  = *clef_it;
            int line = clefPtr->getLine()->getValue().getValue();
            auto sign = clefPtr->getSign()->getValue();
            NSInteger number = 1;
            if (clefPtr->getAttributes()->hasNumber) {
                number = clefPtr->getAttributes()->number.getValue();
            }
            EClef clef = EClef::EClef_None;
            if (sign == ClefSign::g && line == 2) {
                clef = EClef::EClef_TREBLE;
            }else if (sign == ClefSign::f && line == 4){
                clef = EClef::EClef_BASS;
            }else{
                NSAssert(FALSE, @"unsupported format");
            }
            
            ClefM * clefM = [[ClefM alloc]init];
            clefM.mValue = clef;
            
            attr.mClef = clefM;
            attr.mKey = keyM;
            attr.mTime = timeM;
            attr.mStaffth = number;
            
            // 设置measureStartTime
            attr.mStartTime = *currentStartTime - 1;
            attr.mDuration = 0;
            if (clefM){
                attr.mDuration += DivisionUnit * 0.5;
            }
            if (keyM){
                attr.mHasKey = YES;
                attr.mDuration += DivisionUnit * 0.4;
            }
            if (timeM){
                attr.mHasKey = YES;
                attr.mDuration += DivisionUnit * 0.4;
            }
            attr.mPrevious = [self.mPartClefs objectForKey:@(number)];
            [self.mPartClefs setObject:attr forKey:@(number)];
            [dataChoices addObject:attr];
        }
    }
}
// 解析rest标签
-(RestM*)getRestByPtr:(NotePtr)choiceNote
             division:(int )divisions{
    RestM* rest = [[RestM alloc]init];
    if (choiceNote->getHasType()){
        auto type = choiceNote->getType()->getValue();
        if (type == NoteTypeValue::whole){
            rest.mHasMeasure = YES;
        }
        rest.mType = (ENoteType)type;
    }
    else if (choiceNote->getNoteChoice()->getNormalNoteGroup()->getFullNoteGroup()->getFullNoteTypeChoice()->getRest()->getAttributes()->measure == YesNo::yes){
        rest.mType = ENoteType::ENoteType_WHOLE;
        rest.mHasMeasure = YES;
    }else {
        rest.mType = ENoteType::ENoteType_None;
        rest.mHasMeasure = NO;
    }
    if(choiceNote->getHasStaff()){
        rest.mStaffth = (NSInteger)choiceNote->getStaff()->getValue().getValue();
    }else{
        rest.mStaffth = 1;
    }
    auto duration = choiceNote->getNoteChoice()->getNormalNoteGroup()->getDuration()->getValue().getValue();
    rest.mDuration = (duration * DivisionUnit / divisions) ;
//    if (choiceNote->getAttributes()->hasPrintObject &&
//        choiceNote->getAttributes()->printObject == YesNo::no){
//        rest.mNoPrintObject = YES;
//    }
    return rest;
}
// 解析 notation 标签
-(NSArray*)getNotationSetByPtr:(NotePtr)choiceNote with:(NoteM*)noteM{
    NSMutableArray* notationArr = @[].mutableCopy;
    int index = 1;
    for (auto notation_it = choiceNote->getNotationsSet().cbegin(); notation_it != choiceNote->getNotationsSet().cend(); notation_it++,index++) {
        for (auto notationChoice_it = (*notation_it)->getNotationsChoiceSet().cbegin(); notationChoice_it !=(*notation_it)->getNotationsChoiceSet().cend();notationChoice_it++ ) {
            NotationM* notationM = [[NotationM alloc]init];
            notationM.mParentNoteG = self.mCurrentNoteGroup;
            // tie 和 slur 一起处理
            if ((*notationChoice_it)->getChoice() == NotationsChoice::Choice::slur){
                auto slurPtr = (*notationChoice_it)->getSlur();
                ESlurType type = (ESlurType)slurPtr->getAttributes()->type;
                int number = slurPtr->getAttributes()->number.getValue();
                EOrientation placement = EOrientation::EOrientation_None;
//                if(slurPtr->getAttributes()->hasOrientation){
//                    placement = (EOrientation)slurPtr->getAttributes()->orientation;
//                } else {
//                    placement = EOrientation_None;
//                }
                SlurM* slur = [[SlurM alloc]initWithType:type number:number placement:placement];
                notationM.mSlur = slur;
                notationM.mChoice = ENotationChioce::Slur;
                [notationArr addObject:notationM];
            }else if ((*notationChoice_it)->getChoice() == NotationsChoice::Choice::tied) {
                auto tiePtr = (*notationChoice_it)->getTied();
                ESlurType type = (ESlurType)tiePtr->getAttributes()->type;
                int number = tiePtr->getAttributes()->number.getValue();
                EOrientation placement = EOrientation_None;
//                if(tiePtr->getAttributes()->hasOrientation){
//                    placement = (EOrientation)tiePtr->getAttributes()->orientation;
//                } else {
//                    placement = EOrientation_None;
//                }
                TiedM* tie = [[TiedM alloc]initWithType:type number:number placement:placement];
                tie.mNote = noteM;
                notationM.mTie = tie;
                notationM.mChoice = ENotationChioce::Tie;
                [notationArr addObject:notationM];
            }else if ((*notationChoice_it)->getChoice() == NotationsChoice::Choice::articulations) {
                notationM.mChoice = ENotationChioce::Articulations;
                auto articulateSet = (*notationChoice_it)->getArticulations()->getArticulationsChoiceSet();
                if (articulateSet.size() > 0) {
                    NSMutableArray* articalations = @[].mutableCopy;
                    for (auto arti_iter = articulateSet.cbegin(); arti_iter != articulateSet.cend(); arti_iter++ ) {
                        ArticulationM* arti = [[ArticulationM alloc]init];
                        auto choiceArti = (*arti_iter)->getChoice();
                        arti.mChoice = (EArticulationChoice)choiceArti;
                        [articalations addObject:arti];
                    }
                    notationM.mArticulations = articalations.copy;
                }
                [notationArr addObject:notationM];
            }
        }
    }
    return notationArr.copy;
}
// 解析grace 音符
-(NoteGroupM*)parseGraceNoteByPtr:(NotePtr)choiceNote note:(NoteM*)noteM startTime:(double*)currentStartTime{
    // 处理grace node
    NoteGroupM* noteGroup = nil;
    auto grace = choiceNote->getNoteChoice()->getGraceNoteGroup();
    if (grace->getFullNoteGroup()->getFullNoteTypeChoice()->getChoice() == FullNoteTypeChoice::Choice::pitch) {
        auto pitch = grace->getFullNoteGroup()->getFullNoteTypeChoice()->getPitch();
        auto step = pitch->getStep()->getValue();
        auto octave = pitch->getOctave()->getValue().getValue();
        if (pitch->getHasAlter()) {
            auto alter = pitch->getAlter()->getValue().getValue();
            noteM.mAlter = (int)alter;
        }
        noteM.mStep = (ENoteStep)(((int)step + 5)%7);
        noteM.mOctave = octave;
        
        noteGroup = [[NoteGroupM alloc]initWithNotes:@[noteM].mutableCopy];
        MeasureAttributeM* attr = [self.mPartClefs objectForKey:@(noteM.mStaffth)];
        if(noteGroup.mStartTime < attr.mStartTime){
            noteGroup.mCurrentAttr = noteM.mCurrentAttr = attr.mPrevious;
        }else{
            noteGroup.mCurrentAttr = noteM.mCurrentAttr = attr;
        }
        noteGroup.mStaffth = noteM.mStaffth;
        noteGroup.mStartTime = noteM.mStartTime = *currentStartTime;
        noteGroup.mStem = noteM.mStem;
        noteGroup.mType = noteM.mType;
        noteGroup.mChoice = ENoteChoice_Grace;
        
    }
    return noteGroup;
}

// 解析 note
-(void)addNoteTypeToDataChoice:(NSMutableArray*)dataChoices
                            by:(NotePtr)choiceNote
                     startTime:(double *)currentStartTime
                      division:(int )divisions {
    NoteM* noteM = [[NoteM alloc] init];
    // 如果是 printObject 为no ，直接过滤
    if (choiceNote->getAttributes()->hasPrintObject &&
        choiceNote->getAttributes()->printObject == YesNo::no){
        auto duration = choiceNote->getNoteChoice()->getNormalNoteGroup()->getDuration()->getValue().getValue();
        *currentStartTime += (duration * DivisionUnit / divisions);
        return;
    }
    // 处理accident
    if (choiceNote->getHasAccidental()){
        auto accidentValue = choiceNote->getAccidental()->getValue();
        noteM.mAccid = (EAccidType)accidentValue;
    }else {
        noteM.mAccid = (EAccidType)EAccidType_None;
    }
    if (choiceNote->getHasType()){
        int type = (int)choiceNote->getType()->getValue();
        noteM.mType = (ENoteType)type;
    }else if (choiceNote->getNoteChoice()->getNormalNoteGroup()->getFullNoteGroup()->getFullNoteTypeChoice()->getRest()->getAttributes()->measure == YesNo::yes){
        noteM.mType = ENoteType::ENoteType_WHOLE;
    }else {
        noteM.mType = ENoteType::ENoteType_None;
    }
    if (choiceNote->getHasStem()) {
        auto stem = choiceNote->getStem()->getValue();
        noteM.mStem = (ENoteStem)stem;
    }else {
        noteM.mStem = ENoteStem_None;
    }
    if(choiceNote->getHasStaff()){
        noteM.mStaffth = (NSInteger)choiceNote->getStaff()->getValue().getValue();
    }else{
        noteM.mStaffth = 1;
    }
    
    auto normalChoice =  choiceNote->getNoteChoice()->getChoice();
    if (normalChoice == NoteChoice::Choice::normal){
        // 处理普通音符
        auto noteTypeChoice =  choiceNote->getNoteChoice()->getNormalNoteGroup()->getFullNoteGroup()->getFullNoteTypeChoice()->getChoice();
        noteM.mChoice = (ENoteChoice)noteTypeChoice;
        if(choiceNote->getHasNotehead()){
            auto headType= choiceNote->getNotehead()->getValue();
            noteM.mNoteHeadType = (ENoteHeadType)headType;
        }
        if (choiceNote->getDotSet().size()){
            noteM.mDotNum = choiceNote->getDotSet().size();
        }
        if (noteTypeChoice == FullNoteTypeChoice::Choice::pitch){
            auto pitch = choiceNote->getNoteChoice()->getNormalNoteGroup()->getFullNoteGroup()->getFullNoteTypeChoice()->getPitch();
            auto step = pitch->getStep()->getValue();
            auto actave = pitch->getOctave()->getValue().getValue();
            noteM.mStep = (ENoteStep)(((int)step + 5)%7);
            noteM.mOctave = (int)actave;
            auto duration = choiceNote->getNoteChoice()->getNormalNoteGroup()->getDuration()->getValue().getValue();
            noteM.mDuration = (duration * DivisionUnit / divisions) ;
            // 添加noteGroup , if chord == true 加到上一个group
            if (choiceNote->getNoteChoice()->getNormalNoteGroup()->getFullNoteGroup()->getHasChord()){
                [self.mCurrentNoteGroup addNote:noteM];
            }else {
                self.mCurrentNoteGroup = [[NoteGroupM alloc]initWithNotes:@[noteM].mutableCopy];
                // 设置notegroup 的 starttime
                self.mCurrentNoteGroup.mStartTime = noteM.mStartTime = *currentStartTime;
                *currentStartTime = *currentStartTime + noteM.mDuration;
                self.mCurrentNoteGroup.mChoice = ENoteGroupChoice::ENoteChoice_Normal;
                [dataChoices addObject:self.mCurrentNoteGroup];
            }
            MeasureAttributeM* attr = [self.mPartClefs objectForKey:@(noteM.mStaffth)];
            if(self.mCurrentNoteGroup.mStartTime < attr.mStartTime){
                self.mCurrentNoteGroup.mCurrentAttr = noteM.mCurrentAttr = attr.mPrevious;
            }else{
                self.mCurrentNoteGroup.mCurrentAttr = noteM.mCurrentAttr = attr;
            }
            self.mCurrentNoteGroup.mDuration = noteM.mDuration  ;
            self.mCurrentNoteGroup.mStaffth = noteM.mStaffth;
            if (noteM.mStem != ENoteStem_None){
                self.mCurrentNoteGroup.mStem = noteM.mStem;
            }
//            self.mCurrentNoteGroup.mNoPrintObject = noteM.mNoPrintObject;
            self.mCurrentNoteGroup.mType = noteM.mType;
            // 解析beams
            if (choiceNote->getBeamSet().size()) {
                NSMutableArray* beamsArr = @[].mutableCopy;
                int index = 1;
                for (auto beam_it = choiceNote->getBeamSet().cbegin(); beam_it != choiceNote->getBeamSet().cend(); beam_it++,index++) {
                    BeamM* beamM = [[BeamM alloc]init];
                    auto beamValue = (int)(*beam_it)->getValue();
                    beamM.mValue = (EBeamType)beamValue;
                    beamM.mNumber = index;
                    [beamsArr addObject:beamM];
                }
                self.mCurrentNoteGroup.mBeams = beamsArr;
            }
        }else if (noteTypeChoice == FullNoteTypeChoice::Choice::rest){
            // 类型为rest
            RestM* rest = [self getRestByPtr: choiceNote division:divisions];
            MeasureAttributeM* attr = [self.mPartClefs objectForKey:@(noteM.mStaffth)];
            rest.mCurrentAttr = attr;
            // 设置rest 的startTime
            rest.mStartTime =  *currentStartTime;
            *currentStartTime = *currentStartTime + rest.mDuration;
            [dataChoices addObject:rest];
        }
    } else if (normalChoice == NoteChoice::Choice::grace){
        self.mCurrentNoteGroup = [self parseGraceNoteByPtr:choiceNote note:noteM startTime:currentStartTime];
        if (self.mCurrentNoteGroup) {
            [dataChoices addObject:self.mCurrentNoteGroup];
        }
    }
    
    // 解析notations 弧线
    if (choiceNote->getNotationsSet().size()){
        NSArray* notations = [self getNotationSetByPtr:choiceNote  with:noteM];
        [self.mCurrentNoteGroup addNotations:notations];
    }
}


-(NSMutableArray*)parseScorePartMeasures:(PartwisePartPtr)partwise staff:(int*)staff{
    NSMutableArray* measures= @[].mutableCopy;
    // 每个part最新的clef
    // 每个part指定一个divisions
    int divisions = 0;
    double currentStartTime = 0;
    
    for (auto measure_it = partwise->getPartwiseMeasureSet().cbegin(); measure_it != partwise->getPartwiseMeasureSet().cend(); measure_it++) {
        MeasureAttributesPtr attributes = (*measure_it)->getAttributes();
        MusicDataChoiceSet groupSetPtr = (*measure_it)->getMusicDataGroup()->getMusicDataChoiceSet();
        auto width = attributes->width.getValue();
        NSMutableArray* dataChoices = @[].mutableCopy;
        double measureStartTime = currentStartTime;
        
        // 解析measure 中的 note
        for (auto choice_it = groupSetPtr.cbegin() ; choice_it != groupSetPtr.cend() ; choice_it ++) {
            auto choiceType = (*choice_it)->getChoice();
            if (choiceType == MusicDataChoice::Choice::properties) {
                auto choiceMeasureAttr = (*choice_it)->getProperties();
                [self parseAttributeByPtr:choiceMeasureAttr
                               dataChoice:dataChoices
                                    staff:staff
                                startTime:&currentStartTime
                                 division:&divisions];
            }else if (choiceType == MusicDataChoice::Choice::note){
                // 处理音符
                auto choiceNote = (*choice_it)->getNote();
                [self addNoteTypeToDataChoice:dataChoices by:choiceNote startTime:&currentStartTime division:divisions];
                
            }else if (choiceType == MusicDataChoice::Choice::backup){
                BackupM* backup = [[BackupM alloc]init];
                auto choiceBackDuration = (*choice_it)->getBackup()->getDuration()->getValue().getValue();
                backup.mDuration = (choiceBackDuration * DivisionUnit / divisions);
                currentStartTime -= [backup mDuration];
                [dataChoices addObject:backup];
            }else if (choiceType == MusicDataChoice::Choice::forward){
                ForwardM* forward = [[ForwardM alloc]init];
                auto choiceForwardDuration = (*choice_it)->getForward()->getDuration()->getValue().getValue();
                forward.mDuration = (choiceForwardDuration * DivisionUnit / divisions);
                forward.mStartTime = currentStartTime;
                currentStartTime += [forward mDuration];
                [dataChoices addObject:forward];
            }else if (choiceType == MusicDataChoice::Choice::sound) {
                if ((*choice_it)->getSound()->getAttributes()->hasTempo) {
                    auto tempo = (*choice_it)->getSound()->getAttributes()->tempo.getValue();
                    if (!self.mOption.mTempo) {
                        self.mOption.mTempo = tempo;
                    }
                }
            }else if (choiceType == MusicDataChoice::Choice::direction) {
                if ((*choice_it)->getDirection()->getSound()->getAttributes()->hasTempo) {
                    auto tempo = (*choice_it)->getDirection()->getSound()->getAttributes()->tempo.getValue();
                    if (!self.mOption.mTempo) {
                        self.mOption.mTempo = tempo;
                    }
                }
            }
        }
        MeasureM* measure = [[MeasureM alloc]initWithWidth:(float)width musicDataGroup:dataChoices staves:*staff];
        measure.mStartTime= measureStartTime;
        if (measures.count) {
            MeasureM* last = (MeasureM*)[measures lastObject];
            last.mNextMeasure = measure;
        }
        [measures addObject:measure];
    }
    return measures;
}

-(ScoreM*)parseScorePartWise:(ScorePartwisePtr)scorePartwise {
    // 获取score头部信息
    
    NSMutableDictionary* partNameDict = @{}.mutableCopy;
    auto partlist = scorePartwise->getScoreHeaderGroup()->getPartList();
    auto name = partlist->getScorePart()->getPartName()->getValue().getValue();
    auto partid = partlist->getScorePart()->getAttributes()->id.getValue();
    
    int instrument= 1;
    if ((*partlist).getScorePart()->getMidiDeviceInstrumentGroupSet().size()) {
        instrument = (*partlist->getScorePart()->getMidiDeviceInstrumentGroupSet().rbegin())->getMidiInstrument()->getMidiProgram()->getValue().getValue();
    }
    
    partNameDict[[self stringFromStringType:partid]] = @{@"name":[self stringFromStringType:name],
                                                         @"program":@(instrument)};
    auto it = scorePartwise->getPartwisePartSet().cbegin();
    NSMutableArray* parts = @[].mutableCopy;
    
    for (auto partname_it = partlist->getPartGroupOrScorePartSet().rbegin(); partname_it != partlist->getPartGroupOrScorePartSet().rend(); partname_it++) {
        auto choice = (*partname_it)->getChoice();
        if (choice == PartGroupOrScorePart::Choice::partGroup) {
            
        }else if(choice == PartGroupOrScorePart::Choice::scorePart){
            auto name = (*partname_it)->getScorePart()->getPartName()->getValue().getValue();
            auto partid = (*partname_it)->getScorePart()->getAttributes()->id.getValue();
            int instrument = 1;
            if ((*partname_it)->getScorePart()->getMidiDeviceInstrumentGroupSet().size()){
                instrument = (*(*partname_it)->getScorePart()->getMidiDeviceInstrumentGroupSet().rbegin())->getMidiInstrument()->getMidiProgram()->getValue().getValue();
            }
            partNameDict[[self stringFromStringType:partid]] = @{@"name":[self stringFromStringType:name],
                                                                 @"program":@(instrument)};
        }
    }
    for (NSInteger i = 0 ;  it != scorePartwise->getPartwisePartSet().cend() ; i++, it++) {
        auto partwise = (*it);
        std::string partNameID = "";
        if (partwise->getAttributes()->hasId) {
            partNameID = partwise->getAttributes()->id.getValue();
        }
        int staff = 1;
        
        NSMutableArray* measures = [self parseScorePartMeasures:partwise staff:&staff];
        
        NSDictionary* partName = [partNameDict objectForKey:[self stringFromStringType:partNameID]];
        PartM* part = [[PartM alloc]initWithName:partName[@"name"] program:[partName[@"program"] integerValue] Measures:measures  staves:staff];
        
        [parts addObject:part];
    }
    
    ScoreM * score = [[ScoreM alloc]initWithTitle:self.mOption.mTitle tempo:self.mOption.mTempo parts:parts];
    [self processScore:score];
    [self processBeamInScore:score];
    [self processConflictMeasure:score];
    [self spliteMeasuresToMultiLine:score];
//    [self sortMeasuresByPrintObject:score];
    return score;
}

//-(void)sortMeasuresByPrintObject:(ScoreM*)score{
//    for (PartM* part in score.mParts){
//        for (MeasureM* measure in part.mMeasures) {
//            [measure sortMeasureDatas];
//        }
//    }
//}

- (ScoreM*)parseXml {
    // Do any additional setup after loading the view, typically from a nib.
    mx::core::DocumentPtr mxDoc = mx::core::makeDocument();
    mx::xml::XDocPtr xmlDoc = mx::xml::XFactory::makeXDoc();
    // read a MusicXML file into the XML DOM structure
    xmlDoc->loadFile( [self.mOption.mFilePath UTF8String] );
    // create an ostream to receive any parsing messages
    std::stringstream parseMessages;
    // convert the XML DOM into MusicXML Classes
    bool isSuccess = mxDoc->fromXDoc( parseMessages, *xmlDoc );
    if( !isSuccess )
    {
        std::cout << "Parsing of the MusicXML document failed with the following message(s):" << std::endl;
        std::cout << parseMessages.str() << std::endl;
        return NULL;
    }
    
    // maybe the document was timewise document. if so, convert it to partwise
    if( mxDoc->getChoice() == mx::core::DocumentChoice::timewise )
    {
        mxDoc->convertContents();
    }
    // get the root
    auto scorePartwise = mxDoc->getScorePartwise();
    return [self parseScorePartWise:scorePartwise];
    
}

-(void)processBeamInScore:(ScoreM*)score {
    for (int scoreIndex = 0 ;scoreIndex < score.mParts.count; scoreIndex++){
        PartM* part = score.mParts[scoreIndex];
        for (int measureIndex = 0; measureIndex < part.mMeasures.count; measureIndex++) {
            MeasureM* measure = part.mMeasures[measureIndex];
            MeasureM* nextMeasure = nil;
            if(measureIndex < part.mMeasures.count - 1){
                nextMeasure = part.mMeasures[measureIndex+1];
            }
            [self processBeamInMeasure:measure];
            [self processNotationInMeasure:measure];
        }
    }
}

-(void)processSlurInNotation:(NotationM*)notation noteIndex:(NSInteger)noteIndex noteGroup:(NoteGroupM*)noteGroup measure:(MeasureM*)measure{
    if (notation.mSlur.mValue == ESlurType_Begin) {
        SlurM * slurM = notation.mSlur;
        NSInteger j = noteIndex;
        BOOL findEnd = NO;
        while (++j < measure.mMeasureDatas.count && !findEnd && !slurM.mPaired) {
            if ([[measure.mMeasureDatas objectAtIndex:j] isKindOfClass:[NoteGroupM class]]) {
                NoteGroupM* noteFollow = (NoteGroupM*)[measure.mMeasureDatas objectAtIndex:j];
                if (noteFollow.mNotations.count) {
                    for (NotationM* notationFollow in noteFollow.mNotations) {
                        // end && not Paired
                        if ( notationFollow.mChoice == ENotationChioce::Slur) {
                            SlurM* slurFollow = notationFollow.mSlur;
                            if (slurFollow.mValue == ESlurType_End &&
                                slurFollow.mNumber == slurM.mNumber &&
                                !slurFollow.mPaired) {
                                slurM.mEnd = noteFollow;
                                slurFollow.mStart = noteGroup;
                                slurFollow.mPlacement = slurM.mPlacement;
                                [self setStemAndPlacementByStartNotation:notation end:notationFollow];
                                slurFollow.mPaired = YES;
                                slurM.mPaired = YES;
                                findEnd = YES;
                                break;
                            }else if (slurFollow.mValue == ESlurType_Begin&&
                                      slurFollow.mNumber == slurM.mNumber){
                                // 发现新的开始连音 ,舍弃当前
                                slurM.mEnd = nil;
                                findEnd = YES;
                                break;
                            }
                        }
                    }
                }
            }
        }
        if(!findEnd){
            // 当前measure没有找到，找下一个measure
            MeasureM* nextMeasure = measure.mNextMeasure;
            while (nextMeasure && !findEnd) {
                j = -1 ;
                while (++j < nextMeasure.mMeasureDatas.count && !findEnd) {
                    if ([[nextMeasure.mMeasureDatas objectAtIndex:j] isKindOfClass:[NoteGroupM class]]) {
                        NoteGroupM* noteFollow = (NoteGroupM*)[nextMeasure.mMeasureDatas objectAtIndex:j];
                        if (noteFollow.mNotations.count &&
                            noteGroup.mStaffth == noteFollow.mStaffth) {
                            for (NotationM* notationFollow in noteFollow.mNotations) {
                                // end && not Paired
                                if (notationFollow.mChoice == ENotationChioce::Slur) {
                                    SlurM* slurFollow = notationFollow.mSlur;
                                    if (slurFollow.mValue == ESlurType_End &&
                                        slurFollow.mNumber == slurM.mNumber&&
                                        !slurFollow.mPaired) {
                                        slurM.mEnd = noteFollow;
                                        slurFollow.mStart = noteGroup;
                                        slurFollow.mPlacement = slurM.mPlacement;
                                        slurFollow.mPaired = YES;
                                        slurM.mPaired = YES;
                                        findEnd = YES;
                                        [self setStemAndPlacementByStartNotation:notation end:notationFollow];
                                        break;
                                    }else if (slurFollow.mValue == ESlurType_Begin&&
                                              slurFollow.mNumber == slurM.mNumber){
                                        // 发现新的开始连音
                                        slurM.mEnd = nil;
                                        findEnd = YES;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
                nextMeasure = nextMeasure.mNextMeasure;
            }
        }
    }
}

-(void)setStemAndPlacementByStartNotation:(NotationM*)notationStart end:(NotationM*)notationEnd {
    NoteGroupM* startNoteGroup = notationStart.mParentNoteG;
    NoteGroupM* endNoteGroup = notationEnd.mParentNoteG;
    
    NSInteger startRes = [self findSame:startNoteGroup];
    NSInteger endRes = [self findSame:endNoteGroup];
    if (startRes == 1 || endRes == 1) {
        // 在 上方
        [notationStart setPlaceMent:EOrientation::EOrientation_Above];
        [notationEnd setPlaceMent:EOrientation::EOrientation_Above];
        if (notationStart.mChoice == ENotationChioce::Tie ){
            notationStart.mTie.mDrawFromSide = YES;
            notationEnd.mTie.mDrawFromSide = YES;
        }
    } else if (startRes == 2 || endRes == 2){
        [notationStart setPlaceMent:EOrientation::EOrientation_Below];
        [notationEnd setPlaceMent:EOrientation::EOrientation_Below];
        if (notationStart.mChoice == ENotationChioce::Tie ){
            notationStart.mTie.mDrawFromSide = YES;
            notationEnd.mTie.mDrawFromSide = YES;
        }
    }
    // 设置Orient
    if ([notationStart getPlaceMent] == EOrientation_None) {
        if (startNoteGroup.mStem == endNoteGroup.mStem &&
            endNoteGroup.mStem == ENoteStem_UP){
            [notationStart setPlaceMent:EOrientation::EOrientation_Below];
            [notationEnd setPlaceMent:EOrientation::EOrientation_Below];
        } else {
            [notationStart setPlaceMent:EOrientation::EOrientation_Above];
            [notationEnd setPlaceMent:EOrientation::EOrientation_Above];
        }
    }
}
/* 先找上方或者下方是否有相同startTime 的noteG
* 不存在返回0，在上方返回1，下方返回2
*/
-(NSInteger)findSame:(NoteGroupM*)noteGroup {
    NSInteger ret = 0;
    MeasureM* measure = noteGroup.mMeasure;
    for (DrawableNoteM* temp in measure.mMeasureDatas) {
        if ([temp isKindOfClass:[NoteGroupM class]]){
            NoteGroupM* tempNote = (NoteGroupM*)temp;
            if (tempNote == noteGroup ||
                tempNote.mChoice == ENoteChoice_Grace ||
                noteGroup.mChoice == ENoteChoice_Grace
                ) {
                continue;
            }
            if (tempNote.mStaffth == noteGroup.mStaffth &&
                abs(tempNote.mStartTime - noteGroup.mStartTime) < CGFLOAT_MIN ) {
                // 找到相同的，判断上下
                if ([[tempNote mTop] dist:[noteGroup mTop]] > 0 ){
                    // tempNote 高于 startNoteGroup
                    if (noteGroup.mStem != ENoteStem_None){
                        noteGroup.mStem = ENoteStem_DOWN;
                    }
                    ret = 2;
                } else {
                    if (noteGroup.mStem != ENoteStem_None){
                        noteGroup.mStem = ENoteStem_UP;
                    }
                    ret = 1;
                }
            }
        }
        
    }
    return ret;
}


-(void)processTieInNotation:(NotationM*)notation noteIndex:(NSInteger)noteIndex noteGroup:(NoteGroupM*)noteGroup measure:(MeasureM*)measure{
    int count = 0;
    MeasureM* currentMeasure = measure;
    NSInteger j = noteIndex + 1;
    while (count < 2 && !notation.mTie.mPaired){
        for ( ; j < currentMeasure.mMeasureDatas.count ; j ++ ) {
            DrawableNoteM* note = [currentMeasure.mMeasureDatas objectAtIndex:j];
            if ([note isKindOfClass:[NoteGroupM class]] && [[((NoteGroupM*)note) mNotations] count]) {
                NoteGroupM* noteGroupFollow = (NoteGroupM*)note;
                if (noteGroupFollow.mStaffth != noteGroup.mStaffth) {
                    continue;
                }
                for (NotationM* notationFollow in noteGroupFollow.mNotations) {
                    if (notationFollow.mChoice == ENotationChioce::Tie &&
//                        notationFollow.mTie.mNumber == notation.mTie.mNumber &&
                        notationFollow.mTie.mValue == ESlurType_End &&
                        !notationFollow.mTie.mPaired) {
                        if (abs(noteGroup.mStartTime + noteGroup.mDuration - noteGroupFollow.mStartTime) < CGFLOAT_MIN) {
                            notation.mTie.mEnd = noteGroupFollow;
                            notationFollow.mTie.mStart = noteGroup;
                            notationFollow.mTie.mPaired = YES;
                            notation.mTie.mPaired = YES;
                            [self setStemAndPlacementByStartNotation:notation end:notationFollow];
                            break;
                        }
                    }
                }
            }
            if (notation.mTie.mPaired) {
                break;
            }
        }
        currentMeasure = currentMeasure.mNextMeasure;
        count ++;
        j = 0;
    }
}

-(void)processNotationInMeasure:(MeasureM*)measure{
    for (int i = 0 ; i < measure.mMeasureDatas.count ; i ++ ) {
        DrawableNoteM* note = [measure.mMeasureDatas objectAtIndex:i];
        if ([note isKindOfClass:[NoteGroupM class]] && [[((NoteGroupM*)note) mNotations] count]) {
            NoteGroupM* noteGroup = (NoteGroupM*)note;
            for (NotationM* notation in noteGroup.mNotations) {
                if (notation.mChoice == ENotationChioce::Slur){
                    [self processSlurInNotation:notation noteIndex:i noteGroup:noteGroup measure:measure];
                }else if (notation.mChoice == ENotationChioce::Tie) {
                    [self processTieInNotation:notation noteIndex:i noteGroup:noteGroup measure:measure];
                }
            }
        }
    }
}

-(void)processBeamInMeasure:(MeasureM*)measure {
    for (int i = 0 ; i < measure.mMeasureDatas.count ; i ++ ) {
        DrawableNoteM* note = [measure.mMeasureDatas objectAtIndex:i];
        if ([note isKindOfClass:[NoteGroupM class]] && [[((NoteGroupM*)note) mBeams] count]) {
            NoteGroupM* noteGroup = (NoteGroupM*)note;
            NSMutableArray* consivesNoteGroup = @[].mutableCopy;
            for (BeamM* beam in noteGroup.mBeams) {
                if (beam.mValue == EBeamType_Begin){
                    if (![consivesNoteGroup containsObject:noteGroup]) {
                        [consivesNoteGroup addObject:noteGroup];
                    }
                    int j = i;
                    BOOL findEnd = NO;
                    while (++j < measure.mMeasureDatas.count && !findEnd) {
                        if ([[measure.mMeasureDatas objectAtIndex:j] isKindOfClass:[NoteGroupM class]]) {
                            NoteGroupM* noteFollow = (NoteGroupM*)[measure.mMeasureDatas objectAtIndex:j];
                            if (noteFollow.mBeams.count){
                                for (BeamM* beamFollow in noteFollow.mBeams) {
                                    // continue && not Paired
                                    if (beamFollow.mValue == EBeamType_Continue &&
                                        beamFollow.mNumber == beam.mNumber) {
                                        if (![consivesNoteGroup containsObject:noteFollow]) {
                                            [consivesNoteGroup addObject:noteFollow];
                                        }
                                    }
                                    // end && not Paired
                                    if (beamFollow.mValue == EBeamType_End &&
                                        beamFollow.mNumber == beam.mNumber) {
                                        if (![consivesNoteGroup containsObject:noteFollow]) {
                                            [consivesNoteGroup addObject:noteFollow];
                                        }
                                        beam.mEnd = noteFollow;
                                        findEnd = YES;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if (consivesNoteGroup.count>2) {
                [self lineUpNoteGroups:consivesNoteGroup];
            }else if (consivesNoteGroup.count == 2) {
                [self closeNoteGroups:consivesNoteGroup];
            }
            
        }
    }
}

-(void)closeNoteGroups:(NSMutableArray<NoteGroupM*>*)noteGroups {
    NoteGroupM* firstGroup = [noteGroups firstObject];
    NoteGroupM* lastGroup = [noteGroups lastObject];
    /* Bring the stem ends closer together */
    int distance = abs(firstGroup.mStemEndY - lastGroup.mStemEndY);
    if (firstGroup.mStemEndY < lastGroup.mStemEndY) {
        firstGroup.mStemEndY += distance/2;
    }
    else {
        lastGroup.mStemEndY += distance/2;
    }
}
-(void)lineUpNoteGroups:(NSMutableArray<NoteGroupM*>*)noteGroups {

    NoteGroupM* firstGroup = noteGroups[0];
    NoteGroupM* lastGroup = [noteGroups lastObject];
    if (firstGroup.mSetStemTail && lastGroup.mSetStemTail) {
        // 已被处理
        return;
    }
    double firstEndY = 0,lastEndY = 0;
    if (firstGroup.mStem == lastGroup.mStem){
        if (firstGroup.mStem == ENoteStem_UP) {
            int top = [firstGroup mStemEndY];
            for (NoteGroupM* note in noteGroups) {
                top = top < [note mStemEndY] ? top : [note mStemEndY];
            }
            if (top == [firstGroup mStemEndY] && top - lastGroup.mStemEndY <= -2*NoteHeight) {
                firstGroup.mStemEndY = top;
                lastGroup.mStemEndY = top + 2 * NoteHeight;
            }else if  (top == [lastGroup mStemEndY] && top - firstGroup.mStemEndY <= -2*NoteHeight) {
                firstGroup.mStemEndY = top + 2 * NoteHeight;
                lastGroup.mStemEndY = top;
            }else {
                firstGroup.mStemEndY = top;
                lastGroup.mStemEndY = top;
            }
        }else {
            int bottom = [firstGroup mStemEndY];
            for (NoteGroupM* note in noteGroups) {
                bottom = bottom > [note mStemEndY]? bottom : [note mStemEndY];
            }
            if (bottom == [firstGroup mStemEndY] && bottom - [lastGroup mStemEndY] >= 2*NoteHeight) {
                lastGroup.mStemEndY = bottom - 2*NoteHeight;
            }else if  (bottom == [lastGroup mStemEndY] && bottom - [firstGroup mStemEndY] >= 2*NoteHeight) {
                firstGroup.mStemEndY = bottom - 2*NoteHeight;
            }else {
                firstGroup.mStemEndY = bottom;
                lastGroup.mStemEndY = bottom;
            }
        }
        firstEndY = firstGroup.mStemEndY;
        lastEndY = lastGroup.mStemEndY;
        /* All middle stems have the same end */
        for (int i = 1; i < [noteGroups count]-1; i++) {
            NoteGroupM * note = noteGroups[i];
            note.mStemEndY = (note.mDefaultX - firstGroup.mDefaultX)/(lastGroup.mDefaultX - firstGroup.mDefaultX) * (lastEndY - firstEndY) + firstEndY;
        }
    }else {
        int firstStaffBottom  = 0,secondStaffTop = 0;
        for (NoteGroupM* note in noteGroups) {
            if (note.mStem == ENoteStem_UP) {
                if(!secondStaffTop || secondStaffTop > [note mStemEndY]){
                    secondStaffTop = [note mStemEndY];
                }
            }else if(note.mStem == ENoteStem_DOWN) {
                if(!firstStaffBottom || firstStaffBottom < [note mStemEndY]){
                    firstStaffBottom = [note mStemEndY];
                }
            }
        }
        if(firstGroup.mStem == ENoteStem_UP){
            int middle = (secondStaffTop + firstStaffBottom + (PartHeight + PartMarin))* 0.5;
            firstGroup.mStemEndY = middle + NoteHeight - (PartMarin + PartHeight) ;
            lastGroup.mStemEndY = middle - NoteHeight;
            
            firstEndY = firstGroup.mStemEndY;
            lastEndY = lastGroup.mStemEndY - (PartHeight + PartMarin);
            for (int i = 1; i < [noteGroups count]-1; i++) {
                NoteGroupM * note = noteGroups[i];
                if (note.mStem == ENoteStem_UP) {
                    note.mStemEndY = (note.mDefaultX - firstGroup.mDefaultX)/(lastGroup.mDefaultX - firstGroup.mDefaultX) * (lastEndY - firstEndY) + firstEndY;
                }else{
                    note.mStemEndY = (note.mDefaultX - firstGroup.mDefaultX)/(lastGroup.mDefaultX - firstGroup.mDefaultX) * (lastEndY  - firstEndY) + firstEndY + (PartHeight + PartMarin);
                }
            }
        }else{
            int middle = (secondStaffTop + firstStaffBottom + (PartHeight + PartMarin))* 0.5;
            firstGroup.mStemEndY = middle - NoteHeight;
            lastGroup.mStemEndY = middle + NoteHeight - (PartMarin + PartHeight)  ;
            
            firstEndY = firstGroup.mStemEndY;
            lastEndY = lastGroup.mStemEndY + PartHeight + PartMarin;
            
            for (int i = 1; i < [noteGroups count]-1; i++) {
                NoteGroupM * note = noteGroups[i];
                if (note.mStem == ENoteStem_DOWN) {
                    note.mStemEndY = (note.mDefaultX - firstGroup.mDefaultX)/(lastGroup.mDefaultX - firstGroup.mDefaultX) * (lastEndY - firstEndY) + firstEndY;
                }else{
                    note.mStemEndY = (note.mDefaultX+[note drawWidth] - firstGroup.mDefaultX)/(lastGroup.mDefaultX+[note drawWidth] - firstGroup.mDefaultX) * (lastEndY  - firstEndY) + firstEndY - (PartHeight + PartMarin);
                }
            }
        }
    }
    [noteGroups enumerateObjectsUsingBlock:^(NoteGroupM * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.mSetStemTail = YES;
    }];
}

-(void)processScore:(ScoreM*)score {
    NSMutableDictionary* minWidth = @{}.mutableCopy;
    for (int i = 0; i < score.mParts.count; i++) {
        PartM* part = score.mParts[i];
        
        NSMutableDictionary* partWidth = @{}.mutableCopy;
        DrawableNoteM* lastNote = nil;
        for (int indexM = 0 ; indexM < part.mMeasures.count; indexM ++) {
            MeasureM* measure = part.mMeasures[indexM];
            for (int indexMD = 0; indexMD < measure.mMeasureDatas.count; indexMD++) {
                DrawableNoteM* data = measure.mMeasureDatas[indexMD];
                if ([data isKindOfClass:[BackupM class]]) {
                    continue;
                }
//                if([data isKindOfClass:[RestM class]] && ((RestM*)data).mHasMeasure ){
//                    continue;
//                }
                [partWidth setObject:@(data.mDuration) forKey:@(data.mStartTime)];
                lastNote = data;
                
                if ([minWidth objectForKey:@(data.mStartTime)] && [[minWidth objectForKey:@(data.mStartTime)] doubleValue] < data.mDuration) {
                }else{
                    // 过滤0 （grace）
                    if (abs(data.mDuration - 0) >  CGFLOAT_MIN){
                        [minWidth setObject:@(data.mDuration * 1.5) forKey:@(data.mStartTime)];
                    }
                }
            }
        }
    }
    
    NSArray* startTimeArr = minWidth.allKeys;
    startTimeArr = [startTimeArr sortedArrayUsingComparator:^NSComparisonResult(NSNumber* obj1, NSNumber* obj2) {
        return [obj1 compare:obj2];
    }];
    // starttime => defaultX
    NSMutableDictionary* xArr = @{}.mutableCopy;
    NSNumber* lastKey = nil;
    for(int indexKey = 0 ;indexKey < startTimeArr.count ;indexKey++){
        NSNumber* key = startTimeArr[indexKey];
        // fix width
        double width = [[minWidth objectForKey:key] doubleValue];
        if (width >= DivisionUnit* 2){
            [minWidth setObject:@(width * 0.6) forKey:key];
        }else if (width >= DivisionUnit* 1.5){
            [minWidth setObject:@(width * 0.8) forKey:key];
        }else if (width <= DivisionUnit * 0.5){
            [minWidth setObject:@(DivisionUnit* 0.5) forKey:key];
        }
        double defaultX = 0;
        defaultX = [[xArr objectForKey:lastKey] doubleValue] + [[minWidth objectForKey:lastKey] doubleValue];
        [xArr setObject:@(defaultX) forKey:key];
        lastKey = key;
    }
    
    // set global DefaultX and adjustDuration
    for(int indexP = 0; indexP < score.mParts.count; indexP++) {
        PartM* part = score.mParts[indexP];
        for(int indexM = 0; indexM < part.mMeasures.count; indexM ++) {
            MeasureM* measure = part.mMeasures[indexM];
            DrawableNoteM* lastMeasureData = nil;
            for(int indexMD = 0; indexMD < measure.mMeasureDatas.count; indexMD ++) {
                DrawableNoteM* data = measure.mMeasureDatas[indexMD];
                data.mDefaultX = [[xArr objectForKey:@(data.mStartTime)] doubleValue];
//                if([maxWidth objectForKey:@(data.mStartTime)]){
                    data.mAjustDuration = [[minWidth objectForKey:@(data.mStartTime)]doubleValue];
//                }else{
//                    data.mAjustDuration = data.mDuration;
//                }
                if (lastMeasureData.mStartTime < data.mStartTime || !lastMeasureData){
                    lastMeasureData = data;
                }
            }
            measure.mWidth = lastMeasureData.mDefaultX + lastMeasureData.mAjustDuration - measure.mMeasureDatas[0].mDefaultX;
        }
    }

    // align measure width
    for(int measureIndex = 0; measureIndex < [[score.mParts[0] mMeasures]count]; measureIndex++) {
        MeasureM * measureFirst = [score.mParts[0] mMeasures][measureIndex];
        double measureStart = measureFirst.mMeasureDatas.firstObject.mDefaultX,
        measureEnd = measureStart + measureFirst.mWidth;
        for (int i = 1; i < score.mParts.count; i++) {
            MeasureM * measure = [score.mParts[i] mMeasures][measureIndex];
            if (measureStart > measure.mMeasureDatas.firstObject.mDefaultX) {
                measureStart = measure.mMeasureDatas.firstObject.mDefaultX;
            }
            if (measureEnd  < measure.mMeasureDatas.firstObject.mDefaultX + measure.mWidth) {
                measureEnd = measure.mMeasureDatas.firstObject.mDefaultX + measure.mWidth;
            }
        }
        measureFirst.mWidth = measureEnd - measureStart;
    }
    PartM* partMax = score.mParts[0];
    for(int i = 1;i<score.mParts.count;i++){
        PartM* part = score.mParts[i];
        for(int measureIndex = 0; measureIndex < [[part mMeasures]count]; measureIndex++) {
            MeasureM * measure = [part mMeasures][measureIndex];
            measure.mWidth = [[partMax mMeasures][measureIndex] mWidth];
        }
    }
    
    
    // set relative DefaultX  加入 measurePadding 计算
    for(int indexP = 0; indexP < score.mParts.count; indexP++) {
        PartM* part = score.mParts[indexP];
        double measurePreX = 0;
        int paddingCount = 0;
        for(int indexM = 0; indexM < part.mMeasures.count; indexM ++) {
            MeasureM* measure = part.mMeasures[indexM];
            for(int indexMD = 0; indexMD < measure.mMeasureDatas.count; indexMD ++) {
                DrawableNoteM* data = measure.mMeasureDatas[indexMD];
                data.mDefaultX = [[xArr objectForKey:@(data.mStartTime)] doubleValue] - measurePreX + PaddingInMeasure + PaddingInMeasure * 2 * paddingCount;
            }
            measure.mWidth += (2 * PaddingInMeasure);
            measurePreX += measure.mWidth;
            paddingCount++;
        }
    }
}


-(void)processConflictMeasure:(ScoreM*)score {
    for (int scoreIndex = 0 ;scoreIndex < score.mParts.count; scoreIndex++){
        PartM* part = score.mParts[scoreIndex];
        for (int measureIndex = 0; measureIndex < part.mMeasures.count; measureIndex++) {
            MeasureM* measure = part.mMeasures[measureIndex];
            for (int i = 0 ; i < measure.mMeasureDatas.count ; i ++ ) {
                DrawableNoteM* note1 = [measure.mMeasureDatas objectAtIndex:i];
                for (int j = i+1 ; j < measure.mMeasureDatas.count ; j ++ ) {
                    DrawableNoteM* note2 = [measure.mMeasureDatas objectAtIndex:j];
                    if ([note1 isKindOfClass:[NoteGroupM class]]&&
                        [note2 isKindOfClass:[NoteGroupM class]]&&
                        [note1 mStaffth] == [note2 mStaffth]&&
                        [note1 mStartTime] == [note2 mStartTime]){
                        NoteGroupM* first = (NoteGroupM*)note1;
                        NoteGroupM* second = (NoteGroupM*)note2;
//                        if (first.mNoPrintObject == NO || second.mNoPrintObject == NO){
//                            continue;
//                        }
                        if (first.mChoice != ENoteChoice_Grace && second.mChoice != ENoteChoice_Grace) {
                            if (first.mStem == ENoteStem_UP &&
                                second.mStem == ENoteStem_DOWN){
                                int dist = [[first getBottomNote] dist:[second getTopNote]];
                                if (dist >= -2 &&dist < 2) {
                                    [first setOffset:6];
                                }else if(dist < -2) {
                                    [second setOffset:-6];
                                }
                            } else if (first.mStem == ENoteStem_DOWN &&
                                       second.mStem == ENoteStem_UP) {
                                int dist = [[first getTopNote] dist:[second getBottomNote]];
                                if (dist >= -2 && dist < 2) {
                                    [first setOffset:NoteWidth * 1.5];
                                }else if(dist < -2) {
                                    [second setOffset:-NoteWidth * 1.5];
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

/*
 确定除去margin之后可绘制区域的宽度，为预期设定的part的宽度
 对所有的part进行遍历
 对每个part的measure进行遍历
    将每个measure存储到一个新创建的MeasureM实例中，并给实例的属性(measureIndex, mLine)进行赋值
    当最后一个measure超出了预期的part宽度，对该part中之前所有的measure的宽度进行调整，设置比例参数为预期part的宽度和该part之前所有measure的宽度和之比，然后将之前所有的measure的宽度都乘以这个比例值。
 在确定每个measure所在行之后，计算每个measure开始绘制的横坐标，将每个measure的mLine的值和当前行数进行对比，若不同则将当前行数加一并把该measure开始绘制的横坐标设为0
 
 */

-(void)spliteMeasuresToMultiLine:(ScoreM*)score {
    
    // scale measures
    NSInteger screenWidth = self.mSize.width;
    NSInteger mainWidth = screenWidth - ( Part_Left_Margin + Part_Right_Margin + MeasureAttributeWidth);
    for (int partIndex = 0;partIndex < score.mParts.count; partIndex++){
        int lineNumer = 1;
        PartM* part = score.mParts[partIndex];
        double tempWidth = 0;
        int previosLineIndex = 0;
        for (int measureIndex = 0; measureIndex < part.mMeasures.count; measureIndex++) {
            MeasureM* measure = part.mMeasures[measureIndex];
            measure.mMeasureIndex = measureIndex;
            if (measure.mWidth * 0.5 + tempWidth > mainWidth) {
                // 该measure 换行 将之前的measure 设置 rate
                double rate = mainWidth / tempWidth;
                for (int j = measureIndex-1;j>= previosLineIndex ;j--){
                    MeasureM* temp = part.mMeasures[j];
                    temp.mWidthRatio = rate;
                }
                lineNumer++;
                measure.mLine = lineNumer;
                tempWidth = measure.mWidth;
                previosLineIndex = measureIndex;
            }else {
                
                tempWidth += measure.mWidth;
                measure.mLine = lineNumer;
            }
        }
        if (tempWidth > mainWidth){
            // 最后一行要缩小
            double rate = mainWidth / tempWidth;
            for (int j = (int)part.mMeasures.count-1;j>= previosLineIndex ;j--){
                MeasureM* temp = part.mMeasures[j];
                temp.mWidthRatio = rate;
            }
        }
        score.mLines = lineNumer;
    }

    
    // 计算每个measure的startX
    for (int partIndex = 0;partIndex < score.mParts.count; partIndex++){
        PartM* part = score.mParts[partIndex];
        double startX = 0;
        int line = 1;
        for (int measureIndex = 0; measureIndex < part.mMeasures.count; measureIndex++) {
            MeasureM* measure = part.mMeasures[measureIndex];
            if (measure.mLine != line) {
                line++;
                startX = 0;
            }
            measure.mStartX = startX;
            startX += measure.mWidth;
        }
    }
}

-(NSMutableDictionary *)mPartClefs{
    if(!_mPartClefs){
        _mPartClefs = @{}.mutableCopy;
    }
    return _mPartClefs;
}

-(NSString*)stringFromStringType:(std::string)text{
    return [NSString stringWithCString:text.c_str()
                                             encoding:[NSString defaultCStringEncoding]];
}
-(void)dealloc{
    CILog(@"MidiFile dealloc");
}
@end
