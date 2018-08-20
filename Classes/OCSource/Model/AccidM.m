//
//  AccidM.m
//  Pods
//
//  Created by tanhui on 2017/7/24.
//
//

#import "AccidM.h"
#import "Constants.h"

@implementation AccidM
-(instancetype)initWithType:(EAccidType)type andNote:(NoteM*)note andClef:(EClef)clef{
    if ([super init]) {
        _mType = type;
        _mNote = note;
        _mClef = clef;
//        _mOctave = note.mOctave;
//        _mStep = note.mStep;
    }
    return self;
}

-(void)drawRect:(CGRect)rect{
    int ytop = 0;
    NoteM* topStaff = [NoteM getTop:self.mClef];
    int ynote = ytop + [topStaff dist:self.mNote] * NoteHeight/2;
    if (self.mType == EAccidType_Sharp) {
        [self drawSharp:ynote];
    }else if (self.mType == EAccidType_Flat) {
        [self drawFlat:ynote];
    }else if (self.mType == EAccidType_Natural){
        [self drawNatural:ynote];
    }
}

/** Draw a sharp symbol.
 * @param ynote The pixel location of the top of the accidental's note.
 */
- (void) drawSharp:(int)ynote {
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    /* Draw the two vertical lines */
    int ystart = ynote - NoteHeight;
    int yend = ynote + 2*NoteHeight;
    int x = NoteHeight/2;
    [path setLineWidth:1];
    [path moveToPoint:CGPointMake(x, ystart + 2)];
    [path addLineToPoint:CGPointMake(x, yend)];
    [path moveToPoint:CGPointMake(x + NoteHeight/2, ystart)];
    [path addLineToPoint:CGPointMake(x + NoteHeight/2, yend-2)];
    [path stroke];
    
    /* Draw the slightly upwards horizontal lines */
    int xstart = NoteHeight/2 - NoteHeight/4;
    int xend = NoteHeight + NoteHeight/4;
    ystart = ynote + MIDILineWidth;
    yend = ystart - MIDILineWidth - LineSpace/4;
    
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(xstart, ystart)];
    [path addLineToPoint:CGPointMake(xend, yend)];
    ystart += LineSpace;
    yend += LineSpace;
    [path moveToPoint:CGPointMake(xstart, ystart)];
    [path addLineToPoint:CGPointMake(xend, yend)];
    [path setLineWidth:LineSpace/2];
    [path stroke];
}

/** Draw a sharp symbol.
 * @param ynote The pixel location of the top of the accidental's note.
 */
- (void)drawFlat:(int)ynote {
    int x = LineSpace/4;
    UIBezierPath* path = [UIBezierPath bezierPath];
    
    /* Draw the vertical line */
    [path moveToPoint:CGPointMake(x, ynote - NoteHeight - NoteHeight/2)];
    [path addLineToPoint:CGPointMake(x, ynote + NoteHeight)];
    
    /* Draw 3 bezier curves.
     * All 3 curves start and stop at the same points.
     * Each subsequent curve bulges more and more towards
     * the topright corner, making the curve look thicker
     * towards the top-right.
     */
    
    [path moveToPoint:CGPointMake(x, ynote + LineSpace/4)];
    [path addCurveToPoint:CGPointMake(x, ynote + LineSpace + MIDILineWidth + 1)
            controlPoint1:CGPointMake(x + LineSpace/2, ynote - LineSpace/2)
            controlPoint2:CGPointMake(x + LineSpace, ynote + LineSpace/3)
     ];
    
    [path moveToPoint:CGPointMake(x, ynote + LineSpace/4)];
    [path addCurveToPoint:CGPointMake(x, ynote + LineSpace + MIDILineWidth + 1)
            controlPoint1:CGPointMake(x + LineSpace/2, ynote - LineSpace/2)
            controlPoint2:CGPointMake(x + LineSpace + LineSpace/4,
                                      ynote + LineSpace/3 - LineSpace/4)
     ];
    
     
    [path moveToPoint:CGPointMake(x, ynote + LineSpace/4)];
    [path addCurveToPoint:CGPointMake(x, ynote + LineSpace + MIDILineWidth + 1)
            controlPoint1:CGPointMake(x + LineSpace/2, ynote - LineSpace/2)
            controlPoint2:CGPointMake(x + LineSpace + LineSpace/2,
                                      ynote + LineSpace/3 - LineSpace/2)
     ];
    
    [path setLineWidth:1];
    [path stroke];
}
/** Draw a natural symbol.
 * @param ynote The pixel location of the top of the accidental's note.
 */
- (void)drawNatural:(int)ynote {
    UIBezierPath* path = [UIBezierPath bezierPath];
    
    /* Draw the two vertical lines */
    int ystart = ynote - LineSpace - MIDILineWidth;
    int yend = ynote + LineSpace + MIDILineWidth;
    int x = LineSpace/2;
    
    [path moveToPoint:CGPointMake(x, ystart)];
    [path addLineToPoint:CGPointMake(x, yend)];
    x += LineSpace - LineSpace/4;
    ystart = ynote - LineSpace/4;
    yend = ynote + 2*LineSpace + MIDILineWidth - LineSpace/4;
    [path moveToPoint:CGPointMake(x, ystart)];
    [path addLineToPoint:CGPointMake(x, yend)];
    [path setLineWidth:1];
    [path stroke];
    
    /* Draw the slightly upwards horizontal lines */
    path = [UIBezierPath bezierPath];
    int xstart = LineSpace/2;
    int xend = xstart + LineSpace - LineSpace/4;
    ystart = ynote + MIDILineWidth;
    yend = ystart - MIDILineWidth - LineSpace/4;
    [path moveToPoint:CGPointMake(xstart, ystart)];
    [path addLineToPoint:CGPointMake(xend, yend)];
    ystart += LineSpace;
    yend += LineSpace;
    [path moveToPoint:CGPointMake(xstart, ystart)];
    [path addLineToPoint:CGPointMake(xend, yend)];
    
    [path setLineWidth:LineSpace/2];
    [path stroke];
}
-(double)drawWidth{
    return NoteWidth;
}
@end
