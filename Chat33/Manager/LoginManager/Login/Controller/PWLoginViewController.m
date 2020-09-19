//
//  PWLoginViewController.m
//  PWallet
//
//  Created by 于优 on 2018/12/26.
//  Copyright © 2018 陈健. All rights reserved.
//

#import "PWLoginViewController.h"
#import "PWLoginAccountView.h"
#import "PWLoginCodeView.h"

#import "OYCountDownManager.h"
#import "PWEscrowRequest.h"
#import "PWNetworkingTool.h"

#import <IMSDK-Swift.h>

#import <SafariServices/SafariServices.h>



@interface PWLoginViewController ()
/** login */
@property (nonatomic, strong) UIImageView *logoImg;
/** 账户视图 */
@property (nonatomic, strong) PWLoginAccountView *accountView;
/** 验证码视图 */
@property (nonatomic, strong) PWLoginCodeView *codeView;
/** 登录按钮 */
@property (nonatomic, strong) UIButton *loginBtn;
@property (nonatomic, strong) UIButton *mailBtn;
@property (nonatomic, strong) UIButton *checkBtn;
@property (nonatomic, strong) YYLabel *protocolLab;
/** 请求参数 */
@property (nonatomic, strong) NSMutableDictionary *param;

/**
 记录邮箱登录还是手机登录
 */
@property (nonatomic,assign) BOOL isEmailLogin;

@end

@implementation PWLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isEmailLogin = NO;
    [self createView];
}

