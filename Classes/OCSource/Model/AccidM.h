//
//  AccidM.h
//  Pods
//
//  Created by tanhui on 2017/7/24.
//
//

#import "MeasureAttributeM.h"
#import "NoteM.h"



@interface AccidM : DrawableNoteM
//@property(nonatomic, assign)ENoteStep mStep;
//@property(nonatomic, assign)NSInteger mOctave;
@property(nonatomic, assign)EAccidType mType;
@property(nonatomic, strong)NoteM* mNote;
@property(nonatomic, assign)EClef mClef;


-(instancetype)initWithType:(EAccidType)type andNote:(NoteM*)note andClef:(EClef)clef;
@end
