//
//  NoteM.m
//  iOSMusic
//
//  Created by tanhui on 2017/7/12.
//  Copyright © 2017年 tanhui. All rights reserved.
//

#import "NoteM.h"
#import "Constants.h"
#import "AccidM.h"
#import "MeasureM.h"
@implementation BeamM
@end
@implementation ForwardM
@end
@implementation BackupM
@end
@implementation NoteM

/**
 自定义初始化方法

 @param step ENoteStep
 @param actave Integer
 @return instance
 */
+(instancetype)allocWithLetter:(ENoteStep)step andOctave:(NSInteger)actave{
    NoteM *note = [[NoteM alloc]init];
    note.mStep = step;
    note.mOctave = actave;
    return note;
}

-(void)drawRect:(CGRect)rect{
    
}

/**
 音符比较

 @param n 待比较音符
 @return 差值
 */
- (int)dist:(NoteM *)n {
    return (int)(self.mOctave - [n mOctave]) * 7 + (self.mStep - [n mStep]);
}

/**
 比较音符值大小

 @param x first
 @param y second
 @return 较小的那个
 */
+(NoteM *)min:(NoteM*)x with:(NoteM*)y{
    if ([x dist:y] < 0)
        return x;
    else
        return y;
}
/**
 比较音符值大小
 
 @param x first
 @param y second
 @return 较大的那个
 */
+(NoteM *)max:(NoteM*)x with:(NoteM*)y{
    if ([x dist:y] > 0)
        return x;
    else
        return y;
}
/**
 判断音符是否相等

 @param object 待比较
 @return Bool
 */
-(BOOL)isEqual:(NoteM *)object{
    return [self dist:object] == 0;
}

/**
 音符绘制添加偏移 （上下）

 @param offset 偏移数值
 @return 偏移后的note
 */
- (NoteM *)add:(NSInteger)offset {
    long num = self.mOctave * 7 + self.mStep;
    num += offset;
    if (num < 0) {
        num = 0;
    }
    NoteM* note = [[NoteM alloc]init];
    note.mOctave = num/7;
    note.mStep = num%7;
    return note;
}


/**
 根据音调，获取五线谱最上方一条线，对应音符的数值

 @param clef 当前谱号
 @return 对应音符
 */
+(NoteM *)getTop:(EClef)clef{
    NoteM * note = [[NoteM alloc]init];
    if (clef == EClef_TREBLE){
        note.mStep = ENoteStep_E;
        note.mOctave = 5;
    }else {
        note.mStep = ENoteStep_G;
        note.mOctave = 3;
    }
    return note;
}


/**
 通过xml accid 数据判断是升调还是降调

 @param mAccid EAccidType
 */
-(void)setMAccid:(EAccidType)mAccid{
    _mAccid = mAccid;
}

/**
 音符的数值

 @return 数值
 */
-(int)noteNumber{
    int mStepMap[7] = {0,2,4,5,7,9,11};
    int num =  mStepMap[self.mStep] + (self.mOctave+1)* 12 + (int)self.mAlter;
    return num;
}



-(AccidM *)accidSymbol{
    if (self.mAccid != EAccidType_None) {
        AccidM* accid = [[AccidM alloc]initWithType:self.mAccid andNote:self andClef:self.mCurrentAttr.mClef.mValue];
        return accid;
    }
    return nil;
}

@end


@interface NoteGroupM()
@property(nonatomic, strong) NSMutableArray* mNotes;
@property(nonatomic, assign) NSInteger mDotNum;
//@property(nonatomic, strong) NSMutableArray * accidArr;
@end

@implementation NoteGroupM

/**
 初始化

 @param notes 音符数组
 @return instance
 */
-(instancetype)initWithNotes:(NSMutableArray *) notes{
    if (![notes count]) {
        return nil;
    }
    if ([super init]){
        _mNotes = notes.mutableCopy;
        for (NoteM* note in _mNotes) {
            _mDotNum += note.mDotNum;
        }
    }
    self.mStem = ENoteStem_None;
    return self;
}

/**
 添加音符

 @param note 音符
 */
