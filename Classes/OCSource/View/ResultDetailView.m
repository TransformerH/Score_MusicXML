//
//  ResultDetailView.m
//  FBSnapshotTestCase
//
//  Created by tanhui on 2017/9/21.
//

#import "ResultDetailView.h"
#import "ResultDetailM.h"
#import "DrawableNoteM.h"
#import "MeasureM.h"
#import "ScoreM.h"
#import "ScoreViewController.h"
#import "Constants.h"
#import "NoteM.h"
#import "PartM.h"
#import "UIView+Extension.h"
#import "UIImage+music.h"

@interface ResultDetailView ()
@property(nonatomic,copy)NSArray<ResultDetailM*>* mResult;
@property(nonatomic,copy)NSMutableArray* mCircleViews;
@property(nonatomic,strong)ScoreM* mScore;
@end

@implementation ResultDetailView

-(instancetype)initWithFrame:(CGRect)frame errorResults:(NSArray<ResultDetailM*>*)results score:(ScoreM*)score{
    if ([self initWithFrame:frame]) {
        self.mResult = results;
        self.mScore = score;
        self.backgroundColor = [UIColor clearColor];
        [self setUp];
    }
    return self;
}

-(void)setUp{
    CGFloat clefY = Part_Top_Margin;
    int pianoPartH = 0;
    for (PartM *part in self.mScore.mParts) {
        if (part.mProgram <= 8) {
            pianoPartH = clefY;
            break;
        }
        clefY = clefY + (PartMarin + PartHeight) * part.mStavesNum;
    }
    
    NSMutableArray* startTimeArr = @[].mutableCopy;
    self.mResult = [self.mResult sortedArrayUsingComparator:^NSComparisonResult(ResultDetailM* obj1, ResultDetailM* obj2) {
        if (obj1.mMeasureIndex != obj2.mMeasureIndex) {
            return obj1.mMeasureIndex > obj2.mMeasureIndex;
        }else if(obj1.mStaffIndex != obj2.mStaffIndex) {
            return obj1.mStaffIndex > obj2.mStaffIndex;
        }else {
            return obj1.mStartTime > obj2.mStartTime;
        }
    }];
    NSMutableArray* temp = nil;
    for (ResultDetailM* result in self.mResult) {
        BOOL isFind = false;

        for (ResultDetailM* exist in temp){
            if (result.mStaffIndex == exist.mStaffIndex &&
                result.mMeasureIndex == exist.mMeasureIndex &&
                ( abs(result.mStartTime - exist.mStartTime) <= CGFLOAT_MIN ||
                abs(result.mStartTime - (exist.mStartTime + exist.mDuration)) <= CGFLOAT_MIN)
                ) {
                isFind = true;
                break;
            }
        }
        if (isFind){
            [temp addObject:result];
        } else {
            temp = @[result].mutableCopy;
            [startTimeArr addObject:temp];
        }

    }

    for (NSMutableArray* arr in startTimeArr) {
        CGRect rect = [self getRectByStartTimeArr:arr  offset:pianoPartH];
        rect = [self getFixRect:rect];
        CircleView * a = [[CircleView alloc]initWithResultMs:arr.copy frame:rect];
        [self.mCircleViews addObject:a];
        [self addSubview:a];
    }
}

-(CGRect)getFixRect:(CGRect)rect {
    if (rect.size.width > 120) {
        rect.origin.y = rect.origin.y + rect.size.height * 0.5 - 60;
        rect.size.height = 60 + rect.size.height * 0.5;
    } else {
        rect.origin.x = rect.origin.x + rect.size.width * 0.5 - 60;
        rect.origin.y = rect.origin.y + rect.size.height * 0.5 - 60;
        rect.size.width = 60 + rect.size.width * 0.5;
        rect.size.height = 60 + rect.size.height * 0.5;
    }
    return rect;
}

