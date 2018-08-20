//
//  NoteM.h
//  iOSMusic
//
//  Created by tanhui on 2017/7/12.
//  Copyright © 2017年 tanhui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MeasureAttributeM.h"
#import "NotationM.h"

typedef NS_ENUM(NSInteger, ENoteChoice) {
    ENoteChoice_PITCH = 1,
    ENoteChoice_UNPITCH,
    ENoteChoice_REST
};
typedef NS_ENUM(NSInteger, ENoteStep) {
    ENoteStep_A = 5,
    ENoteStep_B = 6,
    ENoteStep_C = 0,
    ENoteStep_D = 1,
    ENoteStep_E = 2,
    ENoteStep_F = 3,
    ENoteStep_G = 4
};
typedef NS_ENUM(NSInteger, ENoteStem) {
    ENoteStem_DOWN = 0,
    ENoteStem_UP,
    ENoteStem_Double,
    ENoteStem_None,
};
typedef NS_ENUM(NSInteger, ENoteType) {
    ENoteType_None = -1,
    ENoteType_oneThousandTwentyFourth = 0,
    ENoteType_fiveHundredTwelfth = 1,
    ENoteType_twoHundredFifthySixth = 2,
    ENoteType_oneHundredTwentyEighth = 3,
    ENoteType_sixtyFourth = 4,
    ENoteType_TIRTH_SECOND = 5,
    ENoteType_SIXTEENTH = 6,
    ENoteType_EIGTHTH = 7,
    ENoteType_QUARTER = 8,
    ENoteType_HALF = 9,
    ENoteType_WHOLE = 10,
    ENoteType_BREVE = 11,
    ENoteType_LONG = 12,
    ENoteType_MAXIMA = 13,
    
};

typedef NS_ENUM(NSInteger, ENoteHeadType) {
    ENoteHeadType_slash = 0,
    ENoteHeadType_triangle = 1,
    ENoteHeadType_diamond = 2,
    ENoteHeadType_square = 3,
    ENoteHeadType_cross = 4,
    ENoteHeadType_x = 5,
    ENoteHeadType_circleX = 6,
    ENoteHeadType_invertedTriangle = 7,
    ENoteHeadType_arrowDown = 8,
    ENoteHeadType_arrowUp = 9,
    ENoteHeadType_slashed = 10,
    ENoteHeadType_backSlashed = 11,
    ENoteHeadType_normal = 12,
    ENoteHeadType_cluster = 13,
    ENoteHeadType_circleDot = 14,
    ENoteHeadType_leftTriangle = 15,
    ENoteHeadType_rectangle = 16,
    ENoteHeadType_none = 17,
    ENoteHeadType_do_ = 18,
    ENoteHeadType_re = 19,
    ENoteHeadType_mi = 20,
    ENoteHeadType_fa = 21,
    ENoteHeadType_faUp = 22,
    ENoteHeadType_so = 23,
    ENoteHeadType_la = 24,
    ENoteHeadType_ti = 25
    
};

typedef NS_ENUM(NSInteger, EBeamType) {
    EBeamType_Begin =0 ,
    EBeamType_Continue,
    EBeamType_End,
    EBeamType_End_FORWARD,
    EBeamType_End_BACK
};

typedef NS_ENUM( NSInteger,ENoteGroupChoice) {
    ENoteChoice_Normal = 0,
    ENoteChoice_Grace,
};

typedef NS_ENUM( NSInteger,EAccidType) {
    EAccidType_None = -1,
    EAccidType_Sharp = 0,
    EAccidType_Natural = 1,
    EAccidType_Flat = 2,
    doubleSharp = 3,
    sharpSharp = 4,
    flatFlat = 5,
    naturalSharp = 6,
    naturalFlat = 7,
    quarterFlat = 8,
    quarterSharp = 9,
    threeQuartersFlat = 10,
    threeQuartersSharp = 11,
    sharpDown = 12,
    sharpUp = 13,
    naturalDown = 14,
    naturalUp = 15,
    flatDown = 16,
    flatUp = 17,
    tripleSharp = 18,
    tripleFlat = 19,
    slashQuarterSharp = 20,
    slashSharp = 21,
    slashFlat = 22,
    doubleSlashFlat = 23,
    sharp1 = 24,
    sharp2 = 25,
    sharp3 = 26,
    sharp5 = 27,
    flat1 = 28,
    flat2 = 29,
    flat3 = 30,
    flat4 = 31,
    sori = 32,
    koron = 33
};



@class NoteGroupM;

@interface BeamM : NSObject
@property(nonatomic, assign) EBeamType mValue;
@property(nonatomic, assign) NSInteger mNumber;
@property(nonatomic, strong) NoteGroupM* mEnd;
@end



@interface NoteM : DrawableNoteM
@property(nonatomic, assign)ENoteChoice mChoice;
@property(nonatomic, assign)ENoteStep mStep;
@property(nonatomic, assign)NSInteger mAlter;
@property(nonatomic, assign)NSInteger mOctave;
@property(nonatomic, assign)ENoteStem mStem;
@property(nonatomic, assign)ENoteType mType;
@property(nonatomic, assign)ENoteHeadType mNoteHeadType;
@property(nonatomic, assign)BOOL mIsChord;
@property(nonatomic, assign)NSInteger mDotNum;
@property(nonatomic, assign)BOOL oppsiteSide;
@property(nonatomic, assign)EAccidType mAccid;

+(instancetype)allocWithLetter:(ENoteStep)step andOctave:(NSInteger)actave;

-(int)noteNumber;

+(NoteM*)max:(NoteM*)x with:(NoteM*)y;
+(NoteM*)min:(NoteM*)x with:(NoteM*)y;
+(NoteM*)getTop:(EClef)clef;
- (int)dist:(NoteM*)n;
- (NoteM*)add:(NSInteger)offset;
@end


@interface NoteGroupM : DrawableNoteM
@property(nonatomic, assign) ENoteGroupChoice mChoice;
@property(nonatomic, strong) NoteM* mTop;
@property(nonatomic, strong) NoteM* mBottom;

@property(nonatomic, assign) NSInteger mStemEndY;
@property(nonatomic, assign) NSInteger mStemStartY;

@property(nonatomic, assign) ENoteStem mStem;
@property(nonatomic, assign) ENoteType mType;
@property(nonatomic, strong) NSArray<BeamM*>* mBeams;
@property(nonatomic, strong, readonly) NSArray<NotationM*>* mNotations;
@property(nonatomic, assign) BOOL mSetStemTail;


-(instancetype)initWithNotes:(NSMutableArray*) notes;
-(void)addNote:(NoteM*)note;
-(NSArray*)notes;
-(NoteM*)getTopNote;
-(NoteM*)getBottomNote;
-(void)setOffset:(double)xOff;
-(void)addNotations:(NSArray<NotationM*>*)notations;
@end

@interface ForwardM : DrawableNoteM
@end

@interface BackupM : DrawableNoteM
@end





