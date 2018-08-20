//
//  MBProgressHUD+Extension.h
//  Pods
//
//  Created by tanhui on 2017/8/22.
//
//

#import <MBProgressHUD/MBProgressHUD.h>

@interface MBProgressHUD (Extension)

extern NSString * const kCIMBProgressHUDMsgLoading;
extern NSString * const kCIMBProgressHUDMsgLoadError;
extern NSString * const kCIMBProgressHUDMsgLoadSuccessful;
extern NSString * const kCIMBProgressHUDMsgNoMoreData;
extern NSTimeInterval kCIMBProgressHUDHideTimeInterval;

typedef NS_ENUM(NSUInteger, CIMBProgressHUDMsgType) {
    CIMBProgressHUDMsgTypeSuccessful,
    CIMBProgressHUDMsgTypeError,
    CIMBProgressHUDMsgTypeWarning,
    CIMBProgressHUDMsgTypeInfo
};

/**
 *  @brief  添加一个带菊花的HUD
 *
 *  @param view  目标view
 *  @param title 标题
 *
 *  @return MBProgressHUD
 */
+ (MBProgressHUD *)CI_showHUDAddedTo:(UIView *)view title:(NSString *)title;
/** 添加一个带菊花的HUD */
+ (MBProgressHUD *)CI_showHUDAddedTo:(UIView *)view
                                title:(NSString *)title
                             animated:(BOOL)animated;

/**
 *  @brief  隐藏指定的HUD
 *
 *  @param afterSecond 多少秒后
 */
- (void)CI_hideAfter:(NSTimeInterval)afterSecond;
/** 隐藏指定的HUD */
- (void)CI_hideWithTitle:(NSString *)title
                hideAfter:(NSTimeInterval)afterSecond;
/** 隐藏指定的HUD */
- (void)CI_hideWithTitle:(NSString *)title
                hideAfter:(NSTimeInterval)afterSecond
                  msgType:(CIMBProgressHUDMsgType)msgType;

/**
 *  @brief  显示一个自定的HUD
 *
 *  @param title       标题
 *  @param view        目标view
 *  @param afterSecond 持续时间
 *
 *  @return MBProgressHUD
 */
+ (MBProgressHUD *)CI_showTitle:(NSString *)title
                          toView:(UIView *)view
                       hideAfter:(NSTimeInterval)afterSecond;
/** 显示一个自定的HUD */
+ (MBProgressHUD *)CI_showTitle:(NSString *)title
                          toView:(UIView *)view
                       hideAfter:(NSTimeInterval)afterSecond
                         msgType:(CIMBProgressHUDMsgType)msgType;

/**
 *  @brief  显示一个渐进式的HUD
 *
 *  @param view 目标view
 *
 *  @return MBProgressHUD
 */
+ (MBProgressHUD *)CI_showDeterminateHUDTo:(UIView *)view;

/** 配置本扩展的默认参数 */
+ (void)CI_setHideTimeInterval:(NSTimeInterval)second fontSize:(CGFloat)fontSize opacity:(CGFloat)opacity;
@end
