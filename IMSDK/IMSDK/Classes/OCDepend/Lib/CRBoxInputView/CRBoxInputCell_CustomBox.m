//
//  CRBoxInputCell_CustomBox.m
//  CRBoxInputView_Example
//
//  Created by Chobits on 2019/1/7.
//  Copyright © 2019 BearRan. All rights reserved.
//

#import "CRBoxInputCell_CustomBox.h"
#import "Masonry.h"

@implementation CRBoxInputCell_CustomBox

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.layer.shadowColor = [UIColor colorWithRed:215.0 / 255 green:231.0 / 255 blue:239.0 / 255 alpha:1].CGColor;
        self.layer.shadowOpacity = 0.7;
        self.layer.shadowOffset = CGSizeMake(-2, -2);
        self.layer.shadowRadius = 5;
    }
    
    return self;
}

- (UIView *)createCustomSecurityView
{
    UIView *customSecurityView = [UIView new];
    
    UIView *cView = [UIView new];
    cView.backgroundColor = [UIColor blackColor];
    cView.layer.cornerRadius = 5;
    cView.layer.masksToBounds = true;
    [customSecurityView addSubview:cView];
    [cView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(customSecurityView);
        make.width.height.mas_equalTo(10);
    }];
    
    return customSecurityView;
}

@end
