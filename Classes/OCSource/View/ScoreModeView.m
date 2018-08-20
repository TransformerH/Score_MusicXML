//
//  ScoreModeView.m
//  CIRouter
//
//  Created by tanhui on 2017/10/19.
//

#import "ScoreModeView.h"
#import "UIImage+music.h"
#import <musicXML/musicXML.h>
#import "ScoreViewController.h"

#define MainItemTag 100
@interface ScoreModeView()<ScoreModeItemDelegate>
@property(nonatomic, strong)ScoreModeItem* mMainItem;
@property(nonatomic, strong)NSMutableArray* mItems;
@property(nonatomic, strong)NSArray* mItemData;
@property(nonatomic, strong)UIView* mPanel;
@property(nonatomic, assign)BOOL mIsOpen;
@property(nonatomic, assign)NSInteger mSelectIndex;
@end
@implementation ScoreModeView
#pragma mark -- LiftCycle
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if ([super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}


-(void)layoutSubviews{
    [super layoutSubviews];
    
    NSInteger hMargin = 6,rowHeight = 42,itemHeight = rowHeight * 0.8, vMargin = 5;
    self.mPanel.frame = CGRectMake(0, CGRectGetMaxY(self.frame), self.frame.size.width, itemHeight*2);
    for (int i = 0; i<self.mItems.count; i++) {
        ScoreModeItem* item = self.mItems[i];
        item.frame = CGRectMake(hMargin, vMargin + itemHeight*i, self.frame.size.width - 2*hMargin, itemHeight - 2*vMargin);
    }
    self.mMainItem.frame = CGRectMake(hMargin-1,rowHeight * 0.1 + vMargin - 1, self.frame.size.width - 2*hMargin + 2, itemHeight - 2*vMargin + 2);
    self.mMainItem.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.mMainItem.layer.borderWidth = 1.0;
    if (self.mIsOpen) {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, rowHeight+ itemHeight*2);
        [self resetMainBtnWithPlaceholder];
    }else{
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, rowHeight);
        [self setMainBtnWithData];
    }
}

#pragma mark -- Custom Action
/**
 根据mode变化刷新界面
 */
-(void)checkMode{
    if ([self.mScoreVC playerState] == EPlayStatePlaying) {
        [MBProgressHUD CI_showTitle:@"播放过程中不可切换模式" toView:self.superview hideAfter:1.0];
        return;
    }
    self.mIsOpen = !self.mIsOpen;
    [self setNeedsLayout];
}


/**
 合并选项
 */
-(void)closeItem{
    self.mIsOpen = NO;
    [self setNeedsLayout];
}
#pragma mark -- Private Method
/**
 初始化设置
 */
-(void)setup {
    self.backgroundColor = [UIColor clearColor];
    UITapGestureRecognizer* ges = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(checkMode)];
    [self addGestureRecognizer:ges];
    self.mMainItem = [[ScoreModeItem alloc]initMainWithTitle:@"请选择"];
    [self addSubview:self.mMainItem];
    self.clipsToBounds = YES;
    self.mSelectIndex = MainItemTag;
    NSArray* itemData = @[
                          @{@"title":@"欣赏模式",@"icon":@"mode_listen"},
                          @{@"title":@"演奏模式",@"icon":@"mode_play"}
                          ];
    self.mItemData = itemData;
}


-(void)resetMainBtnWithPlaceholder{
    [self.mMainItem setIcon:@""];
    [self.mMainItem setTitle:@"请选择"];
}
-(void)setMainBtnWithData{
    NSDictionary* data = nil;
    if (self.mMidiMode == CIMidiPlayerMode_Listen) {
        data = self.mItemData[0];
    } else {
        data = self.mItemData[1];
    }
    [self.mMainItem setTitle:data[@"title"]];
    [self.mMainItem setIcon:data[@"icon"]];
}


/**
 某个index选中

 @param index
 */
-(void)selectIndex:(NSInteger)index{
    self.mSelectIndex = index;
    NSString* tip = nil;
    if (index == 0 ){
        tip = @"已切换至欣赏模式";
        self.mMidiMode = CIMidiPlayerMode_Listen;
    }else if(index == 1){
        tip = @"已切换至演奏模式";
        self.mMidiMode = CIMidiPlayerMode_Accompany;
        [self.mScoreVC resetSheet];
    }
    [MBProgressHUD CI_showTitle:tip toView:self.superview hideAfter:1.0];
}
#pragma mark -- ScoreModeItemDelegate

/**
 item 被点击

 @param index
 */
-(void)scoreModelItemDidSelectIndex:(NSInteger)index{
    [self checkMode];
    if (index == self.mSelectIndex) {
        return;
    }
    if (self.mScoreVC.mIsRecording&&
        ([self.mScoreVC playerState]== EPlayStatePlaying ||[self.mScoreVC playerState]== EPlayState_Pause) &&
        index == 0){
        UIAlertController* alertVC = [UIAlertController alertControllerWithTitle:nil message:@"是否放弃本次演奏" preferredStyle:UIAlertControllerStyleAlert];
        [alertVC addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [alertVC addAction:[UIAlertAction actionWithTitle:@"放弃" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self selectIndex:index];
            [self.mScoreVC resetSheet];
        }]];
        [self.mScoreVC presentViewController:alertVC animated:YES completion:nil];
    }else{
        [self selectIndex:index];
    }
}


