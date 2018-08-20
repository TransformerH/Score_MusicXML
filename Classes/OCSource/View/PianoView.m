//
//  PianoView.m
//  Pods
//
//  Created by tanhui on 2017/8/7.
//
//

#import "PianoView.h"


static int KeysPerOctave = 7;
static int MaxOctave = 7;

static int WhiteKeyWidth;  /** Width of a single white key */
static int WhiteKeyHeight; /** Height of a single white key */
static int BlackKeyWidth;  /** Width of a single black key */
static int BlackKeyHeight; /** Height of a single black key */
static int margin;         /** Margin at left and top */
static int BlackBorder;    /** The width of the black border around the keys */
static int blackKeyOffsets[10];  /** The x pixles of the black keys */
static int mStepMap[7] = {0,2,4,5,7,9,11};
static int WhiteKeyCount ;

@implementation ActiveNote

-(instancetype)initWithNote:(NoteM*)note offset:(CGPoint)offset rect:(CGRect)rect{
    if([super init]){
        self.mNote = note;
        self.mOffset = offset;
        self.mRect = rect;
    }
    return self;
}

@end

@interface PianoView (){
    UIColor *gray1, *gray2, *gray3, *shadeColor,*shade2Color;
}
@property(nonatomic, strong) NSMutableArray* activeNotes;
@end


@implementation PianoView


- (instancetype)init {
    int screenwidth = [[UIScreen mainScreen] bounds].size.width;
    WhiteKeyCount = KeysPerOctave * MaxOctave + 3;
    WhiteKeyWidth = (int)(screenwidth / (2.0 +WhiteKeyCount));
    margin = WhiteKeyWidth / 2;
    BlackBorder = WhiteKeyWidth / 2;
    WhiteKeyHeight = WhiteKeyWidth * 6;
    BlackKeyWidth = WhiteKeyWidth / 2;
    BlackKeyHeight = WhiteKeyHeight * 5 / 9;
    
    CGRect frame = CGRectMake(0, 0,
                              margin*2 + BlackBorder*2 + WhiteKeyWidth * WhiteKeyCount,
                              margin*2 + BlackBorder*3 + WhiteKeyHeight);
    self = [super initWithFrame:frame];
    int nums[] = {
        WhiteKeyWidth - BlackKeyWidth/2 - 1,
        WhiteKeyWidth + BlackKeyWidth/2 - 1,
        2*WhiteKeyWidth - BlackKeyWidth/2,
        2*WhiteKeyWidth + BlackKeyWidth/2,
        4*WhiteKeyWidth - BlackKeyWidth/2 - 1,
        4*WhiteKeyWidth + BlackKeyWidth/2 - 1,
        5*WhiteKeyWidth - BlackKeyWidth/2,
        5*WhiteKeyWidth + BlackKeyWidth/2,
        6*WhiteKeyWidth - BlackKeyWidth/2,
        6*WhiteKeyWidth + BlackKeyWidth/2
    };
    for (int i = 0; i < 10; i++) {
        blackKeyOffsets[i] = nums[i];
    }
    
    gray1 = [UIColor colorWithRed:16/255.0 green:16/255.0 blue:16/255.0 alpha:1.0];
    gray2 = [UIColor colorWithRed:90/255.0 green:90/255.0 blue:90/255.0 alpha:1.0];
    gray3 = [UIColor colorWithRed:200/255.0 green:200/255.0 blue:200/255.0 alpha:1.0];
    
    shadeColor  = [UIColor colorWithRed:210/255.0
                                  green:205/255.0 blue:220/255.0 alpha:1.0];
    
    shade2Color = [UIColor colorWithRed:150/255.0
                                  green:200/255.0 blue:220/255.0 alpha:1.0];
    
    self.backgroundColor = [UIColor lightGrayColor];
    return self;
}



// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    
    /* Draw a border line at the top */
    //    drawLine(gray1, 0, 0, [self frame].size.width, 0);
    
    CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation((margin + BlackBorder), (margin + BlackBorder)));
    
    CGRect backrect = CGRectMake(0, 0,
                                 WhiteKeyWidth * WhiteKeyCount,
                                 WhiteKeyHeight);
    [self fillRect:backrect withColor:[UIColor whiteColor]];
    [[UIColor blackColor] setFill];
    
    [self drawBlackKeys];
    
    [self drawOutline];
    
    [self drawActiveNotes];
    
    CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(-(margin + BlackBorder), -(margin + BlackBorder)));
    
    [self drawBlackBorder];
}
-(void)drawActiveNotes{
    if ([self.activeNotes count]) {
        for (NSInteger i = 0 ; i < self.activeNotes.count; i++) {
            ActiveNote * activeNote = self.activeNotes[i];
            CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(activeNote.mOffset.x + WhiteKeyWidth*2, activeNote.mOffset.y));
            [self fillRect:activeNote.mRect withColor:activeNote.mNote.mStaffth == 1 ? shadeColor: shade2Color];
            CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(-activeNote.mOffset.x - WhiteKeyWidth*2, -activeNote.mOffset.y));
        }
        [self.activeNotes removeAllObjects];
    }
}

/* Draw the black border area surrounding the piano keys.
 * Also, draw gray outlines at the bottom of the white keys.
 */
- (void)drawBlackBorder {
    
    int PianoWidth = WhiteKeyWidth * WhiteKeyCount;
    CGRect rect = CGRectMake(margin, margin, PianoWidth + BlackBorder*2, BlackBorder);
    [self fillRect:rect withColor:gray1];
    rect = CGRectMake(margin, margin, BlackBorder, WhiteKeyHeight + BlackBorder*3);
    [self fillRect:rect withColor:gray1];
    rect = CGRectMake(margin, margin + BlackBorder + WhiteKeyHeight,
                      BlackBorder*2 + PianoWidth, BlackBorder*2);
    [self fillRect:rect withColor:gray1];
    rect = CGRectMake(margin + BlackBorder + PianoWidth, margin,
                      BlackBorder, WhiteKeyHeight + BlackBorder*3);
    [self fillRect:rect withColor:gray1];
    
    /* Draw the gray bottoms of the white keys */
    CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation((margin + BlackBorder), (margin + BlackBorder)));
    
    
    for (int i = 0; i < WhiteKeyCount; i++) {
        rect = CGRectMake(i*WhiteKeyWidth + 1, WhiteKeyHeight + 2,
                          WhiteKeyWidth - 2, BlackBorder/2);
        [self fillRect:rect withColor:gray2];
    }
    
    CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(-(margin + BlackBorder), -(margin + BlackBorder)));
    
}
/* Draw the Black keys */
- (void)drawBlackKeys {
    // draw left single black key
    CGRect rect;
    int x1 = blackKeyOffsets[0];
    rect = CGRectMake(x1, 0, BlackKeyWidth, BlackKeyHeight);
    [self fillRect:rect withColor:gray1];
    rect = CGRectMake(x1+1, BlackKeyHeight - BlackKeyHeight/8,
                      BlackKeyWidth-2, BlackKeyHeight/8);
    [self fillRect:rect withColor:gray2];
    
    CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(  WhiteKeyWidth * 2, 0));
    
    for (int octave = 0; octave < MaxOctave; octave++) {
        CGAffineTransform transform = CGAffineTransformMakeTranslation( (octave * WhiteKeyWidth * KeysPerOctave), 0);
        CGContextConcatCTM(UIGraphicsGetCurrentContext(), transform);
        for (int i = 0; i < 10; i += 2) {
            int x1 = blackKeyOffsets[i];
            rect = CGRectMake(x1, 0, BlackKeyWidth, BlackKeyHeight);
            [self fillRect:rect withColor:gray1];
            rect = CGRectMake(x1+1, BlackKeyHeight - BlackKeyHeight/8,
                              BlackKeyWidth-2, BlackKeyHeight/8);
            [self fillRect:rect withColor:gray2];
        }
        transform = CGAffineTransformMakeTranslation( -(octave * WhiteKeyWidth * KeysPerOctave), 0);
        CGContextConcatCTM(UIGraphicsGetCurrentContext(), transform);
    }
    CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(  -WhiteKeyWidth * 2, 0));
}

