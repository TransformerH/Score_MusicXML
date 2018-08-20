//
//  PianoView.h
//  Pods
//
//  Created by tanhui on 2017/8/7.
//
//

#import <UIKit/UIKit.h>
#import "NoteM.h"

@interface ActiveNote : NSObject

@property(nonatomic, strong) NoteM* mNote;
@property(nonatomic, assign) CGPoint mOffset;
@property(nonatomic, assign) CGRect mRect;

-(instancetype)initWithNote:(NoteM*)note offset:(CGPoint)offset rect:(CGRect)rect;

@end

@interface PianoView : UIView

-(void)updateNotes:(NSArray*)notes;

@end
