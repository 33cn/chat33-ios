//
//  IMSDK.swift
//  IMSDK
//
//  Created by 吴文拼 on 2018/12/27.
//

import UIKit
import RxSwift
import KeychainAccess

//发布类型
@objc public enum Chat33Channel : Int {
    case AppleStore      = 0 //苹果商店
    case ThirdParty      = 1 //企业签名
}

//分享类型
@objc public enum IMSharePlatment : Int {
    case wxFriend //微信好友
    case wxTimeline //朋友圈
}

public class IMSDK: NSObject {
    
    private static let sharedInstance = IMSDK()
    
    @objc public class func shared() -> IMSDK {
        return sharedInstance
    }
    
    @objc public var channel: Chat33Channel = .AppleStore
    
    //MARK:页面配置
    //是否检查更新
    @objc public var isCheckVersion = true
    //是否展示发红包
    @objc public var showRedBag = false
    @objc public var showIdentification = false
    //是否展示分享
    @objc public var showShare = false
    @objc public var showWallet = false
    
    @objc public var isEncyptChat = true
    @objc public var showPromoteHotGroup = true
    
    //二维码中间图
    @objc public var qrCodeCenterIcon : UIImage?
    //二维码界面分享icon
    @objc public var shareIcon : UIImage?
    //二维码界面分享title
    @objc public var shareTitle : String?
    @objc public var appId: String {
        return app_id
    }
    
    //app启动是否检测更新
    @objc public var canUpdate = true
    
    @objc public weak var shareDelegate : IMSDKShareInfoDelegate?
    
    @objc public weak var loginDelegate : IMSDKLoginDelegate?
    
    @objc public weak var certificationDelegate : IMSDKCertificationDelegate?
    
    //MARK:获取登录用户信息
    //姓名
    @objc public var userName : String {
        return IMLoginUser.shared().currentUser?.userName ?? ""
    }
    //头像
    @objc public var avatar : String {
        return IMLoginUser.shared().currentUser?.avatar ?? ""
    }
    //头像
    @objc public var userId : String {
        return IMLoginUser.shared().userId
    }
    
    //MARK:版本号
    @objc public class func sdkVersion() -> String {
        return "2.6.1"
    }
    
    @objc public var configure :IMSDKConfigureModel? {
        return configureModel
    }
    
    private var configureModel :IMSDKConfigureModel?
    
    //MARK:根据配置启动SDK
    @objc public class func launchApp(_ configure: IMSDKConfigureModel) {
        let sdk = IMSDK.shared()
        sdk.configureModel = configure
        configure.configureInfo()
        //启动本地数据库
        IMDBManager.launchDB()
        //启动本地通讯录
        IMContactManager.launchClient()
        IMConversationManager.launchManager()
        //启动阿里云文件服务
        IMOSSClient.launchClient()
        //启动本地文件服务
        FZMLocalFileClient.launchClient()
        //启动socket
        SocketManager.launchManager()
        FZMUIMediator.launchManager()
        sdk.registerEvent()
        sdk.willEnterForeground()
    }
    
    private let disposeBag = DisposeBag()
    private func registerEvent() {
        //观察socket连接
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .socketConnect)
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .user)
        
        //未读数
        Observable.combineLatest(IMConversationManager.shared().groupUnreadCountSubject, IMConversationManager.shared().privateUnreadCountSubject).subscribe {[weak self] (event) in
            guard case .next(let groupUnreadCount, let privateUnreadCount) = event else { return }
            self?.refreshConversationUnread(groupCount: groupUnreadCount, personCount: privateUnreadCount)
            }.disposed(by: disposeBag)
        IMContactManager.shared().applyNumSubject.subscribe {[weak self] (event) in
            guard case .next(let count) = event else { return }
            self?.applyUnread(count: count)
            }.disposed(by: disposeBag)
        
        FZM_NotificationCenter.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        FZM_NotificationCenter.addObserver(self, selector: #selector(enterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    //唤醒
    @objc private func willEnterForeground() {
        IMNotifyCenter.shared().postMessage(event: .appWillEnterForeground)
    }
    //睡眠
    @objc private func enterBackground() {
        IMNotifyCenter.shared().postMessage(event: .appBackground)
    }
    
    //MARK: 代理中心
    var connectDelegateArr = [WeakIMSDKSocketConnectDelegate]()
    var unreadDelegateArr = [WeakIMSDKUnreadCountDelegate]()
    
}

