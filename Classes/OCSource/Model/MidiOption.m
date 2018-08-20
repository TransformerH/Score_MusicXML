//
//  MidiOption.m
//  Alamofire
//
//  Created by tanhui on 2017/11/22.
//

#import "MidiOption.h"
#import <musicXML/musicXML-Swift.h>

@implementation MidiOption

-(instancetype)initWithTitle:(NSString *)title
                   accountID:(NSString *)accountID
                   channelID:(NSString *)channelID
                       token:(NSString*)token
                     musicID:(NSString*)musicID
                    filePath:(NSString *)filePath {
    if ([super init]) {
        _mChannelID = [channelID integerValue];
        _mTitle = title;
        _mToken = token;
        _mAccountID = accountID;
        _mFilePath = filePath;
        _mScoreID = [musicID integerValue];
        [self checkParams:YES];
    }
    return self;
}

-(instancetype)initWithParams:(NSDictionary*)params{
    if ([super init]) {
        _mChannelID = [params[@"channelID"] integerValue];
        _mTitle = params[@"title"];
        _mToken = params[@"token"];
        _mAccountID = params[@"accountID"];
        _mFilePath = params[@"filePath"];
        _mType = params[@"type"];
        _mScoreID = [params[@"musicID"] integerValue];
        _mTypeID = [params[@"typeID"] integerValue];
        _mMode = CIMidiPlayerMode_Listen;
        _mDebug = [params[@"debug"] boolValue];
        _mDomain = params[@"domain"];
        if (params[@"mode"]) {
            _mHasMode = YES;
            if ([params[@"mode"] integerValue] == 1){
                if ([params[@"hasMainChannel"] boolValue]) {
                    self.mHasMainChannel = YES;
                    _mMode = CIMidiPlayerMode_MainWithAccompany;
                } else {
                    self.mHasMainChannel = NO;
                    _mMode = CIMidiPlayerMode_Accompany;
                }
            }
        }
        if (params[@"callback"]) {
            self.callBack = params[@"callback"];
        }
        if (params[@"tempo"]) {
            _mTempo = [params[@"tempo"] integerValue];
        }
        [self checkParams:NO];
    }
    return self;
}

-(void)checkParams:(BOOL)neccessary{
    NSAssert(self.mScoreID, @"必传参数乐谱id");
    NSAssert(self.mFilePath, @"必传参数id");
    NSAssert(self.mTitle, @"必传参数title");
    NSAssert(self.mChannelID, @"必传参数channelID");
    NSAssert(self.mAccountID, @"必传参数accountID");
    NSAssert(self.mToken, @"必传参数token");
//    NSAssert(params[@"mode"], @"必传参数mode");
//    NSAssert(params[@"type"], @"必传参数type");
//    NSAssert(params[@"typeID"], @"必传参数typeID");
//    NSAssert(params[@"hasMainChannel"], @"必传参数hasMainChannel");
//    NSAssert(self.mTempo, @"必传参数tempo");

}
//-(NSString *)mResultData{
//    NSDictionary* result = @{
//                             @"tempo":@self.mTempo,
//                             @"hasMainChannel":@[self.mHasMainChannel integerValue],
//                             @""
//                             };
//}

-(void)setMDomain:(NSString *)mDomain{
    _mDomain = mDomain;
    [ConstValue setUrl:mDomain];
}

@end
