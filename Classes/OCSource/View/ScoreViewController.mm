//
//  CIScoreViewController.m
//  musicXML
//
//  Created by tanhui on 2017/9/15.
//  Copyright © 2017年 tanhuiya. All rights reserved.
//

#import "ScoreViewController.h"
#import "ResultView.h"
#import "UIImage+music.h"
#import "ScoreSettingView.h"
#import <CIRouter/CIRouter.h>
#import "MBProgressHUD+Extension.h"
#import "UIButton+Border.h"
#import "ScoreModeView.h"
#import "UIView+Extension.h"
#import "PrepareView.h"
#import "GuideView.h"
#include "../../musicFramework/parseScore/MidiHandler.h"
#import <musicXML/musicXML-Swift.h>
#import "MonitorView.h"

@interface ScoreViewController ()<ShowResultDelegate>

@property (weak, nonatomic) IBOutlet UIView *mHudTopView;
@property (weak, nonatomic) IBOutlet UIView *mHudBottomView;
@property (weak, nonatomic) IBOutlet UIButton *mPlayOrPauseBtn;
@property (weak, nonatomic) IBOutlet ScoreModeView *mModeSelectView;
@property(nonatomic, strong) MidiPlayer* mPlayer;
@property(nonatomic, strong) ScoreSheet* mSheet;
@property(nonatomic, assign) EPlayState mState;
@property (weak, nonatomic) IBOutlet UIButton *mResultBtn;
@property(nonatomic, strong) MidiOption* mOption;
@property(nonatomic, weak) ScoreM* mScore;
@property(nonatomic, assign) BOOL mIsConnected;// 蓝牙是否连接
@property(nonatomic, assign) BOOL mIsAccompany;// 是有伴奏san(演奏模式)
@property(nonatomic, assign) BOOL mHiddenMenu;
@property (weak, nonatomic) IBOutlet ScoreSettingView *mSettingView;

@property (weak, nonatomic) IBOutlet UIProgressView *mProgressView;
@property (weak, nonatomic) IBOutlet UIButton *mBlueBtn;
@property (weak, nonatomic) IBOutlet UIButton *mAccompany;
@property (weak, nonatomic) IBOutlet UIButton *mTempo;
@property (weak, nonatomic) IBOutlet UIButton *mResetBtn;
@property (weak, nonatomic) IBOutlet UIButton *mBackBtn;
@property (weak, nonatomic) IBOutlet PrepareView *mPrepareView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mTopViewTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mTopViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mModeSelectTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mBottomViewBottom;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mBottomViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ContainerBottom;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ContainerRight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ContainerLeft;
@property(nonatomic, assign) BOOL mSetUp; // 判断是否设置过
@property(nonatomic, assign) BOOL mPopAction; // 判断是否设置过
@property (weak, nonatomic) IBOutlet UIView *mContainerView;
@end

@implementation ScoreViewController

#pragma mark -- liftcycle

-(instancetype)init{
    NSBundle* bundle = [NSBundle bundleForClass:[self class]];
    self = [self initWithNibName:NSStringFromClass([self class]) bundle:bundle];
    return self;
}
///**
// init 方法
//
// @param filePath 文件路径
// @return self
// */
//-(instancetype)initWithFileName:(NSString*)filePath{
//    NSBundle* bundle = [NSBundle bundleForClass:[self class]];
//    self = [self initWithNibName:NSStringFromClass([self class]) bundle:bundle];
//    if (self) {
//    }
//    return self;
//}
- (instancetype)initWithOption:(MidiOption *)option {
    if ([self init]) {
        self.mOption = option;
    }
    return self;
}

