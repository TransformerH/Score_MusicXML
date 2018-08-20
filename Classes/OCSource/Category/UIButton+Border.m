//
//  UIButton+Border.m
//  CIRouter
//
//  Created by tanhui on 2017/10/20.
//

#import "UIButton+Border.h"

@implementation UIButton (Border)
-(void)setBorderColor:(UIColor*)color width:(NSInteger)width radious:(CGFloat)radious{
    self.layer.borderColor = color.CGColor;
    self.layer.borderWidth = width;
    self.layer.cornerRadius = radious;
}
@end
