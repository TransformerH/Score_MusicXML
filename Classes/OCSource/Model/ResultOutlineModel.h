//
//  ResultOutlineModel.h
//  CIRouter
//
//  Created by tanhui on 2017/10/25.
//

#import <Foundation/Foundation.h>
@class ResultDetailM;
@interface ResultOutlineModel : NSObject
@property(nonatomic, copy) NSString* mTitle;
@property(nonatomic, assign) NSInteger mTempo;
@property(nonatomic, assign) NSInteger mErrorNumber;
@property(nonatomic, assign) NSInteger mLostNumber;
@property(nonatomic, assign) NSInteger mTotalNumber;
@property(nonatomic, strong)NSArray<ResultDetailM*>* mErrorNotes;
@end
