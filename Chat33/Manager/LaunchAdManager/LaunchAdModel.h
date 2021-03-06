//
//  LaunchAdModel.h
//  XHLaunchAdExample
//
//  Created by zhuxiaohui on 2016/6/28.
//  Copyright © 2016年 it7090.com. All rights reserved.
//  代码地址:https://github.com/CoderZhuXH/XHLaunchAd
//  广告数据模型

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LaunchAdModel : NSObject

/**
 *  广告URL
 */
@property (nonatomic, copy) NSString *content;

/**
 *  点击打开连接
 */
@property (nonatomic, copy) NSString *openUrl;

/**
 *  广告停留时间
 */
@property (nonatomic, assign) NSInteger duration;

/**
 *  需要缓存的图片
 */
@property (nonatomic, strong) NSArray<NSURL*>* needCacheImageArray;

/**
 *  需要缓存的视频
 */
@property (nonatomic, strong) NSArray<NSURL*>* needCacheVideoArray;

- (instancetype)initWithDict:(NSDictionary *)dict;
@end
