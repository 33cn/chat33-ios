//
//  LaunchAdModel.m
//  XHLaunchAdExample
//
//  Created by zhuxiaohui on 2016/6/28.
//  Copyright © 2016年 it7090.com. All rights reserved.
//  代码地址:https://github.com/CoderZhuXH/XHLaunchAd
//  广告数据模型
#import "LaunchAdModel.h"

@implementation LaunchAdModel

- (instancetype)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        
        self.content = dict[@"url"];
        self.openUrl = dict[@"link"];
        self.duration = [dict[@"duration"] integerValue];
        if (dict[@"others"] != nil && [dict[@"others"] isKindOfClass:[NSArray class]]) {
            NSArray *array = dict[@"others"];
            NSMutableArray<NSURL*> *imageArray = [NSMutableArray array];
            NSMutableArray<NSURL*> *videoArray = [NSMutableArray array];
            for (NSString *urlStr in array) {
                NSURL *url = [NSURL URLWithString:urlStr];
                if (url != nil) {
                    if ([urlStr.pathExtension isEqualToString:@"mp4"]) {
                        [videoArray addObject:url];
                    } else {
                        [imageArray addObject:url];
                    }
                }
            }
            self.needCacheImageArray = [NSArray arrayWithArray:imageArray];
            self.needCacheVideoArray = [NSArray arrayWithArray:videoArray];
        }
    }
    return self;
}
@end
