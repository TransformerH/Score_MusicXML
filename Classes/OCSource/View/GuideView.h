//
//  GuideView.h
//  Alamofire
//
//  Created by tanhui on 2017/11/23.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    TipTypeAccompany,
    TipTypePlay,
    TipTypeTempo,
    TipTypeBlueTooth,
    TipTypeMode,
} TipType;

@interface GuideModel: NSObject
-(instancetype)initWithframe:(CGRect)rect icon:(NSString*)icon line:(NSString*)line tip:(NSString*)tip type:(TipType)type;
@property(nonatomic, copy) NSString* mIcon;
@property(nonatomic, copy) NSString* mLine;
@property(nonatomic, copy) NSString* mTip;
@property(nonatomic, assign) TipType mType;
@property(nonatomic, assign) CGRect mRect;
@end

@interface GuideView : UIView
-(instancetype)initWithGuideIcons:(NSArray<GuideModel*>*)icon;
@end
