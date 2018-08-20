//
//  SheetView.h
//  Pods
//
//  Created by tanhui on 2017/8/7.
//
//

#import <UIKit/UIKit.h>

@class ScoreM;
@class DrawableNoteM;
@interface SheetView : UIView

@property(nonatomic,weak) UIScrollView* mParentView;

-(instancetype)initWithFrame:(CGRect)frame score:(ScoreM*)score;

/**
 更新光标的位置

 @param note <#note description#>
 */
-(void)updateCusor:(DrawableNoteM*)note;

/**
 清除显示的结果信息
 */
-(void)clearResult;
@end
