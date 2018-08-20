//
//  ScorePartWiseM.h
//  iOSMusic
//
//  Created by tanhui on 2017/7/11.
//  Copyright © 2017年 tanhui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DrawableProtocol.h"

@class ScoreM;
@class MeasureM;

@interface PartM : NSObject<DrawableProtocol>
@property(nonatomic, strong, readonly) NSArray<MeasureM*>* mMeasures;
@property(nonatomic, strong, readonly) NSString* mName;
@property(nonatomic, assign)NSInteger mStavesNum;
@property(nonatomic, assign)NSInteger mProgram;
@property(nonatomic, weak) ScoreM* mScore;

-(instancetype)initWithName:(NSString*)name program:(NSInteger)program Measures:(NSArray*) measures staves:(NSInteger)staff;
@end
