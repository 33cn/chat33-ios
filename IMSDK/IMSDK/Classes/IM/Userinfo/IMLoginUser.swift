//
//  IMLoginUser.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/5.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import SwiftyJSON
import KeychainAccess

let userInfoFilePath = DocumentPath + "imuserInfo"

public class IMLoginUser: NSObject {

    private static let sharedInstance = IMLoginUser()
    
    @objc public class func shared() -> IMLoginUser {
        return sharedInstance
    }
    
    override init() {
        super.init()
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: userInfoFilePath) {
            if let dic = NSDictionary.init(contentsOfFile: userInfoFilePath) as? [String:Any] {
                let json = JSON(dic)
                let user = UserInfoModel(with: json)
                self.currentUser = user
            }
        }
    }
    
    @objc public var currentUser : UserInfoModel?
    
    var isLogin : Bool {
        return currentUser == nil ? false : true
    }
    
    var userId : String {
        if isLogin {
            return currentUser!.userId
        }
        return ""
    }
    
    var showId : String {
        if isLogin {
            return currentUser!.showId
        }
        return ""
    }
    
    
    func loginWithUser(user: UserInfoModel) {
        currentUser = user
        self.saveUserInfo(with: user)
        IMNotifyCenter.shared().postMessage(event: .userLogin)
        self.getWorkUser()
    }
    
    func getWorkUser() {
        if app_id == "1001" {
            HttpConnect.shared().moduleState { (response) in
                if let array = response.data?["modules"].arrayValue {
                    array.forEach({ (json) in
                        if json["type"].intValue == 2 && json["enable"].boolValue {
                            HttpConnect.shared().getWorkUserInfo { (workUser, response) in
                                if response.success, let workUser = workUser {
                                    self.currentUser?.workUser = workUser
                                    self.refreshUserInfo()
                                }
                            }
                        }
                    })
                }
            }
        }
    }
    
    func saveUserInfo(with user: UserInfoModel) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: userInfoFilePath) {
            try? fileManager.removeItem(atPath: userInfoFilePath)
        }
        let dic = user.mapToDic() as NSDictionary
        let result = dic.write(toFile: userInfoFilePath, atomically: true)
        if result {
            IMLog("保存用户信息成功")
        }else{
            IMLog("保存用户信息失败")
        }
        IMNotifyCenter.shared().postMessage(event: .userInfoRefresh)
    }
    
    func refreshUserInfo() {
        guard let user = self.currentUser else { return }
        self.saveUserInfo(with: user)
    }
    
     @objc public func clearUserInfo() {
        if self.isLogin {
            FZM_UserDefaults.removeObject(forKey: ESCROW_IS_AUTH)
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: userInfoFilePath) {
                try? fileManager.removeItem(atPath: userInfoFilePath)
            }
            currentUser = nil
            IMNotifyCenter.shared().postMessage(event: .userLogout)
        }
    }
    
}

public class UserInfoModel: NSObject {
    var userId = ""
    var showId = ""
    var userName = ""
    @objc public var token = ""
    var avatar = ""
    var account = ""
    var securityAccount : String{
        if account.contains("@"){
            return account
        }
        if account.count > 11 {
            let str = account as NSString
            return str.replacingCharacters(in: NSMakeRange(5, 4), with: "****")
        }
        return ""
    }
    var sessionId = "" //socket使用
    var isSetPayPwd = false
    @objc public var phone = ""
    @objc public var phoneNoArea: String {
        get {
            if phone.count == 13 {
                return (phone as NSString).substring(from: 2)
            } else if phone.count == 11 {
                return phone
            } else {
                return ""
            }
        }
    }
    @objc public var depositAddress = ""
    
    var pubKeyOnServer = ""
    
    private var pubKey = ""
    private var priKey = ""
    var publicKey: String {
        get {
            if (self.pubKey.isEmpty) {
                return self.getPublicKey()
            } else {
                return pubKey
            }
        }
    }

    var privateKey: String {
        get {
            if (self.priKey.isEmpty) {
                return self.getPrivateKey()
            } else {
                return priKey
            }
        }
    }
    
    var code = ""
    var identification = false
    var identificationInfo = ""
    var seedInServer = "" //保存在服务器上的私钥
    var workUser: FZMWorkUser? = nil
    
    init(with json: JSON) {
        super.init()
        self.userId = json["id"].stringValue
        self.showId = json["uid"].stringValue
        self.userName = json["username"].stringValue
        self.token = json["token"].stringValue
        self.avatar = json["avatar"].stringValue
        self.account = json["account"].stringValue
        self.sessionId = json["sessionId"].stringValue
        self.isSetPayPwd = json["isSetPayPwd"].intValue == 0 ? false : true
        self.phone = json["phone"].stringValue
        self.depositAddress = json["depositAddress"].stringValue
        self.pubKeyOnServer = json["publicKey"].stringValue
        if self.pubKeyOnServer.count > 2, self.pubKeyOnServer.substring(to: 1) != "0x" {
            self.pubKeyOnServer = "0x" + self.pubKeyOnServer
        }
        self.code = app_id != "1004" ? json["code"].stringValue : ""
        self.identification = json["identification"].intValue == 1
        self.identificationInfo = json["identificationInfo"].stringValue
        self.seedInServer = json["privateKey"].stringValue
        self.workUser = FZMWorkUser.init(dic: json["workUser"].dictionaryValue)
        
    }
    
