//
//  RestM.h
//  iOSMusic
//
//  Created by tanhui on 2017/7/20.
//  Copyright © 2017年 tanhui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DrawableNoteM.h"
#import "NoteM.h"

@interface RestM : DrawableNoteM
@property(nonatomic, assign)ENoteType mType;
@property(nonatomic, assign)BOOL mHasMeasure;
@end