- (void)createView {
    
    self.view.backgroundColor = CMColorFromRGB(0x5AB9ED);
    
    UIImageView *bgView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"login_bg"]];
    [self.view addSubview:bgView];
    bgView.userInteractionEnabled = true;
    [bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-90);
    }];
    
    [self.view addSubview: self.logoImg];
    [self.view addSubview: self.accountView];
    [self.view addSubview: self.checkBtn];
    [self.view addSubview: self.protocolLab];
    [self.view addSubview: self.codeView];
    [self.view addSubview: self.loginBtn];
    [self.view addSubview: self.mailBtn];
    
    [self.logoImg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view);
        make.top.mas_equalTo(self.view).offset(kTopOffset - 64 + 50);
        make.size.mas_equalTo(CGSizeMake(60, 60));
    }];
    [self.accountView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.view);
        make.top.equalTo(self.logoImg.mas_bottom).offset(40);
        make.height.mas_equalTo(44);
    }];
    [self.codeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.view);
        make.top.equalTo(self.accountView.mas_bottom).offset(15);
        make.height.mas_equalTo(44);
    }];
    [self.checkBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(27);
        make.top.equalTo(self.codeView.mas_bottom).offset(30);
        make.height.mas_equalTo(15);
        make.width.mas_equalTo(15);
    }];
    
    [self.protocolLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.checkBtn.mas_right).offset(10);
        make.centerY.equalTo(self.checkBtn);
    }];
    
    [self.loginBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(27);
        make.right.equalTo(self.view).offset(-27);
        make.top.equalTo(self.checkBtn.mas_bottom).offset(15);
        make.height.mas_equalTo(40);
    }];
    
    [self.mailBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(27);
        make.right.equalTo(self.view).offset(-27);
        make.top.equalTo(self.loginBtn.mas_bottom).offset(30);
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(20);
    }];
    
    WEAKSELF
    self.codeView.didCodeBtnHandle = ^(UIButton * _Nonnull codeBtn) {
        [weakSelf sendCode:codeBtn];
    };
    self.codeView.didEditEndHandle = ^(NSString * _Nonnull textContent) {
        if (textContent.length >= 6) {
            [weakSelf setLoginBtnState:YES];
        } else {
            [weakSelf setLoginBtnState:NO];
        }
    };
    [self.loginBtn addTarget:self action:@selector(loginBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.mailBtn addTarget:self action:@selector(mialBtnClick) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Action
// 获取验证码
- (void)sendCode:(UIButton *)codeBtn {
    
    if (self.isEmailLogin) {
        [self sendEmail];
        return;
    }
    
    if (self.accountView.textContent.length != 11) {
        [self showCustomMessage:@"请填写正确手机号！" hideAfterDelay:2];
        return;
    }
    
    self.codeView.codeBtnEnabled = NO;
    
    self.accountView.hasFirstResponder = NO;
    
    NSString *url = [IMSDK.shared.configure.serverIp stringByAppendingString:@"/chat/user/sendCode"];
     WEAKSELF
    [PWNetworkingTool postRequestWithUrl:url parameters:@{@"phone":self.accountView.textContent} successBlock:^(id object) {
        weakSelf.codeView.hasFirstResponder = YES;
        // 计时
        [kCountDownManager addSourceWithIdentifier:@"login_sendCode"];
        [kCountDownManager start];
        
    } failureBlock:^(NSError *error) {
        weakSelf.codeView.codeBtnEnabled = YES;
        [weakSelf showError:error hideAfterDelay:2];
    }];
}

// 判断登录&注册
- (void)loginBtnClick {
    [self.view endEditing:true];
    
    if (!self.checkBtn.isSelected) {
        [self showCustomMessage:@"请阅读并同意用户服务协议" hideAfterDelay:1];
        return;
    }
    
    if (self.isEmailLogin) {
        [self emailLogin];
        return;
    }
    
    [self showProgressWithMessage:nil];
    
    NSString *urlStr = [IMSDK.shared.configure.serverIp stringByAppendingString:@"/chat/user/phoneLogin"];
    NSDictionary *param = @{@"phone":self.accountView.textContent, @"code":self.codeView.textContent};
    
    [PWNetworkingTool postRequestWithUrl:urlStr parameters:param successBlock:^(id object) {
        
        if (self.loginSuccess) {
            [self hideProgress];
            self.loginSuccess(object);
        }
        
    } failureBlock:^(NSError *error) {
        [self showError:error hideAfterDelay:2];
    }];
}


-(void)sendEmail {
    self.codeView.codeBtnEnabled = NO;
    
    self.accountView.hasFirstResponder = NO;
    
    NSString *url = [IMSDK.shared.configure.serverIp stringByAppendingString:@"/chat/user/sendEmail"];
     WEAKSELF
    [PWNetworkingTool postRequestWithUrl:url parameters:@{@"email":self.accountView.textContent} successBlock:^(id object) {
        weakSelf.codeView.hasFirstResponder = YES;
        // 计时
        [kCountDownManager addSourceWithIdentifier:@"login_sendCode"];
        [kCountDownManager start];
        
    } failureBlock:^(NSError *error) {
        weakSelf.codeView.codeBtnEnabled = YES;
        [weakSelf showError:error hideAfterDelay:2];
    }];
}

-(void)emailLogin {
    [self showProgressWithMessage:nil];
    
    NSString *urlStr = [IMSDK.shared.configure.serverIp stringByAppendingString:@"/chat/user/emailLogin"];
    NSDictionary *param = @{@"email":self.accountView.textContent, @"code":self.codeView.textContent};
    
    [PWNetworkingTool postRequestWithUrl:urlStr parameters:param successBlock:^(id object) {
        
        if (self.loginSuccess) {
            [self hideProgress];
            self.loginSuccess(object);
        }
        
    } failureBlock:^(NSError *error) {
        [self showError:error hideAfterDelay:2];
    }];
}



- (void)mialBtnClick {
    self.isEmailLogin = !self.isEmailLogin;
    if (self.isEmailLogin) {
        [self.mailBtn setTitle:@"手机登录/注册" forState:UIControlStateNormal];
        self.accountView.isEmailStyle = YES;
    } else {
        [self.mailBtn setTitle:@"邮箱登录/注册" forState:UIControlStateNormal];
        self.accountView.isEmailStyle = NO;
    }
}

///托管系统的登录 i弃用

//// 获取验证码
//- (void)sendCode:(UIButton *)codeBtn {
//
//    if (self.accountView.textContent.length != 11) {
//        [self showCustomMessage:@"请填写正确手机号！" hideAfterDelay:2];
//        return;
//    }
//
//    self.codeView.codeBtnEnabled = NO;
//
//    self.accountView.hasFirstResponder = NO;
//
//    [self.param setObject:self.accountView.textContent forKey:@"mobile"];
//
//    WEAKSELF
//    [PWEscrowRequest sendCode:self.param success:^(id object) {
//        weakSelf.codeView.hasFirstResponder = YES;
//        // 计时
//        [kCountDownManager addSourceWithIdentifier:@"login_sendCode"];
//        [kCountDownManager start];
//
//    } showWebCode:^(PWWebCodeModel * result) {
//        weakSelf.codeView.hasFirstResponder = YES;
//        weakSelf.codeView.codeBtnEnabled = YES;
//        if (result != nil) {
//            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:self.param];
//            [dic setObject:result.businessId forKey:@"businessId"];
//            [dic setObject:result.ticket forKey:@"ticket"];
//
//            [PWEscrowRequest sendCode:dic success:^(id object) {
//                weakSelf.codeView.hasFirstResponder = YES;
//                [kCountDownManager addSourceWithIdentifier:@"login_sendCode"];
//                [kCountDownManager start];
//            } showWebCode:nil failure:^(NSError *error) {
//                weakSelf.codeView.codeBtnEnabled = YES;
//                [weakSelf showError:error hideAfterDelay:2];
//            }];
//        }
//
//    } failure:^(NSError *error) {
//        weakSelf.codeView.codeBtnEnabled = YES;
//        [weakSelf showError:error hideAfterDelay:2];
//    }];
//}

// 判断登录&注册
//- (void)loginBtnClick {
//    [self.view endEditing:true];
//
//    if (!self.checkBtn.isSelected) {
//        [self showCustomMessage:@"请阅读并同意用户服务协议" hideAfterDelay:1];
//        return;
//    }
//
//    [self showProgressWithMessage:nil];
//    NSString *urlStr = [HOSTURL_ESCROW stringByAppendingString:LOGIN_ISREG];
//    NSDictionary *param = @{@"area":@"86", @"reg_type":@"mobile", @"mobile":self.accountView.textContent };
//    [PWNetworkingTool postRequestWithUrl:urlStr parameters:param successBlock:^(id object) {
//
//        NSInteger isreg = [object[@"isreg"] integerValue];
//        if (isreg == 0) { // 未注册
//            [self registeredClick];
//        }
//        else if (isreg == 1) { // 已注册
//            [self loginClick];
//        }
//
//    } failureBlock:^(NSError *error) {
//        [self showError:error hideAfterDelay:2];
//    }];
//}

// 登录
//- (void)loginClick {
//    [self showProgressWithMessage:nil];
//    NSString *urlStr = [HOSTURL_ESCROW stringByAppendingString:LOGIN_LOGIN];
//    NSDictionary *param = @{@"area":@"86", @"reg_type":@"mobile", @"type":@"sms",  @"mobile":self.accountView.textContent, @"code":self.codeView.textContent};
//
//    [PWNetworkingTool postRequestWithUrl:urlStr parameters:param successBlock:^(id object) {
//
//        if (self.loginSuccess) {
//            [self hideProgress];
//            self.loginSuccess(object);
//        }
//
//    } failureBlock:^(NSError *error) {
//        [self showError:error hideAfterDelay:2];
//    }];
//}
//
//// 注册
//- (void)registeredClick {
//    [self showProgressWithMessage:nil];
//    NSString *urlStr = [HOSTURL_ESCROW stringByAppendingString:LOGIN_REG];
//    NSDictionary *param = @{@"area":@"86", @"reg_type":@"mobile", @"type":@"sms",  @"mobile":self.accountView.textContent, @"code":self.codeView.textContent};
//
//    [PWNetworkingTool postRequestWithUrl:urlStr parameters:param successBlock:^(id object) {
//
//        [self loginClick];
//
//    } failureBlock:^(NSError *error) {
//        [self showError:error hideAfterDelay:2];
//    }];
//}


// 改变登录按钮状态
- (void)setLoginBtnState:(BOOL)state {
    
    self.loginBtn.enabled = state;
    CGFloat alpha = state?1:0.5;
    [UIView animateWithDuration:0.3 animations:^{
        self.loginBtn.alpha = alpha;
    }];
}

#pragma mark - setter & getter

- (UIImageView *)logoImg {
    if (!_logoImg) {
        _logoImg = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"qrcode_center"]];
        _logoImg.layer.cornerRadius = 10;
        _logoImg.clipsToBounds = YES;
    }
    return _logoImg;
}

