//
//  NotationM.m
//  CIProgressHUD
//
//  Created by tanhui on 2017/11/2.
//

#import "NotationM.h"
#import "musicXML.h"
#import "Constants.h"
@implementation SlurM

-(instancetype)initWithType:(ESlurType)value number:(NSInteger)number placement:(EOrientation)placement{
    if([super init]){
        self.mValue = value;
        self.mNumber = number;
        self.mPlacement = placement;
    }
    return self;
}
@end

@implementation TiedM

-(instancetype)initWithType:(ESlurType)value number:(NSInteger)number placement:(EOrientation)placement{
    if([super init]){
        self.mValue = value;
        self.mNumber = number;
        self.mPlacement = placement;
    }
    return self;
}
@end

@implementation ArticulationM
@end

@implementation NotationM
#pragma mark -- Private Method

/**
 绘制Notation

 @param currentNoteGroup 当前的notegroup
 */
-(void)drawInNote:(NoteGroupM *)currentNoteGroup{
    NoteM *topstaff = [NoteM getTop:currentNoteGroup.mCurrentAttr.mClef.mValue];
     if (self.mChoice == Articulations) {
        [self drawArticulation:currentNoteGroup topStaff:topstaff ];
     }else if(self.mChoice == Slur ) {
         [self drawSlur:currentNoteGroup topStaff:topstaff ];
     }else if(self.mChoice == Tie){
         [self drawTie:currentNoteGroup topStaff:topstaff ];
     }
}

/**
 绘制Articalation

 @param currentNoteGroup
 @param topStaff 当前的notegroup
 */
-(void)drawArticulation:(NoteGroupM *)currentNoteGroup topStaff:(NoteM *)topStaff {
    double globalYOffset = 0;
    for (ArticulationM* artiM in self.mArticulations) {
        UIBezierPath *path = [UIBezierPath bezierPath];
        double y = 0;
        if (currentNoteGroup.mStem == ENoteStem_UP) {
            y = [topStaff dist:[currentNoteGroup getBottomNote]] * NoteHeight/2 + NoteHeight * 3 / 2;
        } else {
            y = [topStaff dist:[currentNoteGroup getTopNote]] * NoteHeight/2 - NoteHeight -1;
        }
        if (artiM.mChoice == staccato_) {
            // 跳音标示
            [path appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectMake(NoteWidth * 0.5 , y, 2, 2)]];
            [path fill];
            globalYOffset += 2;
        } else if (artiM.mChoice == tenuto) {
            globalYOffset += 2;
            [path moveToPoint:CGPointMake(0, y)];
            [path addLineToPoint:CGPointMake(NoteWidth, y)];
            [path stroke];
        } else if (artiM.mChoice == accent) {
            if (currentNoteGroup.mStem == ENoteStem_UP) {
                y = y + globalYOffset + NoteWidth;
            }else {
                y = y - globalYOffset;
            }
            [path moveToPoint:CGPointMake(0, y)];
            [path addLineToPoint:CGPointMake(NoteWidth, y-NoteWidth* 0.4)];
            [path addLineToPoint:CGPointMake(0, y - NoteWidth* 0.8)];
            [path stroke];
        }
    }
    
}
/**
 绘制连音（Tie）
 
 @param currentNoteGroup
 @param topStaff 当前的notegroup
 */