extension IMSDK {
    @objc public func isUserSetShowWallet() -> Bool {
        guard IMLoginUser.shared().isLogin else { return false }
        guard IMLoginUser.shared().showId != "930" else { return false }//苹果审核账号
        let count = Int((try? Keychain.init().getString(CHAT33_USER_SHOW_WALLET_KEY)) ?? "0") ?? 0
        return count >= 20
    }
}

//MARK: 编辑用户信息
extension IMSDK {
    //编辑头像
    @objc public func editHeadImage(image: UIImage, completeBlock: NormalHandler?) {
        IMOSSClient.shared().uploadImage(file: image.jpegData(compressionQuality: 0.6)!, uploadProgressBlock: { (progress) in
            
        }) { (url, success) in
            if success, let url = url {
                HttpConnect.shared().editUserHeadImage(headImageUrl: url, completionBlock: completeBlock)
            }else{
                let response = HttpResponse(failMsg: "上传错误")
                completeBlock?(response)
            }
        }
    }
    //编辑用户名
    @objc public func editUsername(name: String, completeBlock: NormalHandler?) {
        HttpConnect.shared().editUserName(name: name, completionBlock: completeBlock)
    }
}

//MARK: 登录模块
extension IMSDK {
    //token登录
    @objc public func login(token: String, type: Int = 1, clientId: String = "", completeBlock: NormalHandler?) {
        HttpConnect.shared().userTokenLogin(token: token, type: type, clientId: "") { (user, response) in
            completeBlock?(response)
        }
    }
    
    //退出登录
    @objc public func logout() {
        HttpConnect.shared().logout(completionBlock: nil)
        IMLoginUser.shared().clearUserInfo()
    }
    
    //是否登录
    @objc public func isLogin() -> Bool {
        return IMLoginUser.shared().isLogin
    }
}

extension IMSDK {
    @objc public func setDeviceToken(_ deviceToken: String) {
        guard IMLoginUser.shared().isLogin else { return }
        HttpConnect.shared().setDeviceToken(deviceToken, completionBlock: nil)
    }
}


//MARK: 页面
extension IMSDK {
    @objc public func setHomeTab(with tab: UITabBarController) {
        FZMUIMediator.shared().homeTabbarVC = tab
    }
    
    //获取聊天主页面
    @objc public func getConversationNavigationController() -> UINavigationController {
        return FZMUIMediator.shared().getConversationNavigationController()
    }
    //获取通讯录主页面
    @objc public func getContactNavigationController() -> UINavigationController {
        return FZMUIMediator.shared().getContactNavigationController()
    }
    //获取个人中心主页面
    @objc public func getMeNavigationController() -> UINavigationController {
        return FZMUIMediator.shared().getMeNavigationController()
    }
    
}

extension IMSDK {
    @objc public class func getBundleImage(_ name: String) -> UIImage? {
        return GetBundleImage(name)
    }
}

//MARK: 解析链接
extension IMSDK {
    @objc public func parsingUrl(_ url: String) {
        FZMUIMediator.shared().parsingUrl(with: url)
    }
}


//MARK:启动sdk的配置信息
public class IMSDKConfigureModel: NSObject {
    @objc public var appId = "" //app标识
    @objc public var service = ""
    @objc public var serverIp = "" //服务器地址
    @objc public var contractIp = "" //合约地址
    @objc public var escrowIp = ""
    @objc public var socketIp = "" //socket服务地址
    @objc public var shareUrl = "" //二维码地址
    @objc public var ossIp = "" //阿里云链接地址
    @objc public var ossKey = "" //阿里云key
    @objc public var ossSecret = "" //阿里云secret
    @objc public var ossBuket = "" //阿里云文件路径
    @objc public var feedbackUrl = ""
    @objc public var aMapKey = "" //高德地图key
    