-(void)addNote:(NoteM *)note{
    [_mNotes addObject:note];
    
    _mNotes = [_mNotes sortedArrayUsingComparator:^NSComparisonResult(NoteM* note1, NoteM* note2) {
        return [note1 dist:note2]<0;
    }].mutableCopy;
    NoteM* previous = nil;
    self.mDotNum = 0;
    for (NoteM* note in self.mNotes) {
        if (previous && [note dist:previous]>=-1) {
            note.oppsiteSide = YES;
        }
        self.mDotNum += note.mDotNum;
        previous = note;
    }
}

-(void)drawRect:(CGRect)rect{
    int ytop = 0;
    NoteM* topStaff = [NoteM getTop:self.mCurrentAttr.mClef.mValue];
//    if (self.mNoPrintObject){
//        [[UIColor lightGrayColor] set];
//    } else {
        [[UIColor blackColor]set];
//    }
    [self drawNotes:ytop topStaff:topStaff];
    [self drawAccid:ytop topStaff:topStaff];
    [self drawStem:ytop topStaff:topStaff];
    [[UIColor blackColor]set];
}

#pragma mark -- PrivateMethod

/**
 绘制音符升降音记号
 
 @param ytop
 @param topStaff
 */
-(int)drawAccid:(int)ytop topStaff:(NoteM*)topStaff{
    int xpos = 2;
    for (NoteM *noteM in self.notes) {
        if ([noteM accidSymbol]) {
            AccidM *symbol = [noteM accidSymbol];
            xpos += [symbol drawWidth];
            CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(-xpos, 0));
            [symbol drawRect:CGRectZero];
            CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(xpos, 0));
        }
    }
    return 0;
}

/**
 绘制音符符干以及尾巴
 
 @param ytop
 @param topStaff
 */
-(void)drawStem:(int)ytop topStaff:(NoteM*)topStaff{
    if (self.mNotations.count) {
        [self drawNotationCurv:ytop topStaff:topStaff];
    }
    if (self.mStem == ENoteStem_None)return;
    [self drawVerticalLine:ytop topStaff:topStaff];
    if (self.mBeams.count) {
        [self drawBeamStem:ytop topStaff:topStaff];
    }else{
        [self drawCurvyStem:ytop topStaff:topStaff];
    }
    
}

/**
 绘制音符的额外装饰
 
 @param ytop
 @param topstaff
 */
- (void)drawNotationCurv:(int)ytop topStaff:(NoteM*)topstaff {
    NoteM* topStaff = [NoteM getTop:self.mCurrentAttr.mClef.mValue];
    for (NotationM* notation in self.mNotations) {
        [notation drawInNote:self];
    }
}

/**
 绘制音符beam（直的连线）

 @param ytop
 @param topstaff
 */
- (void)drawBeamStem:(int)ytop topStaff:(NoteM*)topstaff {
    int i = 0;
    for (BeamM* beam in self.mBeams) {
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path setLineWidth:MIDILineWidth*3];
        double x_ori = 0,y_ori = 0 ,x_des = 0,y_des = 0;
        if (beam.mValue == EBeamType_Begin && beam.mEnd) {
            
            if (self.mStem == ENoteStem_UP) {
                y_ori =  i * MIDILineWidth*5 + self.mStemEndY;
                x_ori = NoteWidth;
                y_des =  i * MIDILineWidth*5 + beam.mEnd.mStemEndY;
                x_des = x_ori + beam.mEnd.mDefaultX - self.mDefaultX  + 1;
                if (self.mStem != beam.mEnd.mStem) {
                    y_des -= (PartMarin + PartHeight);
                    x_des -= [self drawWidth];
                }
            }else if(self.mStem == ENoteStem_DOWN){
                y_des =  - i * MIDILineWidth*5 + beam.mEnd.mStemEndY;
                y_ori = - i * MIDILineWidth*5 + self.mStemEndY;
                x_ori = 0;
                x_des = x_ori + beam.mEnd.mDefaultX  - self.mDefaultX + 1;
                if (self.mStem != beam.mEnd.mStem) {
                    y_des += PartMarin + PartHeight;
                    x_des += [self drawWidth];
                }
            }
            
        }
        
        if (beam.mValue == EBeamType_End_BACK){
            if (self.mStem == ENoteStem_UP) {
                y_ori =  i * MIDILineWidth*5 + self.mStemEndY;
                x_ori = NoteWidth;
                x_des = x_ori -NoteWidth*0.5 + 1;
                y_des = y_ori;
                
            }else if(self.mStem == ENoteStem_DOWN){
                y_ori =  - i * MIDILineWidth*5 + self.mStemEndY;
                x_ori = 0;
                y_des = y_ori;
                x_des = x_ori- NoteWidth*0.5 + 1;
            }
        }
        
        [path moveToPoint:CGPointMake(x_ori, y_ori)];
        [path addLineToPoint:CGPointMake( x_des, y_des)];
        [path stroke];
        i++;
    }
}