- (PWLoginAccountView *)accountView {
    if (!_accountView) {
        _accountView = [PWLoginAccountView shopView];
    }
    return _accountView;
}

- (PWLoginCodeView *)codeView {
    if (!_codeView) {
        _codeView = [PWLoginCodeView shopView];
    }
    return _codeView;
}

- (UIButton *)loginBtn {
    if (!_loginBtn) {
        _loginBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_loginBtn setTitle:@"登录/注册" forState:UIControlStateNormal];
        _loginBtn.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        _loginBtn.clipsToBounds = YES;
        _loginBtn.layer.cornerRadius = 20;
        _loginBtn.backgroundColor = CMColorFromRGB(0xFFFFFF);
        [_loginBtn setTitleColor:CMColorFromRGB(0x32B2F7) forState:UIControlStateNormal];
        [self setLoginBtnState:NO];
    }
    return _loginBtn;
}

- (UIButton *)mailBtn {
    if (!_mailBtn) {
        _mailBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_mailBtn setTitle:@"邮箱登录/注册" forState:UIControlStateNormal];
        _mailBtn.titleLabel.font = [UIFont systemFontOfSize:18];
        [_mailBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    return _mailBtn;
}

- (UIButton *)checkBtn {
    if (!_checkBtn) {
        _checkBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_checkBtn setImage:[UIImage imageNamed:@"check_nor"] forState:UIControlStateNormal];
        [_checkBtn setImage:[UIImage imageNamed:@"check_sel"] forState:UIControlStateSelected];
        [_checkBtn addTarget:self action:@selector(checkBtnPress) forControlEvents:UIControlEventTouchUpInside];
    }
    return _checkBtn;
}