#pragma mark -- Getter Setter

-(void)setMIsOpen:(BOOL)mIsOpen{
    _mIsOpen = mIsOpen;
    self.backgroundColor = mIsOpen? [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2]: [UIColor clearColor];
}

-(void)setMMidiMode:(CIMidiPlayerMode)mMidiMode{
    _mMidiMode = mMidiMode;
    if (self.mMidiMode != CIMidiPlayerMode_Listen) {
        self.mScoreVC.mIsRecording = YES;
    }else{
        self.mScoreVC.mIsRecording = NO;
    }
    
}

-(UIView*)mPanel{
    if (!_mPanel) {
        _mPanel = [[UIView alloc]init];
        _mPanel.backgroundColor = self.backgroundColor;
        [self addSubview:_mPanel];
        self.mItems = @[].mutableCopy;
        for (NSInteger index = 0;index < self.mItemData.count;index++) {
            NSDictionary* item = self.mItemData[index];
            ScoreModeItem* scoreItem = [[ScoreModeItem alloc]initWithTitle:item[@"title"] icon:item[@"icon"] index:index arrowDown:NO];
            scoreItem.delegate = self;
            [self.mItems addObject:scoreItem];
            [_mPanel addSubview:scoreItem];
        }
    }
    return _mPanel;
}
@end



@interface ScoreModeItem()
@property(nonatomic, copy)NSString* mTitle;
@property(nonatomic, copy)NSString* mIcon;
@property(nonatomic, strong)UIImageView* mIconView;
@property(nonatomic, strong)UIImageView* mAccessor;
@property(nonatomic, strong)UIView* mLine;
@property(nonatomic, strong)UILabel* mTitleLabel;
@property(nonatomic, assign)NSInteger mIndex;
@property(nonatomic, assign)BOOL mIsDown;
@end
@implementation ScoreModeItem
#pragma mark -- LiftCycle
-(instancetype)initWithTitle:(NSString*)title icon:(NSString*)icon index:(NSInteger)index arrowDown:(BOOL)isdown{
    if ([super init]) {
        _mTitle = title;
        _mIcon = icon;
        _mIsDown = isdown;
        _mIndex = index;
        [self itemSetup];
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];

    }
    return self;
}

-(instancetype)initMainWithTitle:(NSString*)title {
    if ([super init]) {
        _mTitle = title;
        _mIcon = nil;
        _mIsDown = YES;
        _mIndex = MainItemTag;
        [self itemSetup];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    CGFloat iconW = 12;
    self.mIconView.frame = CGRectMake(5, 0, iconW, self.frame.size.height);
    self.mTitleLabel.frame = CGRectMake(CGRectGetMaxX(self.mIconView.frame)+4, 0, self.frame.size.width - iconW * 2, self.frame.size.height);
    self.mAccessor.frame = CGRectMake(self.frame.size.width - iconW, 0, iconW * 0.6, self.frame.size.height);
    self.mLine.frame = CGRectMake(self.mAccessor.frame.origin.x - 6, 2, 1, self.frame.size.height-4);
    
}
#pragma mark -- Private Method
-(void)itemSetup {
    self.userInteractionEnabled = YES;
    self.layer.cornerRadius = 8;
    self.layer.masksToBounds = YES;
    if (self.mIndex < MainItemTag) {
        UITapGestureRecognizer* ges = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(itemSelect)];
        [self addGestureRecognizer:ges];
    }
}
#pragma mark -- Custom Action

-(void)itemSelect{
    if (self.delegate && [self.delegate respondsToSelector:@selector(scoreModelItemDidSelectIndex:)]) {
        [self.delegate scoreModelItemDidSelectIndex:self.mIndex];
    }
}


#pragma mark -- Getter Setter

-(UIImageView *)mIconView{
    if (!_mIconView) {
        _mIconView = [[UIImageView alloc]init];
        UIImage* image = [UIImage imageForResource:self.mIcon ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
        _mIconView.image = image;
        _mIconView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_mIconView];
    }
    return _mIconView;
}
-(UILabel *)mTitleLabel{
    if (!_mTitleLabel) {
        _mTitleLabel = [[UILabel alloc]init];
        _mTitleLabel.text = _mTitle;
        _mTitleLabel.textColor = [UIColor whiteColor];
        _mTitleLabel.font = [UIFont systemFontOfSize:12];
        [self addSubview:_mTitleLabel];
    }
    return _mTitleLabel;
}
-(UIView *)mLine{
    if (!_mLine) {
        _mLine = [[UIView alloc]init];
        _mLine.backgroundColor = [UIColor lightGrayColor];
        [self addSubview:_mLine];
    }
    return _mLine;
}
-(UIImageView *)mAccessor{
    if (!_mAccessor) {
        NSString* icon = self.mIsDown? @"arrow_down":@"arrow_right";
        UIImage* image = [UIImage imageForResource:icon ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
        _mAccessor = [[UIImageView alloc]initWithImage:image];
        _mAccessor.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_mAccessor];
    }
    return _mAccessor;
}

-(void)setTitle:(NSString*)title{
    self.mTitleLabel.text = title;
}
-(void)setIcon:(NSString*)icon{
    self.mIconView.image = [UIImage imageForResource:icon ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
    self.mAccessor.image = [UIImage imageForResource:@"arrow_right" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
}
@end
