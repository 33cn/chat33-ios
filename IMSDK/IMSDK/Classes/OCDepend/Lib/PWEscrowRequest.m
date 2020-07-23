//
//  PWEscrowRequest.m
//  PWallet
//  托管账户网络请求
//  Created by .. on 2019/1/2.
//  Copyright © 2019 ... All rights reserved.
//

#import "PWEscrowRequest.h"
#import "PWNetworkingTool.h"
#import "PWLoginWebCode.h"
#import <YYModel/YYModel.h>
#import "NSError+PWError.h"
#import <IMSDK/IMSDK-Swift.h>


@interface PWHomeCoinCache : NSObject
@property (nonatomic,strong) NSArray *coinArray;
@property (nonatomic,strong) NSArray *coinPriceArray;
@property (nonatomic,copy) NSString *totalAssets;
+ (instancetype)shared;
@end
static PWHomeCoinCache *shareHomeCoinCache = nil;
@implementation PWHomeCoinCache
+ (instancetype)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareHomeCoinCache = [[PWHomeCoinCache alloc] init];
    });
    return shareHomeCoinCache;
}
@end





@implementation PWWebCodeModel

@end

@implementation PWEscrowRequest



+ (NSString *)getRid {
    // 时间戳
    NSDate* nowDate = [[NSDate alloc]init];
    NSString *string = [NSString stringWithFormat:@"%ld",(long)[nowDate timeIntervalSince1970]];
    // 随机数
    NSMutableArray *startArray = [[NSMutableArray alloc] initWithObjects:@0,@1,@2,@3,@4,@5,@6,@7,@8,@9,nil];
    
    NSInteger number = 6;
    for (NSInteger i = 0; i < number; i++) {
        NSInteger index = arc4random()%startArray.count;
        string = [NSString stringWithFormat:@"%@%@",string,startArray[index]];
        startArray[index] = [startArray lastObject];
        [startArray removeLastObject];
        
    }
    return string;
}

+ (void)sendCode:(NSDictionary*)parameters success:(requestSuccessBlock)successBlock showWebCode:(void(^)(PWWebCodeModel *result))showWebCodeBlock failure:(requestFailureBlock)failureBlock {
    
    NSString *urlStr = [HOSTURL_ESCROW stringByAppendingString:LOGIN_SENDCODE];
    
    NSMutableDictionary *param = [[NSMutableDictionary alloc] initWithDictionary:parameters];
    [param setObject:@"86" forKey:@"area"];
    if ([param valueForKey:@"param"] == nil) {
        [param setObject:@"FzmRandom" forKey:@"param"];
    }
    
    [PWNetworkingTool postRequestWithUrl:urlStr parameters:param successBlock:^(id object) {
        
        if ([object[@"isShow"] boolValue]) {
            
            NSString *url = object[@"data"][@"jsUrl"];
            PWLoginWebCode *webCode = [[PWLoginWebCode alloc] initWithUrl:url Frame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
            if (![webCode showing]) {
                [webCode show];
                webCode.webCodeViewBlock = ^(NSDictionary *jsonResult) {
                    
                    PWWebCodeModel *model = [PWWebCodeModel yy_modelWithDictionary:jsonResult];
                    model.businessId = object[@"data"][@"businessId"];
                    
                    if (showWebCodeBlock) {
                        showWebCodeBlock(model);
                    }
                };
                webCode.userCancel = ^(NSDictionary *jsonResult) {
                    if (showWebCodeBlock) {
                        showWebCodeBlock(nil);
                    }
                };
            }
        } else {
            if (successBlock) {
                successBlock(object);
            }
        }
        
        
    } failureBlock:^(NSError *error) {
        if (failureBlock) {
            failureBlock(error);
        }
    }];
}

+ (void)validateCode:(NSDictionary*)parameters success:(requestSuccessBlock)successBlock failure:(requestFailureBlock)failureBlock {
    NSString *urlStr = [HOSTURL_ESCROW stringByAppendingString:LOGIN_VALIDATE];
    
    NSMutableDictionary *param = [[NSMutableDictionary alloc] initWithDictionary:parameters];
    [param setObject:@"86" forKey:@"area"];
    [param setObject:@"sms" forKey:@"type"];
    
    [PWNetworkingTool postRequestWithUrl:urlStr parameters:param successBlock:^(id object) {
        
        if (successBlock) {
            successBlock(object);
        }
        
    } failureBlock:^(NSError *error) {
        if (failureBlock) {
            failureBlock(error);
        }
    }];
}


@end
