//
//  PWLoginAccountView.m
//  PWallet
//
//  Created by 于优 on 2018/12/26.
//  Copyright © 2018 ... All rights reserved.
//

#import "PWLoginAccountView.h"

@interface PWLoginAccountView () <UITextFieldDelegate>

/** 区号 */
@property (nonatomic, strong) UIButton *areaBtn;
/** 输入框 */
@property (nonatomic, strong) UITextField *accountTF;
/** 选择账号按钮 */
@property (nonatomic, strong) UIButton *accountBtn;
/** 输入长度 */
@property (nonatomic, assign) NSInteger index;

@end

@implementation PWLoginAccountView

+ (instancetype)shopView {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.index = 0;
        [self crtateView];
    }
    return self;
}

- (void)crtateView {
    
    [self addSubview:self.areaBtn];
    [self addSubview:self.accountTF];
    [self addSubview:self.accountBtn];
    
    [self.areaBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self);
        make.bottom.mas_equalTo(self);
        make.left.equalTo(self).offset(27);
        make.width.mas_equalTo(70);
//        make.size.mas_equalTo(CGSizeMake(70, 44));
    }];
    
    [self.accountTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self);
        make.bottom.mas_equalTo(self);
        make.left.equalTo(self.areaBtn.mas_right).offset(10);
        make.right.equalTo(self).offset(-27);
    }];
    
    [self.accountBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self);
        make.bottom.mas_equalTo(self);
        make.right.equalTo(self).offset(-27);
        make.width.mas_equalTo(40);
    }];
    
    
    [self.accountTF addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}


- (void)layoutSubviews {
    [super layoutSubviews];
    [self setLayerBorder:self.areaBtn color:CMColorFromRGB(0xFFFFFF)];
    [self setLayerBorder:self.accountTF color:CMColorFromRGB(0xFFFFFF)];
}


#pragma mark - Delegate

- (void)textFieldDidChange:(UITextField *)textField {
    
    if (textField.text.length > self.index) {
        if(textField.text.length == 4 || textField.text.length == 9) {
            NSMutableString *str = [[NSMutableString alloc] initWithString:textField.text];
            [str insertString:@" " atIndex: textField.text.length - 1];
            textField.text = str;
        }
        if (textField.text.length >= 13) {
            textField.text= [textField.text substringToIndex:13];
        }
        self.index = textField.text.length;
        
    } else {
        if(textField.text.length == 4 || textField.text.length == 9) {
            textField.text = [NSString stringWithFormat:@"%@",textField.text];
            textField.text = [textField.text substringToIndex:(textField.text.length - 1)];
        }
        self.index = textField.text.length;
    }
}

#pragma mark - Action

- (void)setLayerBorder:(UIView *)view color:(UIColor *)color {

//    [view sizeToFit];
//    [view layoutIfNeeded];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        UIBezierPath * bezierPath = [UIBezierPath bezierPath];
        [bezierPath moveToPoint:CGPointMake(0.0f, view.frame.size.height)];
        [bezierPath addLineToPoint:CGPointMake(view.frame.size.width, view.frame.size.height)];
        CAShapeLayer * shapeLayer = [CAShapeLayer layer];
        shapeLayer.strokeColor = color.CGColor;
        shapeLayer.fillColor  = [UIColor clearColor].CGColor;
        shapeLayer.path = bezierPath.CGPath;
        shapeLayer.lineWidth = 1;
        
        [view.layer addSublayer:shapeLayer];
    });
}

#pragma mark - setter & getter

- (void)setHasFirstResponder:(BOOL)hasFirstResponder {
    _hasFirstResponder = hasFirstResponder;
    if (hasFirstResponder) {
        [self.accountTF becomeFirstResponder];
    } else {
        [self.accountTF resignFirstResponder];
    }
}

- (NSString *)textContent {
    
    return [self.accountTF.text stringByReplacingOccurrencesOfString:@" " withString:@""];
}

- (UIButton *)areaBtn {
    if (!_areaBtn) {
        _areaBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_areaBtn setTitle:@"+86" forState:UIControlStateNormal];
        _areaBtn.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        [_areaBtn setTitleColor:CMColorFromRGB(0xFFFFFF) forState:UIControlStateNormal];
    }
    return _areaBtn;
}

- (UITextField *)accountTF {
    if (!_accountTF) {
        _accountTF = [UITextField new];
        _accountTF.delegate = self;
        _accountTF.textAlignment = NSTextAlignmentCenter;
        _accountTF.font = [UIFont boldSystemFontOfSize:18];
        _accountTF.textColor = CMColorFromRGB(0xFFFFFF);
        NSAttributedString *placeholderString = [[NSAttributedString alloc] initWithString:@"请输入账号" attributes:@{NSForegroundColorAttributeName : CMColorFromRGB(0xFFFFFF), NSFontAttributeName: [UIFont boldSystemFontOfSize:18]}];
        _accountTF.attributedPlaceholder = placeholderString;
        _accountTF.borderStyle = UITextBorderStyleNone;
        _accountTF.keyboardType = UIKeyboardTypeNumberPad;
    }
    return _accountTF;
}

- (UIButton *)accountBtn {
    if (!_accountBtn) {
        _accountBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_accountBtn setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
    }
    return _accountBtn;
}

@end