    @objc public var tintColor: UIColor?
    @objc public var oldTintColor: UIColor?
    @objc public var titleColor: UIColor?
    @objc public var backgroundColor: UIColor?
    @objc public var cCCColor: UIColor?
    @objc public var redColor: UIColor?
    @objc public var blackWordColor: UIColor?
    @objc public var grayWordColor: UIColor?
    @objc public var lineColor: UIColor?
    @objc public var shadowColor: UIColor?
    @objc public var orangeColor: UIColor?
    @objc public var whiteColor: UIColor?
    @objc public var eA6Color: UIColor?
    @objc public var transferBgColor: UIColor?
    @objc public var receiptBgColor: UIColor?
    @objc public var receiptDoneBgColor: UIColor?
    @objc public var luckyPacketColor: UIColor?
    
    fileprivate func configureInfo() {
        if appId.count > 0 {
            app_id = appId
        }
        if service.count > 0 {
            FZM_Service = service
        }
        if ossIp.count > 0 {
            OSS_End_Point = ossIp
        }
        if ossKey.count > 0 {
            OSS_Access_Key = ossKey
        }
        if ossSecret.count > 0 {
            OSS_Access_Secret = ossSecret
        }
        if ossBuket.count > 0 {
            OSS_Buket = ossBuket
        }
        if serverIp.count > 0 {
            NetworkDomain = serverIp
        }
        if contractIp.count > 0 {
            ContractDomain = contractIp
        }
        if escrowIp.count > 0 {
            EscrowDomain = escrowIp
        }
        if socketIp.count > 0 {
            SocketServer = socketIp
        }
        if shareUrl.count > 0 {
            qrCodeShareUrl = shareUrl
        }
        if feedbackUrl.count > 0  {
            FeedbackUrl = feedbackUrl
        }
        if aMapKey.count > 0 {
            
        }
        if let tintColor = tintColor {
            FZM_TintColor = tintColor
        }
        if let oldTintColor = oldTintColor {
            FZM_OldTintColor = oldTintColor
        }
        if let titleColor = titleColor {
            FZM_TitleColor = titleColor
        }
        if let backgroundColor = backgroundColor {
            FZM_BackgroundColor = backgroundColor
        }
        if let cCCColor = cCCColor {
            FZM_CCCColor = cCCColor
        }
        if let redColor = redColor {
            FZM_RedColor = redColor
        }
        if let blackWordColor = blackWordColor {
            FZM_BlackWordColor = blackWordColor
        }
        if let grayWordColor = grayWordColor {
            FZM_GrayWordColor = grayWordColor
        }
        if let lineColor = lineColor {
            FZM_LineColor = lineColor
        }
        if let shadowColor = shadowColor {
            FZM_ShadowColor = shadowColor
        }
        if let orangeColor = orangeColor {
            FZM_OrangeColor = orangeColor
        }
        if let whiteColor = whiteColor {
            FZM_WhiteColor = whiteColor
        }
        if let eA6Color = eA6Color {
            FZM_EA6Color = eA6Color
        }
        if let transferBgColor = transferBgColor {
            FZM_TransferBgColor = transferBgColor
        }
        if let receiptBgColor = receiptBgColor {
            FZM_ReceiptBgColor = receiptBgColor
        }
        if let receiptDoneBgColor = receiptDoneBgColor {
            FZM_ReceiptDoneBgColor = receiptDoneBgColor
        }
        if let luckyPacketColor = luckyPacketColor {
            FZM_LuckyPacketColor = luckyPacketColor
        }
    }
    
}

extension IMSDK: SocketConnectDelegate, UserInfoChangeDelegate {
    func userLogin() {
        IMSDK.shared().loginDelegate?.sdkLogin()
    }
    
    func userLogout() {
        IMSDK.shared().loginDelegate?.sdkLogout()
    }
    
    func userInfoChange() {
        
    }
    
    func socketConnect() {
        self.connect(true)
    }
    
    func socketDisConnect() {
        self.connect(false)
    }
    
    
}