-(CGRect)getRectByStartTimeArr:(NSArray*)results offset:(double)yoffset{

    ResultDetailM* first = results.firstObject;
    int tempStaff = 0;
    MeasureM* selectMeasure = nil;
    for (NSInteger partIndex = 0; partIndex < self.mScore.mParts.count; partIndex++){
        PartM* part = self.mScore.mParts[partIndex];
        if(part.mProgram > 8){continue;}
        for (int measureIndex = 0; measureIndex < part.mMeasures.count; measureIndex++) {
            MeasureM* measure = part.mMeasures[measureIndex];
            if (first.mMeasureIndex == measureIndex && first.mPartIndex == partIndex) {
                selectMeasure = measure;
                break;
            }
        }
        if(selectMeasure){
            break;
        }
        tempStaff += part.mStavesNum;
    }
    double topY = CGFLOAT_MAX,bottomY = 0,leftX = CGFLOAT_MAX,rightX = 0;
    for (ResultDetailM* model in results) {
        for (DrawableNoteM* note in selectMeasure.mMeasureDatas) {
            if([note isKindOfClass:[NoteGroupM class]]){
                NoteGroupM* noteGroup = (NoteGroupM*)note;
                if (abs (model.mStartTime - noteGroup.mStartTime) <= CGFLOAT_MIN) {
                    double tempTop =0,tempBottom = 0;
                    if (noteGroup.mStem == ENoteStem_UP) {
                        tempTop = noteGroup.mStemEndY - NoteHeight;
                        tempBottom = noteGroup.mStemStartY + NoteHeight;
                    } else if (noteGroup.mStem == ENoteStem_DOWN){
                        tempTop = noteGroup.mStemStartY - NoteHeight;
                        tempBottom = noteGroup.mStemEndY + NoteHeight;
                    } else {
                        tempTop = noteGroup.mStemStartY - NoteHeight;
                        tempBottom = noteGroup.mStemStartY + NoteHeight;
                    }
                    topY = topY > tempTop ? tempTop : topY;
                    bottomY = bottomY < tempBottom ? tempBottom: bottomY;
                    double tempX = noteGroup.mDefaultX ;
                    leftX = leftX > tempX ? tempX : leftX;
                    double tempY = noteGroup.mDefaultX + noteGroup.mAjustDuration;
                    rightX = rightX < tempY ? tempY : rightX;
                    
                }
            }
        }
    }

    double x = selectMeasure.mStartX + leftX + (Part_Left_Margin + MeasureAttributeWidth);
    double partOffset = (selectMeasure.mLine - 1) * (self.mScore.mPartLineHeight + PartLineMargin) + (first.mStaffIndex - 1)*(PartMarin + PartHeight);
    CGRect ret = CGRectMake(x, partOffset + topY + yoffset, rightX - leftX, bottomY - topY);
    return ret;
}

-(NSMutableArray *)mCircleViews{
    if (!_mCircleViews) {
        _mCircleViews = @[].mutableCopy;
    }
    return _mCircleViews;
}

-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    UIView* selectView = nil;
    for (CircleView* view in self.mCircleViews) {
        CGRect circleRect,rect = view.frame;
        if (rect.size.width > 120){
            CGFloat bottomHalf = rect.size.height - 60;
            circleRect = CGRectMake(rect.origin.x,rect.origin.y + rect.size.height - 2*bottomHalf - 1, rect.size.width, 2*bottomHalf - 1);
        }else{
            CGFloat rightHalf = rect.size.width - 60.0;
            CGFloat bottomHalf = rect.size.height - 60;
            circleRect = CGRectMake(rect.origin.x + rect.size.width - 2*rightHalf, rect.origin.y + rect.size.height - 2*bottomHalf, rightHalf * 2 - 1, 2*bottomHalf - 1);
        }
        if (CGRectContainsPoint(circleRect, point)) {
            selectView = view;
            break;
        }
    }
    if (selectView){
        return selectView;
    }
    return [super hitTest:point withEvent:event];
}

@end

@interface CircleView()<CAAnimationDelegate>
@property(nonatomic, strong)CAShapeLayer* animateLayer;
@property(nonatomic, assign)NSInteger errorNumber;
@property(nonatomic, assign)NSInteger lostNumber;
@property(nonatomic, assign)BOOL mHasOverview;
@property(nonatomic, strong)UIImageView* mHoverImage;
@end
@implementation CircleView

