//
//  FZMPushManager.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/11/5.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import UserNotifications
import PushKit


#if DEBUG

let pushAppId = "UfgXFPggLA8w9eurTvRAA3"
let pushAppSecret = "lmbRiPnsyb9DdNf18xOjw2"
let pushAppKey = "W6NC6cxklf65kC3GAKh8kA"

#else

let pushAppId = "SAeI8hFG5n5xngUhXHfsp7"
let pushAppSecret = "S8AXFSuiVF6k4wkKlVSPA3"
let pushAppKey = "CZAQt3VBHO9nQpgNWgLMaA"

#endif

class FZMPushManager: NSObject {

    private static let sharedInstance = FZMPushManager()
    
    class func shared() -> FZMPushManager {
        return sharedInstance
    }
    
    class func launchPushClient() {
        _ = self.shared()
    }
    
    private var clientId = ""
    var cid : String {
        return clientId
    }
    
    override init() {
        super.init()
//        GeTuiSdk.start(withAppId: pushAppId, appKey: pushAppKey, appSecret: pushAppSecret, delegate: self)
//        self.registerRemoteNotification()
    }
    
    func setBadge(_ count: Int) {
        if count >= 0 {
//            GeTuiSdk.setBadge(UInt(count))
        }
    }
    
    
    // MARK: - 用户通知(推送) _自定义方法
    
    /** 注册用户通知(推送) */
    func registerRemoteNotification() {
        let systemVer = (UIDevice.current.systemVersion as NSString).floatValue;
        if systemVer >= 10.0 {
            if #available(iOS 10.0, *) {
                let center:UNUserNotificationCenter = UNUserNotificationCenter.current()
                center.delegate = self;
                center.requestAuthorization(options: [.alert,.badge,.sound], completionHandler: { (granted:Bool, error:Error?) -> Void in
                    if (granted) {
                        print("注册通知成功") //点击允许
                    } else {
                        print("注册通知失败") //点击不允许
                    }
                })
                
                UIApplication.shared.registerForRemoteNotifications()
            } else {
                if #available(iOS 8.0, *) {
                    let userSettings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
                    UIApplication.shared.registerUserNotificationSettings(userSettings)
                    
                    UIApplication.shared.registerForRemoteNotifications()
                }
            };
        }else if systemVer >= 8.0 {
            if #available(iOS 8.0, *) {
                let userSettings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
                UIApplication.shared.registerUserNotificationSettings(userSettings)
                
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
}

extension FZMPushManager: UNUserNotificationCenterDelegate {
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        print("willPresentNotification: %@",notification.request.content.userInfo);
        
        completionHandler([.badge,.sound,.alert]);
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print("didReceiveNotificationResponse: %@",response.notification.request.content.userInfo);
        
        // [ GTSdk ]：将收到的APNs信息传给个推统计
//        GeTuiSdk.handleRemoteNotification(response.notification.request.content.userInfo);
        
        completionHandler();
    }
}

