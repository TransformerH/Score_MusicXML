//
//  ScoreSheet.m
//  iOSMusic
//
//  Created by tanhui on 2017/7/11.
//  Copyright © 2017年 tanhui. All rights reserved.
//

#import "ScoreSheet.h"
#import "musicXML.h"
#import "Constants.h"
#import "MidiPlayer.h"
#import "DrawableNoteM.h"
#import "SheetView.h"
#import "PianoView.h"
#import "ResultDetailM.h"
#import "ResultDetailView.h"
#include "../../musicFramework/compare/ComparePooling.h"
#import "ResultView.h"
#import <CIRouter/CIRouter.h>


@implementation MidiResult
@end
// add test
@interface ScoreSheet ()<MidiPlayerDelegate>{
    std::vector<MidiSignal*> receives;
    ComparePooling* mPool;
    dispatch_semaphore_t semaphore;
}
@property(nonatomic, strong) ScoreM* mScore;
@property(nonatomic, strong) SheetView* mSheetview;
@property(nonatomic, strong) PianoView* mPiano;
@property(nonatomic, assign) double mCurrentTick;
@property(nonatomic, assign) BOOL mIsPlaying;
@property(nonatomic, strong) NSTimer* mTimer;
@property(nonatomic, strong) ResultOutlineModel* mOutlineModel;
@end

//bool less_second(CNote* & m1, CNote* & m2) {
//    return m1->mStartTime < m2->mStartTime;
//}

@implementation ScoreSheet

#pragma mark -- lifecycle

-(instancetype)initWithFrame:(CGRect)frame score:(ScoreM*)score{
    if ([super initWithFrame:frame]) {
        _mScore = score;
        mPool = NULL;
        (void)[self mPiano];
        (void)[self mSheetview];
        self.userInteractionEnabled = YES;
        semaphore = dispatch_semaphore_create(1);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scoreDidreceiveMidiOn:) name:ScoreDidReceiveMidiOnNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scoreDidreceiveMidiOff:) name:ScoreDidReceiveMidiOffNotification object:nil];
        receives = std::vector<MidiSignal*>();
        self.mScoreSheetViewModel = [[ScoreSheetViewModel alloc]init];
    }
    return self;
}

/**
 释放比较池
 */
-(void)releasePool {
    if (mPool != NULL) {
        delete mPool;
        mPool = NULL;
    }
}

-(void)dealloc{
    CILog(@"ScoreSheet Dealloc");
    [[NSNotificationCenter defaultCenter]removeObserver:self  name:ScoreDidReceiveMidiOnNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self  name:ScoreDidReceiveMidiOffNotification object:nil];
    [self releasePool];
}

#pragma mark -- Public method

-(void)setPool:(ComparePooling *)pool{
    mPool = pool;
}

-(void)showResults{
    do {
        if([self.resultDelegate playerState] == EPlayState_Stop){
            // 手动reset
            break;
        }
        if ([self.resultDelegate getMidiPlayMode] == CIMidiPlayerMode_Listen) {
            if ([self.resultDelegate respondsToSelector:@selector(resetSheet)]) {
                [self.resultDelegate resetSheet];
            }
            break;
        } else {
            CResult* result = mPool->getFinalResult();
            if(self.resultDelegate && [self.resultDelegate respondsToSelector:@selector(playerDidFinishWithResult:)]){
                [self.resultDelegate playerDidFinishWithResult:nil];
                [self.resultDelegate stop];
                [self showResultSymbols:result];
            }
        }
    } while (false);
    [self releasePool];
}


-(void)showDetailResult{
    ResultDetailView* detailView = [[ResultDetailView alloc]initWithFrame:self.mSheetview.frame errorResults:self.mOutlineModel.mErrorNotes score:self.mScore];
    [self.mSheetview.mParentView addSubview:detailView];
}


-(void)clearResult{
    [self.mSheetview clearResult];
}

-(void)reset{
    [self.mSheetview.mParentView setContentOffset:CGPointMake(0, 0)];
    UIScrollView* scrollView = self.mSheetview.mParentView;
    for (UIView* view in scrollView.subviews) {
        if ([view isKindOfClass:[ResultDetailView class]]) {
            [view removeFromSuperview];
        }
    }
}