-(instancetype)initWithResultMs:(NSArray<ResultDetailM*>*)resultMs frame:(CGRect)frame{
    if ([super initWithFrame:frame]) {
        self.detailMArr = resultMs;
        for (ResultDetailM* detail in resultMs) {
            if (detail.mErrorType == EResultErrorType_Lost) {
                self.lostNumber++;
            } else if (detail.mErrorType == EResultErrorType_Error) {
                self.errorNumber++;
            }
        }
        self.backgroundColor = [UIColor clearColor];
        UILongPressGestureRecognizer* longGes = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(showMessage:)];
        [self addGestureRecognizer:longGes];
        
    }
    return self;
}

-(CGRect)getCircleRect {
    CGRect rect = self.bounds,circleRect ;
    if (rect.size.width > 120){
        //        CGFloat rightHalf = rect.size.width * 0.5;
        CGFloat bottomHalf = rect.size.height - 60;
        circleRect = CGRectMake(0, rect.size.height - 2*bottomHalf - 1, rect.size.width, 2*bottomHalf - 1);
    }else{
        CGFloat rightHalf = rect.size.width - 60.0;
        CGFloat bottomHalf = rect.size.height - 60;
        circleRect = CGRectMake(rect.size.width - 2*rightHalf, rect.size.height - 2*bottomHalf, rightHalf * 2 - 1, 2*bottomHalf - 1);
    }
    return circleRect;
}
-(void)drawRect:(CGRect)rect{
    CGRect circleRect = [self getCircleRect];
    
    UIBezierPath* bPath = [UIBezierPath bezierPathWithOvalInRect:circleRect];
    ResultDetailM* first = [self.detailMArr firstObject];
    [[UIColor colorWithRed:211/255.0 green:45/255.0 blue:139/255.0 alpha:1.0]set];
    [bPath setLineWidth:2.0];
    [bPath stroke];
    
    // 画虚线
    CAShapeLayer *dotteShapeLayer = [CAShapeLayer layer];
    CGMutablePathRef dotteShapePath =  CGPathCreateMutable();
    [dotteShapeLayer setStrokeColor:[[UIColor colorWithRed:211/255.0 green:45/255.0 blue:139/255.0 alpha:1.0] CGColor]];
    dotteShapeLayer.lineWidth = 1.0f ;
    NSArray *dotteShapeArr = [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:4],[NSNumber numberWithInt:4], nil];
    [dotteShapeLayer setLineDashPattern:dotteShapeArr];
    CGPathMoveToPoint(dotteShapePath, NULL,CGRectGetMidX(circleRect), CGRectGetMidY(circleRect));
    CGPathAddLineToPoint(dotteShapePath, NULL, 14 , 14);
    [dotteShapeLayer setPath:dotteShapePath];
    CGPathRelease(dotteShapePath);
    [self.layer addSublayer:dotteShapeLayer];
    
    // 画圆
    UIBezierPath* dotPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(11, 11, 6, 6)];
    [dotPath fill];
    UIBezierPath* circlePath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(6, 6, 16, 16)];
    [[UIColor redColor]set];
    [circlePath stroke];
    
}

