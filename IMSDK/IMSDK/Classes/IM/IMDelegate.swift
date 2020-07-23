//
//  IMDelegate.swift
//  IMSDK
//
//  Created by 吴文拼 on 2018/12/29.
//

import Foundation

@objc public enum IMSDKDelegateEventType: Int {
    case connect
    case unreadCount
}

extension IMSDK {
    @objc public func addDelegate(with delegate: NSObject, event: IMSDKDelegateEventType) {
        switch event {
        case .connect:
            if let delegate = delegate as? IMSDKSocketConnectDelegate {
                self.connectDelegateArr.append(WeakIMSDKSocketConnectDelegate(delegate: delegate))
            }
        case .unreadCount:
            if let delegate = delegate as? IMSDKUnreadCountDelegate {
                self.unreadDelegateArr.append(WeakIMSDKUnreadCountDelegate(delegate: delegate))
            }
        }
    }
    
    //连接状态
    func connect(_ status: Bool) {
        self.connectDelegateArr.forEach { (delegator) in
            if status {
                if let delegate = delegator.delegate, delegate.responds(to: #selector(delegate.socketConnect)) {
                    delegate.socketConnect()
                }
            }else {
                if let delegate = delegator.delegate, delegate.responds(to: #selector(delegate.socketDisConnect)) {
                    delegate.socketDisConnect()
                }
            }
        }
    }
    
    //消息未读数
    func refreshConversationUnread(groupCount: Int, personCount: Int) {
        self.unreadDelegateArr.forEach { (delegator) in
            if let delegate = delegator.delegate, delegate.responds(to: #selector(delegate.conversationUnreadRefresh(_:_:))) {
                delegate.conversationUnreadRefresh(groupCount, personCount)
            }
        }
    }
    //申请未读数
    func applyUnread(count: Int) {
        self.unreadDelegateArr.forEach { (delegator) in
            if let delegate = delegator.delegate, delegate.responds(to: #selector(delegate.applyUnreadRefresh(_:))) {
                delegate.applyUnreadRefresh(count)
            }
        }
    }
    
}

//MARK:Socket连接情况
@objc public protocol IMSDKSocketConnectDelegate: NSObjectProtocol {
    //已连接
    func socketConnect()
    //断开连接
    func socketDisConnect()
}

class WeakIMSDKSocketConnectDelegate: NSObject {
    weak var delegate: IMSDKSocketConnectDelegate?
    required init(delegate: IMSDKSocketConnectDelegate?) {
        self.delegate = delegate
        super.init()
    }
}


//MARK:未读数
@objc public protocol IMSDKUnreadCountDelegate: NSObjectProtocol {
    //聊天未读数
    func conversationUnreadRefresh(_ groupCount: Int, _ personCount: Int)
    //申请未处理数
    func applyUnreadRefresh(_ unreadCount: Int)
}
class WeakIMSDKUnreadCountDelegate: NSObject {
    weak var delegate: IMSDKUnreadCountDelegate?
    required init(delegate: IMSDKUnreadCountDelegate?) {
        self.delegate = delegate
        super.init()
    }
}

//MARK: 分享
@objc public protocol IMSDKShareInfoDelegate: NSObjectProtocol {
    //分享二维码
    func shareQRCode(url: String, image: UIImage, platment: IMSharePlatment)
    func shareWeb(url: String,title: String,content: String,platment: IMSharePlatment)
    func share(image:UIImage, platment: IMSharePlatment)
    func share(text:String, platment: IMSharePlatment)
    func shareRedBag(url: String,coinName:String, platment: IMSharePlatment)
    
}

//MARK:登录
@objc public protocol IMSDKLoginDelegate: NSObjectProtocol {
    func sdkLogin()
    func sdkLogout()
}

//MARK:登录
@objc public protocol IMSDKCertificationDelegate: NSObjectProtocol {
    func certification()
}
