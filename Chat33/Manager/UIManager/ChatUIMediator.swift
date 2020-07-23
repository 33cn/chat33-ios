//
//  FZMUIMediator.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/20.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift
import MobileCoreServices
import IMSDK
import RTRootNavigationController

class ChatUIMediator: NSObject {
    
    private static let sharedInstance = ChatUIMediator()
    private let disposeBag = DisposeBag()
    class func shared() -> ChatUIMediator{
        return sharedInstance
    }
    
    private var homeTabbarVC : FZMTabBarController?
    
    func createMainView() {
        IMSDK.shared().addDelegate(with: self, event: .unreadCount)
        IMSDK.shared().loginDelegate = self
//        IMSDK.shared().certificationDelegate = self
        let conversationNav = IMSDK.shared().getConversationNavigationController()
        self.createTabBarItem(nav: conversationNav, title: "消息", normalImg: UIImage(named: "tab_chat"), selectImg: UIImage(named: "tab_chat_select"))
        let contactNav = IMSDK.shared().getContactNavigationController()
        self.createTabBarItem(nav: contactNav, title: "通讯录", normalImg: UIImage(named: "tab_contact"), selectImg: UIImage(named: "tab_contact_select"))
        let meInfoNav = IMSDK.shared().getMeNavigationController()
        self.createTabBarItem(nav: meInfoNav, title: "我的", normalImg: UIImage(named: "tab_me"), selectImg: UIImage(named: "tab_me_select"))
        
        let tabBar = FZMTabBarController()
        tabBar.viewControllers = [conversationNav, contactNav, meInfoNav]
        UIApplication.shared.delegate?.window??.backgroundColor = UIColor.white
        UIApplication.shared.delegate?.window??.rootViewController = tabBar
        UIApplication.shared.delegate?.window??.makeKeyAndVisible()
        homeTabbarVC = tabBar
        IMSDK.shared().setHomeTab(with: homeTabbarVC!)
        if !IMSDK.shared().isLogin() {
            self.goLoginView()
        }
    }
    
    func resetWalletVc() {
        
    }
    
    func createTabBarItem(nav: UINavigationController, title: String, normalImg: UIImage?, selectImg: UIImage?) {
        let item = UITabBarItem(title: title, image: normalImg?.withRenderingMode(.alwaysOriginal), selectedImage: selectImg?.withRenderingMode(.alwaysOriginal))
        item.setTitleTextAttributes([.foregroundColor:UIColor(hex: 0x8A97A5),
                                     .font:UIFont.systemFont(ofSize: 12)],
                                    for: .normal)
        item.setTitleTextAttributes([.foregroundColor:UIColor(hex: 0x32B2F7),
                                     .font:UIFont.systemFont(ofSize: 12)],
                                    for: .selected)
        nav.tabBarItem = item
    }
    
    //登录页
    func goLoginView() {
        FZMLoginManager.shared().showLoginPage()
    }
    
    //打开网页
    func openUrl(with path: String) {
        guard let goUrl = URL(string: path) else {return}
        UIApplication.shared.openURL(goUrl)
    }
    
    func select(with index: Int) {
        guard let tabBar = homeTabbarVC else { return }
        tabBar.selectedIndex = index
    }
    
    //设置未读数
    func setTabbarBadge(with index: Int, count: Int) {
        guard let tabBar = homeTabbarVC else { return }
        tabBar.setTabbarBadge(with: index, count: count)
    }
}

extension ChatUIMediator: IMSDKUnreadCountDelegate {
    func conversationUnreadRefresh(_ groupCount: Int, _ personCount: Int) {
        self.setTabbarBadge(with: 0, count: groupCount + personCount)
        UIApplication.shared.applicationIconBadgeNumber = groupCount + personCount
    }
    
    func applyUnreadRefresh(_ unreadCount: Int) {
        if IMSDK.shared().showWallet {
            self.setTabbarBadge(with: 2, count: unreadCount)
        } else {
            self.setTabbarBadge(with: 1, count: unreadCount)
        }
    }
}


extension ChatUIMediator: IMSDKLoginDelegate {
    func sdkLogin() {
        
    }
    func sdkLogout() {
        self.goLoginView()
        self.resetWalletVc()
    }
}


//extension ChatUIMediator: IMSDKCertificationDelegate {
//    func certification() {
//        if UIViewController.currentViewController()?.navigationController?.isKind(of: RTRootNavigationController.self) ?? false {
//            let vc = PWAuthHomeViewController.init()
//            vc.hidesBottomBarWhenPushed = true
//            UIViewController.currentViewController()?.navigationController?.pushViewController(vc, animated: true)
//        }
//    }
//}
