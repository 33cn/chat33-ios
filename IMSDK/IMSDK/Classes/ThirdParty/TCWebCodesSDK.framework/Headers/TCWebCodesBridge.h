//
//  TCWebCodesBridge.h
//  vCodesDemo
//
//  Created by easelin on 16/3/28.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>


@interface TCWebCodesBridge : NSObject <UIWebViewDelegate, WKUIDelegate, WKNavigationDelegate>

/**
 返回单利
 */
+ (instancetype)sharedBridge;

/**
 设置是否显示H5的返回头部
 */
@property (nonatomic) BOOL showHeader;

/**
 设置回调
 @note 成功/失败可以通过 resultJSON[@"ret"] 判断，0为成功，非0为失败
 @warning 为了避免引用，内部在回调完成后会重置回调为空，请记得每次都需要设置回调
 */
@property (nonatomic, copy) void (^callback)(NSDictionary *resultJSON, UIView *webView);

/**
 开始加载H5
 @param url，业务服务器通过腾讯云拉取的验证码URL
 @param frame, webView控件大小
 @return 返回H5的webView控件
 @note 该函数用于开始加载，并且返回H5的webView控件，用于显示
 @warning 请不要设置返回webView控件的回调
 */
- (UIView*)startLoad:(NSString*)url webFrame:(CGRect)frame;

/**
 设置其余属性
 @note 该接口是为了后续扩展
 @warning 请设置value为基本类型: string, number
 @example [[TCWebCodesBridge sharedBridge] setCapValue:@"\"popup\"" forKey:@"type"];
 */
- (void)setCapValue:(id)aValue forKey:(id<NSCopying>)aKey;


//// 以下为可选接口
/**
 设置验证码加载完成的回调
 @note 加载情况可以通过 resultJSON[@"state"] 判断
 0-加载成功； 1-图片加载失败； 2-下发混合验证码，如果业务自定义了属性fwidth，当state=2时需要更新webview宽高，resultJSON["fwidth"] resultJSON["fheight"]
 */
@property (nonatomic, copy) void (^readyCallback)(NSDictionary *resultJSON, UIView *webView);

/**
 根据验证码宽度，计算验证码尺寸（滑动拼图验证码）。只对type=popup类型验证码生效
 @param width 验证码宽度
 @return 返回验证码宽高，当所设width超过屏幕最大宽度，该接口修改width最大为屏幕宽度
 @note 仅当业务需要自定义验证码样式时使用！！！
 */
- (CGSize)getCapSizeByWidth:(CGFloat)width;

/**
 根据验证码宽度和验证码类型，计算验证码尺寸，只对type=popup类型验证码生效
 @param width 验证码宽度
 @param type 验证码类型 1-字符 2-拼图 4-图中点字中文 6-图中点字英文 7-滑动拼图 其他-默认值
 @return 返回验证码宽高，当所设width超过屏幕最大宽度，该接口修改width最大为屏幕宽度
 @note 仅当业务需要自定义验证码样式时使用！！！
 */
- (CGSize)getCapSizeByWidth:(CGFloat)width capType:(int)type;

/**
 @note 清空调用setCapValue设置的所有属性，在setCapValue前调用！！！这里主要用于demo中测试多种类型验证码，业务接入时无需调用
 */
- (void)resetCapValue;

@end
