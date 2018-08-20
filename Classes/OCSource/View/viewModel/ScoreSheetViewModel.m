//
//  ScoreSheetViewModel.m
//  CIRouter
//
//  Created by tanhui on 2017/10/12.
//

#import "ScoreSheetViewModel.h"
#import "BleMidiParser.h"
#import "DrawableNoteM.h"
#import "Constants.h"
#import "musicXML.h"
#import <CIRouter/CIRouter.h>

@interface ScoreSheetViewModel()
@property (strong , nonatomic) BleMidiParser* mBleParser;
@property(nonatomic, assign) double mCurrentTick;
@end


@implementation ScoreSheetViewModel
- (instancetype)init{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(blueToothStateChanged:) name:@"kBlueToothStateDidChanged" object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(blueToothDidReceiveMidiSignal:) name:@"kBlueToothDidReceiveMidiSignal" object:nil];
        
        id connected = [[CIRouter shared]callBlock:@"/bluetooth/connected"];
        _isConnected = [connected boolValue];
    }
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"kBlueToothStateDidChanged" object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"kBlueToothDidReceiveMidiSignal" object:nil];
    
}
#pragma mark -- Notification
/**
 蓝牙状态改变

 @param note
 */
-(void)blueToothStateChanged:(NSNotification *)note{
    NSDictionary* info = note.userInfo;
    BOOL connect = [info[@"connected"] boolValue];
    _isConnected = connect;
}

/**
 收到蓝牙的信号

 @param note
 */
-(void)blueToothDidReceiveMidiSignal:(NSNotification *)note{
    if (!self.isPlaying) {
        return ;
    }
    NSDictionary* info = note.userInfo;
    NSData* data = info[@"data"];
    int length = [info[@"length"]intValue];
    struct timeval now;
    gettimeofday(&now, NULL);
    long msec = 0;
    
    if (self.startTime){
        //        CILog(@"rawdata -- %@",data);
        msec = now.tv_sec *1000 + now.tv_usec /1000 - self.startTime;
        [self.mBleParser parse:(char *)data.bytes length:length atMS:msec];
    }
}

#pragma mark -- Public Method
-(void)prepareRecording{
    self.isPlaying = YES;
}
-(void)beginRecording{
    struct timeval now;
    gettimeofday(&now, NULL);
    self.startTime = now.tv_sec * 1000 + now.tv_usec / 1000;
}
-(void)stopRecording{
    self.isPlaying = NO;
}

-(void)pause{
    struct timeval now;
    gettimeofday(&now, NULL);
    self.pauseTime = now.tv_sec * 1000 + now.tv_usec / 1000;
}

-(void)resume{
    struct timeval now;
    gettimeofday(&now, NULL);
    self.startTime = self.startTime + now.tv_sec * 1000 + now.tv_usec / 1000 - self.pauseTime;
}
#pragma mark -- Getter Setter
-(BleMidiParser *)mBleParser{
    if (!_mBleParser) {
        _mBleParser = [[BleMidiParser alloc]init];
    }
    return _mBleParser;
}

@end