/**
 绘制音符尾巴

 @param ytop ytop
 @param topstaff 五线谱最上面一条线对应note
 */
- (void)drawCurvyStem:(int)ytop topStaff:(NoteM*)topstaff {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path setLineWidth:MIDILineWidth];
    
    int xstart = MIDILineWidth;
    if (self.mStem == ENoteStem_DOWN)
        xstart = LineSpace/4 ;
    else
        xstart = LineSpace/4 + NoteWidth;
    
    double curX_offset = LineSpace,curY_offset = NoteHeight*2.5,
    controlX_1 = curX_offset * 0.38,controlY_1 = curY_offset * 0.6 ,controlX_2 =  curX_offset * 1.37,controlY_2 = curY_offset * 0.55;
    
    if (self.mChoice == ENoteChoice_Grace) {
        curX_offset = LineSpace-3, curY_offset = NoteHeight,controlY_1 = LineSpace ,controlX_2 =  LineSpace * 1.5,controlY_2 = NoteHeight;
    }
    if (self.mStem == ENoteStem_UP) {
        NSInteger ystem = self.mStemEndY;
        if (self.mType == ENoteType_EIGTHTH ||
            self.mType == ENoteType_SIXTEENTH ||
//            duration == Triplet ||
            self.mType == ENoteType_TIRTH_SECOND) {
            
            [path moveToPoint:CGPointMake(xstart, ystem)];
            [path addCurveToPoint:CGPointMake(xstart + curX_offset,
                                              ystem + curY_offset)
                    controlPoint1:CGPointMake(xstart + controlX_1,
                                              ystem + controlY_1)
                    controlPoint2:CGPointMake(xstart + controlX_2,
                                              ystem + controlY_2)
             ];
            
            [path moveToPoint:CGPointMake(xstart, ystem+3)];
            [path addCurveToPoint:CGPointMake(xstart + curX_offset,
                                              ystem + curY_offset)
                    controlPoint1:CGPointMake(xstart + controlX_1,
                                              ystem + controlY_1)
                    controlPoint2:CGPointMake(xstart + controlX_2,
                                              ystem + controlY_2)
             ];
        }
        ystem += NoteHeight;
        
        if (self.mType == ENoteType_SIXTEENTH ||
            self.mType == ENoteType_TIRTH_SECOND) {
            
            [path moveToPoint:CGPointMake(xstart, ystem)];
            [path addCurveToPoint:CGPointMake(xstart + curX_offset,
                                              ystem + curY_offset)
                    controlPoint1:CGPointMake(xstart + controlX_1,
                                              ystem + controlY_1)
                    controlPoint2:CGPointMake(xstart + controlX_2,
                                              ystem + controlY_2)
             ];
            
            [path moveToPoint:CGPointMake(xstart, ystem+3)];
            [path addCurveToPoint:CGPointMake(xstart + curX_offset,
                                              ystem + curY_offset)
                    controlPoint1:CGPointMake(xstart + controlX_1,
                                              ystem + controlY_1)
                    controlPoint2:CGPointMake(xstart + controlX_2,
                                              ystem + controlY_2)
             ];
            
        }
        
        ystem += NoteHeight;
        if (self.mType == ENoteType_TIRTH_SECOND) {
            [path moveToPoint:CGPointMake(xstart, ystem)];
            [path addCurveToPoint:CGPointMake(xstart + curX_offset,
                                              ystem + curY_offset)
                    controlPoint1:CGPointMake(xstart + controlX_1,
                                              ystem + controlY_1)
                    controlPoint2:CGPointMake(xstart + controlX_2,
                                              ystem + controlY_2)
             ];
            
            [path moveToPoint:CGPointMake(xstart, ystem+3)];
            [path addCurveToPoint:CGPointMake(xstart + curX_offset,
                                              ystem + curY_offset)
                    controlPoint1:CGPointMake(xstart + controlX_1,
                                              ystem + controlY_1)
                    controlPoint2:CGPointMake(xstart + controlX_2,
                                              ystem + controlY_2)
             ];
        }
    }
    
    else if (self.mStem == ENoteStem_DOWN) {
        int ystem = self.mStemEndY;
        
        if (self.mType == ENoteType_EIGTHTH |
//            duration == Triplet ||
            self.mType == ENoteType_SIXTEENTH ||
            self.mType == ENoteType_TIRTH_SECOND) {
            
            [path moveToPoint:CGPointMake(xstart, ystem)];
            [path addCurveToPoint:CGPointMake(xstart + curX_offset,
                                              ystem - curY_offset )
                    controlPoint1:CGPointMake(xstart + controlX_1,
                                              ystem - controlY_1)
                    controlPoint2:CGPointMake(xstart + controlX_2,
                                              ystem - controlY_2)
             ];
            [path moveToPoint:CGPointMake(xstart, ystem-3)];
            [path addCurveToPoint:CGPointMake(xstart + curX_offset,
                                              ystem - curY_offset )
                    controlPoint1:CGPointMake(xstart + controlX_1,
                                              ystem - controlY_1)
                    controlPoint2:CGPointMake(xstart + controlX_2,
                                              ystem - controlY_2)
             ];
        }
        ystem -= NoteHeight;
        
        if (self.mType == ENoteType_SIXTEENTH ||
            self.mType == ENoteType_TIRTH_SECOND) {
            
            [path moveToPoint:CGPointMake(xstart, ystem)];
            [path addCurveToPoint:CGPointMake(xstart + curX_offset,
                                              ystem - curY_offset )
                    controlPoint1:CGPointMake(xstart + controlX_1,
                                              ystem - controlY_1)
                    controlPoint2:CGPointMake(xstart + controlX_2,
                                              ystem - controlY_2)
             ];
            [path moveToPoint:CGPointMake(xstart, ystem-3)];
            [path addCurveToPoint:CGPointMake(xstart + curX_offset,
                                              ystem - curY_offset )
                    controlPoint1:CGPointMake(xstart + controlX_1,
                                              ystem - controlY_1)
                    controlPoint2:CGPointMake(xstart + controlX_2,
                                              ystem - controlY_2)
             ];
        }
        
        ystem -= NoteHeight;
        if (self.mType == ENoteType_TIRTH_SECOND) {
            [path moveToPoint:CGPointMake(xstart, ystem)];
            [path addCurveToPoint:CGPointMake(xstart + curX_offset,
                                              ystem - curY_offset )
                    controlPoint1:CGPointMake(xstart + controlX_1,
                                              ystem - controlY_1)
                    controlPoint2:CGPointMake(xstart + controlX_2,
                                              ystem - controlY_2)
             ];
            [path moveToPoint:CGPointMake(xstart, ystem-3)];
            [path addCurveToPoint:CGPointMake(xstart + curX_offset,
                                              ystem - curY_offset )
                    controlPoint1:CGPointMake(xstart + controlX_1,
                                              ystem - controlY_1)
                    controlPoint2:CGPointMake(xstart + controlX_2,
                                              ystem - controlY_2)
             ];
        }
    }
    [path stroke];
}

