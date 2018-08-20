//
//  BleMidiParser.h
//  Pods
//
//  Created by tanhui on 2017/8/23.
//
//

#import <Foundation/Foundation.h>

@interface BleMidiParser : NSObject

-(void)parse:(char* )data length:(int)length atMS:(double)ms;

@end
