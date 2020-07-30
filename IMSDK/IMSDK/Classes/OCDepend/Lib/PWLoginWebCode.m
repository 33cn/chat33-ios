//
//  PWLoginWebCode.m
//  PWallet
//
//  Created by 于优 on 2018/10/23.
//  Copyright © 2018年 ... All rights reserved.
//

#import "PWLoginWebCode.h"

//#import <TCWebCodesSDK/TCWebCodesBridge.h>
//#import <TCWebCodesSDK.framework/TCWebCodesBridge.h>

#import "TCWebCodesBridge.h"

@interface PWLoginWebCode ()

@property (nonatomic, strong) UIView *webView;
@property (nonatomic, strong) UIControl *backgroundView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, assign) BOOL isShowing; // 正在显示

@end

@implementation PWLoginWebCode

- (instancetype)init {
    self = [super init];
    if (self) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        _activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    }
    return self;
}

- (UIControl *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[UIControl alloc] init];
        _backgroundView.backgroundColor = [UIColor blackColor];
        _backgroundView.alpha = .5f;
        _backgroundView.userInteractionEnabled = YES;
    }
    return _backgroundView;
}


- (void)showToView:(UIView *)view {
    [self show];
//    [view addSubview:self.backgroundView];
//    [view bringSubviewToFront:self.backgroundView];
//    //    [self addSubview:_backgroundView];
//    _isShowing = YES;
}

- (void)show {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [keyWindow addSubview:self.backgroundView];
    _isShowing = YES;
}

- (BOOL)showing {
    return _isShowing;
}

- (instancetype)initWithUrl:(NSString *)url Frame:(CGRect)frame {
    self = [super init];
    
    if (self) {
        _url = url;
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        _activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        
        _backgroundView = [[UIControl alloc] initWithFrame:frame];
//        _backgroundView.backgroundColor = [UIColor whiteColor];
        _backgroundView.backgroundColor = [UIColor colorWithRed:50/255.0 green:50/255.0 blue:50/255.0 alpha:0.5];
//        _backgroundView.alpha = .5f;
        _backgroundView.userInteractionEnabled = YES;
        
        
        [self drawView];
    }
    return self;
}


- (void)startLoading {
    _activityIndicator.center = _webView.center;
    [_backgroundView addSubview:_activityIndicator];
    [_backgroundView bringSubviewToFront: _activityIndicator];
    [_activityIndicator startAnimating];
}

- (void)stopLoading {
    [_activityIndicator stopAnimating];
    [_activityIndicator removeFromSuperview];
}

- (void)drawView {
    CGFloat w = self.backgroundView.frame.size.width * 0.7f;
    CGSize size = [[TCWebCodesBridge sharedBridge] getCapSizeByWidth:w];
    
    [[TCWebCodesBridge sharedBridge] setCapValue:@"\"popup\"" forKey:@"type"];
    [[TCWebCodesBridge sharedBridge] setCapValue:[NSString stringWithFormat:@"\"%f\"",w] forKey:@"fwidth"];
    [_webView removeFromSuperview];
    _webView = nil;
    
    CGFloat left = (self.backgroundView.bounds.size.width - size.width) * 0.5;
    CGFloat top = (self.backgroundView.bounds.size.height - size.height) * 0.5;
    CGRect frame = CGRectMake(left, top -20, size.width, size.height);
    
    _webView = [[TCWebCodesBridge sharedBridge] startLoad:_url webFrame:frame];
    //     CGRectMake((self.bounds.size.width - size.width) / 2, (self.bounds.size.height - size.height) / 2, size.width, size.height)
    _webView.userInteractionEnabled = YES;
    [_backgroundView addSubview:_webView];
    [self startLoading];
    __weak typeof (self)weakSelf = self;
    [[TCWebCodesBridge sharedBridge] setReadyCallback:^(NSDictionary *resultJSON, UIView *webView) {
        NSString *jsonStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:resultJSON options:0 error:NULL] encoding:NSUTF8StringEncoding];
        NSLog(@"加载完成json %@",jsonStr);
        if (2 == [resultJSON[@"state"] intValue]) {
            CGFloat width = [resultJSON[@"fwidth"] floatValue];
            CGFloat height = [resultJSON[@"fheight"] floatValue];
            weakSelf.webView.frame = CGRectMake((self.backgroundView.bounds.size.width - width) * .5f, (self.backgroundView.bounds.size.height - height) / 2 -20, width, height);
            [self stopLoading];
        } else {
            if (0 != [resultJSON[@"state"] intValue]) {
                
                [[[UIAlertView alloc] initWithTitle:@"验证码加载失败" message:jsonStr delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }
            
        }
        [self stopLoading];
    }];
    
    [[TCWebCodesBridge sharedBridge] setCallback:^(NSDictionary *resultJSON, UIView *webView) {
        NSString *jsonStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:resultJSON options:0 error:NULL] encoding:NSUTF8StringEncoding];
        if (0 == [resultJSON[@"ret"] intValue]) {
            if (self.webCodeViewBlock) {
                self.webCodeViewBlock(resultJSON);
            }
        }
        else  if (2 == [resultJSON[@"ret"] intValue]){
            // do nothing
            if (self.userCancel) {
                self.userCancel(resultJSON);
            }
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"验证失败" message:jsonStr delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
        
        [weakSelf.backgroundView removeFromSuperview];
        [self dismiss];
    }];
    
}



- (void)dismiss {
    
    [UIView animateWithDuration:0.3f animations:^{
        
        self.backgroundView.alpha = 0;
    } completion:^(BOOL finished) {
        
        if (self.backgroundView.superview) {
            [self.backgroundView removeFromSuperview];
        }
    }];
    
    _isShowing = NO;
}


@end
