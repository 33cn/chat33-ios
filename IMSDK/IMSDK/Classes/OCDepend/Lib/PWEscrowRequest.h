//
//  PWEscrowRequest.h
//  PWallet
//  托管账户网络请求
//  Created by .. on 2019/1/2.
//  Copyright © 2019 ... All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DependHeader.h"


NS_ASSUME_NONNULL_BEGIN

@interface PWWebCodeModel : NSObject

/** businessId */
@property (nonatomic, copy) NSString *businessId;
/** ticket */
@property (nonatomic, copy) NSString *ticket;
/** ret */
@property (nonatomic, assign) BOOL ret;

@end

@interface PWEscrowRequest : NSObject

/**
 获取短信
 @param parameters 参数 （只需传入codetype，mobile即可）
 @param successBlock 成功回调
 @param showWebCodeBlock 需要图形验证码的回调
 @param failureBlock 失败回调
 */
+ (void)sendCode:(NSDictionary*)parameters success:(requestSuccessBlock)successBlock showWebCode:(void(^)(PWWebCodeModel *__nullable result))showWebCodeBlock failure:(requestFailureBlock)failureBlock;

/**
 短信预验证
 @param parameters 参数 （只需传入codetype，mobile，code即可）
 @param successBlock 成功回调
 @param failureBlock 失败回调
 */
+ (void)validateCode:(NSDictionary*)parameters success:(requestSuccessBlock)successBlock failure:(requestFailureBlock)failureBlock;


@end

NS_ASSUME_NONNULL_END
