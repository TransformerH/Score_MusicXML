//
//  MeasureAttributeM.m
//  iOSMusic
//
//  Created by tanhui on 2017/7/13.
//  Copyright © 2017年 tanhui. All rights reserved.
//

#import "MeasureAttributeM.h"
#import "Constants.h"
#import "UIImage+music.h"
#import "NoteM.h"
#import "AccidM.h"

@implementation MeasureTimeM
@end

@implementation ClefM
@end

@interface MeasureKeyM ()
@property(nonatomic, strong) NSMutableArray* treble;
@property(nonatomic, strong) NSMutableArray* bass;
@property(nonatomic, assign) NSNumber * mFifth;
@property(nonatomic, assign) EKeyMode mMode;
@end

@implementation MeasureKeyM

-(NSMutableArray*)getAccids:(EClef)clef {
    if (clef == EClef_TREBLE) {
        return  self.treble;
    }else{
        return self.bass;
    }
}

-(instancetype)initWithFifth:(NSNumber*)fifth mode:(EKeyMode)mode{
    if ([super init]) {
        _mFifth = fifth;
        _mMode = mode;
        [self createSymbols];
    }
    return self;
}
- (void)createSymbols {
    int count = abs([self.mFifth integerValue]);
    int arrsize = count;
    if (arrsize == 0) {
        arrsize = 1;
    }
    self.treble = @[].mutableCopy;
    self.bass = @[].mutableCopy;
    
    if (count == 0) {
        return;
    }
    
    NoteM* treblenotes[6];
    NoteM* bassnotes[6];
    EAccidType type = self.mFifth.integerValue <0 ?  EAccidType_Flat:EAccidType_Sharp;
    if (type == EAccidType_Sharp)  {
        treblenotes[0] = [NoteM allocWithLetter:ENoteStep_F andOctave:5];
        treblenotes[1] = [NoteM allocWithLetter:ENoteStep_C andOctave:5];
        treblenotes[2] = [NoteM allocWithLetter:ENoteStep_G andOctave:5];
        treblenotes[3] = [NoteM allocWithLetter:ENoteStep_D andOctave:5];
        treblenotes[4] = [NoteM allocWithLetter:ENoteStep_A andOctave:4];
        treblenotes[5] = [NoteM allocWithLetter:ENoteStep_E andOctave:5];
        
        bassnotes[0] = [NoteM allocWithLetter:ENoteStep_F andOctave:3];
        bassnotes[1] = [NoteM allocWithLetter:ENoteStep_C andOctave:3];
        bassnotes[2] = [NoteM allocWithLetter:ENoteStep_G andOctave:3];
        bassnotes[3] = [NoteM allocWithLetter:ENoteStep_D andOctave:3];
        bassnotes[4] = [NoteM allocWithLetter:ENoteStep_A andOctave:2];
        bassnotes[5] = [NoteM allocWithLetter:ENoteStep_E andOctave:3];
        
    }
    else if (type == EAccidType_Flat) {
        treblenotes[0] = [NoteM allocWithLetter:ENoteStep_B andOctave:4];
        treblenotes[1] = [NoteM allocWithLetter:ENoteStep_E andOctave:5];
        treblenotes[2] = [NoteM allocWithLetter:ENoteStep_A andOctave:4];
        treblenotes[3] = [NoteM allocWithLetter:ENoteStep_D andOctave:5];
        treblenotes[4] = [NoteM allocWithLetter:ENoteStep_G andOctave:4];
        treblenotes[5] = [NoteM allocWithLetter:ENoteStep_C andOctave:5];
        
        bassnotes[0] = [NoteM allocWithLetter:ENoteStep_B andOctave:2];
        bassnotes[1] = [NoteM allocWithLetter:ENoteStep_E andOctave:3];
        bassnotes[2] = [NoteM allocWithLetter:ENoteStep_A andOctave:2];
        bassnotes[3] = [NoteM allocWithLetter:ENoteStep_D andOctave:3];
        bassnotes[4] = [NoteM allocWithLetter:ENoteStep_G andOctave:2];
        bassnotes[5] = [NoteM allocWithLetter:ENoteStep_C andOctave:3];
        
    }

    
    for (int i = 0; i < count; i++) {
        AccidM *s = [[AccidM alloc] initWithType:type andNote:treblenotes[i] andClef:EClef_TREBLE];
        [self.treble addObject:s];
        AccidM *s2 = [[AccidM alloc]initWithType:type andNote:bassnotes[i] andClef:EClef_BASS];
        [self.bass addObject:s2];
    }
    
    
}