- (void)drawTie:(NoteGroupM *)currentNoteGroup topStaff:(NoteM *)topStaff{
    TiedM *tieM = self.mTie;
    NoteGroupM *next = tieM.mEnd;
    double x_ori = 0,y_ori = 0 ,x_des = 0,y_des = 0;
    BOOL drawFromSide = NO;
    if ([currentNoteGroup notes].count > 1 ||
        [next notes].count > 1 ||
        tieM.mDrawFromSide) {
        drawFromSide = YES;
    }
    if (tieM.mValue == ESlurType_Begin){
        if (!next) {
            return;
        }
        if (drawFromSide) {
            x_ori = NoteWidth + 2;
            y_ori = [topStaff dist:tieM.mNote] *  NoteHeight * 0.5 + NoteHeight * 0.5;
        } else {
            x_ori = NoteWidth * 0.5 + 2;
            if (tieM.mPlacement == EOrientation_Above) {
                y_ori = currentNoteGroup.mStemStartY - NoteHeight;
            } else {
                y_ori = currentNoteGroup.mStemStartY + NoteHeight;
            }
        }
        y_des = y_ori;
        
        // 不是同一行的Measure
        if (currentNoteGroup.mMeasure.mLine != next.mMeasure.mLine ) {
            MeasureM* tempMeasure = currentNoteGroup.mMeasure;
            // 画第一段线
            double distance = 0;
            while (tempMeasure && tempMeasure.mNextMeasure.mLine == currentNoteGroup.mMeasure.mLine) {
                distance += tempMeasure.mWidth;
                tempMeasure = tempMeasure.mNextMeasure;
            }
            x_des = tempMeasure.mWidth + distance - (currentNoteGroup.mDefaultX + Padding_In_Note ) -2;
            [self drawCurveLine:x_ori desX:x_des oriY:y_ori desY:y_des];
        }else {
            if (currentNoteGroup.mChoice == ENoteChoice_Normal) {
                if (drawFromSide) {
                    x_des = x_ori + next.mDefaultX  - currentNoteGroup.mDefaultX  - 2;
                }else {
                    x_des = x_ori + next.mDefaultX  - currentNoteGroup.mDefaultX -1;
                }
            }
            if(currentNoteGroup.mMeasure != next.mMeasure){
                x_des += (next.mMeasure.mStartX - currentNoteGroup.mMeasure.mStartX);
            }
            [self drawCurveLine:x_ori desX:x_des oriY:y_ori desY:y_des];
        }
    } else {
        NoteGroupM *start = self.mTie.mStart;
        if (!start || currentNoteGroup.mMeasure.mLine == start.mMeasure.mLine ) return;
        MeasureM *temp = start.mMeasure.mNextMeasure;
        while (temp && temp.mLine != currentNoteGroup.mMeasure.mLine) {
            temp = temp.mNextMeasure;
        }
        double distance = currentNoteGroup.mMeasure.mStartX - temp.mStartX + (currentNoteGroup.mDefaultX + Padding_In_Note );
        if (drawFromSide) {
            x_ori = -1;
            y_ori = [topStaff dist:tieM.mNote] * NoteHeight * 0.5 + NoteHeight * 0.5 ;
        } else {
            x_ori = NoteWidth * 0.5 + 1;
            if (tieM.mPlacement == EOrientation_Above) {
                y_ori = currentNoteGroup.mStemStartY - NoteHeight;
            } else {
                y_ori = currentNoteGroup.mStemStartY + NoteHeight;
            }
        }
        x_des = x_ori - distance;
        y_des = y_ori;
        [self drawCurveLine:x_ori desX:x_des oriY:y_ori desY:y_des];
    }
}
/**
 绘制连音（Slur）
 
 @param currentNoteGroup
 @param topStaff 当前的notegroup
 */
- (void)drawSlur:(NoteGroupM *)currentNoteGroup topStaff:(NoteM *)topStaff{
    SlurM* slurM = self.mSlur;
    double x_ori = 0,y_ori = 0 ,x_des = 0,y_des = 0;

    if (slurM.mValue == ESlurType_Begin) {
        if (!slurM.mEnd) return;
        NoteGroupM* next = slurM.mEnd;
        if (slurM.mPlacement == EOrientation_None) {
            if(currentNoteGroup.mStem == ENoteStem_UP &&
               next.mStem == ENoteStem_UP){
                slurM.mPlacement = EOrientation_Below;
            }else {
                slurM.mPlacement = EOrientation_Above;
            }
        }
        x_ori = NoteWidth * 0.5 + 2;
        if (slurM.mPlacement == EOrientation_Above) {
            if (currentNoteGroup.mStem == ENoteStem_UP) {
                y_ori = currentNoteGroup.mStemEndY - NoteHeight;
            } else {
                y_ori = currentNoteGroup.mStemStartY - NoteHeight * 2;
            }
            if (next.mStem == ENoteStem_UP) {
                y_des = next.mStemEndY - NoteHeight;
            } else {
                y_des = next.mStemStartY - NoteHeight * 2;
            }

        }else if (slurM.mPlacement == EOrientation_Below) {
            if (currentNoteGroup.mStem == ENoteStem_UP) {
                y_ori = currentNoteGroup.mStemStartY + NoteHeight * 1.5;
            } else {
                y_ori = currentNoteGroup.mStemEndY + NoteHeight ;
            }
            if (next.mStem == ENoteStem_UP) {
                y_des = next.mStemStartY + NoteHeight * 1.5;
            } else {
                y_des = next.mStemEndY + NoteHeight ;
            }
            
        }
        
        if(currentNoteGroup.mStaffth != next.mStaffth){
            if (currentNoteGroup.mStaffth == 1 && next.mStaffth == 2) {
                y_des += (PartMarin + PartHeight);
            }else if (currentNoteGroup.mStaffth == 2 && next.mStaffth == 1){
                y_des -= (PartMarin + PartHeight);
            }
        }
        
        // 不是同一行的Measure
        if (currentNoteGroup.mMeasure.mLine != next.mMeasure.mLine ) {
            MeasureM* tempMeasure = currentNoteGroup.mMeasure;
            // 画第一段线
            double distance = 0;
            while (tempMeasure && tempMeasure.mNextMeasure.mLine == currentNoteGroup.mMeasure.mLine) {
                distance += tempMeasure.mWidth;
                tempMeasure = tempMeasure.mNextMeasure;
            }
            x_des = tempMeasure.mWidth + distance - (currentNoteGroup.mDefaultX + Padding_In_Note ) -2;
            y_des = y_ori;
            [self drawCurveLine:x_ori desX:x_des oriY:y_ori desY:y_des];
        }else {
            if (currentNoteGroup.mChoice == ENoteChoice_Normal) {
                x_des = x_ori + next.mDefaultX  - currentNoteGroup.mDefaultX  -1;
            } else if (currentNoteGroup.mChoice == ENoteChoice_Grace) {
                x_des = x_ori + Grace_offSet;
            }
            
            if(currentNoteGroup.mMeasure != next.mMeasure){
                x_des += (next.mMeasure.mStartX - currentNoteGroup.mMeasure.mStartX);
            }
            [self drawCurveLine:x_ori desX:x_des oriY:y_ori desY:y_des];
        }
        
    } else if (slurM.mValue == ESlurType_End){
        NoteGroupM* start = self.mSlur.mStart;
        if (!start || currentNoteGroup.mMeasure.mLine == start.mMeasure.mLine ) return;
        MeasureM* temp = start.mMeasure.mNextMeasure;
        while (temp && temp.mLine != currentNoteGroup.mMeasure.mLine) {
            temp = temp.mNextMeasure;
        }
        double distance = currentNoteGroup.mMeasure.mStartX - temp.mStartX + (currentNoteGroup.mDefaultX + Padding_In_Note) - 2;
        x_des = x_ori - distance;
        
        if (slurM.mPlacement == EOrientation_Above) {
            
            y_ori = [topStaff dist:currentNoteGroup.mTop]*NoteHeight/2 - NoteHeight;
            if (currentNoteGroup.mStem == ENoteStem_UP) {
                y_ori = currentNoteGroup.mStemEndY - NoteHeight;
            }
        }else if (slurM.mPlacement == EOrientation_Below) {
            y_ori = currentNoteGroup.mStemStartY + NoteHeight * 1.5;
        }
        y_des = y_ori;
        [self drawCurveLine:x_ori desX:x_des oriY:y_ori desY:y_des];
    }
    
}