-(CAShapeLayer *)animateLayer{
    if (!_animateLayer) {
        _animateLayer = [CAShapeLayer layer];
        _animateLayer.frame = CGRectMake(0, 0, 5, 5);
        _animateLayer.position = CGPointMake(14, 14);
        _animateLayer.cornerRadius = _animateLayer.frame.size.width * 0.5;
        _animateLayer.masksToBounds = YES;
        _animateLayer.backgroundColor = [UIColor colorWithRed:211/255.0 green:45/255.0 blue:139/255.0 alpha:0.5].CGColor;
        [self.layer addSublayer:_animateLayer];
    }
    return _animateLayer;
}
-(void)beginAnimate {
    if (self.animateLayer.animationKeys.count > 0) {
        return;
    }
    [self.animateLayer removeAnimationForKey:@"scaleAnimate"];
    CABasicAnimation* animateZoomIn = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animateZoomIn.duration = 1.0;
    animateZoomIn.repeatCount = 1;
    animateZoomIn.toValue = [NSNumber numberWithInt:6.0];
    animateZoomIn.removedOnCompletion = YES;
    animateZoomIn.delegate = self;
    [self.animateLayer addAnimation:animateZoomIn forKey:@"scaleAnimate"];
}
-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    if (flag) {
        [self.animateLayer removeAllAnimations];
    }
}
-(void)tapAction:(UITapGestureRecognizer*)ges {
    [ges.view removeFromSuperview];
    if (self.mHoverImage) {
        [self.mHoverImage removeFromSuperview];
        self.mHoverImage = nil;
    }
}
#define CellHeight 30
-(void)showMessage:(UIGestureRecognizer*)ges {
    if (self.mHoverImage) {
        return;
    }
    [self beginAnimate];

    NSInteger height = (self.lostNumber && self.errorNumber) ? CellHeight * 2 : CellHeight;
    UIImageView* resultImg = [[UIImageView alloc]initWithFrame:CGRectMake(self.frame.origin.x + 15, self.frame.origin.y + 5, 100, height + 5)];
    UIImage* image = [UIImage imageForResource:@"result_back" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
    UIImage* new = [image stretchableImageWithLeftCapWidth:image.size.width*0.8 topCapHeight:image.size.height*0.3];
    [resultImg setImage:new];
    [self addSubview:resultImg];
    resultImg.maxY = 10;
    resultImg.x = 0;
    if (self.lostNumber){
        UILabel* lostLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 0, resultImg.size.width - 10, CellHeight)];
        lostLabel.font = [UIFont boldSystemFontOfSize:12.0];
        [resultImg addSubview:lostLabel];
        lostLabel.text = [NSString stringWithFormat:@"漏音: %ld个",(long)self.lostNumber];
    }
    if (self.errorNumber){
        UILabel* errorLabel = [[UILabel alloc]init];
        errorLabel.font = [UIFont boldSystemFontOfSize:12.0];
        if (self.lostNumber) {
            errorLabel.frame = CGRectMake(10, CellHeight,resultImg.size.width- 10, CellHeight);
        }else {
            errorLabel.frame = CGRectMake(10, 0,resultImg.size.width- 10, CellHeight);
        }
        [resultImg addSubview:errorLabel];
        errorLabel.text = [NSString stringWithFormat:@"错音: %ld个",(long)self.errorNumber];
    }
    self.mHoverImage = resultImg;
    
    UITapGestureRecognizer* tapGes = [[UITapGestureRecognizer alloc]initWithTarget:self  action:@selector(tapAction:)];
    UIView* view = [[UIView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    [[UIApplication sharedApplication].keyWindow addSubview:view];
    [view addGestureRecognizer:tapGes];
}


- (ScoreViewController *)findViewController:(UIView *)sourceView{
    id target = sourceView;
    while (target) {
        target = ((UIResponder *)target).nextResponder;
        if ([target isKindOfClass:[ScoreViewController class]]) {
            break;
        }
    }
    return (ScoreViewController*)target;
}

@end

@implementation ErrorListViewController
-(void)viewDidLoad{
    [super viewDidLoad];
    self.tableView.tableFooterView = [UIView new];
    NSMutableArray* arr = @[].mutableCopy;
    if (self.lostNumber) {
        [arr addObject:@{@"title": @"漏音", @"value": @(self.lostNumber)}];
    }
    if (self.errorNumber) {
        [arr addObject:@{@"title": @"错音", @"value": @(self.errorNumber)}];
    }
    self.mDatas = arr.copy;
    [self.tableView reloadData];
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.mDatas.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString* cellStr = @"errorCellIdentifier";
//    ResultDetailM* detailM = self.detailMList[indexPath.row];
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellStr];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellStr];
        cell.textLabel.font = [UIFont systemFontOfSize:12];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    NSDictionary* dict = self.mDatas[indexPath.row];
    NSString* tip = [NSString stringWithFormat:@"%@: %@个",dict[@"title"],dict[@"value"]];
//    if (detailM.mErrorType == EResultErrorType_Lost) {
//        tip = [NSString stringWithFormat:@"%ld 漏键",detailM.mNoteNumber];
//    }else if (detailM.mErrorType == EResultErrorType_Error) {
//        tip = [NSString stringWithFormat:@"错键%ld 应为%ld",detailM.mErrorNumber,detailM.mNoteNumber];
//    }
    cell.textLabel.text = tip;
    return cell;
}
-(void)setDetailMList:(NSArray<ResultDetailM *> *)detailMList{
    _detailMList = detailMList;
    
//    [self.tableView reloadData];
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 35;
}
-(NSInteger)getHeight {
    if (self.lostNumber && self.errorNumber) {
        return 35 * 2;
    } else {
        return 35;
    }
}
@end
