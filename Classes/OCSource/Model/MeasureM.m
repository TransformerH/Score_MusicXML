//
//  PartWiseMeasure.m
//  iOSMusic
//
//  Created by tanhui on 2017/7/11.
//  Copyright © 2017年 tanhui. All rights reserved.
//

#import "MeasureM.h"
#import "Constants.h"
#import "NoteM.h"
#import "RestM.h"
@interface MeasureM ()
@end

#define MeasureLeftMargin 10
@implementation MeasureM

/**
 初始化方法

 @param width
 @param musicDataGroup 音符数组
 @param staff index
 @return instance
 */
-(instancetype)initWithWidth:(float)width musicDataGroup:(NSArray< DrawableNoteM*>*)musicDataGroup staves:(NSInteger)staff{
    if ([super init]) {
        _mMeasureDatas = musicDataGroup;
        _mWidth = width;
        _mStavesNum = staff;
        __weak typeof(self) _weakSelf = self;
        [musicDataGroup enumerateObjectsUsingBlock:^(DrawableNoteM * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.mMeasure = _weakSelf;
        }];
    }
    return self;
}

-(void)dealloc{
    //    CILog(@"Measure Dealloc");
}

#pragma mark -- Private Method
-(UIColor *) randomColor {
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  // 0.5 to 1.0,away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //0.5 to 1.0,away from black
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}

/**
 获取第二个staff 的第一个音符

 @return 音符
 */
-(DrawableNoteM*)getFisrtNoteAtStaffTwo {
    for (DrawableNoteM* musicData in self.mMeasureDatas){
        if (musicData.mStaffth == 2) {
            return musicData;
        }
    }
    return nil;
}

/**
 绘制第一行第一个measure

 @param rect
 */
-(void)drawMeasureFirst:(CGRect)rect {
    double left_margin = 5;
    CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(-(MeasureAttributeWidth - left_margin) , 0));
    if (self.mStavesNum == 1){
        DrawableNoteM* firstInMeasure = self.mMeasureDatas.firstObject;
        [firstInMeasure.mCurrentAttr drawRectWithoutTime:rect];
    } else {
        DrawableNoteM* firstInMeasure = self.mMeasureDatas.firstObject;
        [firstInMeasure.mCurrentAttr drawRectWithoutTime:rect];
        double y_offset = (PartMarin + PartHeight );
        CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(0 , y_offset));
        DrawableNoteM* secondInMeasure = [self getFisrtNoteAtStaffTwo];
        [secondInMeasure.mCurrentAttr drawRectWithoutTime:rect];
        CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(0, -y_offset));
    }
    CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation((MeasureAttributeWidth - left_margin) , 0));
}

/**
 绘制五线谱
 */
-(void)drawHorizonLine {
    for (NSInteger index = 0 , ytop = 0 ;index < self.mStavesNum ; index++){
        CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(0, ytop));
        UIBezierPath *path = [UIBezierPath bezierPath];
        for (int line = 1, y = 0; line <= 5; line++) {
            [path moveToPoint:CGPointMake(self.mLine-1 ? -MeasureAttributeWidth : 0, y)];
            [path addLineToPoint:CGPointMake(self.mWidth, y)];
            y += MIDILineWidth + LineSpace;
        }
        [path stroke];
        [[UIColor blackColor] setStroke];
        CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(0, -ytop));
        ytop += PartMarin + PartHeight;
    }
    
}
//-(void)sortMeasureDatas{
//    _mMeasureDatas = [_mMeasureDatas sortedArrayUsingComparator:^NSComparisonResult(DrawableNoteM* obj1, DrawableNoteM* obj2) {
//        return obj1.mNoPrintObject < obj2.mNoPrintObject;
//    }];
//}

-(void)drawRect:(CGRect)rect{
    if (self.mLineFirst) {
        if (self.mLine != 1) {
            [self drawMeasureFirst:rect];
        }
        [self drawPartCurve];
    }
    for (DrawableNoteM* musicData in self.mMeasureDatas) {
        // only draw property and notes
        
        int y_offset = 0;
        if (musicData.mStaffth != 1){
            y_offset += (PartMarin + PartHeight);
        }
        // 添加随机填充色
//        CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(musicData.mDefaultX, y_offset));
//        UIBezierPath* path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, musicData.mAjustDuration, 10)];
//        [[self randomColor]setFill];
//        [path fill];
//        [path stroke];
//        CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(-(musicData.mDefaultX), -y_offset));
        
        if ([musicData isKindOfClass:[RestM class]] && ((RestM*)musicData).mHasMeasure) {
            // 处理 占整个measure的rest
            CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(self.mWidth*0.5 , y_offset));
            [musicData drawRect:rect];
            CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(-(self.mWidth*0.5), -y_offset));
        }else {
            //grace note 需要的偏移
            double x_offset = 0;
            if ([musicData isKindOfClass:[NoteGroupM class]]) {
                NoteGroupM* ngM = (NoteGroupM*)musicData;
                if ( ngM.mChoice == ENoteChoice_Grace ) {
                    x_offset = -Grace_offSet;
                }
            }
            CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(musicData.mDefaultX+ Padding_In_Note + x_offset, y_offset));

            [musicData drawRect:rect];
            
            CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(-(musicData.mDefaultX+ Padding_In_Note ) - x_offset, -y_offset));
        }
        
        
    }
    [self drawHorizonLine];
}

/**
 绘制大括号
 */
-(void)drawPartCurve {
    if (self.mStavesNum < 2) {
        return;
    }
    double height = PartMarin + PartHeight * 2;
    double width = height * 0.12;
    double x_offset = self.mLine-1 ? width+MeasureAttributeWidth+2 : width+2;

    CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(- x_offset , 0 ));
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(width, 0)];
    [path addCurveToPoint:CGPointMake(0, height* 0.5) controlPoint1:CGPointMake(width * -0.4, height * 0.085) controlPoint2:CGPointMake(width * 1.5, height * 0.37)];
    [path addCurveToPoint:CGPointMake(width, height) controlPoint1:CGPointMake(width * 1.5, height * 0.63) controlPoint2:CGPointMake(width * -0.4, height * 0.915)];
    
    [path addCurveToPoint:CGPointMake(0, height* 0.5) controlPoint1:CGPointMake(width * -0.4, height * 0.915) controlPoint2:CGPointMake(width * 1.7, height * 0.63)];
    [path addCurveToPoint:CGPointMake(width, 0) controlPoint1:CGPointMake(width * 1.7, height * 0.37) controlPoint2:CGPointMake(width * -0.4, height * 0.085)];
    [path stroke];
    CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(x_offset , 0));
}

#pragma mark -- getter setter

-(double)mWidth{
    if (self.mWidthRatio) {
        return _mWidth*self.mWidthRatio;
    }
    return _mWidth;
}
-(void)setMeasureDatas:(NSArray< DrawableNoteM*>*)measureDatas{
    _mMeasureDatas = measureDatas;
}
@end