-(void)setOffset:(double)xOff{
    self.mDefaultX += xOff;
}

-(void)addNotations:(NSArray<NotationM*>*)notations{
    if (!_mNotations) {
        _mNotations = notations;
    }else {
        NSMutableArray<NotationM*>* temp = _mNotations.mutableCopy;
        [temp addObjectsFromArray:notations];
        _mNotations = temp.copy;
    }
}


/**
 画直线

 @param ytop
 @param topstaff
 */
-(void)drawVerticalLine:(int)ytop topStaff:(NoteM*)topstaff {
    int xstart = 0;
    
    if (self.mStem == ENoteStem_DOWN){
        xstart = LineSpace/4 ;
    }
    else{
        xstart = LineSpace/4 + NoteWidth;
    }
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(xstart, self.mStemStartY)];
    [path addLineToPoint:CGPointMake(xstart, self.mStemEndY)];
    [path stroke];
    
}


/**
 绘制 音符 数组

 @param ytop y轴值
 @param topStaff 五线谱最上面一条线对应note
 */
-(void)drawNotes:(int)ytop topStaff:(NoteM*)topStaff{
    UIBezierPath *path;
    
    for (NoteM* note in self.mNotes) {
        int ynote = [topStaff dist:note] * NoteHeight/2;
        int xnote = LineSpace/4;
        /* Draw rotated ellipse.  You must first translate (0,0)
         * to the center of the ellipse.
         */
        // 将坐标原点移动到椭圆的中心
        int x_offset = xnote;
        
        if (note.oppsiteSide) {
            if (note.mStem == ENoteStem_UP) {
                 //符杆在右边，向上
                x_offset += NoteWidth;
            }else{
                //符杆在左边，向下
                x_offset -= NoteWidth;
            }
        }
        
        if(note.mNoteHeadType == ENoteHeadType_x){
            CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(1,ynote));
            path = [UIBezierPath bezierPath];
            [path setLineWidth:MIDILineWidth];
            [path moveToPoint:CGPointZero];
            [path addLineToPoint:CGPointMake(NoteWidth, LineSpace)];
            [path moveToPoint:CGPointMake(0, LineSpace)];
            [path addLineToPoint:CGPointMake(NoteWidth, 0)];
            [path stroke];
            CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(-1,-ynote));
        }else{
            CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(x_offset,(ynote )));
            CGContextRotateCTM(UIGraphicsGetCurrentContext(),  -20 * M_PI / 180);
            double start_x = 0.0 ,start_y = 0.0,width = 0,height = 0;
            
            // 判断是否有倚音
            if (self.mChoice == ENoteChoice_Normal) {
                start_x = -NoteWidth/6.33, start_y = NoteWidth/5.73 , width = NoteWidth, height = NoteHeight;
            } else if (self.mChoice == ENoteChoice_Grace)  {
                // 有倚音调整 x, y坐标
                start_x = -NoteWidth/6.33+ 2 , start_y = NoteWidth/5.73 + 2 , width = NoteWidth-2, height = NoteHeight - 2.5;
            }
            
            //
            if (note.mType == ENoteType_WHOLE ||
                note.mType == ENoteType_HALF) {
                path = [UIBezierPath bezierPath];
                [path setLineWidth:1];
                [path appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectMake(start_x, start_y, width, height-1)]];
                [path appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectMake(start_x, start_y + 1, width, height-2)]];
                [path appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectMake(start_x, start_y + 1, width, height-3)]];

                [path stroke];
            }
            else {
                path = [UIBezierPath bezierPath];
                [path setLineWidth:MIDILineWidth];
                [path appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectMake(start_x, start_y, width, height-1)]];
                [path fill];
            }
            path = [UIBezierPath bezierPath];
            
            [path setLineWidth:MIDILineWidth];
            [path appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectMake(start_x, start_y, width, height-1)]];
            [path stroke];
            CGContextRotateCTM(UIGraphicsGetCurrentContext(),  20 * M_PI / 180);
            CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(-x_offset,-(ynote )));
        }
        
        
        /* Draw horizontal lines if note is above/below the staff */
        path = [UIBezierPath bezierPath];
        [path setLineWidth:MIDILineWidth];
        NoteM *top = [topStaff add:1];
        int dist = [note dist:top];
        int y = ytop;
        
        if (dist >= 2) {
            for (int i = 2; i <= dist; i += 2) {
                y -= NoteHeight;
                
                [path moveToPoint:CGPointMake(xnote - LineSpace/3.0, y)];
                [path addLineToPoint:CGPointMake(xnote + NoteWidth + LineSpace/3.0, y) ];
                
            }
        }
        
        NoteM *bottom = [top add:(-8)];
        y = ytop + (LineSpace + MIDILineWidth) * 4 ;
        dist = [bottom dist:note];
        if (dist >= 2) {
            for (int i = 2; i <= dist; i+= 2) {
                y += NoteHeight;
                [path moveToPoint:CGPointMake(xnote - LineSpace/3.0, y) ];
                [path addLineToPoint:CGPointMake(xnote + NoteWidth + LineSpace/3.0, y) ];
            }
        }
        [path stroke];
        
        /* End drawing horizontal lines */
    }
    
    /* Draw a dot if this is a dotted duration. */
    if (self.mDotNum) {
        int xnote = LineSpace/4;
        int ynote = [topStaff dist:self.mTop] * NoteHeight/2;
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path setLineWidth:MIDILineWidth];
        for (int i = 0; i<self.mDotNum; i++) {
            [path appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectMake(xnote + NoteWidth + LineSpace/3, ynote + LineSpace/3, 3, 3)]];
            ynote += NoteHeight;
        }
        [path fill];
    }
}