    func mapToDic() -> [String:Any] {
        return ["id":userId,
                "uid":showId,
                "username":userName,
                "token":token,
                "avatar":avatar,
                "account":account,
                "sessionId":sessionId,
                "isSetPayPwd":isSetPayPwd,
                "phone":phone,
                "depositAddress":depositAddress,
                "publicKey":pubKeyOnServer,
                "code":code,
                "identification":identification ? 1 : 0,
                "identificationInfo":identificationInfo,
                "privateKey": seedInServer,
                "workUser": self.workUser?.mapToDic() ?? [:],
        ]
    }
    @objc public func createSeed(isChinses: Bool, pwd: String) -> Bool {
        if let seed = isChinses ? ChatapiNewMnemonicString(1, 160, nil) : ChatapiNewMnemonicString(0, 128, nil) {
            self.setSeed(pwd: pwd , seed: seed)
            return true
        }
        return false
    }
    
    func setEncryptChatWithUser(userId: String, isEncrypt:Bool) {
        FZM_UserDefaults.set(isEncrypt, forKey: self.userId + "isEncrypt" + userId)
        FZM_UserDefaults.synchronize()

    }
    
    func isEncryptChatWithUser(_ user: IMUserModel) -> Bool {
        guard IMSDK.shared().isEncyptChat else { return false }
        if self.privateKey.isEmpty || self.publicKey.isEmpty || user.publicKey.isEmpty {
            return false
        }
        if let isEncrypt = FZM_UserDefaults.value(forKey: self.userId + "isEncrypt" + user.userId) as? Bool {
            return isEncrypt
        }
        return !self.privateKey.isEmpty && !self.publicKey.isEmpty && !user.publicKey.isEmpty
    }
    
    @objc public func setPrivateKey(_ priKey:String, pubKey:String) {
        guard self.priKey != priKey, self.pubKey != pubKey else { return }
        if let _ = try? Keychain.init().set(priKey, key: self.userId + "priKey"),
            let _ = try? Keychain.init().set(pubKey, key: self.userId + "pubKey") {
            self.priKey = priKey
            self.pubKey = pubKey
            FZNEncryptKeyManager.shared().updataUserPublicKey(pubKey)
            self.pubKeyOnServer = publicKey
            self.showId = FZMEncryptManager.publicKeyToAddress(publicKey: publicKey)
            IMContactManager.shared().clearAllFriendsCache()
            DispatchQueue.main.async {
                IMLoginUser.shared().refreshUserInfo()
            }
        }
    }
    
    private func getPublicKey() -> String {
        if let pubKey = try? Keychain.init().getString((self.userId + "pubKey")) {
            self.pubKey = pubKey
        }
        return self.pubKey
    }
    
    private func getPrivateKey() -> String {
        if let priKey = try? Keychain.init().getString((self.userId + "priKey")) {
            self.priKey = priKey
        }
        return self.priKey
    }
    
    @objc public func setSeed(pwd:String,seed:String) {
        if let encSeed = ChatapiSeedEncKey(ChatapiEncPasswd(pwd), ChatapiStringTobyte(seed, nil), nil) {
            do {
                try Keychain.init().set(encSeed, key: self.userId + "seed")
                self.createKeyBy(seed: seed)
                if let seedString = ChatapiByteTohex(encSeed) {
                    FZNEncryptKeyManager.shared().updataUserPublicKey(self.publicKey, seed: seedString) { (resonse) in
                        if resonse.success {
                            self.seedInServer = seedString
                            IMLoginUser.shared().refreshUserInfo()
                        }
                    }
                }
            } catch let error {
                IMLog(error)
            }
        }
    }
    
    func getSeed(pwd: String) -> String? {
        if let encSeed = self.getCiphertextSeed() {
            var error: NSError?
            let seed = ChatapiByteTostring(ChatapiSeedDecKey(ChatapiEncPasswd(pwd), encSeed, &error))
            return error == nil ? seed : nil
            
        }
        return nil
    }
    
    private func createKeyBy(seed: String) {
        if let wallet = ChatapiNewWalletFromMnemonic_v2("BTY", seed, nil),
            let pubKeyData = try? wallet.newKeyPub(0),
            let priKeyData = try? wallet.newKeyPriv(0),
            let priKey = ChatapiByteTohex(priKeyData),
            let pubKey = ChatapiByteTohex(pubKeyData) {
            self.setPrivateKey(priKey, pubKey: pubKey)
        }
    }
    
    private func getCiphertextSeed() -> Data? {
        if let encSeed = try? Keychain.init().getData(self.userId + "seed") {
            return encSeed
        }
        return nil
    }
    
    func setGroupKey(groupId: String, fromKey: String, key: String, keyId: String) {
        let groupKey = FZMGroupKey.init(groupId: groupId, fromKey: fromKey, key: key, keyId: keyId)
        groupKey.save()
    }
    func getLatestGroupKey(groupId: String) -> FZMGroupKey? {
        if let latestGroupKey = FZMGroupKey.getLatesGroupKey(groupId: groupId) {
            return latestGroupKey
        }
        return nil
    }
    
    func getGroupKey(groupId: String, keyId: String) -> FZMGroupKey? {
        if let groupKey = FZMGroupKey.getGroupKey(groupId: groupId, keyId: keyId) {
            return groupKey
        }
        return nil
    }
    
    func setAckMsgTime(timestamp: Int) {
        FZM_UserDefaults.setUserValue(timestamp, forKey: "AckMsgTime")
    }
    func getAckMsgTime() -> Int? {
        if let time = FZM_UserDefaults.getUserObject(forKey: "AckMsgTime") {
            return time as? Int
        } else {
            return nil
        }
    }
    
}
