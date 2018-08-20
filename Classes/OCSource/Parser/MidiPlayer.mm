//
//  MidiPlayer.m
//  Pods
//
//  Created by tanhui on 2017/8/3.
//
//

#import "MidiPlayer.h"
#include "../../musicFramework/parseScore/MidiHandler.h"
//#import "MidiHandler.h"
#import "fmod.hpp"
#import "musicXML.h"

@implementation MidiInfoRetM
@end

@interface MidiPlayer () {
    FMOD::System    *system;
    FMOD::Sound    *sound1;
    FMOD::Channel  *channel;
    FMOD::ChannelGroup* group;
    NSTimer *timer;
    MidiInfo* mInfo;
}

//@property(nonatomic, assign) MidiHandler* mHandler;
@property(nonatomic, strong) NSString* mInputPath;
@property(nonatomic, strong) NSString* mOutputPath;
@end

@implementation MidiPlayer

/**
 检查FMOD状态

 @param result 状态
 */
void ERRCHECK(FMOD_RESULT result){
    if (result != FMOD_OK){
        fprintf(stderr, "FMOD error! (%d) %s\n", result, FMOD_ErrorString(result));
        exit(-1);
    }
}


/**
 初始化

 @param path 路径
 @return instance
 */
-(instancetype)initWithFile:(NSString*)path {
    if ([super init]) {
        
        self.mInputPath = path;

        NSString* fileName = [path lastPathComponent];

        if (![fileName hasSuffix:@".mid"]){
            fileName = [[fileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"mid"];
        }
        self.mOutputPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:fileName];
        system = NULL;
        sound1  = NULL;
        channel = NULL;
        group = NULL;
    }
    return self;
}

-(void)dealloc{
    CILog(@"MidiPlayer dealloc");
    FMOD_RESULT result = FMOD_OK;
    
    if(sound1 != NULL){
        result = sound1->release();
    }
    if(system != NULL){
        result = system->close();
        result = system->release();
    }
    if(group != NULL){
        result = group->release();
    }
    if (mInfo != NULL){
        delete mInfo;
    }
}

#pragma mark -- Public Action
/**
 准备播放
 
 @param mode 模式
 @return 播放信息
 */
-(MidiInfo*)prepareToPlay:(CIMidiPlayerMode)mode{
    MidiHandler handler = MidiHandler([self.mInputPath UTF8String]);
//    self.mHandler->setTempoValue(120);
    mInfo = handler.save([self.mOutputPath UTF8String],(MidiPlayerMode)mode);
    [self prepareFmod];
    return mInfo;
}

/**
 准备播放

 @param tempo 速度
 @param mode 模式
 @return 播放信息
 */
-(MidiInfo*)prepareToPlay:(NSInteger)tempo mode:(CIMidiPlayerMode)mode{
    if (tempo>=30 && tempo <= 120) {
        MidiHandler handler = MidiHandler([self.mInputPath UTF8String]);
        handler.setTempoValue((int)tempo);
        mInfo = handler.save([self.mOutputPath UTF8String],(MidiPlayerMode)mode);
        [self prepareFmod];
        return mInfo;
    }
    return NULL;
}

/**
 准备midi文件
 */
-(void)prepareFmod{
    FMOD_RESULT   result        = FMOD_OK;
    char          buffer[500]   = {0};
    unsigned int  version       = 0;

    /*
     Create a System object and initialize
     */
    result = FMOD::System_Create(&system);
    ERRCHECK(result);

    result = system->getVersion(&version);
    ERRCHECK(result);

    if (version < FMOD_VERSION)
    {
        fprintf(stderr, "You are using an old version of FMOD %08x.  This program requires %08x\n", version, FMOD_VERSION);
        exit(-1);
    }

    result = system->init(32, FMOD_INIT_NORMAL , NULL);
    ERRCHECK(result);

    // set up DLS file
    FMOD_CREATESOUNDEXINFO   soundExInfo;
    memset(&soundExInfo, 0, sizeof(FMOD_CREATESOUNDEXINFO));
    soundExInfo.cbsize   = sizeof(FMOD_CREATESOUNDEXINFO);
    char dlsName[500] = {0};

    NSString* dlsPath = [NSString stringWithFormat:@"%@/musicXML.bundle/gm.dls", [[NSBundle bundleForClass:self.class] resourcePath]];
    [dlsPath getCString:dlsName maxLength:500 encoding:NSASCIIStringEncoding];
    soundExInfo.dlsname  = dlsName;

    // midi one
    [self.mOutputPath getCString:buffer maxLength:500 encoding:NSUTF8StringEncoding];

    result = system->createSound(buffer,  FMOD_CREATESTREAM, &soundExInfo, &sound1);
    ERRCHECK(result);
    result = sound1->setMode(FMOD_LOOP_OFF);
    ERRCHECK(result);
    result =  system->createChannelGroup(buffer, &group);
    ERRCHECK(result);
    
}


-(void)play {
//    [self stop];
    FMOD_RESULT result = FMOD_OK;
    result = system->playSound(sound1, group, false, &channel);
    ERRCHECK(result);
//    channel->setPosition(9000, FMOD_TIMEUNIT_MS);
    timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(timerUpdate:) userInfo:nil repeats:YES];
//    [[NSRunLoop currentRunLoop]addTimer:timer forMode:NSRunLoopCommonModes];
}

-(BOOL)pauseOrResume {
    bool pause = false;
    channel->getPaused(&pause);
    channel->setPaused(!pause);
    return !pause;
}

-(void)stop{
    if (channel) {
        channel->stop();
    }
    FMOD_RESULT result = FMOD_OK;
    if(sound1 != NULL){
        result = sound1->release();
    }
    if(system != NULL){
        result = system->close();
        result = system->release();
    }
    if(group != NULL){
        result = group->release();
    }
    NSError* error = nil;
    if(![[NSFileManager defaultManager]removeItemAtPath:self.mOutputPath error:&error]){
        if(error){
            NSLog(@"%@",error);
        }
    }
}

#pragma mark -- Private Action

/**
 定时器

 @param timer
 */
- (void)timerUpdate:(NSTimer *)timer{
    unsigned int ms = 0;
    unsigned int lenms = 0;
    bool         playing = 0;
    FMOD_RESULT result = FMOD_OK;
    result = channel->isPlaying(&playing);

    result = channel->getPosition(&ms, FMOD_TIMEUNIT_MS);
    FMOD::Sound *currentsound = 0;
    channel->getCurrentSound(&currentsound);
    result = currentsound->getLength(&lenms, FMOD_TIMEUNIT_MS);

    unsigned int position = 0;
    channel->getPosition(&position, FMOD_TIMEUNIT_MS);
//    std::cout<<"current position --"<<position<<std::endl;
    if (!playing){
        //播放结束
        [timer invalidate];
    }

    if(self.delegate && [self.delegate respondsToSelector:@selector(midiPlayerDelegateIsPlaying:currentMS:totalMS:)]) {
        [self.delegate midiPlayerDelegateIsPlaying:playing currentMS:ms totalMS:lenms];
    }
}

-(int)getTempoMPQ{
    return 60.0/ mInfo->mTempo * 1000000 + 0.5;
}


@end

