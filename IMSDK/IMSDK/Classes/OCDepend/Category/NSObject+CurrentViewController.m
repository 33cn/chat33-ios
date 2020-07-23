//
//  NSObject+CurrentViewController.m
//  PWallet
//
//  Created by lee on 2018/10/16.
//  Copyright © 2018 ... All rights reserved.
//

#import "NSObject+CurrentViewController.h"

@implementation NSObject (CurrentViewController)
//获取当前屏幕显示的viewcontroller
+ (UIViewController *)currentViewController {
    UIViewController *result = nil;
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows) {
            if (tmpWin.windowLevel == UIWindowLevelNormal) {
                window = tmpWin;
                break;
            }
        }
    }
    if ([window subviews].count>0) {
        UIView *frontView = [[window subviews] objectAtIndex:0];
        id nextResponder = [frontView nextResponder];

        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            result = nextResponder;
        }
        else {
            result = window.rootViewController;
        }
    }
    else {
        result = window.rootViewController;
    }
    if ([result isKindOfClass:[UITabBarController class]]) {
        result = [((UITabBarController*)result) selectedViewController];
    }
    if ([result isKindOfClass:[UINavigationController class]]) {
        result = [((UINavigationController*)result) visibleViewController];
    }
    return result;
}
@end
