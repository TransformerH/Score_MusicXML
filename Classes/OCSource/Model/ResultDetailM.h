//
//  ResultDetailM.h
//  FBSnapshotTestCase
//
//  Created by tanhui on 2017/9/21.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    EResultErrorType_Error,
    EResultErrorType_Lost,
} EResultErrorType;

@interface ResultDetailM : NSObject

@property(nonatomic,assign)NSInteger mStaffIndex;
@property(nonatomic,assign)NSInteger mMeasureIndex;
@property(nonatomic,assign)NSInteger mPartIndex;
@property(nonatomic,assign)NSInteger mErrorNumber;
@property(nonatomic,assign)NSInteger mNoteNumber;
@property(nonatomic,assign)double mDuration;
@property(nonatomic,assign)EResultErrorType mErrorType;
@property(nonatomic,assign)double  mStartTime;

@end
