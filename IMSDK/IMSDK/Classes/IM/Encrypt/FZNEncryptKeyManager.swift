//
//  FZNEncryptKeyManager.swift
//  IMSDK
//
//  Created by .. on 2019/6/27.
//

import UIKit
import Starscream
import RTRootNavigationController

class FZNEncryptKeyManager: NSObject {
    private static let sharedInstance = FZNEncryptKeyManager()
    class func shared() -> FZNEncryptKeyManager {
        return sharedInstance
    }
    class func launch() {
        _ = FZNEncryptKeyManager.shared()
    }
    
    private override init() {
        super.init()
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .user)
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .appState)
    }

    func refreshUserPublicKey(_ publicKey: String) {
        guard IMSDK.shared().isEncyptChat else { return }
        guard !publicKey.isEmpty else { return }
        var dic = [String: Any]()
        dic["eventType"] = SocketEventType.updataUserPublicKey.rawValue
        dic["publicKey"] =  publicKey
        SocketManager.shared().sendInfoToServer(with: dic)
    }
    
    func updataUserPublicKey(_ publicKey: String, seed: String, completionBlock: NormalHandler?) {
        HttpConnect.shared().updataUserPublicKey(publicKey, seed: seed, completionBlock: completionBlock)
    }
    
    func updataUserPublicKey(_ publicKey: String) {
        guard IMSDK.shared().isEncyptChat else { return }
        self.refreshUserPublicKey(publicKey)
        self.updateAllEncryptGroupKey()
    }
    
    func updateAllEncryptGroupKey() {
        guard IMSDK.shared().isEncyptChat else { return }
        IMConversationManager.shared().groupList.forEach { (group) in
            self.updataGroupKey(groupId: group.groupId)
        }
    }
    
    func updataGroupKey(groupId: String) {
        guard IMSDK.shared().isEncyptChat,
            let myUserId = IMLoginUser.shared().currentUser?.userId,
            let myPublickKey = IMLoginUser.shared().currentUser?.publicKey,
            !myPublickKey.isEmpty
        else { return }
        IMConversationManager.shared().getGroup(with: groupId) { (group) in
            guard group.isEncryptGroup else {return}
            IMConversationManager.shared().getServerGroupMemberList(groupId: groupId) { (list, response) in
                guard response.success, !list.isEmpty else { return }
                DispatchQueue.global().async {
                    var encryptUsers = ([String](),[String]())
                    list.forEach({ (user) in
                        if !user.publicKey.isEmpty && !user.userId.isEmpty {
                            encryptUsers.0.append(user.userId)
                            encryptUsers.1.append(user.userId == myUserId ? myPublickKey : user.publicKey)
                        }
                    })
                    self.updataGroupKey(groupId: groupId, encryptUsers: encryptUsers)
                }
            }
        }
    }
    
    private func updataGroupKey(groupId: String, encryptUsers: ([String],[String])) {
        guard IMSDK.shared().isEncyptChat else { return }
        DispatchQueue.global().async {
            guard let priKey = IMLoginUser.shared().currentUser?.privateKey,
                let pubKey = IMLoginUser.shared().currentUser?.publicKey,
                let key = String.randomHexStr(len: 64).data(using: .utf8),
                groupId.count > 0,
                encryptUsers.0.count == encryptUsers.1.count,
                encryptUsers.0.count > 0
                else { return }
            
            var dic = [String: Any]()
            dic["eventType"] = SocketEventType.updataGroupKey.rawValue
            dic["roomId"] =  groupId
            dic["fromKey"] = pubKey
            var secret = [[String: Any]]()
            
            for i in 0..<encryptUsers.0.count {
                let userId = encryptUsers.0[i]
                let pubKey = encryptUsers.1[i]
                if let encryptedKey = FZMEncryptManager.encryptSymmetric(privateKey: priKey, publicKey: pubKey, plaintext: key)?.toHexString() {
                    secret.append(["userId": userId, "key": encryptedKey])
                }
            }
            
            guard secret.count > 0 else { return }
            dic["secret"] = secret
            SocketManager.shared().sendInfoToServer(with: dic)
        }
    }
}

extension FZNEncryptKeyManager: UserInfoChangeDelegate {
    func userLogin() {
        guard IMSDK.shared().isEncyptChat, let loginUser = IMLoginUser.shared().currentUser else { return }
        HttpConnect.shared().getRoomSessionKey(completionBlock: nil)
        if loginUser.seedInServer.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                FZMUIMediator.shared().pushVC(.goSetSeedPwd(isShowForget: false))
            }
        } else {
            if loginUser.publicKey.isEmpty || loginUser.publicKey != loginUser.pubKeyOnServer {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                    FZMUIMediator.shared().pushVC(.goSetSeedPwd(isShowForget: true))
                }
            }
        }
    }
    
    func userLogout() {
    }
    func userInfoChange() {
        
    }
}

extension FZNEncryptKeyManager: AppActiveDelegate {
    func appEnterBackground() {
    }
    func appWillEnterForeground() {
        guard IMSDK.shared().isEncyptChat,IMLoginUser.shared().isLogin, let loginUser = IMLoginUser.shared().currentUser else { return }
        HttpConnect.shared().getRoomSessionKey(completionBlock: nil)
        if loginUser.seedInServer.isEmpty {
            FZMUIMediator.shared().pushVC(.goSetSeedPwd(isShowForget: false))
        } else {
            if loginUser.publicKey.isEmpty || loginUser.publicKey != loginUser.pubKeyOnServer {
                FZMUIMediator.shared().pushVC(.goSetSeedPwd(isShowForget: true))
            }
        }
    }
}
