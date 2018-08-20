//
//  MBProgressHUD+Extension.m
//  Pods
//
//  Created by tanhui on 2017/8/22.
//
//

#import "MBProgressHUD+Extension.h"

NSString * const kCIMBProgressHUDMsgLoading = @"正在加载...";
NSString * const kCIMBProgressHUDMsgLoadError = @"加载失败";
NSString * const kCIMBProgressHUDMsgLoadSuccessful = @"加载成功";
NSString * const kCIMBProgressHUDMsgNoMoreData = @"没有更多数据了";
NSTimeInterval kCIMBProgressHUDHideTimeInterval = 1.2f;

static CGFloat FONT_SIZE = 13.0f;
static CGFloat OPACITY = 0.85;


@implementation MBProgressHUD (Extension)

+ (MBProgressHUD *)CI_showHUDAddedTo:(UIView *)view title:(NSString *)title animated:(BOOL)animated {
    MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:view animated:animated];
    HUD.label.font = [UIFont systemFontOfSize:FONT_SIZE];
    HUD.detailsLabel.text = title;
    HUD.opacity = OPACITY;
    return HUD;
}

+ (MBProgressHUD *)CI_showHUDAddedTo:(UIView *)view title:(NSString *)title {
    MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:view animated:YES];
    HUD.label.font = [UIFont systemFontOfSize:FONT_SIZE];
    HUD.detailsLabel.text = title;
    HUD.opacity = OPACITY;
    return HUD;
}

- (void)CI_hideWithTitle:(NSString *)title hideAfter:(NSTimeInterval)afterSecond {
    if (title) {
        self.detailsLabel.text = title;
        self.mode = MBProgressHUDModeText;
    }
    [self hideAnimated:YES afterDelay:afterSecond];
}

- (void)CI_hideAfter:(NSTimeInterval)afterSecond {
    [self hideAnimated:YES afterDelay:afterSecond];
}

- (void)CI_hideWithTitle:(NSString *)title
                hideAfter:(NSTimeInterval)afterSecond
                  msgType:(CIMBProgressHUDMsgType)msgType {
    self.detailsLabel.text = title;
    self.mode = MBProgressHUDModeCustomView;
    self.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[[self class ]p_imageNamedWithMsgType:msgType]]];
    [self hideAnimated:YES afterDelay:afterSecond];
}

+ (MBProgressHUD *)CI_showTitle:(NSString *)title toView:(UIView *)view hideAfter:(NSTimeInterval)afterSecond {
    MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:view animated:YES];
    HUD.mode = MBProgressHUDModeText;
    HUD.label.font = [UIFont systemFontOfSize:FONT_SIZE];
    HUD.detailsLabel.text = title;
    HUD.opacity = OPACITY;
    [HUD hideAnimated:YES afterDelay:afterSecond];
    return HUD;
}

+ (MBProgressHUD *)CI_showTitle:(NSString *)title
                          toView:(UIView *)view
                       hideAfter:(NSTimeInterval)afterSecond
                         msgType:(CIMBProgressHUDMsgType)msgType {
    
    MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:view animated:YES];
    HUD.label.font = [UIFont systemFontOfSize:FONT_SIZE];
    
    NSString *imageNamed = [self p_imageNamedWithMsgType:msgType];
    
    HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageNamed]];
    HUD.detailsLabel.text = title;
    HUD.opacity = OPACITY;
    HUD.mode = MBProgressHUDModeCustomView;
    [HUD hideAnimated:YES afterDelay:afterSecond];
    return HUD;
    
}

+ (NSString *)p_imageNamedWithMsgType:(CIMBProgressHUDMsgType)msgType {
    NSString *imageNamed = nil;
    if (msgType == CIMBProgressHUDMsgTypeSuccessful) {
        imageNamed = @"CI_hud_success";
    } else if (msgType == CIMBProgressHUDMsgTypeError) {
        imageNamed = @"CI_hud_error";
    } else if (msgType == CIMBProgressHUDMsgTypeWarning) {
        imageNamed = @"CI_hud_warning";
    } else if (msgType == CIMBProgressHUDMsgTypeInfo) {
        imageNamed = @"CI_hud_info";
    }
    return imageNamed;
}

+ (MBProgressHUD *)CI_showDeterminateHUDTo:(UIView *)view {
    MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:view animated:YES];
    HUD.mode = MBProgressHUDModeDeterminateHorizontalBar;
    HUD.animationType = MBProgressHUDAnimationZoom;
    HUD.detailsLabel.text = kCIMBProgressHUDMsgLoading;
    HUD.label.font = [UIFont systemFontOfSize:FONT_SIZE];
    return HUD;
}

+ (void)CI_setHideTimeInterval:(NSTimeInterval)second fontSize:(CGFloat)fontSize opacity:(CGFloat)opacity {
    kCIMBProgressHUDHideTimeInterval = second;
    FONT_SIZE = fontSize;
    OPACITY = opacity;
}
@end
