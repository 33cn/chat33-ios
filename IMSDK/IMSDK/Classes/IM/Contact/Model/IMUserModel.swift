//
//  IMUserModel.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/17.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import SwiftyJSON

public class IMUserModel: NSObject, Comparable {

    var userId = ""
    var showId = ""
    var name = ""
    @objc public var avatar = ""
    var remark = ""
    var noDisturbing : IMDisturbingType = .close //免打扰
    var commonlyUsed : IMCommonlyType = .normal //常用联系人级别
    var onTop = false //置顶
    var position = "" //职位
    var isFriend = false
    var isDelete = false
    var requestDate = Date()
    var groupInfoList = [String: IMGroupUserInfoModel]()//用户在各个群的信息
    @objc public var showName : String{
        get{
            if isFriend && !isDelete {
                let showName = remark.count > 0 ? remark : name
                return showName.count > 20 ? showName.substring(to: 20) : showName
            }else {
                return name
            }
        }
    }
    var source = ""
    var needConfirm = false
    var needAnswer = false
    var question = ""
    var extRemark = UserExtRemark.init()
    @objc public var depositAddress = ""
    var publicKey = ""
    var identification = false
    var identificationInfo = ""
    var isBlocked = false //是否加入黑名单
    override init() {
        super.init()
    }
    
    init(with serverJson: JSON) {
        super.init()
        userId = serverJson["id"].stringValue
        showId = serverJson["uid"].stringValue
        name = serverJson["name"].stringValue.count > 0 ? serverJson["name"].stringValue : serverJson["username"].stringValue
        remark = serverJson["remark"].stringValue
        if let privateKey = IMLoginUser.shared().currentUser?.privateKey,
            let publicKey = IMLoginUser.shared().currentUser?.publicKey,
            let plainTextRemark = FZMEncryptManager.decryptSymmetric(privateKey: privateKey, publicKey: publicKey, ciphertext: Data.init(hex: remark)) {
            remark = String.init(data: plainTextRemark, encoding: .utf8) ?? remark
        }
        avatar = serverJson["avatar"].stringValue
        position = serverJson["position"].stringValue
        onTop = serverJson["stickyOnTop"].intValue == 1
        if let disturb = IMDisturbingType(rawValue: serverJson["noDisturbing"].intValue) {
            noDisturbing = disturb
        }
        if let common = IMCommonlyType(rawValue: serverJson["commonlyUsed"].intValue) {
            commonlyUsed = common
        }
//        if serverJson["isFriend"].intValue == 1 {
//            isFriend = true
//        }
//        if serverJson["isDelete"].intValue == 2 {
//            isDelete = true
//        }
        source = serverJson["source"].stringValue
        needConfirm = serverJson["needConfirm"].intValue == 1
        needAnswer = serverJson["needAnswer"].intValue == 1
        question = serverJson["question"].stringValue
        extRemark = UserExtRemark.init(with: serverJson["extRemark"])
        depositAddress = serverJson["depositAddress"].stringValue
        publicKey = serverJson["publicKey"].stringValue
        self.identification = serverJson["identification"].intValue == 1
        self.identificationInfo = serverJson["identificationInfo"].stringValue
//        self.isBlocked = serverJson["isBlocked"].intValue == 0 ? false : true
    }
    
//    func update(with user: IMUserModel) {
//        name = user.name
//        showId = user.showId
//        remark = user.remark
//        avatar = user.avatar
//        position = user.position
//        onTop = user.onTop
//        noDisturbing = user.noDisturbing
//        commonlyUsed = user.commonlyUsed
////        isFriend = user.isFriend
////        isDelete = user.isDelete
//        requestDate = user.requestDate
//        source = user.source
//        needConfirm = user.needConfirm
//        needAnswer = user.needAnswer
//        question = user.question
//        extRemark = user.extRemark
//        depositAddress = user.depositAddress
//        publicKey = user.publicKey
//        identification = user.identification
//        identificationInfo = user.identificationInfo
//        self.isBlocked = user.isBlocked
//    }
    
    public static func < (lhs: IMUserModel, rhs: IMUserModel) -> Bool {
        return lhs.showName < rhs.showName
    }
}

enum IMDisturbingType: Int {
    case open = 1 //开启
    case close = 2 //关闭
}

enum IMCommonlyType: Int {
    case normal = 1 //普通
    case often = 2 //经常
}

class UserExtRemark: NSObject {
    var pictureUrls = [String]()
    var telephones = [[String: String]]()
    var des = ""
    
    var isEmpty: Bool {
        return pictureUrls.isEmpty && telephones.isEmpty && des.isEmpty
    }
    
    override init() {
        super.init()
    }
    
    init(with extJson: JSON) {
        super.init()
        var extJson = extJson
        if let encryptExt = extJson["encrypt"].string,
            let privateKey = IMLoginUser.shared().currentUser?.privateKey,
            let publicKey = IMLoginUser.shared().currentUser?.publicKey,
            let plainTextExtRemark = FZMEncryptManager.decryptSymmetric(privateKey: privateKey, publicKey: publicKey, ciphertext: Data.init(hex: encryptExt)),
            let jsonObjec = try? JSONSerialization.jsonObject(with: plainTextExtRemark, options: []) {
            extJson = JSON.init(jsonObjec)
        }
        
        if let pics = extJson["pictures"].arrayObject as? [String] {
            pictureUrls = pics
        }
        if let tels = extJson["telephones"].arrayObject as? [[String: String]] {
            telephones = tels
        }
        des = extJson["description"].stringValue
    }
}
