//
//  PWLoginAccountView.h
//  PWallet
//
//  Created by 于优 on 2018/12/26.
//  Copyright © 2018 ... All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PWLoginAccountView : UIView

+ (instancetype)shopView;
/** 输入内容 */
@property (nonatomic, copy) NSString *textContent;
/** 第一响应 */
@property (nonatomic, assign) BOOL hasFirstResponder;

@end

NS_ASSUME_NONNULL_END