@end

@implementation MeasureAttributeM

static UIImage* images[13];
static int images_init = 0;

+(void)load{
    [MeasureAttributeM loadImages];
}

+ (void)loadImages {
    if (images_init == 0) {
        for (int i = 0; i < 13; i++) {
            images[i] = NULL;
        }
        images[2] = [UIImage imageForResource:@"2" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]] ;
        images[3] = [UIImage imageForResource:@"3" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]] ;
        images[4] = [UIImage imageForResource:@"4" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]] ;
        images[6] = [UIImage imageForResource:@"6" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]] ;
        images[8] = [UIImage imageForResource:@"8" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]] ;
        images[9] = [UIImage imageForResource:@"9" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]] ;
        images[12] = [UIImage imageForResource:@"12" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]] ;
    }
    images_init = 1;
}

-(void)setMPrevious:(MeasureAttributeM *)mPrevious{
    _mPrevious = mPrevious;
    _mPrevious.mPrevious = nil;
    if (!self.mKey) {
        self.mKey = mPrevious.mKey;
    }
}

-(double)drawWidth{
    return (self.mAjustDuration - 20);
}

-(void)drawRectWithoutTime:(CGRect)rect{
    double x_offset = 0;
    if (self.mClef) {
        [self drawClef:&x_offset];
    }
    if (self.mKey) {
        [self drawKey:&x_offset];
    }
}

-(void)drawRect:(CGRect)rect{
    double x_offset = 0;

    if (self.mClef) {
        [self drawClef:&x_offset];
    }
    if (self.mHasKey) {
        [self drawKey:&x_offset];
    }
    if (self.mHasTime){
        [self drawTime:&x_offset];
    }
}

-(void)drawClef:(double*)x_offset {
    int y = 0;
    
    int height = 0;
    UIImage *image;
    if (self.mClef.mValue == EClef_TREBLE) {
        image = [UIImage imageForResource:@"middle" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
        height = 3 * PartHeight/2 + NoteHeight/2;
        y =  - NoteHeight;
    }
    else if (self.mClef.mValue == EClef_BASS) {
        image =[UIImage imageForResource:@"base" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
        height = PartHeight - NoteHeight;
    }
    /* Scale the image width to match the height */
    int imgwidth = (int)([image size].width * 1.0*height / [image size].height);
    [image drawInRect:CGRectMake(0, y, imgwidth, height) blendMode:kCGBlendModeNormal alpha:1.0];
    
    *x_offset = *x_offset + imgwidth + 2;
}

-(void)drawKey :(double*)x_offset{
    
    NSMutableArray* arr = [self.mKey getAccids:self.mClef.mValue];
    for (AccidM* accid in arr) {
        CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(*x_offset, 0));
        [accid drawRect:CGRectZero];
        CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(- (*x_offset), 0));
        *x_offset+= [accid drawWidth];
    }
    *x_offset =  *x_offset + 2;
}
-(void)drawTime :(double*)x_offset{
    if (!self.mTime.mBeates || !self.mTime.mBeateType) {
        return;
    }
    CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(*x_offset, 0));
    UIImage *numer = images[[self.mTime.mBeates integerValue]];
    UIImage *denom = images[[self.mTime.mBeateType integerValue]];
    
    /* Scale the image width to match the height */
    int imgheight = NoteHeight * 2;
    int imgwidth = (int)([numer size].width * 1.0*imgheight / [numer size].height);
    
    [numer drawInRect:CGRectMake(0, 0, imgwidth, imgheight) blendMode:kCGBlendModeNormal alpha:1.0];
    [denom drawInRect:CGRectMake(0, 0+imgheight, imgwidth, imgheight) blendMode:kCGBlendModeNormal alpha:1.0];
    
    CGContextConcatCTM(UIGraphicsGetCurrentContext(), CGAffineTransformMakeTranslation(- (*x_offset), 0));
}

@end
