//
//  AppDelegate.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/19.
//  Copyright © 2018年 吴文拼. All rights reserved.
// 

import UIKit
import IMSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //配置IM服务
        let configure = IMSDKConfigureModel()
        //与服务端约定的appId
        configure.appId = "http://put.your.appId.here"
        //客服信息
        configure.service = "http://put.your.service.here"

        //oss地址
        configure.ossIp = "http://put.your.ossIp.here"
        configure.ossKey = "http://put.your.ossKey.here"
        configure.ossSecret = "http://put.your.ossSecret.here"
        configure.ossBuket = "http://put.your.ossBuket.here"

        //反馈地址
        configure.feedbackUrl = "http://put.your.url.here"
        //socket地址
        configure.socketIp = "http://put.your.url.here"
        //api地址
        configure.serverIp = "http://put.your.url.here"
        //分享地址
        configure.shareUrl = "http://put.your.url.here"
        //合约地址
        configure.contractIp = "http://put.your.url.here"
        
        IMSDK.launchApp(configure)
        IMSDK.shared().isEncyptChat = true
        IMSDK.shared().showIdentification = false

        IMSDK.shared().showShare = true
        IMSDK.shared().shareTitle = "Chat33"
        IMSDK.shared().shareIcon = #imageLiteral(resourceName: "qrcode_share_chat")
        IMSDK.shared().qrCodeCenterIcon = #imageLiteral(resourceName: "qrcode_center")
        
        //初始化页面
        ChatUIMediator.shared().createMainView()
        
        //启动百度crab
        self.launchBaiduCrab()
        //启动推送
        FZMPushManager.launchPushClient()
        //启动分享
        FZMShareManager.launch()

        
        return true
    }
    
    func launchBaiduCrab() {
        guard let dic = Bundle.main.infoDictionary ,let version = dic["CFBundleShortVersionString"] as? String else { return }
        CrabCrashReport.sharedInstance().initCrashReporter(withAppKey: "a288dea565ec64dc", andVersion: version, andChannel: "AppStore")
        CrabCrashReport.sharedInstance().setCrashReportEnabled(true)
        CrabCrashReport.sharedInstance().setCatchANREnable(true)
        CrabCrashReport.sharedInstance().setANRTimeoutInterval(3000)
        CrabCrashReport.sharedInstance().setColloctCaughtExceptionEnable(true)
        CrabCrashReport.sharedInstance().setExceptionMonitorTimeoutInterval(10000)
        CrabCrashReport.sharedInstance().setPagePathMaxLines(10)
        CrabCrashReport.sharedInstance().setUploadCrashOnlyWifi(false)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard !url.absoluteString.contains("wxee2742e706bdceed") else { return true }
        IMSDK.shared().parsingUrl(url.absoluteString)
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        
        if UIViewController.currentViewController()?.shouldAutorotate == true {
            return UIInterfaceOrientationMask.allButUpsideDown
        }
        return UIInterfaceOrientationMask.portrait
    }


    // MARK: - 远程通知(推送)回调
    
    /** 远程通知注册成功委托 */
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("\n>>>[DeviceToken(Data)]: %@\n\n", NSData.init(data: deviceToken));
        
        let deviceTokenString = Array<UInt8>.init(deviceToken).map {String.init(format: "%02x", $0&0x000000FF)}.joined()
        IMSDK.shared().setDeviceToken(deviceTokenString)
        
    }
    
    /** 远程通知注册失败委托 */
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("\n>>>[DeviceToken Error]:%@\n\n",error.localizedDescription);
    }
    
    // MARK: - APP运行中接收到通知(推送)处理 - iOS 10 以下
    
    /** APP已经接收到“远程”通知(推送) - (App运行在后台) */
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        application.applicationIconBadgeNumber = 0;        // 标签
        
        print("\n>>>[Receive RemoteNotification]:%@\n\n",userInfo);
        
        UMessage.setAutoAlert(false)
        if Int(UIDevice.current.systemVersion) ?? 0 < 10 {
            UMessage.didReceiveRemoteNotification(userInfo)
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        UMessage.setAutoAlert(false)
        if Int(UIDevice.current.systemVersion) ?? 0 < 10 {
            UMessage.didReceiveRemoteNotification(userInfo)
        }
        
        completionHandler(UIBackgroundFetchResult.newData);
    }
    
}


