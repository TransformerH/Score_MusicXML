
//
//  ScoreSettingView.m
//  Pods
//
//  Created by tanhui on 2017/9/19.
//
//

#import "ScoreSettingView.h"
#import "UIImage+music.h"
#import <CIRouter/CIRouter.h>
#import "ScoreViewController.h"

@interface ScoreSettingView()

@property(nonatomic, strong) UIButton* mIncreaseBtn;
@property(nonatomic, strong) UIButton* mDecreaseBtn;
@property(nonatomic, strong) UILabel* mValueLabel;
@end

@implementation ScoreSettingView

#pragma mark -- lifecycle
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setUp];
    }
    return self;
}

#pragma remark -- Public Method
-(void)setTempo:(int)tempo{
    [self setTempoValue:tempo];
}
-(int)getTempo{
    return self.mValueLabel.text.intValue;
}
-(void)setState:(EPlayState)state{
    if (state == EPlayStatePlaying || state == EPlayState_Pause){
        self.mDecreaseBtn.enabled = NO;
        self.mIncreaseBtn.enabled = NO;
    }else{
        self.mDecreaseBtn.enabled = YES;
        self.mIncreaseBtn.enabled = YES;
    }
}

#pragma mark -- Private Method

/**
 初始化设置
 */
-(void)setUp{
    self.userInteractionEnabled = YES;
    self.contentMode = UIViewContentModeScaleAspectFit;
    self.image = [UIImage imageForResource:@"tempo_back" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
}

-(void)layoutSubviews{
    [super layoutSubviews];
    CGFloat btnWidth = self.frame.size.width/3 -1, topMargin = 5;
    self.mDecreaseBtn.frame = CGRectMake(0, topMargin, btnWidth, self.frame.size.height - topMargin);
    self.mValueLabel.frame = CGRectMake(0, topMargin, btnWidth, self.frame.size.height - topMargin);
    self.mValueLabel.center = CGPointMake(self.frame.size.width* 0.5, self.mValueLabel.center.y);
    self.mIncreaseBtn.frame = CGRectMake(self.frame.size.width - btnWidth, topMargin, btnWidth, self.frame.size.height - topMargin);
}

/**
 减少速度
 */
-(void)decreaseValue{
    [self setTempoValue:[self.mValueLabel.text integerValue]-5];
}

/**
 增加速度
 */
-(void)increaseValue{
    [self setTempoValue:[self.mValueLabel.text integerValue]+5];
}
/**
 设置速度值

 @param value value
 */
-(void)setTempoValue:(NSInteger)value {
    if(value >= 120){
        value = 120;
        [MBProgressHUD CI_showTitle:@"已达速度上限" toView:self.superview hideAfter:1.0];
    }else if (value <= 30){
        value = 30;
        [MBProgressHUD CI_showTitle:@"已达速度下限" toView:self.superview hideAfter:1.0];
    }
    NSString* valuestr = [NSString stringWithFormat:@"%ld",value];
    self.mValueLabel.text = valuestr;
}


#pragma mark -- getter setter

-(UILabel *)mValueLabel{
    if(!_mValueLabel){
        _mValueLabel = [[UILabel alloc]init];
        _mValueLabel.font = [UIFont systemFontOfSize:12];
        [self addSubview:_mValueLabel];
        _mValueLabel.textColor = [UIColor whiteColor];
        _mValueLabel.textAlignment = NSTextAlignmentCenter;
        _mValueLabel.text = @"85";
    }
    return _mValueLabel;
}
-(UIButton *)mDecreaseBtn{
    if(!_mDecreaseBtn) {
        _mDecreaseBtn = [[UIButton alloc]init];
        [_mDecreaseBtn setBackgroundColor:[UIColor clearColor]];
        [_mDecreaseBtn setTitle:@"-" forState:UIControlStateNormal];
        [_mDecreaseBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_mDecreaseBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        [self addSubview:_mDecreaseBtn];
        [_mDecreaseBtn addTarget:self action:@selector(decreaseValue) forControlEvents:UIControlEventTouchUpInside];
    }
    return _mDecreaseBtn;
}

-(UIButton *)mIncreaseBtn{
    if(!_mIncreaseBtn) {
        _mIncreaseBtn = [[UIButton alloc]init];
        [_mIncreaseBtn setBackgroundColor:[UIColor clearColor]];
        [_mIncreaseBtn setTitle:@"+" forState:UIControlStateNormal];
        [_mIncreaseBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_mIncreaseBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        [self addSubview:_mIncreaseBtn];
        [_mIncreaseBtn addTarget:self action:@selector(increaseValue) forControlEvents:UIControlEventTouchUpInside];
    }
    return _mIncreaseBtn;
}
@end
