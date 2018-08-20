//
//  CIResultView.m
//  musicXML
//
//  Created by tanhui on 2017/9/1.
//  Copyright © 2017年 tanhuiya. All rights reserved.
//

#import "ResultView.h"
#import "ScoreSheet.h"
#import "UIImage+music.h"
#import <musicXML/musicXML-Swift.h>

@implementation ResultView
#pragma mark -- liftcycle

/**
 自定义初始化方法

 @return instance
 */
+ (instancetype)customXiBView{
    NSString *className = NSStringFromClass([self class]);
    return [[[NSBundle bundleForClass:[self class]] loadNibNamed:className owner:self options:nil] firstObject];
}

-(void)awakeFromNib{
    [super awakeFromNib];
    [self.mCloseBtn setImage:[UIImage imageForResource:@"close" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]] forState:UIControlStateNormal];
}


-(void)layoutSubviews{
    [super layoutSubviews];
    self.mErrorView.layer.cornerRadius = 5;
    self.mErrorView.layer.borderColor = [[UIColor colorWithRed:6.0f/255.0f green:182.0f/255.0f blue:102.0f/255.0f alpha:1.0f] CGColor];
    self.mErrorView.layer.borderWidth = 0.5;
    self.mErrorView.clipsToBounds = YES;
    self.mDetailBtn.layer.cornerRadius = 7.5;
    self.mDetailBtn.layer.borderColor = [[UIColor colorWithRed:6.0f/255.0f green:182.0f/255.0f blue:102.0f/255.0f alpha:1.0f] CGColor];
    self.mDetailBtn.layer.borderWidth = 0.5;
    self.mDetailBtn.clipsToBounds = YES;
    
    self.mContainerView.layer.cornerRadius = 10;
    self.mContainerView.layer.backgroundColor = [[UIColor colorWithRed:252.0f/255.0f green:249.0f/255.0f blue:236.0f/255.0f alpha:1.0f] CGColor];
    self.mContainerView.clipsToBounds = YES;
}

#pragma mark -- Getter Setter
-(void)setResult:(ResultOutlineModel*)result{
    self.mTitleLable.text = result.mTitle;
    self.mTempoLabel.text = [NSString stringWithFormat:@"%ld",result.mTempo];
    self.lostNumberLabel.text = [NSString stringWithFormat:@"%ld",result.mLostNumber];
    self.errorNumberLabel.text = [NSString stringWithFormat:@"%ld",result.mErrorNumber];
    self.mResult = result;
    __weak typeof(self) weakSelf = self;
    NSDictionary* resultDict = @{
                             @"tempo":@(self.mOption.mTempo),
                             @"hasMainChannel":@((NSInteger)self.mOption.mHasMainChannel),
                             @"errorNumber":@(result.mErrorNumber),
                             @"lostNumber":@(result.mLostNumber),
                             @"totalNumber":@(result.mTotalNumber),
                             };
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:resultDict options:NSJSONWritingPrettyPrinted error:nil];
    NSString* strData = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSData *data = [strData dataUsingEncoding:NSUTF8StringEncoding];
    NSString* encodeData =  [data base64EncodedStringWithOptions:0];
    
    [[MusicService shareService] fetchScoreWithScoreID:self.mOption.mScoreID
                                      accountID:self.mOption.mAccountID
                                      channelID:self.mOption.mChannelID
                                          token:self.mOption.mToken
                                           data:encodeData
                                         typeID:self.mOption.mTypeID
                                           type:self.mOption.mType
                                        success:^(NSInteger score) {

                                            weakSelf.mScoreLabel.text = [NSString stringWithFormat:@"%ld",(long)score];
                                            if (self.mOption.callBack){
                                                self.mOption.callBack();
                                            }
    }
                                          error:^{
        weakSelf.mScoreLabel.text = @"0";
    }];
}



#pragma mark -- IB Action
- (IBAction)detailAction:(id)sender {
    if (!self.mResult) {
        return;
    }
    [self.mSheet showDetailResult];
    [self close:nil];
}
- (IBAction)close:(id)sender {
    [self removeFromSuperview];
}

@end
