//
//  PWNetworkingTool.m
//  PWallet
//
//  Created by .. on 2018/5/16.
//  Copyright © 2018年 ... All rights reserved.
//

#import "PWNetworkingTool.h"
#import "AFNetworking.h"
#import "PWSessionManagerSingleton.h"
#import "NSError+PWError.h"
#import <IMSDK/IMSDK-Swift.h>



@implementation PWNetworkingTool

+ (void)getRequestWithUrl:(NSString *)url
               parameters:(NSDictionary *)parameters
             successBlock:(requestSuccessBlock)successBlock
             failureBlock:(requestFailureBlock)failureBlock {
    AFHTTPSessionManager *manager = [PWSessionManagerSingleton sharedSessionManager];
    NSLog(@"PWNetworkingTool请求URL:%@",url);
    NSLog(@"PWNetworkingTool请求参数:%@",parameters);
    [manager GET:url
      parameters:parameters
        progress:nil
         success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
             [self requestResponseObject:responseObject successBlock:successBlock failureBlock:failureBlock];
         }
         failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
             if (failureBlock) {
                 failureBlock([NSError errorWithCode:error.code errorMessage:error.description]);
             }
         }];
}

+ (void)postRequestWithUrl:(NSString *)url
                parameters:(NSDictionary *)parameters
              successBlock:(requestSuccessBlock)successBlock
              failureBlock:(requestFailureBlock)failureBlock {
    NSLog(@"PWNetworkingTool请求URL:%@",url);
    NSLog(@"PWNetworkingTool请求参数:%@",parameters);
    AFHTTPSessionManager *manager = [PWSessionManagerSingleton sharedSessionManager];
    [manager POST:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self requestResponseObject:responseObject successBlock:successBlock failureBlock:failureBlock];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failureBlock) {
            failureBlock([NSError errorWithCode:error.code errorMessage:error.description]);
        }
    }];
}

+ (void)postRequestWithUrl:(NSString *)url parameters:(NSDictionary *)parameters data:(NSData *)fileData FieldName:(NSString *)fieldName FileName:(NSString *)fileName MimeType:(NSString *)mimeType successBlock:(requestSuccessBlock)successBlock failureBlock:(requestFailureBlock)failureBlock
{
    NSLog(@"PWNetworkingTool请求URL:%@",url);
    NSLog(@"PWNetworkingTool请求参数:%@",parameters);
    AFHTTPSessionManager *manager = [PWSessionManagerSingleton sharedSessionManager];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    [manager.requestSerializer setValue:@"coin_wallet" forHTTPHeaderField:@"FZM-Ca-AppKey"];
    [manager POST:url
       parameters:parameters
constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
    [formData appendPartWithFileData:fileData
                                name:fieldName
                            fileName:fileName
                            mimeType:mimeType];
} progress:^(NSProgress * _Nonnull uploadProgress) {
    
} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
    [self requestResponseObject:responseObject successBlock:successBlock failureBlock:failureBlock];
} failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
    if (failureBlock) {
        failureBlock([NSError errorWithCode:error.code errorMessage:error.description]);
    }
}];
}

/**
 *  对http请求后响应的处理
 *
 *  @param responseObject    请求返回的响应对象
 *  @param successBlock      处理响应数据后的成功回调
 *  @param failureBlock      处理响应数据后的失败回调
 */
+ (void)requestResponseObject:(id)responseObject successBlock:(requestSuccessBlock)successBlock
                 failureBlock:(requestFailureBlock)failureBlock {
    NSLog(@"PWNetworkingTool请求返回信息%@",responseObject);
    if (responseObject[@"code"] != nil) {
        if ([responseObject[@"code"] integerValue] == 401) {
            [[IMLoginUser shared] clearUserInfo];
            FZMAlertView * alert = [[FZMAlertView alloc] initWithOnlyAlert:@"登录失效, 请重新登录" btnTitle:@"确定" confirmBlock:^{}];
            alert.tag = 401;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if ([[UIApplication sharedApplication].keyWindow viewWithTag:401] == nil) {
                    [alert show];
                }
            });
            return;
        }
        if ([responseObject[@"code"] integerValue] == 0 || [responseObject[@"code"] integerValue] == 200) {
            if (successBlock) {
                successBlock(responseObject[@"data"]);
                return;
            }
        } else if (failureBlock) {
            NSString *errorMessage = responseObject[@"msg"];
            if (errorMessage == nil) {
                errorMessage = responseObject[@"message"];
            }
            if (errorMessage == nil) {
                errorMessage = responseObject[@"error"];
            }
            failureBlock([NSError errorWithCode:[responseObject[@"code"] integerValue] errorMessage:errorMessage]);
            return;
        }
    }
    
    if (responseObject[@"result"] != nil) {
        if ([responseObject[@"result"] integerValue] == 0) {
            if (successBlock) {
                successBlock(responseObject[@"data"]);
                return;
            }
        } else if (failureBlock) {
            NSString *errorMessage = responseObject[@"msg"];
            if (errorMessage == nil) {
                errorMessage = responseObject[@"message"];
            }
            if (errorMessage == nil) {
                errorMessage = responseObject[@"error"];
            }
            failureBlock([NSError errorWithCode:[responseObject[@"code"] integerValue] errorMessage:errorMessage]);
            return;
        }
    }
    
}
@end