/** Draw the outline of a 12-note (7 white note) piano octave */
- (void)drawOctaveOutline{
    
    CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(  WhiteKeyWidth * 2, 0));
    
    int right = WhiteKeyWidth * KeysPerOctave ;
    
    /* Draw the bounding rectangle, from C to B */
    drawLine(gray1, 0, 0, 0, WhiteKeyHeight);
    drawLine(gray1, right, 0, right, WhiteKeyHeight);
    
    
    /* Draw the line between E and F */
    drawLine(gray1, 3*WhiteKeyWidth, 0, 3*WhiteKeyWidth, WhiteKeyHeight);
    
    /* Draw the sides/bottom of the black keys */
    for (int i = 0; i < 10; i += 2) {
        int x1 = blackKeyOffsets[i];
        int x2 = blackKeyOffsets[i+1];
        
        drawLine(gray1, x1, 0, x1, BlackKeyHeight);
        drawLine(gray1, x2, 0, x2, BlackKeyHeight);
        drawLine(gray1, x1, BlackKeyHeight, x2, BlackKeyHeight);
        
    }
    
    /* Draw the bottom-half of the white keys */
    for (int i = 1; i < KeysPerOctave; i++) {
        if (i == 3) {
            continue;  /* We draw the line between E and F above */
        }
        drawLine(gray1, i*WhiteKeyWidth, BlackKeyHeight, i*WhiteKeyWidth, WhiteKeyHeight);
        
    }
    
    CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(  -WhiteKeyWidth * 2, 0));
}


/** Draw an outline of the piano for 7 octaves */
- (void)drawOutline {
    
    drawLine(gray1, 0, 0, 0, WhiteKeyHeight);
    int x1 = blackKeyOffsets[0];
    int x2 = blackKeyOffsets[1];
    drawLine(gray1, x1, 0, x1, BlackKeyHeight);
    drawLine(gray1, x2, 0, x2, BlackKeyHeight);
    drawLine(gray1, x1, BlackKeyHeight, x2, BlackKeyHeight);
    drawLine(gray1, WhiteKeyWidth, BlackKeyHeight, WhiteKeyWidth, WhiteKeyHeight);
    
    
    CGContextRef context =UIGraphicsGetCurrentContext();
    
    for (int octave = 0; octave < MaxOctave; octave++) {
        CGContextConcatCTM(context, CGAffineTransformMakeTranslation(octave * WhiteKeyWidth * KeysPerOctave, 0));
        [self drawOctaveOutline];
        CGContextConcatCTM(context, CGAffineTransformMakeTranslation(-(octave * WhiteKeyWidth * KeysPerOctave), 0));
    }
}

///** Fill in a rectangle with the given color */
- (void)fillRect:(CGRect)rect withColor:(UIColor*)color {
    [color setFill];
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:rect];
    [path fill];
}

/** Draw a line with the given color */
static void drawLine(UIColor *color, int x1, int y1, int x2, int y2) {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path setLineWidth:1];
    [path moveToPoint:CGPointMake(x1, y1)];
    [path addLineToPoint:CGPointMake(x2, y2)];
    [color setStroke];
    [path stroke];
    [[UIColor blackColor] setStroke];
}

-(void)updateNotes:(NSArray*)notes{
    for (NoteM* note in notes) {
        [self shadeOneNote:note];
    }
    [self setNeedsDisplay];
}

//
///* Shade the given note with the given brush.
// * We only draw notes from notenumber 24 to 96.
// * (Middle-C is 60).
// */
- (void)shadeOneNote:(NoteM*)note  {

    int octave = (int)note.mOctave;
    int notescale = mStepMap[(int)note.mStep] + (int)note.mAlter;
    
    octave -= 1;
    if (octave < -1 || octave >= MaxOctave)
        return;
    
    CGPoint offset = CGPointMake(octave * WhiteKeyWidth * KeysPerOctave, 0);
    int x1, x2, x3;
    
    int bottomHalfHeight = WhiteKeyHeight - (BlackKeyHeight+1);
    
    /* notescale goes from 0 to 11, from C to B. */
    switch (notescale) {
        case 0: /* C */
            x1 = 1;
            x2 = blackKeyOffsets[0] - 1;
            
            [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x1, 0, x2 - x1, BlackKeyHeight+1)]];
            [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x1, BlackKeyHeight+1, WhiteKeyWidth-2, bottomHalfHeight)]];
            
            break;
        case 1: /* C# */
            x1 = blackKeyOffsets[0];
            x2 = blackKeyOffsets[1];
            [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x1, 0, x2 - x1, BlackKeyHeight)]];
