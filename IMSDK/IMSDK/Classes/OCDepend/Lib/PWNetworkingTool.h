//
//  PWNetworkingTool.h
//  PWallet
//
//  Created by .. on 2018/5/16.
//  Copyright © 2018年 ... All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DependHeader.h"

@interface PWNetworkingTool : NSObject
/**
 *  get请求
 *
 *  @param url          url
 *  @param parameters   请求头
 *  @param successBlock success
 *  @param failureBlock failed
 */
+ (void)getRequestWithUrl:(NSString *)url
                 parameters:(NSDictionary *)parameters
             successBlock:(requestSuccessBlock)successBlock
              failureBlock:(requestFailureBlock)failureBlock;
/**
 *  post请求
 *
 *  @param url          url
 *  @param parameters   请求头
 *  @param successBlock success
 *  @param failureBlock failed
 */
+ (void)postRequestWithUrl:(NSString *)url
                  parameters:(NSDictionary *)parameters
              successBlock:(requestSuccessBlock)successBlock
               failureBlock:(requestFailureBlock)failureBlock;

/**
 向服务器上传文件
 
 *  @param url       要上传的文件接口
 *  @param parameters 上传的参数
 *  @param fileData  上传的文件\数据
 *  @param fieldName 服务对应的字段
 *  @param fileName  上传到时服务器的文件名
 *  @param mimeType  上传的文件类型
 *  @param successBlock success
 *  @param failureBlock failed
 */
+ (void)postRequestWithUrl:(NSString *)url
                parameters:(NSDictionary *)parameters
                      data:(NSData *)fileData
                 FieldName:(NSString *)fieldName
                  FileName:(NSString *)fileName
                  MimeType:(NSString *)mimeType
              successBlock:(requestSuccessBlock)successBlock
              failureBlock:(requestFailureBlock)failureBlock;

@end