- (void)checkBtnPress {
    [self.checkBtn setSelected:!self.checkBtn.isSelected];
}

- (YYLabel *)protocolLab {
    if (!_protocolLab) {
        _protocolLab = [[YYLabel alloc]init];
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"已阅读《Chat33用户服务协议》"attributes: @{NSFontAttributeName: [UIFont systemFontOfSize:14],NSForegroundColorAttributeName: [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0]}];
        [string yy_setTextHighlightRange:[[string string] rangeOfString:@"《Chat33用户服务协议》"] color:[UIColor colorWithRed:13/255.0 green:115/255.0 blue:173/255.0 alpha:1.0] backgroundColor:[UIColor clearColor] tapAction:^(UIView * _Nonnull containerView, NSAttributedString * _Nonnull text, NSRange range, CGRect rect) {
            NSString *urlStr = [IMSDK.shared.configure.shareUrl stringByReplacingOccurrencesOfString:@"share.html?" withString:@"agreement"];
            SFSafariViewController *vc = [[SFSafariViewController alloc]initWithURL:[NSURL URLWithString:urlStr]];
            [self presentViewController:vc animated:true completion:nil];
        }];
        _protocolLab.attributedText = string;
    }
    return _protocolLab;
}

- (NSMutableDictionary *)param {
    if (!_param) {
        _param = [NSMutableDictionary new];
        [_param setObject:@"quick" forKey:@"codetype"];
    }
    return _param;
}

@end
