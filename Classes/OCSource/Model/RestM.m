//
//  RestM.m
//  iOSMusic
//
//  Created by tanhui on 2017/7/20.
//  Copyright © 2017年 tanhui. All rights reserved.
//

#import "RestM.h"
#import "Constants.h"

@implementation RestM

-(double)drawWidth{
    return NoteWidth;
}

-(void)drawRect:(CGRect)rect{
//    if (self.mNoPrintObject){
//        [[UIColor lightGrayColor] set];
//    } else {
        [[UIColor blackColor] set];
//    }
    if (self.mType == ENoteType_WHOLE) {
        [self drawWhole:0];
    }
    else if (self.mType == ENoteType_HALF) {
        [self drawHalf:0];
    }
    else if (self.mType == ENoteType_QUARTER) {
        [self drawQuarter:0];
    }
    else if (self.mType == ENoteType_EIGTHTH) {
        [self drawEighth:0];
    }
    else if (self.mType == ENoteType_SIXTEENTH) {
        [self drawSixteenth:0];
    }
    [[UIColor blackColor]set];
}

- (void)drawWhole:(int)ytop {
    int y = ytop + NoteHeight;
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:
                          CGRectMake(0, y, NoteWidth, NoteHeight/2)];
    [path fill];
}
- (void)drawHalf:(int)ytop {
    int y = ytop + NoteHeight + NoteHeight/2;
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:
                          CGRectMake(0, y, NoteWidth, NoteHeight/2)];
    [path fill];
}
- (void)drawQuarter:(int)ytop {
    
    UIBezierPath *path;
    
    path = [UIBezierPath bezierPath];
    [path setLineCapStyle:kCGLineCapButt];
    
    int y = ytop + NoteHeight/2;
    int x = 2;
    int xend = x + 2*NoteHeight/3;
    [path moveToPoint:CGPointMake(x, y)];
    [path addLineToPoint:CGPointMake(xend-1, y + NoteHeight - 1)];
    [path setLineWidth:1];
    [path stroke];
    
    path = [UIBezierPath bezierPath];
    [path setLineCapStyle:kCGLineCapButt];
    y  = ytop + NoteHeight + 1;
    [path moveToPoint:CGPointMake(xend-2, y)];
    [path addLineToPoint:CGPointMake(x, y + NoteHeight)];
    [path setLineWidth:LineSpace/2];
    [path stroke];
    
    path = [UIBezierPath bezierPath];
    [path setLineCapStyle:kCGLineCapButt];
    y = ytop + NoteHeight*2 - 1;
    [path moveToPoint:CGPointMake(0, y)];
    [path addLineToPoint:CGPointMake(xend+2, y + NoteHeight)];
    [path setLineWidth:1];
    [path stroke];
    
    path = [UIBezierPath bezierPath];
    [path setLineCapStyle:kCGLineCapButt];
    if (NoteHeight == 6) {
        [path moveToPoint:CGPointMake(xend, y + 1 + 3*NoteHeight/4)];
        [path addLineToPoint:CGPointMake(x/2, y + 1 + 3*NoteHeight/4)];
    }
    else { /* NoteHeight == 8 */
        [path moveToPoint:CGPointMake(xend, y + 3*NoteHeight/4)];
        [path addLineToPoint:CGPointMake(x/2, y + 3*NoteHeight/4)];
    }
    [path setLineWidth:LineSpace/2];
    [path stroke];
    
    path = [UIBezierPath bezierPath];
    [path setLineCapStyle:kCGLineCapButt];
    [path moveToPoint:CGPointMake(0, y + 2*NoteHeight/3 + 1)];
    [path addLineToPoint:CGPointMake(xend - 1, y + 3*NoteHeight/2)];
    [path setLineWidth:1];
    [path stroke];
}

- (void)drawEighth:(int)ytop {
    
    UIBezierPath *path;
    int y = ytop + NoteHeight - 1;
    path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, y+1, LineSpace, LineSpace-1)];
    [path fill];
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake((LineSpace-2)/2, y + LineSpace - 1)];
    [path addLineToPoint:CGPointMake(3*LineSpace/2,   y + LineSpace/2)];
    [path moveToPoint:CGPointMake(3*LineSpace/2,   y + LineSpace/2)];
    [path addLineToPoint:CGPointMake(3*LineSpace/4,   y + NoteHeight*2)];
    [path setLineWidth:1];
    [path stroke];
}

-(void)drawSixteenth:(int)ytop {
    
    UIBezierPath *path;
    int y = ytop + NoteHeight - 1;
    path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, y+1, LineSpace, LineSpace-1)];
    
    [path appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectMake(-2, y+1 + NoteHeight, LineSpace, LineSpace-1)]];
    
    [path fill];
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake((LineSpace-2)/2, y + LineSpace - 1)];
    [path addLineToPoint:CGPointMake(3*LineSpace/2,   y + LineSpace/2)];
    
    [path moveToPoint:CGPointMake((LineSpace-2)/2-2, y + LineSpace - 1 + NoteHeight)];
    [path addLineToPoint:CGPointMake(3*LineSpace/2 -2,   y + LineSpace/2 + NoteHeight)];
    
    [path moveToPoint:CGPointMake(3*LineSpace/2,   y + LineSpace/2)];
    [path addLineToPoint:CGPointMake(3*LineSpace/4,   y + NoteHeight*3)];
    
    
    [path setLineWidth:1];
    [path stroke];
}


@end
