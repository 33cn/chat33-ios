//
//  PWLoginCodeView.m
//  PWallet
//
//  Created by 于优 on 2018/12/26.
//  Copyright © 2018 ... All rights reserved.
//

#import "PWLoginCodeView.h"
#import "UITextField+Delete.h"
#import "WLUnitField.h"
#import "OYCountDownManager.h"

@interface PWLoginCodeView () <WLUnitFieldDelegate>

/** 验证码输入 */
@property (nonatomic, strong) WLUnitField *codeField;
/** 提示文字 */
@property (nonatomic, strong) UILabel *placeholderLab;
/** 验证码 */
@property (nonatomic, strong) UIButton *codeBtn;

@end

@implementation PWLoginCodeView

+ (instancetype)shopView {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self crtateView];
        
        /// 倒计时监听
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(countDown) name:OYCountDownNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OYCountDownNotification object:nil];
}

- (void)crtateView {
    
    [self addSubview: self.codeField];
    [self addSubview: self.placeholderLab];
    [self addSubview: self.codeBtn];
    
    [self.placeholderLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self);
        make.bottom.mas_equalTo(self);
        make.width.mas_equalTo(160);
        make.left.equalTo(self).offset(100);
    }];

    [self.codeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(self);
        make.size.mas_equalTo(CGSizeMake(100, 40));
        make.right.equalTo(self).offset(-27);
    }];
    
    [self.codeField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.codeField addTarget:self action:@selector(textFieldDidBeginEditing:) forControlEvents:UIControlEventEditingDidBegin];
    [self.codeField addTarget:self action:@selector(textFieldDidEndEditing:) forControlEvents:UIControlEventEditingDidEnd];
    
    [self.codeBtn addTarget:self action:@selector(sendCode:) forControlEvents: UIControlEventTouchUpInside];
}

#pragma mark - Action

- (void)countDown {
    
    NSInteger p = [kCountDownManager timeIntervalWithIdentifier:@"login_sendCode"];
    
    if (p >= 60) {
        self.codeBtnEnabled = YES;
        [self.codeBtn setTitle:@"获取验证码" forState:UIControlStateNormal];
        [self.codeBtn setTitleColor:CMColorFromRGB(0xFFFFFF) forState:UIControlStateNormal];
        self.codeBtn.layer.borderColor = CMColorFromRGB(0xFFFFFF).CGColor;
        [kCountDownManager removeSourceWithIdentifier:@"login_sendCode"];
        
    }
    else if (p > 0) {
//        self.codeBtn.userInteractionEnabled = NO;
        [self.codeBtn setTitle:[NSString stringWithFormat:@"已发送(%lds)", (long)60 - p] forState:UIControlStateNormal];
        [self.codeBtn setTitleColor:CMColorFromRGB(0xFFFFFF) forState:UIControlStateNormal];
        self.codeBtn.layer.borderColor = CMColorFromRGB(0xFFFFFF).CGColor;
    }
}

#pragma mark - Delegate

- (void)textFieldDidChange:(WLUnitField *)textField {
    NSLog(@"%s, %@", __FUNCTION__, textField.text);
    if (self.didEditEndHandle) {
        self.didEditEndHandle(self.codeField.text);
    }
}

- (void)textFieldDidBeginEditing:(WLUnitField *)textField {
    self.placeholderLab.hidden = YES;
}

- (void)textFieldDidEndEditing:(WLUnitField *)textField {
    if (self.codeField.text.length > 0) {
        self.placeholderLab.hidden = YES;
    } else {
        self.placeholderLab.hidden = NO;
    }
}

#pragma mark - Action

- (void)sendCode:(UIButton *)sender {
    
    if (self.didCodeBtnHandle) {
        self.didCodeBtnHandle(sender);
    }
}

- (void)setCodeBtnEnabled:(BOOL)codeBtnEnabled {
    _codeBtnEnabled = codeBtnEnabled;
    
    self.codeBtn.userInteractionEnabled = codeBtnEnabled;
}

- (void)removeContent {
    self.codeField.text = @"";
}

#pragma mark - setter & getter

- (void)setHasFirstResponder:(BOOL)hasFirstResponder {
    _hasFirstResponder = hasFirstResponder;
    if (hasFirstResponder) {
        [self.codeField becomeFirstResponder];
    } else {
        [self.codeField resignFirstResponder];
    }
}

- (NSString *)textContent {
    return self.codeField.text;
}


- (WLUnitField *)codeField {
    if (!_codeField) {
        _codeField = [[WLUnitField alloc] initWithStyle:WLUnitFieldStyleUnderline inputUnitCount:6];
//        CGFloat width = (kScreenWidth - (27 * 3) - 100 - 5 * 7) / 6;
        _codeField.frame = CGRectMake(27, 0, kScreenWidth - (27 * 3) - 100, 44);
        _codeField.delegate = self;
        _codeField.keyboardType = UIKeyboardTypeNumberPad;
        _codeField.unitSpace = 7;
        _codeField.textFont = [UIFont boldSystemFontOfSize:18];
        _codeField.textColor = [UIColor whiteColor];
        _codeField.tintColor = [UIColor whiteColor];
        _codeField.cursorColor = CMColorFromRGB(0xFFFFFF);
        _codeField.trackTintColor = [UIColor whiteColor];
        _codeField.autoResignFirstResponderWhenInputFinished = YES;
    }
    return _codeField;
}

- (UILabel *)placeholderLab {
    if (!_placeholderLab) {
        _placeholderLab = [UILabel new];
        _placeholderLab.textAlignment = NSTextAlignmentLeft;
        _placeholderLab.textColor = CMColorFromRGB(0xFFFFFF);
        _placeholderLab.font = [UIFont boldSystemFontOfSize:18];
        _placeholderLab.text = @"输入验证码";
    }
    return _placeholderLab;
}

- (UIButton *)codeBtn {
    if (!_codeBtn) {
        _codeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_codeBtn setTitle:@"获取验证码" forState:UIControlStateNormal];
        _codeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [_codeBtn setTitleColor:CMColorFromRGB(0xFFFFFF) forState:UIControlStateNormal];
        _codeBtn.layer.borderColor = CMColorFromRGB(0xFFFFFF).CGColor;
        _codeBtn.layer.borderWidth = 1;
        _codeBtn.layer.cornerRadius = 20;
        _codeBtn.clipsToBounds = YES;
    }
    return _codeBtn;
}

@end
