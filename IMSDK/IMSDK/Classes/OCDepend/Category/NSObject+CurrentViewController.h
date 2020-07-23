//
//  NSObject+CurrentViewController.h
//  PWallet
//
//  Created by lee on 2018/10/16.
//  Copyright © 2018 ... All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (CurrentViewController)
//获取当前屏幕显示的viewcontroller
+ (UIViewController *)currentViewController;
@end
