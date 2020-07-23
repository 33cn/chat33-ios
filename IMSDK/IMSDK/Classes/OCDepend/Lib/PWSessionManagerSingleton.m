//
//  PWSessionManagerSingleton.m
//  PWallet
//
//  Created by .. on 2018/5/16.
//  Copyright © 2018年 ... All rights reserved.
//

#import "PWSessionManagerSingleton.h"
#import <AFNetworking/AFNetworking.h>
#import <IMSDK/IMSDK-Swift.h>

@interface PWSessionManagerSingleton ()

@end

static AFHTTPSessionManager *shareManager = nil;

@implementation PWSessionManagerSingleton
+ (AFHTTPSessionManager *) sharedSessionManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareManager = [AFHTTPSessionManager manager];
        //配置shareManager
        // 设置请求以及相应的序列化器
        shareManager.requestSerializer = [AFJSONRequestSerializer serializer];
        shareManager.responseSerializer = [AFJSONResponseSerializer serializer];
        // 设置超时时间
        shareManager.requestSerializer.timeoutInterval = 30.0;
        // 设置响应内容的类型
        shareManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"application/octet-stream", @"text/json", @"text/javascript",@"text/html",@"text/plain",nil];
        
        NSString *UUID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        [shareManager.requestSerializer setValue:@"chat" forHTTPHeaderField:@"Fzm-Request-Source"];
        [shareManager.requestSerializer setValue:@"ios" forHTTPHeaderField:@"FZM-REQUEST-OS"];
        [shareManager.requestSerializer setValue:UUID forHTTPHeaderField:@"FZM-REQUEST-UUID"];
        [shareManager.requestSerializer setValue:IMSDK.shared.appId forHTTPHeaderField:@"FZM-APP-ID"];
        [shareManager.requestSerializer setValue:@"iOS" forHTTPHeaderField:@"FZM-DEVICE"];
        [shareManager.requestSerializer setValue:[UIDevice currentDevice].name forHTTPHeaderField:@"FZM-DEVICE-NAME"];
        [shareManager.requestSerializer setValue:UUID forHTTPHeaderField:@"FZM-UUID"];
        [shareManager.requestSerializer setValue: [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"] forHTTPHeaderField:@"FZM-VERSION"];
        [shareManager.requestSerializer setValue: IMSDK.shared.channel == Chat33ChannelAppleStore ? @"appleStore" : @"thirdParty"  forHTTPHeaderField:@"FZM-iOS-CHANNEL"];
       
    });
    
//    NSString *token = [IMLoginUser shared].currentUser.token;
//    [shareManager.requestSerializer setValue:token forHTTPHeaderField:@"Auth-Token"];
//    [shareManager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@",token] forHTTPHeaderField:@"Authorization"];
    
    return shareManager;
}

@end
