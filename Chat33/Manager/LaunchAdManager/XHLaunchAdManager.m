//
//  XHLaunchAdManager.m
//  XHLaunchAdExample
//
//  Created by zhuxiaohui on 2017/5/3.
//  Copyright © 2017年 it7090.com. All rights reserved.
//  代码地址:https://github.com/CoderZhuXH/XHLaunchAd
//  开屏广告初始化

#import "XHLaunchAdManager.h"
#import "LaunchAdModel.h"
#import <XHLaunchAd.h>
#import "PWNetworkingTool.h"
#import <SafariServices/SafariServices.h>
#import <IMSDK-Swift.h>


@interface XHLaunchAdManager()<XHLaunchAdDelegate>

@end

@implementation XHLaunchAdManager

+(void)load{
//    [self shareManager];
}

+(XHLaunchAdManager *)shareManager{
    static XHLaunchAdManager *instance = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken,^{
        instance = [[XHLaunchAdManager alloc] init];
    });
    return instance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        //在UIApplicationDidFinishLaunching时初始化开屏广告,做到对业务层无干扰,当然你也可以直接在AppDelegate didFinishLaunchingWithOptions方法中初始化
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            //初始化开屏广告
            if (IMSDK.shared.isLogin) {
                [self setupXHLaunchAd];
            }
        }];
    }
    return self;
}

-(void)setupXHLaunchAd{
    
    [self loadAd];
    
}

#pragma mark - 图片开屏广告-网络数据-示例
//图片开屏广告 - 网络数据
-(void)loadAd{
    
    //设置你工程的启动页使用的是:LaunchImage 还是 LaunchScreen.storyboard(不设置默认:LaunchImage)
    [XHLaunchAd setLaunchSourceType:SourceTypeLaunchScreen];
    
    //1.因为数据请求是异步的,请在数据请求前,调用下面方法配置数据等待时间.
    //2.设为3即表示:启动页将停留3s等待服务器返回广告数据,3s内等到广告数据,将正常显示广告,否则将不显示
    //3.数据获取成功,配置广告数据后,自动结束等待,显示广告
    //注意:请求广告数据前,必须设置此属性,否则会先进入window的的根控制器
    [XHLaunchAd setWaitDataDuration:3];
    
    //广告数据请求
    [PWNetworkingTool postRequestWithUrl:[HOSTURL_CHAT stringByAppendingString:LAUNCH_AD] parameters:@{} successBlock:^(id response) {
        NSLog(@"广告数据 = %@",response);
        //广告数据转模型
        LaunchAdModel *model = [[LaunchAdModel alloc] initWithDict:response];
        
        if (model.content.length > 0) {
            if ([model.content.pathExtension isEqualToString:@"mp4"]) {
                [self showVideoAd:model];
            } else {
                [self showImageAd:model];
            }
        }
        
        if (model.needCacheImageArray.count > 0) {
            [self batchDownloadImageAndCache:model.needCacheImageArray];
        }
        if (model.needCacheVideoArray.count > 0) {
            [self batchDownloadVideoAndCache:model.needCacheVideoArray];
        }
        
    } failureBlock:^(NSError *error) {
        
    }];
}

- (void)showVideoAd:(LaunchAdModel*)model {
    //配置广告数据
    XHLaunchVideoAdConfiguration *videoAdconfiguration = [XHLaunchVideoAdConfiguration new];
    //广告停留时间
    videoAdconfiguration.duration = model.duration;
    //广告frame
    videoAdconfiguration.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    //广告视频URLString/或本地视频名(请带上后缀)
    //注意:视频广告只支持先缓存,下次显示(看效果请二次运行)
    videoAdconfiguration.videoNameOrURLString = model.content;
    //是否关闭音频
    videoAdconfiguration.muted = NO;
    //视频缩放模式
    videoAdconfiguration.videoGravity = AVLayerVideoGravityResizeAspectFill;
    //是否只循环播放一次
    videoAdconfiguration.videoCycleOnce = NO;
    //广告点击打开页面参数(openModel可为NSString,模型,字典等任意类型)
    videoAdconfiguration.openModel = model.openUrl;
    //广告显示完成动画
    videoAdconfiguration.showFinishAnimate =ShowFinishAnimateFadein;
    //广告显示完成动画时间
    videoAdconfiguration.showFinishAnimateTime = 0.8;
    //后台返回时,是否显示广告
    videoAdconfiguration.showEnterForeground = NO;
    //跳过按钮类型
    videoAdconfiguration.skipButtonType = SkipTypeRoundProgressText;
    
    [XHLaunchAd videoAdWithVideoAdConfiguration:videoAdconfiguration delegate:self];
}

