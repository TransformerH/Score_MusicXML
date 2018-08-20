//
//  PrepareView.m
//  BlueTooth
//
//  Created by tanhui on 2017/10/24.
//

#import "PrepareView.h"
#import "UIImage+music.h"

@interface PrepareView()
@property(nonatomic, strong) UILabel* mNumberLabel;
@property(nonatomic, strong) UIImageView* mIcon;
@end


@implementation PrepareView


-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if ([super initWithCoder:aDecoder]) {
        [self addSubview:self.mIcon];
        [self addSubview:self.mNumberLabel];
    }
    return self;
}

-(void)setNumber:(NSInteger)number{
    if (number <= 4) {
        if (number % 2){
            self.mIcon.image = [UIImage imageForResource:@"clap_left" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
        }else {
            self.mIcon.image = [UIImage imageForResource:@"clap_right" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
        }
        self.mNumberLabel.text = [NSString stringWithFormat:@"%ld",(long)number];
    }else{
        self.mIcon.image = [UIImage imageForResource:@"clap_left" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
        self.mNumberLabel.text = @"准备";
    }
    self.hidden = number < 1;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    self.mIcon.frame = CGRectMake(5, 5, 15, self.frame.size.height-10);
    self.mNumberLabel.frame = CGRectMake(21, 0, self.frame.size.width - 21, self.frame.size.height);
}

-(UIImageView *)mIcon{
    if (!_mIcon) {
        _mIcon = [[UIImageView alloc]init];
        _mIcon.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_mIcon];
    }
    return _mIcon;
}
-(UILabel *)mNumberLabel{
    if (!_mNumberLabel) {
        _mNumberLabel = [[UILabel alloc]init];
        _mNumberLabel.textAlignment = NSTextAlignmentCenter;
        _mNumberLabel.font = [UIFont systemFontOfSize:12];
        [self addSubview:_mNumberLabel];
    }
    return _mNumberLabel;
}

@end
