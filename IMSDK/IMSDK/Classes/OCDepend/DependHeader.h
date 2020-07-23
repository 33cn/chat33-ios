//
//  DependHeader.h
//  IMSDK
//
//  Created by .. on 2019/3/12.
//

#ifndef DependHeader_h
#define DependHeader_h

#import <Masonry/Masonry.h>
#import "UIViewController+ShowInfo.h"
#import "UITextView+KeyBoard.h"
#import <SDWebImage/SDWebImage-umbrella.h>
#import "NSObject+Empty.h"
#import <YYModel/YYModel.h>
#import <YYText/YYText.h>
#import "UITextField+KeyBoard.h"


typedef NS_ENUM(NSUInteger, TransferFrom) {
    /**
     *  联系人
     */
    TransferFromContact = 0,
    /**
     *  币种信息
     */
    TransferFromCoinDetail,
};

//网络请求成功回调block
typedef void (^requestSuccessBlock)(id object);
//网络请求失败回调block
typedef void (^requestFailureBlock)(NSError *error);

//判断xxxx是否为空(支持类型NSString、NSArray、NSDictionary、NSSet)
#define IS_BLANK(obj) [NSObject empty:obj]

#define ENGLISHCHAR @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
#define LAST_OPERATION_COIN @"LAST_OPERATION_COIN"

//颜色
#define CMColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define CMColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
#define CMColorRGBA(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:a]
#define CMRandomColor QNColor(arc4random_uniform(256), arc4random_uniform(256), arc4random_uniform(256))

#define SGColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define SGColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
#define SGColorRGBA(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:a]
#define SGRandomColor QNColor(arc4random_uniform(256), arc4random_uniform(256), arc4random_uniform(256))

//主题蓝
#define MainColor (SGColorRGBA(47, 134, 242, 1))
//工程中常规按钮高度
#define kBtnHeight 44
//工程中常规按钮颜色
#define kBtnColor (SGColorRGBA(47, 134, 242, 1))

#define BgColor CMColor(246,248,250)
#define ErrorColor CMColor(220,40,40)
//字体颜色
#define TextColor51 CMColor(51, 51, 51)
#define TextColor119 CMColor(119,119,119)
#define TextColor99 CMColorFromRGB(0x999999)
#define TextColor77 CMColorFromRGB(0x777777)

//线的颜色
#define LineColor CMColorFromRGB(0xD2D8E1)
#define PlaceHolderColor CMColor(153,153,153)
#define TipRedColor CMColor(220,40,40)
#define CodeBgColor CMColorRGBA(246, 250, 255, 1)

#define kPUBLICNUMBERFONT_SIZE(fontSize) [UIFont fontWithName:@"DINAlternate-Bold" size:fontSize]

//字体
#define CMTextFont12  [UIFont systemFontOfSize:12]
#define CMTextFont13  [UIFont systemFontOfSize:13]
#define CMTextFont14  [UIFont systemFontOfSize:14]
#define CMTextFont15  [UIFont systemFontOfSize:15]
#define CMTextFont16  [UIFont systemFontOfSize:16]
#define CMTextFont17  [UIFont systemFontOfSize:17]
#define CMTextFont18  [UIFont systemFontOfSize:18]
#define CMTextFont19  [UIFont systemFontOfSize:19]
#define CMTextFont20  [UIFont systemFontOfSize:20]
#define CMTextFont22  [UIFont systemFontOfSize:22]
#define CMTextFont24  [UIFont systemFontOfSize:24]
#define CMTextFont28  [UIFont systemFontOfSize:28]
#define CMTextFont30  [UIFont systemFontOfSize:30]
#define CMTextFont33  [UIFont systemFontOfSize:33]
#define CMTextFont45  [UIFont systemFontOfSize:45]
#define CMTextFont(size) [UIFont systemFontOfSize:size]
#define CMTextBoldFont(size) [UIFont boldSystemFontOfSize:size]fine CMColorRGBA(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:a]

#define isIPhoneXR ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(828, 1792), [[UIScreen mainScreen] currentMode].size) : NO)
#define isIPhoneXS ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)
#define isIPhoneSMax ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2688), [[UIScreen mainScreen] currentMode].size) : NO)
#define isIPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)
#define isIPhone6 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ?  CGSizeEqualToSize(CGSizeMake(750, 1334), [[UIScreen mainScreen] currentMode].size) : NO)
#define isIPhone6P ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size) : NO)
#define isIPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)
#define isIPhoneXSeries (isIPhoneX || isIPhoneXS || isIPhoneXR || isIPhoneSMax)

#define SCREENBOUNDS [[UIScreen mainScreen] bounds]

#define kScreenHeight ([UIScreen mainScreen].bounds.size.height)
#define kScreenWidth  ([UIScreen mainScreen].bounds.size.width)

// 适配iPhoneX时的偏移量
#define kTopOffset (isIPhoneXSeries ? 88  : 64)
#define kBottomOffset (isIPhoneXSeries ? 83 : 49)
#define kIphoneXBottomOffset (isIPhoneXSeries ? 34 : 0)

#define WEAKSELF  __typeof(self) __weak weakSelf = self;

#define HOSTURL @"https://b.biqianbao.net"


#define HOSTURL_ESCROW IMSDK.shared.configure.escrowIp

#define ESCROW_IS_AUTH @"ESCROW_IS_AUTH"


// 短信
#define LOGIN_SENDCODE @"v1/send/sms"
// 短信预验证
#define LOGIN_VALIDATE @"v1/send/pre-validate"
// 用户是否注册
#define LOGIN_ISREG @"v1/user/is-reg"
// 用户登录
#define LOGIN_LOGIN @"v1/user/login"
// 用户注册
#define LOGIN_REG @"v1/user/reg"
// 设置&修改密码
#define LOGIN_SETPASSWORD @"v1/user/set-pay-password"
// 用户登出
#define LOGIN_LOGOUT @"v1/user/logout"
// 用户信息
#define LOGIN_INFO @"v1/user/info"


#endif /* DependHeader_h */
