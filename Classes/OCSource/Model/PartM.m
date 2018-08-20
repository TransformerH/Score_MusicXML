//
//  ScorePartWiseM.m
//  iOSMusic
//
//  Created by tanhui on 2017/7/11.
//  Copyright © 2017年 tanhui. All rights reserved.
//

#import "PartM.h"
#import "MeasureM.h"
#import "Constants.h"
#import "ScoreM.h"

@interface PartM ()
@end

@implementation PartM
#pragma mark -- LifeCycle

-(instancetype)initWithName:(NSString*)name program:(NSInteger)program Measures:(NSArray*) measures staves:(NSInteger)staff{
    if ([super init]) {
        _mName = name;
        _mMeasures = measures;
        _mStavesNum = staff;
        _mProgram = program;
    }
    return self;
}


#pragma mark PUBLIC
-(void)drawRect:(CGRect)rect{
    float horiWidth = 0.0;
    int line = 0;
    for (MeasureM* measure in self.mMeasures) {
        if (measure.mLine != line) {
            measure.mLineFirst = YES;
            horiWidth  = 0;
            line = measure.mLine;
        }
        CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(horiWidth , (measure.mLine -1)* (self.mScore.mPartLineHeight+PartLineMargin) ));
        
        [measure drawRect:rect];
        [self drawEndLine:measure.mWidth];
        CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(-horiWidth , -(measure.mLine -1)* (self.mScore.mPartLineHeight+PartLineMargin)  ));
        horiWidth += measure.mWidth;
    }
}

#pragma mark -- Private Method
-(void)drawPartName {
    CGSize size = [self.mName sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]}];
    [self.mName drawInRect:CGRectMake(0, 5, 30, 20) withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]}];
}

-(void)drawEndLine:(double)width{
    int yend =  (int) (PartHeight + (PartHeight + PartMarin) * (self.mStavesNum -1));
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(width, 0)];
    [path addLineToPoint:CGPointMake(width, yend)];
    [path setLineWidth:MIDILineWidth];
    [path stroke];
}


@end
