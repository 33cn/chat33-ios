//
//  UITextField+Delete.h
//  PWallet
//
//  Created by 于优 on 2018/12/10.
//  Copyright © 2018 ... All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WJTextFieldDelegate <UITextFieldDelegate>

- (void)textFieldDidDeleteBackward:(UITextField *)textField;

@end

@interface UITextField (Delete)

@property (weak, nonatomic) id<WJTextFieldDelegate> delegate;

@end

/**
 *  监听删除按钮
 *  object:UITextField
 */
extern NSString * const WJTextFieldDidDeleteBackwardNotification;

NS_ASSUME_NONNULL_END