#pragma mark -- Getter Setter

-(NSArray*)notes{
    return self.mNotes;
}


-(NSInteger)mStemEndY{
    if (!_mStemEndY){
        NoteM* topStaff = [NoteM getTop:self.mCurrentAttr.mClef.mValue];
        double staffHeight = 3*NoteHeight;
        if (self.mChoice == ENoteChoice_Grace) {
            staffHeight = 1.5* NoteHeight;
        }
        if (self.mStem == ENoteStem_UP) {
            _mStemEndY =  [topStaff dist:self.mTop]* NoteHeight/2  - staffHeight;
        }else if (self.mStem == ENoteStem_DOWN){
            _mStemEndY =  [topStaff dist:self.mBottom]* NoteHeight/2 + NoteHeight + staffHeight;
        }else if (self.mStem == ENoteStem_None){
            _mStemEndY = [topStaff dist:self.mBottom]* NoteHeight/2 + NoteHeight;
        }
    }
    return _mStemEndY;
}

-(NSInteger)mStemStartY{
    if (!_mStemStartY) {
        NoteM* topStaff = [NoteM getTop:self.mCurrentAttr.mClef.mValue];
        if (self.mStem == ENoteStem_UP) {
            _mStemStartY =  [topStaff dist:self.mBottom] * NoteHeight/2 + NoteHeight/3
            ;
        }else if (self.mStem == ENoteStem_DOWN){
            _mStemStartY = [topStaff dist:self.mTop] * NoteHeight/2 + NoteHeight - NoteHeight/3;
        }else if (self.mStem == ENoteStem_None){
            _mStemStartY = [topStaff dist:self.mTop] * NoteHeight/2;
        }
    }
    return _mStemStartY;
    
}

