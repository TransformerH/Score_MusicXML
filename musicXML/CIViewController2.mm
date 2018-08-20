//
//  CIViewController.m
//  musicXML
//
//  Created by tanhuiya on 07/20/2017.
//  Copyright (c) 2017 tanhuiya. All rights reserved.
//

#import "CIViewController2.h"
#import <musicXML/musicXML.h>
#import "ResultView.h"

@interface CIViewController2 ()<BluethoothConnectDelegate,ShowResultDelegate>
@property (weak, nonatomic) IBOutlet UISegmentedControl *mMode;
@property (weak, nonatomic) IBOutlet UIButton *mConBtn;
@property (weak, nonatomic) IBOutlet UIStepper *mStepper;
@property (weak, nonatomic) IBOutlet UILabel *mTempoValue;
@property(nonatomic, strong) ScoreSheet* mSheet;
@property(nonatomic, strong) MidiPlayer* mPlayer;
@property(nonatomic, strong) Connector* mConnector;
@property(nonatomic, assign) NSInteger mIsConnected;

@property(nonatomic, strong) UILabel* mCountLabel;

@end

@implementation CIViewController2


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    NSString* path2 = [[NSBundle mainBundle]pathForResource:@"Resource/BeetAnGeSample" ofType:@"xml"];
    xml_midiFile* file2 = [[xml_midiFile alloc]initWithFile:path2];
    
    MidiPlayer* player = [[MidiPlayer alloc] initWithFile:path2];
    self.mPlayer = player;
    
    ScoreSheet* sheet = [[ScoreSheet alloc]initWithFrame:CGRectMake(0, 50, self.view.bounds.size.width, self.view.bounds.size.height) score:file2.mScore];
    sheet.mPlayer = player;
    sheet.resultDelegate = self;
    self.mSheet = sheet;
    
    [self.view addSubview:sheet];
    [self stepValueChanged:nil];
    
    [self play:nil];
}

- (IBAction)stepValueChanged:(id)sender {
    self.mTempoValue.text = [NSString stringWithFormat:@"%d", (int)self.mStepper.value];
}


- (IBAction)play:(id)sender {
//    [self.mSheet clearResult];
//
//    __block int time = 4;
////    [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
////        if (--time<0) {
////            self.mCountLabel.hidden = YES;
////            [timer invalidate];
////
//            [Log clearTempLog];
//            [self.mPlayer prepareToPlay];
//            [self.mPlayer play];
//            if (self.mMode.selectedSegmentIndex == 1){
//                // recording should after invoking play method
//                [self.mConnector beginRecording];
//            }
//            [self.mSheet beginRecording];
////        }else{
////            self.mCountLabel.hidden = NO;
////            self.mCountLabel.text = [NSString stringWithFormat:@"%d",time];
////        }
////    }];
    
}

- (IBAction)stop:(id)sender {
    [self.mPlayer pause];
    if (self.mMode.selectedSegmentIndex == 1){
        [self.mConnector stopRecording];
    }
    [self.mSheet stopRecording];
}

- (IBAction)connect:(id)sender {
//    if (!_mIsConnected) {
//        ConnectorView * connctorView = [[ConnectorView alloc]initWithFrame:self.view.frame];
//        [self.view addSubview:connctorView];
//        Connector * connctor = [[Connector alloc]init];
//        connctorView.mConnector = connctor;
//        self.mConnector = connctor;
//        connctor.connectionDelegate = self;
//    } else {
//        [self.mConnector cancelConnection];
//        self.mIsConnected = 0;
//    }
}

-(void)connectSuccessPeripherals{
    self.mIsConnected = 1;
}

-(void)connectDisConnectPeripherals:(NSError*)error{
    CILog(@"%@",error);
    self.mIsConnected = 0;
}

-(void)connectFailedPeripheralsWithError:(NSError*)error{
    if (error.localizedDescription && error.localizedDescription.length) {
//        [MBProgressHUD CI_showTitle:error.localizedDescription toView:self.view hideAfter:1.5];
    }
}

-(void)setMIsConnected:(NSInteger)mIsConnected{
    _mIsConnected = mIsConnected;
    [self.mConBtn setTitle:(mIsConnected ? @"disConnect":@"connect") forState:UIControlStateNormal];
//    [MBProgressHUD CI_showTitle:mIsConnected?@"已连接":@"连接已断开" toView:self.view hideAfter:1.5];
}


-(double)getMSPerQuarter{
    return [self.mPlayer getTempoMPQ];
}


-(void)playerDidFinishWithResult:(MidiResult *)result{
    ResultView* view = [ResultView customXiBView];
//    view.mLost.text = [NSString stringWithFormat:@"%lu", (long)result.lostNotes];
//    view.mrate.text = [NSString stringWithFormat:@"%lf", result.rate];
//    view.mError.text = [NSString stringWithFormat:@"%lu", (long)result.errorNotes];
//    view.mTimeout.text = [NSString stringWithFormat:@"%lu", result->mTimeOutNotes.size()];
//    view.mShort.text = [NSString stringWithFormat:@"%lu", result->mShortNotes.size()];
    [self.view addSubview:view];
    
    [Log saveLogFile];
    
}


-(UILabel *)mCountLabel{
    if (!_mCountLabel) {
        _mCountLabel = [[UILabel alloc]initWithFrame:CGRectMake(250,100,200,100)];
        _mCountLabel.backgroundColor = UIColor.clearColor;
        _mCountLabel.textColor = [UIColor redColor];
        _mCountLabel.hidden = YES;
        _mCountLabel.font = [UIFont boldSystemFontOfSize:50];
        [self.view addSubview:_mCountLabel];
    }
    return _mCountLabel;
}

@end
