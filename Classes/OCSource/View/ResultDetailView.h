//
//  ResultDetailView.h
//  FBSnapshotTestCase
//
//  Created by tanhui on 2017/9/21.
//

#import <UIKit/UIKit.h>
@class ResultDetailM;
@class ScoreM;
@interface ResultDetailView : UIView
-(instancetype)initWithFrame:(CGRect)frame errorResults:(NSArray<ResultDetailM*>*)results  score:(ScoreM*)score;
@end

@interface CircleView : UIView
-(instancetype)initWithResultMs:(NSArray<ResultDetailM*>*)resultM frame:(CGRect)frame;
@property(nonatomic,strong)NSArray<ResultDetailM*>* detailMArr;
@end


@interface ErrorListViewController: UITableViewController
@property(nonatomic, assign)NSInteger errorNumber;
@property(nonatomic, assign)NSInteger lostNumber;
@property(nonatomic,strong)NSArray<ResultDetailM*>* detailMList;
@property(nonatomic,strong)NSArray* mDatas;
-(NSInteger)getHeight;
@end