-(void)dealloc{
    CILog(@"ScoreViewController Dealloc");
}
-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:YES];
    [self rotateToLandScape];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(blueToothStateChanged:) name:kBlueToothStateDidChanged object:nil];
}
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    if (!self.mPopAction) {
        [self rotateToPortrai];
    }
    [self.navigationController setNavigationBarHidden:NO];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kBlueToothStateDidChanged object:nil];
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    BOOL showTip = [[[UtilService alloc]init] showTips];
    if (!showTip) {
        return;
    }
    CGRect accompRect = [self.mAccompany convertRect:self.mAccompany.bounds toView:self.view];
    CGRect playRect = [self.mPlayOrPauseBtn convertRect:self.mPlayOrPauseBtn.bounds toView:self.view];
    CGRect tempoRect = [self.mTempo convertRect:self.mTempo.bounds toView:self.view];
    CGRect bleRect = [self.mBlueBtn convertRect:self.mBlueBtn.bounds toView:self.view];
    CGRect modeRect = [self.mModeSelectView convertRect:self.mModeSelectView.bounds toView:self.view];
    NSArray* icons = @[
                       [[GuideModel alloc]initWithframe:accompRect icon:@"accomp_cover" line:@"accomp_line" tip:@"点击此处任意切换伴奏的关闭与开启哦！" type:TipTypeAccompany],
                       [[GuideModel alloc]initWithframe:playRect icon:@"play_action_cover" line:@"play_line" tip:@"点击此处可以对乐谱进行播放暂停和重播的操作哦！" type:TipTypePlay],
                       [[GuideModel alloc]initWithframe:tempoRect icon:@"tempo_cover" line:@"tempo_line" tip:@"点击此处任意调整曲谱的速度哦！" type:TipTypeTempo],
                       [[GuideModel alloc]initWithframe:bleRect icon:@"bluetooth_cover" line:@"bluetooth_line" tip:@"点击此处可以对蓝牙进行设置哦！\n（演奏模式下必须开启哦~）" type:TipTypeBlueTooth],
                       [[GuideModel alloc]initWithframe:modeRect icon:@"mode_cover" line:@"mode_line" tip:@"点击此处可以切换欣赏和演奏模式哦！" type:TipTypeMode]];
    
    GuideView* guideView = [[GuideView alloc]initWithGuideIcons:icons];
    guideView.frame = self.view.bounds;
    [self.view addSubview:guideView];
}

/**
 旋转至竖屏
 */
- (void) rotateToPortrai{
    NSNumber *orientationUnknown = [NSNumber numberWithInt:UIInterfaceOrientationUnknown];
    [[UIDevice currentDevice] setValue:orientationUnknown forKey:@"orientation"];
    NSNumber *orientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
}

/**
 旋转至横屏
 */
- (void) rotateToLandScape{
    NSNumber *orientationUnknown = [NSNumber numberWithInt:UIInterfaceOrientationUnknown];
    [[UIDevice currentDevice] setValue:orientationUnknown forKey:@"orientation"];
    NSNumber *orientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
    [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
}


/**
 解析MusicXML文件的绘制信息，
 创建ScoreSheet对象，调用ScoreSheet的初始化函数创建ScoreViewController的子控件：创建SheetView的实例，在SheetView上绘制乐谱。创建ScrollView实例，将SheetView的实例添加到scrollView中，就可以进行上下滑动查看乐谱。在ScoreSheet中添加scrollView实例，
 初始化MidiPlayer类的实例player,并将实例赋值给ScoreSheet的mPlayer属性。
 ScoreSheet的作用是将用来展示乐谱的视图SheetView和用来演奏乐谱的MidiPlayer连接在一起，用来实现乐谱上的指示针随着演奏而不断更新的功能。
 
 对总的视图进行布局，设置按钮等控件

 @param rect
 */
-(void)setup:(CGRect)rect{
    xml_midiFile* file = [[xml_midiFile alloc]initWithOption:self.mOption sheetSize:rect.size];
    MidiPlayer* player = [[MidiPlayer alloc] initWithFile:self.mOption.mFilePath];
    self.mPlayer = player;
    
    ScoreSheet* sheet = [[ScoreSheet alloc]initWithFrame:CGRectMake(rect.origin.x, rect.origin.y + 46, rect.size.width, rect.size.height) score:file.mScore];
    sheet.mOption = self.mOption;
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(touch)];
    [sheet addGestureRecognizer:tap];
    sheet.mPlayer = player;
    sheet.resultDelegate = self;
    self.mSheet = sheet;
    [self.mContainerView insertSubview:sheet atIndex:0];
    [self.mSettingView setTempo:(int)file.mScore.mTempo];
    self.mModeSelectView.mScoreVC = self;
    self.mModeSelectView.mMidiMode = self.mOption.mMode;
    
    self.mScore = file.mScore;
    self.mContainerView.backgroundColor = [UIColor colorWithRed:252/255.0 green:249/255.0 blue:236/255.0 alpha:1.0];
    
    [self.mTempo setImage:[UIImage imageForResource:@"tempo" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]]  forState:UIControlStateNormal];
    [self.mResetBtn setImage:[UIImage imageForResource:@"replay" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]]  forState:UIControlStateNormal];
    [self.mBackBtn setImage:[UIImage imageForResource:@"back" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]]  forState:UIControlStateNormal];
    [self.mPlayOrPauseBtn setImage:[UIImage imageForResource:@"play" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]]  forState:UIControlStateNormal];
    
    self.mSettingView.mScoreVC = self;
    
    self.mResultBtn.layer.cornerRadius =8;
    self.mResultBtn.clipsToBounds = YES;
    self.mResultBtn.hidden = YES;
    
    [self.mPlayOrPauseBtn setBorderColor:[UIColor whiteColor] width:1.0 radious:6.0];
    [self.mResetBtn setBorderColor:[UIColor whiteColor] width:1.0 radious:6.0];
    [self.mTempo setBorderColor:[UIColor whiteColor] width:1.0 radious:8.0];
    self.mIsConnected = [[[CIRouter shared]callBlock:@"/bluetooth/connected"] boolValue];
    
    if(self.mOption.mHasMode && self.mOption.mMode == CIMidiPlayerMode_MainWithAccompany){
        self.mIsAccompany = YES;
        self.mIsRecording = YES;
    }else {
        self.mIsAccompany = NO;
        self.mIsRecording = NO;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self rotateToLandScape];
    if (!self.mOption) {
        self.mOption = [[MidiOption alloc]initWithParams: self.params];
    }
    if (self.mOption.mDebug) {
        [self setUpMonitorTouch];
    }
}

