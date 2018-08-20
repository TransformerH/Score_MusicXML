//
//  NotationM.h
//  CIProgressHUD
//
//  Created by tanhui on 2017/11/2.
//

#import <Foundation/Foundation.h>
#import "DrawableNoteM.h"

typedef NS_ENUM(NSInteger, ESlurType) {
    ESlurType_Begin =0 ,
    ESlurType_End,
    ESlurType_Continue,
};

typedef NS_ENUM(NSInteger, EOrientation) {
    EOrientation_Above =0 ,
    EOrientation_Below,
    EOrientation_None
};

typedef NS_ENUM(NSInteger, EArticulationChoice) {
    accent = 1,
    strongAccent = 2,
    staccato_ = 3,
    tenuto = 4,
    detachedLegato = 5,
    staccatissimo = 6,
    spiccato_ = 7,
    scoop = 8,
    plop = 9,
    doit = 10,
    falloff = 11,
    breathMark = 12,
    caesura = 13,
    stress = 14,
    unstress = 15,
    otherArticulation = 16
};
typedef NS_ENUM(NSInteger, ENotationChioce) {
    Tie = 1,
    Slur = 2,
    tuplet = 3,
    glissando = 4,
    slide = 5,
    ornaments = 6,
    technical = 7,
    Articulations = 8,
    dynamics = 9,
    fermata = 10,
    arpeggiate = 11,
    nonArpeggiate = 12,
    accidentalMark = 13,
    otherNotation = 14
};

@class NoteGroupM;
@class NoteM;
@interface SlurM: NSObject
@property(nonatomic, assign) ESlurType mValue;
@property(nonatomic, assign) NSInteger mNumber;
@property(nonatomic, strong) NoteGroupM* mEnd;
@property(nonatomic, weak) NoteGroupM* mStart;
@property(nonatomic, assign) EOrientation mPlacement;
@property(nonatomic, assign) BOOL mPaired;
-(instancetype)initWithType:(ESlurType)value number:(NSInteger)number placement:(EOrientation)placement;
@end

@interface TiedM: NSObject
@property(nonatomic, assign) ESlurType mValue;
@property(nonatomic, assign) NSInteger mNumber;
@property(nonatomic, strong) NoteGroupM* mEnd;
@property(nonatomic, weak) NoteGroupM* mStart;
@property(nonatomic, weak) NoteM* mNote;
@property(nonatomic, assign) EOrientation mPlacement;
@property(nonatomic, assign) BOOL mPaired;
@property(nonatomic, assign) BOOL mDrawFromSide;
-(instancetype)initWithType:(ESlurType)value number:(NSInteger)number placement:(EOrientation)placement;
@end

@interface ArticulationM: NSObject
@property(nonatomic, assign) EArticulationChoice mChoice;
@end

@interface NotationM : NSObject<DrawableProtocol>
@property(nonatomic, weak) NoteGroupM* mParentNoteG;
@property(nonatomic, assign) ENotationChioce mChoice;
@property(nonatomic, strong) SlurM* mSlur;
@property(nonatomic, strong) TiedM* mTie;
@property(nonatomic, strong) NSArray<ArticulationM*>* mArticulations;
-(void)setPlaceMent:(EOrientation)orient;
-(EOrientation)getPlaceMent;
@end