-(void)prepareRecording{
    if ([self.resultDelegate respondsToSelector:@selector(getMidiPlayMode)] &&
        [self.resultDelegate getMidiPlayMode] != CIMidiPlayerMode_Listen){
        
        [self.mScoreSheetViewModel prepareRecording];
    }else{
        self.mScoreSheetViewModel.isPlaying = NO;
    }
}

-(void)beginRecording {
    self.mCurrentTick = 0;
    if (mPool != NULL){
        mPool->resetPool();
        NSInteger instrument = [[[CIRouter shared]callBlock:@"/bluetooth/selectInstrument"] integerValue];
        mPool->setMode(InstrumentMode_DoubleKey_YMH);
    }
    if ([self.resultDelegate respondsToSelector:@selector(getMidiPlayMode)] &&
        [self.resultDelegate getMidiPlayMode] != CIMidiPlayerMode_Listen){
        [self.mScoreSheetViewModel beginRecording];
    }else{
        self.mScoreSheetViewModel.isPlaying = NO;
    }
    [self.mTimer fire];
}

-(void)stopRecording {
    self.mScoreSheetViewModel.isPlaying = NO;
    [self.mTimer invalidate];
    self.mTimer = nil;
}
-(void)resumeRecording{
    self.mScoreSheetViewModel.isPlaying = YES;
    [self.mTimer fire];
}


#pragma mark -- Private Method

/**
 发送收到的信号
 */
-(void)deliverMidiSignals {
    if ([self mIsPlaying]) {
        NSString* str = @"";
        for (int i = 0 ; i<receives.size(); i++) {
            MidiSignal* signal = receives[i];
            str = [str stringByAppendingFormat:@"\n note%d tick=%lf ; ",i,signal->mTimeStamp];
        }
        std::vector<CNote*>ret = mPool->receiveMidiSignals(receives, [self getCurrentTicks]);
        dispatch_semaphore_signal(semaphore);
        receives.clear();
        dispatch_semaphore_signal(semaphore);
    }
}

/**
 添加 midi 信号到接收器

 @param channel 信号通道
 @param tick 时间
 @param number 信号值
 @param type 信号类型On/Off
 */
-(void)addMidiSignal:(NSInteger)channel tick:(NSInteger)tick number:(NSInteger)number type:(EMidiSignalType)type{
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    //    CILog(@"channel --%d, %d",channel,number);
    receives.push_back(new MidiSignal((int)channel,tick,number,type));
    dispatch_semaphore_signal(semaphore);
}


/**
 播放结束
 */
-(void)playOver {
    if ([self.resultDelegate playerState] == EPlayState_Pause){
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf stopRecording];
        [weakSelf showResults];
        [weakSelf.mSheetview updateCusor:nil];
    });
}

/**
 显示结果 （分数）

 @param result 结果
 */
-(void)showResultSymbols:(CResult*)result {
    ResultView* resultview = [ResultView customXiBView];
    resultview.mSheet = self;
    resultview.mOption = self.mOption;
    self.mOutlineModel = [self generateResultOutlineMode:result];
    [resultview setResult:self.mOutlineModel];
    resultview.frame = self.mSheetview.mParentView.frame;
    [self.superview addSubview:resultview];
    delete result;
}


/**
 生成 ResultOutlineModel 对象

 @param result 结果
 @return ResultOutlineModel
 */