- (void)showImageAd:(LaunchAdModel*)model {
    //配置广告数据
    XHLaunchImageAdConfiguration *imageAdconfiguration = [XHLaunchImageAdConfiguration new];
    //广告停留时间
    imageAdconfiguration.duration = model.duration;
    //广告frame
    imageAdconfiguration.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    //广告图片URLString/或本地图片名(.jpg/.gif请带上后缀)
    imageAdconfiguration.imageNameOrURLString = model.content;
    //设置GIF动图是否只循环播放一次(仅对动图设置有效)
    imageAdconfiguration.GIFImageCycleOnce = NO;
    //缓存机制(仅对网络图片有效)
    //为告展示效果更好,可设置为XHLaunchAdImageCacheInBackground,先缓存,下次显示
    imageAdconfiguration.imageOption = XHLaunchAdImageDefault;
    //图片填充模式
    imageAdconfiguration.contentMode = UIViewContentModeScaleAspectFill;
    //广告点击打开页面参数(openModel可为NSString,模型,字典等任意类型)
    imageAdconfiguration.openModel = model.openUrl;
    //广告显示完成动画
    imageAdconfiguration.showFinishAnimate =ShowFinishAnimateLite;
    //广告显示完成动画时间
    imageAdconfiguration.showFinishAnimateTime = 0.8;
    //跳过按钮类型
    imageAdconfiguration.skipButtonType = SkipTypeRoundProgressText;
    //后台返回时,是否显示广告
    imageAdconfiguration.showEnterForeground = NO;
    //显示开屏广告
    [XHLaunchAd imageAdWithImageAdConfiguration:imageAdconfiguration delegate:self];
}


#pragma mark - 批量下载并缓存
/**
 *  批量下载并缓存图片
 */
-(void)batchDownloadImageAndCache:(NSArray<NSURL*>*)imageURLArray{
    
    [XHLaunchAd downLoadImageAndCacheWithURLArray:imageURLArray completed:^(NSArray * _Nonnull completedArray) {
        
        /** 打印批量下载缓存结果 */
        
        //url:图片的url字符串,
        //result:0表示该图片下载失败,1表示该图片下载并缓存完成或本地缓存中已有该图片
        NSLog(@"批量下载缓存图片结果 = %@" ,completedArray);
    }];
}

/**
 *  批量下载并缓存视频
 */
-(void)batchDownloadVideoAndCache:(NSArray<NSURL*>*)videoURLArray{
    
    [XHLaunchAd downLoadVideoAndCacheWithURLArray:videoURLArray completed:^(NSArray * _Nonnull completedArray) {
        
        /** 打印批量下载缓存结果 */
        
        //url:视频的url字符串,
        //result:0表示该视频下载失败,1表示该视频下载并缓存完成或本地缓存中已有该视频
        NSLog(@"批量下载缓存视频结果 = %@" ,completedArray);
        
    }];
    
}



#pragma mark - XHLaunchAd delegate - 其他
/**
 广告点击事件回调
 */
-(void)xhLaunchAd:(XHLaunchAd *)launchAd clickAndOpenModel:(id)openModel clickPoint:(CGPoint)clickPoint{
    
    NSLog(@"广告点击事件");
    
    /** openModel即配置广告数据设置的点击广告时打开页面参数(configuration.openModel) */
    NSString *urlStr = (NSString*)openModel;
    [IMSDK.shared parsingUrl:urlStr];
    
}

@end
