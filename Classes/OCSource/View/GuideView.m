//
//  GuideView.m
//  Alamofire
//
//  Created by tanhui on 2017/11/23.
//
#import "UIImage+music.h"
#import "UIView+Extension.h"
#import "Constants.h"
#import "GuideView.h"

@implementation GuideModel
-(instancetype)initWithframe:(CGRect)rect icon:(NSString*)icon line:(NSString*)line tip:(NSString*)tip type:(TipType)type{
    if ([super init]) {
        _mRect = rect;
        _mIcon = icon;
        _mLine = line;
        _mTip = tip;
        _mType = type;
    }
    return self;
}
@end

@interface GuideView()
@property(nonatomic, strong) NSMutableArray* mGuideInfos;
@property(nonatomic, strong) UIImageView* mCover;
@property(nonatomic, strong) UIImageView* mLine;
@property(nonatomic, strong) UIButton* mConfirm;
@property(nonatomic, strong) UILabel* mTip;
@property(nonatomic, strong) GuideModel* mCurrentGuide;
@end

@implementation GuideView

-(instancetype)initWithGuideIcons:(NSArray<GuideModel*> *)icon {
    if ([super init]) {
        self.mGuideInfos = icon.mutableCopy;
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
        [self setUpView];
    }
    return self;
}
-(void)setUpView {
    if (!self.mGuideInfos.count) {
        [self removeFromSuperview];
        return;
    }
    self.mCurrentGuide = self.mGuideInfos.firstObject;
    [self.mGuideInfos removeObjectAtIndex:0];
    self.mCover.image = [UIImage imageForResource:self.mCurrentGuide.mIcon ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
    self.mLine.image = [UIImage imageForResource:self.mCurrentGuide.mLine ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
    self.mTip.text = self.mCurrentGuide.mTip;
    CGSize size = [self.mTip.text sizeWithAttributes:@{NSFontAttributeName:self.mTip.font}];
    self.mTip.size = size;
    [self setNeedsLayout];
}

-(void)layoutSubviews{
    [super layoutSubviews];
    switch (self.mCurrentGuide.mType) {
        case TipTypePlay:
            self.mCover.frame = CGRectMake(self.mCurrentGuide.mRect.origin.x - 6, self.mCurrentGuide.mRect.origin.y - 3, self.mCurrentGuide.mRect.size.width * 2 + 30 + 12, self.mCurrentGuide.mRect.size.height + 6);
            self.mLine.frame = CGRectMake(CGRectGetMidX(self.mCover.frame) - 50, CGRectGetMinY(self.mCover.frame) - 150, 50, 150);
            self.mTip.centerX = CGRectGetMidX(self.mCover.frame);
            self.mTip.maxY = CGRectGetMinY(self.mLine.frame);
            self.mConfirm.center = CGPointMake(self.mTip.centerX, CGRectGetMinY(self.mTip.frame) - self.mConfirm.height * 0.5 - 5);
            break;
        case TipTypeAccompany:
        case TipTypeTempo:
        case TipTypeBlueTooth:
            self.mCover.frame = CGRectMake(self.mCurrentGuide.mRect.origin.x - 6, self.mCurrentGuide.mRect.origin.y - 3, self.mCurrentGuide.mRect.size.width + 12, self.mCurrentGuide.mRect.size.height + 6);
            self.mLine.frame = CGRectMake(CGRectGetMidX(self.mCover.frame) - 236, CGRectGetMaxY(self.mCover.frame), 236, 140);
            self.mTip.centerX = CGRectGetMinX(self.mLine.frame);
            self.mTip.y = CGRectGetMaxY(self.mLine.frame) ;
            self.mConfirm.center = CGPointMake(self.mTip.centerX, CGRectGetMaxY(self.mTip.frame) + self.mConfirm.height * 0.5 + 5);
            break;
        case TipTypeMode:
            self.mCover.frame = CGRectMake(self.mCurrentGuide.mRect.origin.x - 6, self.mCurrentGuide.mRect.origin.y, self.mCurrentGuide.mRect.size.width + 12, self.mCurrentGuide.mRect.size.height);
            self.mLine.frame = CGRectMake(CGRectGetMidX(self.mCover.frame) , CGRectGetMaxY(self.mCover.frame), 236, 140);
            self.mTip.centerX = CGRectGetMaxX(self.mLine.frame);
            self.mTip.y = CGRectGetMaxY(self.mLine.frame);
            self.mConfirm.center = CGPointMake(self.mTip.centerX, CGRectGetMaxY(self.mTip.frame) + self.mConfirm.height * 0.5 + 5);
            break;
        default:
            break;
    }
}

-(UILabel *)mTip{
    if (!_mTip) {
        _mTip = [[UILabel alloc]init];
        _mTip.textAlignment = NSTextAlignmentCenter;
        _mTip.font = [UIFont systemFontOfSize:16];
        _mTip.textColor = [UIColor whiteColor];
        [self addSubview:_mTip];
    }
    return _mTip;
}

-(UIImageView *)mLine{
    if (!_mLine) {
        _mLine = [[UIImageView alloc]init];
        _mLine.contentMode = UIViewContentModeScaleAspectFit;
//        _mLine.backgroundColor = [UIColor yellowColor];
        [self addSubview:_mLine];
    }
    return _mLine;
}
-(UIImageView *)mCover{
    if (!_mCover) {
        _mCover = [[UIImageView alloc]init];
        _mCover.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_mCover];
    }
    return _mCover;
}
-(UIButton *)mConfirm{
    if (!_mConfirm) {
        _mConfirm = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 150, 62)];
        [_mConfirm setImage:[UIImage imageForResource:@"iknown" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]] forState:UIControlStateNormal];
        [self addSubview:_mConfirm];
        [_mConfirm addTarget:self action:@selector(setUpView) forControlEvents:UIControlEventTouchUpInside];
    }
    return _mConfirm;
}
@end