-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    if (!self.mSetUp){
        self.mSetUp = YES;
        CGRect rect = self.view.frame;
        [self setup:rect];
    }
}

-(void)viewSafeAreaInsetsDidChange{
    [super viewSafeAreaInsetsDidChange];
    self.ContainerLeft.constant = self.view.safeAreaInsets.left;
    self.ContainerRight.constant = self.view.safeAreaInsets.right;
    self.ContainerBottom.constant = self.view.safeAreaInsets.bottom;
    if (!self.mSetUp){
        self.mSetUp = YES;
        CGRect rect = self.view.frame;
        if (@available(iOS 11.0, *)) {
            UIEdgeInsets inset = self.view.safeAreaInsets;
            rect = CGRectMake(0,
                              rect.origin.y + inset.top,
                              rect.size.width - inset.left - inset.right,
                              rect.size.height - inset.top - inset.bottom);
        }
        [self setup:rect];
    }
}

#pragma mark -- custom Action

/**
 蓝牙状态改变
 
 @param note
 */
-(void)blueToothStateChanged:(NSNotification *)note{
    NSDictionary* info = note.userInfo;
    BOOL connect = [info[@"connected"] boolValue];
    if (!connect &&
        self.mState == EPlayStatePlaying &&
        self.mIsRecording){
        [self playOrPause:nil];
    }
    self.mIsConnected = connect;
    [MBProgressHUD CI_showTitle:connect ? @"蓝牙已连接":@"蓝牙连接已断开" toView:self.view hideAfter:1.0];
}

/**
 触摸屏幕触发的事件
 */
-(void)touch{
    self.mHiddenMenu = !self.mHiddenMenu;
}

/**
 添加模拟界面
 */
-(void)addMonitorView{
    NSArray* nibView = [[NSBundle bundleForClass:[self class]] loadNibNamed:@"MonitorView" owner:nil options:nil];
    MonitorView* monitor = [nibView lastObject];
    monitor.mOption = self.mOption;
    [self.view addSubview:monitor];
}
#pragma mark -- IB Action

/**
 蓝牙开关切换事件

 @param sender
 */
