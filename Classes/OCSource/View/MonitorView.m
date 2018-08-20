//
//  MonitorView.m
//  Alamofire
//
//  Created by tanhui on 2018/1/9.
//

#import "MonitorView.h"
#import <musicXML/musicXML-Swift.h>
#import "MBProgressHUD+Extension.h"

@interface MonitorView()
@property (weak, nonatomic) IBOutlet UITextField *mError;
@property (weak, nonatomic) IBOutlet UITextField *mLost;
@property (weak, nonatomic) IBOutlet UITextField *mTotal;
@end

@implementation MonitorView

-(void)awakeFromNib{
    [super awakeFromNib];
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(commit)]];
}

-(void)commit{
    [self endEditing:YES];
}

-(void)setMOption:(MidiOption *)mOption{
    _mOption = mOption;
}


- (IBAction)submit:(id)sender {
    NSDictionary* resultDict = @{
                                 @"tempo":@(self.mOption.mTempo),
                                 @"hasMainChannel":@((NSInteger)self.mOption.mHasMainChannel),
                                 @"errorNumber":@([self.mError.text integerValue]),
                                 @"lostNumber":@([self.mLost.text integerValue]),
                                 @"totalNumber":@([self.mTotal.text integerValue]),
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
                                            [MBProgressHUD CI_showTitle:@"发送成功" toView:self hideAfter:1.0];
                                            if (self.mOption.callBack){
                                                self.mOption.callBack();
                                            }
                                            [self removeFromSuperview];
                                        }
                                          error:^{
                                              [MBProgressHUD CI_showTitle:@"发送失败" toView:self hideAfter:1.0];
                                          }];
}
- (IBAction)cancel:(id)sender {
    [self removeFromSuperview];
}


@end
