//
//  ScoreModeView.h
//  CIRouter
//
//  Created by tanhui on 2017/10/19.
//

#import <UIKit/UIKit.h>
#import "MidiPlayer.h"

@class ScoreViewController;

@interface ScoreModeView : UIView
@property(nonatomic, weak) ScoreViewController* mScoreVC;
@property(nonatomic, assign) CIMidiPlayerMode  mMidiMode;
-(void)closeItem;
@end


@protocol ScoreModeItemDelegate<NSObject>
-(void)scoreModelItemDidSelectIndex:(NSInteger)index;
@end
@interface ScoreModeItem: UIView
@property(nonatomic, weak)id<ScoreModeItemDelegate> delegate;
-(instancetype)initMainWithTitle:(NSString*)title;
-(instancetype)initWithTitle:(NSString*)title icon:(NSString*)icon index:(NSInteger)index arrowDown:(BOOL)isdown;
-(void)setTitle:(NSString*)title;
-(void)setIcon:(NSString*)icon;
@end
