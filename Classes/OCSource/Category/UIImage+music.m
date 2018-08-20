//
//  UIImage+music.m
//  Pods
//
//  Created by tanhui on 2017/7/21.
//
//

#import "UIImage+music.h"

@implementation UIImage (music)

+(UIImage*)imageForResource:(NSString*)path ofType:(NSString*)type inBundle:(NSBundle*)bundle {
    NSInteger scale =  UIScreen.mainScreen.scale;
    if (scale == 1) {
        scale = 2;
    }
    NSString* pathWhole = [NSString stringWithFormat:@"musicXML.bundle/%@@%ix",path,scale];
    if(![bundle pathForResource:pathWhole ofType:type]){
        pathWhole = [NSString stringWithFormat:@"musicXML.bundle/%@",path];
    }
    return [UIImage imageWithContentsOfFile:[bundle pathForResource:pathWhole ofType:type]];
}


@end