-(ResultOutlineModel*)generateResultOutlineMode:(CResult*)result{
    ResultOutlineModel* model = [[ResultOutlineModel alloc]init];
    NSMutableArray<ResultDetailM*>* errorNotes = @[].mutableCopy;
    NSInteger errorNumber = 0,lostNumber = 0;
    for (auto iter = result->mResultNotes.cbegin(); iter != result->mResultNotes.cend(); iter ++) {
        ResultDetailM* resultM = [[ResultDetailM alloc]init];
        resultM.mStartTime =(*iter)->mStartTime;
        resultM.mStaffIndex =(*iter)->mStaffIndex;
        resultM.mNoteNumber = (*iter)->mNoteNumber;
        resultM.mDuration = (*iter)->mDuration;
        resultM.mMeasureIndex = (*iter)->mMeasureIndex;
        resultM.mPartIndex = (*iter)->mPartIndex;
        if ((*iter)->mType == ECNoteResultTypeError) {
            resultM.mErrorNumber = (*iter)->mErrorNumber;
            resultM.mErrorType = EResultErrorType_Error;
            errorNumber++;
        }else if((*iter)->mType == ECNoteResultTypeLost){
            resultM.mErrorType = EResultErrorType_Lost;
            lostNumber++;
        }
        [errorNotes addObject:resultM];
    }
    model.mTotalNumber = result->mTotalNotes;
    model.mErrorNotes = errorNotes.copy;
    model.mErrorNumber = errorNumber;
    model.mLostNumber = lostNumber;
    model.mTempo = [self.resultDelegate getTempo];
    model.mTitle = self.mScore.mTitle;
    return model;
}
// 获取当前时间
-(double)getCurrentTicks{
    return self.mCurrentTick;
}
#pragma mark -- Notification
// 收到On 信号
-(void)scoreDidreceiveMidiOn:(NSNotification*)note {
    if(!self.mIsPlaying|| !self.mScoreSheetViewModel.isPlaying){
        return;
    }
    NSDictionary* info = note.object;
    int channel = [info[@"channel"] intValue];
    int noteNum = [info[@"note"] intValue];
    double ms = [info[@"ms"] doubleValue];
    
    double msPerDivision = [self.mPlayer getTempoMPQ]/1000.0/DivisionUnit;
    double ticks = ms / msPerDivision;
    //    CILog(@"Off  origin ms-- %lf,  Tick--- %lf",ms,ticks);
    [self addMidiSignal:channel tick:ticks number:noteNum type:EMidiSignalType::EMidiSignalTypeOn];
    [Log writefile:channel note:noteNum velocity:0 tick:ticks remark:@"On"];
}
// 收到Off 信号
-(void)scoreDidreceiveMidiOff:(NSNotification*)note {
    if(!self.mIsPlaying || !self.mScoreSheetViewModel.isPlaying){
        return;
    }
    NSDictionary* info = note.object;
    int channel = [info[@"channel"] intValue];
    int noteNum = [info[@"note"] intValue];
    double ms = [info[@"ms"] doubleValue];
    double msPerDivision = [self.mPlayer getTempoMPQ]/1000.0/DivisionUnit;
    double ticks = ms / msPerDivision;
    [self addMidiSignal:channel tick:ticks number:noteNum type:EMidiSignalType::EMidiSignalTypeOff];
    [Log writefile:channel note:noteNum velocity:0 tick:ticks remark:@"Off"];
}

#pragma mark -- MidiPlayerDelegate
-(void)midiPlayerDelegateIsPlaying:(BOOL)isplaying currentMS:(int)ms totalMS:(int)lenMs{
    self.mIsPlaying = isplaying;
    if([self.resultDelegate respondsToSelector:@selector(playerDidPlayAt:total:)]){
        [self.resultDelegate playerDidPlayAt:ms total:lenMs];
    }
    if (!isplaying) {
        [self playOver];
        return;
    }
    ms = ms - self.midiSecondOffset * 1000;
    if (ms <= 0)return;
    int tempo = [self.mPlayer getTempoMPQ];
    // ticks per ms
    double ticksPerMs = DivisionUnit* 1.0/tempo * 1000;
    double currentTicks = ms * ticksPerMs;
    self.mCurrentTick = currentTicks;
    DrawableNoteM* note = [self.mScore getLatestNoteByTicks:currentTicks];
    
    NSArray* pianoNotes = [self.mScore getNotesByStartTime:currentTicks];
    [self.mSheetview updateCusor:note];
    [self.mPiano updateNotes:pianoNotes];
}









#pragma mark -- getter setter

-(void)setMPlayer:(MidiPlayer *)mPlayer{
    _mPlayer = mPlayer;
    mPlayer.delegate = self;
}

-(NSTimer *)mTimer{
    if (!_mTimer){
        _mTimer =[NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(deliverMidiSignals) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop]addTimer:self.mTimer forMode:NSRunLoopCommonModes];
    }
    return _mTimer;
}

-(SheetView *)mSheetview{
    if (!_mSheetview) {
        _mSheetview = [[SheetView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width ,self.mScore.mTotalHeight) score:self.mScore];
        UIScrollView* scrollview = [[UIScrollView alloc]initWithFrame:self.bounds];
        [scrollview addSubview:_mSheetview];
        _mSheetview.mParentView = scrollview;
        [self addSubview:scrollview];
        scrollview.contentSize = CGSizeMake(0 ,_mSheetview.frame.size.height);
    }
    return _mSheetview;
}

-(PianoView *)mPiano{
    if (!_mPiano) {
        _mPiano = [[PianoView alloc]init];
    }
    return _mPiano;
}


@end