-(NoteM *)mTop{
    if(!_mTop){
        _mTop = self.mNotes[0];
        for (NoteM* note in self.mNotes) {
            if ((note.mStep + note.mOctave * 7)>(_mTop.mStep + _mTop.mOctave * 7)) {
                _mTop = note;
            }
        }
    }
    return _mTop;
}

-(NoteM *)mBottom{
    if (!_mBottom) {
        _mBottom = self.mNotes[0];
        for (NoteM* note in self.mNotes) {
            if ((note.mStep + note.mOctave * 7)<(_mBottom.mStep + _mBottom.mOctave * 7)) {
                _mBottom = note;
            }
        }
    }
    return _mBottom;
}

-(NoteM*)getTopNote{
    return self.mTop;
}
-(NoteM*)getBottomNote{
    return self.mBottom;
}

//-(NSMutableArray *)accidArr{
//    if (!_accidArr) {
//        _accidArr = @[].mutableCopy;
//        for (NoteM* note in self.mNotes) {
//            if (note.mAccid != EAccidType_None) {
//                AccidM* accid = [[AccidM alloc]initWithType:note.mAccid andNote:note andClef:note.mCurrentAttr.mClef.mValue];
//                [_accidArr addObject:accid];
//            }
//        }
//    }
//    return _accidArr;
//}

-(double)drawWidth{
    return NoteWidth;
}

@end
