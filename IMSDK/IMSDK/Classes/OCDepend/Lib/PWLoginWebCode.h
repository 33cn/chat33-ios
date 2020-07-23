//
//  PWLoginWebCode.h
//  PWallet
//
//  Created by 于优 on 2018/10/23.
//  Copyright © 2018年 ... All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^webCodeViewBlock)(NSDictionary *jsonResult);

@interface PWLoginWebCode : NSObject

// 要显示webcode的url
@property (nonatomic, copy) NSString *url;

@property (nonatomic, copy) webCodeViewBlock webCodeViewBlock;

// 用户取消
@property (nonatomic, copy) webCodeViewBlock userCancel;

- (instancetype)initWithUrl:(NSString *)url Frame:(CGRect)frame;

- (void)show;

- (BOOL)showing;

- (void)dismiss;

@end
