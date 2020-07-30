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
import IMSDK


#if DEBUG
let pushAppKey = "5dc924cb570df3de690009d8"

#else
let pushAppKey = "5e159f9fcb23d26129000311"

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
        
        UMConfigure.initWithAppkey(pushAppKey, channel: IMSDK.shared().channel == .AppleStore ? "AppStore" : "ThirdParty")
        let entity = UMessageRegisterEntity.init()
        entity.types = Int(UMessageAuthorizationOptions.badge.rawValue | UMessageAuthorizationOptions.alert.rawValue | UMessageAuthorizationOptions.sound.rawValue)
        
        self.registerRemoteNotification()
        
        UMessage.setBadgeClear(false)
        UMessage.registerForRemoteNotifications(launchOptions: nil, entity: entity) { (granted, error) in
            if granted {
                print("友盟推送注册成功")
            } else {
                print("友盟推送注册失败")
            }
        }
    }
    
    func setBadge(_ count: Int) {
        if count >= 0 {
            
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
        
        if let trigger = notification.request.trigger,
            trigger.isKind(of: UNPushNotificationTrigger.self) {
            UMessage.setAutoAlert(false)
            UMessage.didReceiveRemoteNotification(notification.request.content.userInfo)
        }
        completionHandler([.badge,.sound,.alert]);
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print("didReceiveNotificationResponse: %@",response.notification.request.content.userInfo);
        if let trigger = response.notification.request.trigger,
            trigger.isKind(of: UNPushNotificationTrigger.self) {
            UMessage.didReceiveRemoteNotification(response.notification.request.content.userInfo)
        }
        
        completionHandler();
    }
}

