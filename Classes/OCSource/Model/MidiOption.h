//
//  MidiOption.h
//  Alamofire
//
//  Created by tanhui on 2017/11/22.
//

#import <Foundation/Foundation.h>
#import "Constants.h"

@interface MidiOption : NSObject
@property(nonatomic, copy) NSString* mTitle;// 乐谱标题
@property(nonatomic, copy) NSString* mFilePath; // xml文件路径
@property(nonatomic, assign) NSInteger mScoreID; // 乐谱ID
@property(nonatomic, assign) NSInteger mTypeID; // 作业ID
@property(nonatomic, copy) NSString* mType; // 作业类型 ‘work’
@property(nonatomic, copy) NSString* mToken; // token
@property(nonatomic, copy) NSString* mAccountID;
@property(nonatomic, assign) NSInteger mChannelID;
@property(nonatomic, assign) BOOL mHasMode; // 是否传mode过来
@property(nonatomic, assign) CIMidiPlayerMode mMode; // 播放模式
@property(nonatomic, assign) NSInteger mTempo; // 速度
@property(nonatomic, assign) BOOL mHasMainChannel;// 是否需要伴奏
@property(nonatomic, copy) void(^callBack)(void); // 回调方法
@property(nonatomic, assign) BOOL mDebug;// 是否是调试模式
@property(nonatomic, copy) NSString* mDomain; // 域名


-(instancetype)initWithTitle:(NSString *)title
                   accountID:(NSString *)accountID
                   channelID:(NSString *)channelID
                       token:(NSString*)token
                     musicID:(NSString*)musicID
                    filePath:(NSString *)filePath;

-(instancetype)initWithParams:(NSDictionary*)params;
@end