/**
 绘制贝塞尔曲线

 @param x_ori 源点X
 @param x_des 目标点X
 @param y_ori 源点Y
 @param y_des 目标点Y
 */
-(void)drawCurveLine:(double)x_ori desX:(double)x_des oriY:(double)y_ori desY:(double)y_des{
    
    CGPoint first ,second;
    if (x_ori < x_des){
        first = CGPointMake(x_ori, y_ori);
        second = CGPointMake(x_des, y_des);
    } else {
        second = CGPointMake(x_ori, y_ori);
        first = CGPointMake(x_des, y_des);
    }
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    double off = (second.x-first.x)* 0.2 > 30 ? 30: (second.x-first.x)* 0.2;
    EOrientation orientation;
    if (self.mChoice == Slur) {
        orientation = self.mSlur.mPlacement;
    } else if (self.mChoice == Tie) {
        orientation = self.mTie.mPlacement;
    } else {
        return;
    }
    [path moveToPoint:first];
    double dist = second.x - first.x;
    if (orientation == EOrientation_Below) {
        if (dist > 50){
            [path addCurveToPoint:second controlPoint1:CGPointMake(first.x + dist * 0.2, first.y + 22) controlPoint2:CGPointMake(second.x - dist * 0.2, second.y + 22)];
            [path addCurveToPoint:first controlPoint1:CGPointMake(second.x - dist * 0.2, second.y + 25) controlPoint2:CGPointMake(first.x + dist * 0.2, first.y + 25)];
        }else {
            CGPoint controlP = CGPointMake((x_des+x_ori)*0.5,(y_ori+y_des)*0.5+off);
            [path addQuadCurveToPoint:second controlPoint:controlP];
            CGPoint controlP2 = CGPointMake((x_des+x_ori)*0.5,(y_ori+y_des)*0.5+off+3);
            [path addQuadCurveToPoint:first controlPoint:controlP2];
        }
    }else{
        if (dist > 50){
            [path addCurveToPoint:second controlPoint1:CGPointMake(first.x + dist * 0.2, first.y - 22) controlPoint2:CGPointMake(second.x - dist * 0.2, second.y - 22)];
            [path addCurveToPoint:first controlPoint1:CGPointMake(second.x - dist * 0.2, second.y - 25) controlPoint2:CGPointMake(first.x + dist * 0.2, first.y - 25)];
        }else{
            CGPoint controlP = CGPointMake((x_des+x_ori)*0.5,(y_ori+y_des)*0.5 - off);
            [path addQuadCurveToPoint:second controlPoint:controlP];
            CGPoint controlP2 = CGPointMake((x_des+x_ori)*0.5,(y_ori+y_des)*0.5 - off - 3);
            [path addQuadCurveToPoint:first controlPoint:controlP2];
        }
    }
    
    [path fill];
}


#pragma mark -- Getter Setter
-(void)setPlaceMent:(EOrientation)orient{
    if (self.mChoice == Slur){
        self.mSlur.mPlacement = orient;
    } else if (self.mChoice == Tie){
        self.mTie.mPlacement = orient;
    }
}
-(EOrientation)getPlaceMent{
    if (self.mChoice == Slur){
        return self.mSlur.mPlacement;
    } else if (self.mChoice == Tie){
        return self.mTie.mPlacement;
    }
    return EOrientation_None;
}

@end

