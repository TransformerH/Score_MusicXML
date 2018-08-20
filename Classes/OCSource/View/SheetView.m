//
//  SheetView.m
//  Pods
//
//  Created by tanhui on 2017/8/7.
//
//

#import "SheetView.h"
#import "Constants.h"
#import "NoteM.h"
#import "ScoreM.h"
#import "PartM.h"
#import "MeasureM.h"
#import "UIView+Extension.h"

@interface SheetView ()
@property(nonatomic, strong) ScoreM* mScore;
@property(nonatomic , strong)CAShapeLayer* iconLayer;

@property(nonatomic,strong) NSArray* mLostNotes;
@property(nonatomic,strong) NSArray* mErrortNotes;
@property(nonatomic,strong) NSArray* mShortNotes;
@property(nonatomic,strong) NSArray* mLongNotes;

@end


@implementation SheetView

/**
 每行行首画竖线

 @param line 第几行
 */
-(void)drawStartBar:(NSInteger)line{
    double x_offset = line == 1 ? (Part_Left_Margin + MeasureAttributeWidth): (Part_Left_Margin);

    CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(x_offset , (line -1)* (self.mScore.mPartLineHeight+PartLineMargin) + Part_Top_Margin));
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(0, self.mScore.mPartLineHeight )];
    [path setLineWidth:MIDILineWidth];
    [path stroke];
    
    CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(-x_offset , -(line -1)* (self.mScore.mPartLineHeight+PartLineMargin)-Part_Top_Margin ));
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:rect];
    [[UIColor colorWithRed:252/255.0 green:249/255.0 blue:236/255.0 alpha:1.0] setFill];
    [path fill];
    [[UIColor blackColor] setFill];
    // 绘制title
    CGSize sizeTitle = [self.mScore.mTitle sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:20]}];
    [self.mScore.mTitle drawAtPoint:CGPointMake(CGRectGetMidX(rect)-sizeTitle.width*0.5, 10) withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:20]}];
    // draw start Bar
    CGFloat clefY = Part_Top_Margin;
    // 设置partHeight
    for (int line = 1; line <= self.mScore.mLines; line++) {
        [self drawStartBar:line ];
    }
    // 绘制五线谱
    int pianoPartH = 0;
    for (PartM *part in self.mScore.mParts) {
        CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation((Part_Left_Margin + MeasureAttributeWidth) , clefY ));
        [part drawRect:rect];
        CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(-(Part_Left_Margin + MeasureAttributeWidth) , -clefY ));
        if (part.mProgram <= 8) {
            pianoPartH = clefY;
        }
        clefY = clefY + (PartMarin + PartHeight) * part.mStavesNum;
    }
}

-(void)clearResult{
    self.mLostNotes = nil;
    self.mErrortNotes = nil;
    self.mShortNotes = nil;
    self.mLongNotes = nil;
    [self setNeedsDisplay];
}

-(void)updateCusor:(DrawableNoteM*)note{
    if(!note){
        [self.iconLayer removeFromSuperlayer];
        self.iconLayer = nil;
        return;
    }
    MeasureM* measure = note.mMeasure;
    double X = measure.mStartX + note.mDefaultX + (Part_Left_Margin + MeasureAttributeWidth);
    double Y = (measure.mLine - 1) * (self.mScore.mPartLineHeight + PartLineMargin) + Part_Top_Margin;
    UIBezierPath* path = [UIBezierPath bezierPathWithRect:CGRectMake(X + Padding_In_Note , Y, 12, self.mScore.mPartLineHeight)];
    self.iconLayer.path = path.CGPath;
    
    
    if (Y > Part_Top_Margin) {
        if ((Y - 30) > (self.mParentView.contentSize.height - self.mParentView.height) ){
            CGFloat offset = self.mParentView.contentSize.height - self.mParentView.height;
            self.mParentView.contentOffset = CGPointMake(0,offset < 0 ? 0 : offset );
        }else {
            self.mParentView.contentOffset = CGPointMake(0,Y - 30);
        }
    }
}


-(instancetype)initWithFrame:(CGRect)frame score:(ScoreM*)score{
    if ([super initWithFrame:frame]) {
        _mScore = score;
    }
    return self;
}
-(CAShapeLayer *)iconLayer{
    if (!_iconLayer) {
        _iconLayer = [CAShapeLayer layer];
        _iconLayer.fillColor = [UIColor colorWithRed:253/255.0 green:150/255.0 blue:142/255.0 alpha:0.7].CGColor;
        [self.layer addSublayer:_iconLayer];
    }
    return _iconLayer;
}
-(void)dealloc{
    CILog(@"SheetView Dealloc");
}
@end