- (IBAction)blueToothSwitchAction:(id)sender {
    if (self.mIsRecording && self.mState == EPlayStatePlaying){
        return ;
    }
    if (self.mState == EPlayStatePlaying){
        [self playOrPause:nil];
    }
    NSString* blemodulename = [[[UtilService alloc]init]blueModuleName];
    UIViewController * vc = [[CIRouter shared]matchController:blemodulename];
    [self.navigationController pushViewController:vc animated:YES];
    
}


/**
 播放模式按钮点击事件

 @param sender button
 */
- (IBAction)accompanyModeChange:(id)sender {
    if (self.mState != EPlayState_Pause && self.mState != EPlayStatePlaying){
        self.mIsAccompany = !self.mIsAccompany;
        if (self.mIsAccompany){
            [MBProgressHUD CI_showTitle:@"打开伴奏" toView:self.view hideAfter:1.0];
        }else{
            [MBProgressHUD CI_showTitle:@"关闭伴奏" toView:self.view hideAfter:1.0];
        }
    }else{
        [MBProgressHUD CI_showTitle:@"播放过程中不可切换伴奏" toView:self.view hideAfter:1.0];
    }
}


/**
 返回按钮点击事件

 @param sender button
 */
- (IBAction)back:(id)sender {
    self.mPopAction = YES;
    if ((self.mState == EPlayStatePlaying || self.mState == EPlayState_Pause )&&
        self.mIsRecording){
        // 演奏模式且已经播放
        if (self.mState == EPlayStatePlaying){
            [self pauseOrResume:NO];
        }
        UIAlertController* alertVC = [UIAlertController alertControllerWithTitle:nil message:@"是否放弃本次演奏" preferredStyle:UIAlertControllerStyleAlert];
        [alertVC addAction: [UIAlertAction actionWithTitle:@"放弃" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.mPlayer stop];
            [self.navigationController popViewControllerAnimated:YES];
        }]];
        [alertVC addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            //            [self pauseOrResume:NO];
        }]];
        [self presentViewController:alertVC animated:YES completion:nil];
    }else {
        [self.mPlayer stop];
        [self.navigationController popViewControllerAnimated:YES];
    }
}


/**
 暂停或者继续

 @param sender rt
 */
- (IBAction)playOrPause:(id)sender {
    if (self.mState == EPlayStateNone ||
        self.mState == EPlayState_Stop ) {
        if (self.mIsRecording){
            [self checkPlay];
        }else{
            [self play];
        }
    }else if (self.mState == EPlayStatePlaying ||
              self.mState == EPlayState_Pause){
        [self pauseOrResume:YES];
    }
}

/**
 开始录制
 */
-(void)startSheet{
    [self.mSheet beginRecording];
}

- (IBAction)showResultView:(id)sender {
    [self.mSheet showDetailResult];
}

- (IBAction)resetAction:(id)sender {
    if ((self.mState == EPlayStatePlaying ||self.mState == EPlayState_Pause)&&
        self.mIsRecording){
        // 演奏模式且已经播放
        if (self.mState == EPlayStatePlaying ){
            [self pauseOrResume:NO];
        }
        UIAlertController* alertVC = [UIAlertController alertControllerWithTitle:nil message:@"是否放弃本次演奏" preferredStyle:UIAlertControllerStyleAlert];
        [alertVC addAction: [UIAlertAction actionWithTitle:@"放弃" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self resetSheet];
        }]];
        [alertVC addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            //            [self pauseOrResume:NO];
        }]];
        [self presentViewController:alertVC animated:YES completion:nil];
    }else {
        [self resetSheet];
    }
}


- (IBAction)setting:(id)sender {
    self.mSettingView.hidden = !self.mSettingView.isHidden;
}


#pragma mark ShowResultDelegate

-(BOOL)playerIsRecording{
    return self.mIsRecording;
}

-(CIMidiPlayerMode)getMidiPlayMode{
    return self.mModeSelectView.mMidiMode;
}
-(void)playerDidFinishWithResult:(MidiResult *)result{
    self.mResultBtn.hidden = NO;
    [Log saveLogFile:[self.mOption.mFilePath lastPathComponent]];
    if (!self.mIsRecording ) {
        return;
    }
}
-(void)playerDidPlayAt:(int)ms total:(int)totalms{
    if(ms/(double)totalms <= 1 && ms/(double)totalms > 0 ){
        self.mProgressView.progress = ms/(double)totalms;
    }else{
        self.mProgressView.progress = 0;
    }
}

