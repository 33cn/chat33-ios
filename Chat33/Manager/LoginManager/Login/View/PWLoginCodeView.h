//
//  PWLoginCodeView.h
//  PWallet
//
//  Created by 于优 on 2018/12/26.
//  Copyright © 2018 ... All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PWLoginCodeView : UIView

+ (instancetype)shopView;

/** 第一响应 */
@property (nonatomic, assign) BOOL hasFirstResponder;
/** codeBtn是否可点击 */
@property (nonatomic, assign) BOOL codeBtnEnabled;
/** 输入内容 */
@property (nonatomic, copy) NSString *textContent;
/** 验证码点击事件 */
@property (nonatomic, copy) void(^didCodeBtnHandle)(UIButton *codeBtn);
/** 输入完成事件 */
@property (nonatomic, copy) void(^didEditEndHandle)(NSString *textContent);

- (void)removeContent;

@end

NS_ASSUME_NONNULL_END
