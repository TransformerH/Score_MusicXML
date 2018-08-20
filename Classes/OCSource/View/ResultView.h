//
//  CIResultView.h
//  musicXML
//
//  Created by tanhui on 2017/9/1.
//  Copyright © 2017年 tanhuiya. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ResultOutlineModel.h"
#import "MidiOption.h"

@class ScoreSheet;
@interface ResultView : UIView
+ (instancetype)customXiBView;
@property (weak, nonatomic) ScoreSheet* mSheet;
@property (weak, nonatomic) IBOutlet UILabel *mTitleLable;
@property (weak, nonatomic) IBOutlet UILabel *mScoreLabel;
@property (weak, nonatomic) IBOutlet UILabel *mTempoLabel;
@property (weak, nonatomic) IBOutlet UILabel *lostNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *errorNumberLabel;
@property (weak, nonatomic) IBOutlet UIView *mErrorView;
@property (weak, nonatomic) IBOutlet UIButton *mDetailBtn;
@property (weak, nonatomic) IBOutlet UIButton *mCloseBtn;
@property (weak, nonatomic) IBOutlet UIView *mContainerView;
@property (strong, nonatomic)ResultOutlineModel* mResult; // 自定义结果对象
@property(nonatomic, weak) MidiOption* mOption;
-(void)setResult:(ResultOutlineModel*)result;
@end