-(void)stop {
    if (self.mState != EPlayState_Stop){
        self.mState = EPlayState_Stop;
    }
}

-(NSInteger)getTempo {
    return [self.mSettingView getTempo];
}

#pragma mark -- public Method

-(BOOL)getPlaying{
    return self.mSheet.mScoreSheetViewModel.isPlaying;
}
-(void)resetSheet{
    [self.mPlayer stop];
    [self stop];
    [self.mSheet reset];
    self.mProgressView.progress = 0;
    if (!self.mIsRecording) {
        self.mIsAccompany = NO;
    }
}
-(EPlayState)playerState{
    return self.mState;
}

#pragma mark -- Private Method

/**
 播放前检查蓝牙是否链接
 */
-(void)checkPlay {
    if (self.mIsConnected) {
        [self play];
    }else{
        __weak typeof(self) weakSelf = self;
        UIAlertController* alertVC = [UIAlertController alertControllerWithTitle:nil message:@"Midi蓝牙设备未连接，前往连接蓝牙设备" preferredStyle:UIAlertControllerStyleAlert];
        [alertVC addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [alertVC addAction:[UIAlertAction actionWithTitle:@"前往设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf blueToothSwitchAction:nil];
        }]];
        [self presentViewController:alertVC animated:YES completion:nil];
    }
}

/**
 播放midi
 */
-(void)play{
    self.mResultBtn.hidden = YES;
    [self touch];// 隐藏top bottom bar
    [self resetSheet];
    [self.mSheet clearResult];
    [self.mSheet prepareRecording];
    MidiInfo* retInfo = [self.mPlayer prepareToPlay:[self.mSettingView getTempo] mode:[self getMidiPlayMode]];
    [self.mSheet setPool:retInfo->mComparePool];
    
    // 清除log
    [Log clearTempLog];
    if (!self.mIsRecording) {
        [self.mPlayer play];
        [self startSheet];
    }else{
        double ticksPers = DivisionUnit* 1.0/[self.mPlayer getTempoMPQ] * 1000000;
        double secodePerdot = DivisionUnit/ticksPers;
        [self.mPrepareView setNumber:5];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __block int numDot = 4;
            self.mSheet.midiSecondOffset = numDot * secodePerdot;
            __weak typeof(self) weakSelf = self;
            [self.mPlayer play];
            NSTimer* timer = [NSTimer timerWithTimeInterval:secodePerdot repeats:YES block:^(NSTimer * _Nonnull timer) {
                if (numDot<1) {
                    [weakSelf.mPrepareView setNumber:0];
                    [timer invalidate];
                    [weakSelf startSheet];
                }else{
                    [weakSelf.mPrepareView setNumber:numDot];
                }
                numDot--;
            }];
            [[NSRunLoop mainRunLoop]addTimer:timer forMode:NSRunLoopCommonModes];
            [timer fire];
        });
    }
    self.mState =EPlayStatePlaying;
}

/**
 暂停或继续
 
 @param showResult 是否显示结果
 */
-(void)pauseOrResume:(BOOL)showResult {
    BOOL pause = [self.mPlayer pauseOrResume];
    if (pause){
        self.mState = EPlayState_Pause;
        if (showResult && self.mIsRecording){
            [self.mSheet showResults];
        }
        [self.mSheet stopRecording];
    }else {
        self.mState = EPlayStatePlaying;
        [self.mSheet resumeRecording];
    }
}

/**
 模拟发送界面设置
 */
-(void)setUpMonitorTouch{
    UITapGestureRecognizer* ges = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(addMonitorView)];
    ges.numberOfTapsRequired = 2;
    [self.mHudTopView addGestureRecognizer:ges];
}

//设置是否隐藏
- (BOOL)prefersStatusBarHidden {
    //    [super prefersStatusBarHidden];
    return YES;
}
- (BOOL)shouldAutorotate{
    return YES;
}
-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{    // 返回默认情况
    return UIInterfaceOrientationMaskLandscapeRight ;
}
//一开始的方向  很重要
-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationLandscapeRight;
}
#pragma mark -- getter setter


