//
//  UIImage+music.h
//  Pods
//
//  Created by tanhui on 2017/7/21.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (music)
+(UIImage*)imageForResource:(NSString*)path ofType:(NSString*)type inBundle:(NSBundle*)bundle;
@end
