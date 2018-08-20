//
//  CINavigationController.m
//  musicXML_Example
//
//  Created by tanhui on 2017/10/10.
//  Copyright © 2017年 tanhuiya. All rights reserved.
//

#import "CINavigationController.h"

@interface CINavigationController ()
@property (nonatomic, assign) BOOL supportLandscape;

@end

@implementation CINavigationController
- (id)init
{
    if (self = [super init])
    {
        [self setup];
    }
    
    return self;
}

- (void)setup
{
    //其他设置
    self.supportLandscape = NO;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (UIInterfaceOrientationMask) navigationControllerSupportedInterfaceOrientations:(UINavigationController *) navigationController{
    if(self.supportLandscape){
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeRight;
    }else{
        return UIInterfaceOrientationMaskPortrait;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