//            if (color == gray1) {
//                [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x1+1, BlackKeyHeight - BlackKeyHeight/8,BlackKeyWidth-2, BlackKeyHeight/8)]];
//            }
            break;
        case 2: /* D */
            x1 = WhiteKeyWidth + 1;
            x2 = blackKeyOffsets[1] + 1;
            x3 = blackKeyOffsets[2] - 1;
            [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x2, 0, x3 - x2, BlackKeyHeight+1)]];
            [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x1, BlackKeyHeight+1, WhiteKeyWidth-2, bottomHalfHeight)]];
            break;
        case 3: /* D# */
            x1 = blackKeyOffsets[2];
            x2 = blackKeyOffsets[3];
            [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x1, 0, BlackKeyWidth, BlackKeyHeight)]];
//            if (color == gray1) {
//                [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x1+1, BlackKeyHeight - BlackKeyHeight/8,BlackKeyWidth-2, BlackKeyHeight/8)]];
//            }
            break;
        case 4: /* E */
            x1 = WhiteKeyWidth * 2 + 1;
            x2 = blackKeyOffsets[3] + 1;
            x3 = WhiteKeyWidth * 3 - 1;
            [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x2, 0, x3 - x2, BlackKeyHeight+1)]];
            [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x1, BlackKeyHeight+1, WhiteKeyWidth-2, bottomHalfHeight)]];
            break;
        case 5: /* F */
            x1 = WhiteKeyWidth * 3 + 1;
            x2 = blackKeyOffsets[4] - 1;
            x3 = WhiteKeyWidth * 4 - 1;
            
            [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x1, 0, x2 - x1, BlackKeyHeight+1)]];
            [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x1, BlackKeyHeight+1, WhiteKeyWidth-2, bottomHalfHeight)]];
            
            break;
        case 6: /* F# */
            x1 = blackKeyOffsets[4];
            x2 = blackKeyOffsets[5];
            [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x1, 0, BlackKeyWidth, BlackKeyHeight)]];
//            if (color == gray1) {
//                [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x1+1, BlackKeyHeight - BlackKeyHeight/8,BlackKeyWidth-2, BlackKeyHeight/8)]];
//            }
            break;
        case 7: /* G */
            x1 = WhiteKeyWidth * 4 + 1;
            x2 = blackKeyOffsets[5] + 1;
            x3 = blackKeyOffsets[6] - 1;
            [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x2, 0, x3 - x2, BlackKeyHeight+1)]];
            [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x1, BlackKeyHeight+1, WhiteKeyWidth-2, bottomHalfHeight)]];
            
            break;
        case 8: /* G# */
            x1 = blackKeyOffsets[6];
            x2 = blackKeyOffsets[7];
            
            [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x1, 0, BlackKeyWidth, BlackKeyHeight)]];
            
//            if (color == gray1) {
//                
//                [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x1+1, BlackKeyHeight - BlackKeyHeight/8,BlackKeyWidth-2,BlackKeyHeight/8)]];
//            }
            break;
        case 9: /* A */
            x1 = WhiteKeyWidth * 5 + 1;
            x2 = blackKeyOffsets[7] + 1;
            x3 = blackKeyOffsets[8] - 1;
            
            [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x2, 0, x3 - x2, BlackKeyHeight+1)]];
            [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x1, BlackKeyHeight+1, WhiteKeyWidth-2, bottomHalfHeight)]];
            
            break;
        case 10: /* A# */
            x1 = blackKeyOffsets[8];
            x2 = blackKeyOffsets[9];
            
            [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x1, 0, BlackKeyWidth, BlackKeyHeight)]];
            
//            if (color == gray1) {
//                [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x1+1, BlackKeyHeight - BlackKeyHeight/8, BlackKeyWidth-2, BlackKeyHeight/8)]];
//            }
            break;
        case 11: /* B */
            x1 = WhiteKeyWidth * 6 + 1;
            x2 = blackKeyOffsets[9] + 1;
            x3 = WhiteKeyWidth * KeysPerOctave - 1;
            
            [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x2, 0, x3 - x2, BlackKeyHeight+1)]];
            [self.activeNotes addObject:[[ActiveNote alloc]initWithNote:note offset:offset rect:CGRectMake(x1, BlackKeyHeight+1, WhiteKeyWidth-2, bottomHalfHeight)]];
            
            break;
        default:
            break;
    }
    
}




-(NSMutableArray *)activeNotes{
    if (!_activeNotes) {
        _activeNotes = @[].mutableCopy;
    }
    return _activeNotes;
}

@end