/**
 设置当前状态

 @param mState 新状态
 */
-(void)setMState:(EPlayState)mState{
    _mState = mState;
    [self.mSettingView setState:mState];
    if (mState == EPlayState_Pause ||
        mState == EPlayStateNone ||
        mState ==EPlayState_Stop ) {
        [self.mPlayOrPauseBtn setImage:[UIImage imageForResource:@"play" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]]  forState:UIControlStateNormal];
    }else if(mState == EPlayStatePlaying){
        [self.mPlayOrPauseBtn setImage:[UIImage imageForResource:@"pause" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]]  forState:UIControlStateNormal];
    }
}
-(void)setMIsConnected:(BOOL)mIsConnected{
    _mIsConnected = mIsConnected;
    if (mIsConnected) {
        [self.mBlueBtn setBorderColor:[UIColor colorWithRed:69/255.0 green:214/255.0 blue:158/255.0 alpha:1.0] width:1.0 radious:8];
        [self.mBlueBtn setImage:[UIImage imageForResource:@"blue_connect" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]]  forState:UIControlStateNormal];
    }else{
        [self.mBlueBtn setBorderColor:[UIColor lightGrayColor] width:1.0 radious:8];
        [self.mBlueBtn setImage:[UIImage imageForResource:@"blue_disconnect" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]]  forState:UIControlStateNormal];
    }
}

-(void)setMIsAccompany:(BOOL)mIsAccompany{
    _mIsAccompany = mIsAccompany;
    
    if (mIsAccompany) {
        [self.mAccompany setBorderColor:[UIColor colorWithRed:69/255.0 green:214/255.0 blue:158/255.0 alpha:1.0] width:1.0 radious:8];
        [self.mAccompany setImage:[UIImage imageForResource:@"accomp_open" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]]  forState:UIControlStateNormal];
        if (self.mIsRecording){
            self.mModeSelectView.mMidiMode = CIMidiPlayerMode_MainWithAccompany;
        }
    }else{
        [self.mAccompany setBorderColor:[UIColor lightGrayColor] width:1.0 radious:8];
        [self.mAccompany setImage:[UIImage imageForResource:@"accomp_close" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]]  forState:UIControlStateNormal];
        
        if (self.mIsRecording){
            self.mModeSelectView.mMidiMode = CIMidiPlayerMode_Accompany;
        }
    }
    [self.mAccompany setImage:[UIImage imageForResource:@"accomp_disable" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]]  forState:UIControlStateDisabled];
}

-(void)setMIsRecording:(BOOL)mIsRecording{
    _mIsRecording = mIsRecording;
    self.mAccompany.enabled = mIsRecording;
}

/**
 根据变量 设置界面是否伸缩 以及 播放

 @param mHiddenMenu mHiddenMenu
 */
-(void)setMHiddenMenu:(BOOL)mHiddenMenu{
    _mHiddenMenu = mHiddenMenu;
    if (!mHiddenMenu) {
        [self.view layoutIfNeeded];
        [UIView animateWithDuration:0.4 animations:^{
            self.mTopViewTop.constant = 0;
            self.mModeSelectTop.constant = 0;
            self.mBottomViewBottom.constant = 0;
            self.mSheet.y =  self.mTopViewHeight.constant;
            [self.view layoutIfNeeded];
        }];
    }else{
        [self.mModeSelectView closeItem];
        [self.view layoutIfNeeded];
        [UIView animateWithDuration:0.4 animations:^{
            self.mTopViewTop.constant = -(self.mTopViewHeight.constant);
            self.mModeSelectTop.constant = -(self.mTopViewHeight.constant);
            self.mBottomViewBottom.constant = -(self.mBottomViewHeight.constant);
            self.mSheet.y =  0;
            
            self.mSettingView.hidden = YES;
            self.mPrepareView.hidden = YES;
            
            [self.view layoutIfNeeded];
        }];
        
    }
}


@end

@implementation UIProgressView(customView)
- (CGSize)sizeThatFits:(CGSize)size {
    CGSize newSize = CGSizeMake(self.frame.size.width,  4);
    return newSize;
}
@end

