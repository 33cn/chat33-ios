//
//  IMGroupModel.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/29.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import SwiftyJSON

class IMGroupModel: NSObject {

    var groupId = ""
    var showId = ""
    var name = ""
    var avatar = ""
    var noDisturbing : IMDisturbingType = .close //免打扰
    var commonlyUsed : IMCommonlyType = .normal //常用联系人级别
    var onTop = false //置顶
    
    override init() {
        super.init()
    }
    
    init(with serverJson: JSON) {
        super.init()
        groupId = serverJson["id"].stringValue
        showId = serverJson["markId"].stringValue
        name = serverJson["name"].stringValue
        avatar = serverJson["avatar"].stringValue
        onTop = serverJson["onTop"].intValue == 1
        if let disturb = IMDisturbingType(rawValue: serverJson["noDisturbing"].intValue) {
            noDisturbing = disturb
        }
        if let common = IMCommonlyType(rawValue: serverJson["commonlyUsed"].intValue) {
            commonlyUsed = common
        }
    }
    
    static func < (lhs: IMGroupModel, rhs: IMGroupModel) -> Bool {
        return lhs.name < rhs.name
    }
}

class IMGroupDetailInfoModel: NSObject {
    
    var groupId = ""
    var showId = ""
    var name = ""
    var avatar = ""
    var groupNickname = ""
    var notifyList = [IMGroupNotifyModel]()
    var notifyNum = 0
    var noDisturbing : IMDisturbingType = .close //免打扰
    var commonlyUsed : IMCommonlyType = .normal //常用联系人级别
    var onTop = false //置顶
    var memberLevel : IMGroupMemberLevel = .normal
    var memberNumber = 0
    var canAddFriend = false
    var recordPermission = false
    var joinPermission : IMGroupJoinPermission = .notNeed
    var myBannedType : IMGroupUserBannedType = .normal
    var mutedNumber = 0
    var bannedType : IMGroupBannedType = .all
    var users = [IMGroupUserInfoModel]()
    var master : IMGroupUserInfoModel?
    var disableDeadline: Int = 0
    var isMaster : Bool{
        return memberLevel == .owner
    }
    var isManager : Bool{
        return memberLevel == .manager
    }
    var managerNumber = 0
    var showName : String {
        if name.count > 0 {
            return name.count > 20 ? name.substring(to: 20) : name
        }else {
            let str = users.reduce("") {
                return $0 + "\($1.groupNickname)、"
            }
            return str
        }
    }
    
    var disableGroupInfo: String {
        get {
            if disableDeadline != 0 {
                let forever: Int64 = 7258089600000
                if disableDeadline == forever {
                     return "该群聊已被永久查封，如需解封可联系客服：" + FZM_Service
                }
                let date = Date.init(timeIntervalSince1970: TimeInterval(disableDeadline / 1000))
                let formatter = DateFormatter.init()
                formatter.dateFormat = "yyyy年MM月dd号HH:mm"
                let dateStr = formatter.string(from: date)
                return "该群聊已被查封至\(dateStr)，如需解封可联系客服：" + FZM_Service
            }
            return ""
        }
    }
    
    var isEncryptGroup = false
    
    var identification = false
    var identificationInfo = ""
    
    init(with serverJson: JSON) {
        super.init()
        groupId = serverJson["id"].stringValue
        showId = serverJson["markId"].stringValue
        name = serverJson["name"].stringValue
        avatar = serverJson["avatar"].stringValue
        groupNickname = serverJson["roomNickname"].stringValue
        if groupNickname.count == 0, let user = IMLoginUser.shared().currentUser {
            groupNickname = user.userName
        }
        let list = serverJson["systemMsg"]["list"].arrayValue.compactMap({ (notifyJson) -> IMGroupNotifyModel? in
            return IMGroupNotifyModel(with: notifyJson)
        })
        notifyList = list.sorted(by: >)
        notifyNum = serverJson["systemMsg"]["number"].intValue
        onTop = serverJson["onTop"].intValue == 1
        if let disturb = IMDisturbingType(rawValue: serverJson["noDisturbing"].intValue) {
            noDisturbing = disturb
        }
        if let common = IMCommonlyType(rawValue: serverJson["commonlyUsed"].intValue) {
            commonlyUsed = common
        }
        if let level = IMGroupMemberLevel(rawValue: serverJson["memberLevel"].intValue) {
            memberLevel = level
        }
        memberNumber = serverJson["memberNumber"].intValue
        canAddFriend = serverJson["canAddFriend"].intValue == 1
        recordPermission = serverJson["recordPermission"].intValue == 1
        if let permission = IMGroupJoinPermission(rawValue: serverJson["joinPermission"].intValue) {
            joinPermission = permission
        }
        if let banned = IMGroupBannedType(rawValue: serverJson["roomMutedType"].intValue) {
            bannedType = banned
        }
        if let myBanned = IMGroupUserBannedType(rawValue: serverJson["mutedType"].intValue) {
            myBannedType = myBanned
        }
        mutedNumber = serverJson["mutedNumber"].intValue
        if let arr = serverJson["users"].array {
            arr.forEach { (json) in
                users.append(IMGroupUserInfoModel(with: json, groupId: groupId))
            }
        }
        users.forEach { (user) in
            if user.memberLevel == .owner {
                master = user
            }
            if user.memberLevel == .manager {
                managerNumber += 1
            }
        }
        disableDeadline = serverJson["disableDeadline"].intValue
        isEncryptGroup = serverJson["encrypt"].intValue == 1 ? true : false
        
        identification = serverJson["identification"].intValue == 1
        identificationInfo = serverJson["identificationInfo"].stringValue
        self.decryptGroupName()
    }
    
    func update(with group: IMGroupDetailInfoModel) {
        name = group.name
        avatar = group.avatar
        onTop = group.onTop
        noDisturbing = group.noDisturbing
        commonlyUsed = group.commonlyUsed
        memberLevel = group.memberLevel
        memberNumber = group.memberNumber
        canAddFriend = group.canAddFriend
        recordPermission = group.recordPermission
        joinPermission = group.joinPermission
        bannedType = group.bannedType
        myBannedType = group.myBannedType
        mutedNumber = group.mutedNumber
        users = group.users
        disableDeadline = group.disableDeadline
        master = group.master
        managerNumber = group.managerNumber
        notifyNum = group.notifyNum
        notifyList = group.notifyList
        groupNickname = group.groupNickname
        isEncryptGroup = group.isEncryptGroup
        identification = group.identification
        identificationInfo = group.identificationInfo
    }
    
    var bannedDescription : String {
        var str = ""
        switch self.bannedType {
        case .blackMap:
            str = "\(self.mutedNumber)人已禁言"
        case .whiteMap:
            str = "\(self.mutedNumber)人可发言"
        case .bannedAll:
            str = "全员禁言"
        case .all:
            str = "全员发言"
        }
        return str
    }
}

extension IMGroupDetailInfoModel {
    func decryptGroupName() {
        guard name.isEncryptString() else { return }
        if name.isEncryptString() {
            let spt = name.components(separatedBy: String.getEncryptStringPrefix())
            if spt.count == 3 {
                let showName = spt[0]
                let keyId = spt[1]
                if let groupKey = IMLoginUser.shared().currentUser?.getGroupKey(groupId: self.groupId, keyId: keyId),
                    let key = groupKey.plainTextKey,
                    let plaintext = FZMEncryptManager.decryptSymmetric(key: key, ciphertext: Data.init(hex: showName)),
                    let plaintextName = String.init(data: plaintext, encoding: .utf8) {
                    name = plaintextName
                    //名字不是使用最新群秘钥加密 更新群名
                    if let latestGroupKey = IMLoginUser.shared().currentUser?.getLatestGroupKey(groupId: groupId),
                        latestGroupKey.keyId != keyId {
                        self.updateEncryptName()
                    }
                }
            }
        }
    }
    func updateEncryptName() {
        guard !name.isEncryptString() else { return }
        if (isMaster || isManager),
            let latestGroupKey = IMLoginUser.shared().currentUser?.getLatestGroupKey(groupId: groupId),
            let latestKey = latestGroupKey.plainTextKey,
            let plainText = name.data(using: .utf8),
            let ciphertext = FZMEncryptManager.encryptSymmetric(key: latestKey, plaintext: plainText) {
            IMConversationManager.shared().editGroupName(groupId: groupId, name: ciphertext.toHexString() + String.getEncryptStringPrefix() + latestGroupKey.keyId + String.getEncryptStringPrefix() + groupId, completionBlock: nil)
        }
    }
}

class IMGroupNotifyModel: NSObject, Comparable {
    var content = ""
    var datetime : Double = 0
    var msgId = ""
    var senderName = ""
    init(with serverJson: JSON) {
        super.init()
        content = serverJson["content"].stringValue
        datetime = serverJson["datetime"].doubleValue
        msgId = serverJson["logId"].stringValue
        senderName = serverJson["senderName"].stringValue
    }
    
    static func < (lhs: IMGroupNotifyModel, rhs: IMGroupNotifyModel) -> Bool {
        return lhs.datetime < rhs.datetime
    }
}

class IMGroupUserInfoModel: NSObject, Comparable {
    var userId = ""
    var publicKey = ""
    var nickname = ""
    var groupNickname = ""
    var friendRemark = ""
    var avatar = ""
    var memberLevel : IMGroupMemberLevel = .normal
    var showName : String {
        return friendRemark.count > 0 ? friendRemark : (groupNickname.count > 0 ? groupNickname : nickname)
    }
    var lastTime = Date()
    var groupId = ""
    var deadline : Double = 0
    var bannedType : IMGroupUserBannedType = .normal
    var identification = false
    
    override init() {
        super.init()
    }
    
    init(with serverJson: JSON, groupId: String) {
        super.init()
        userId = serverJson["id"].stringValue
        publicKey = serverJson["publicKey"].stringValue
        nickname = serverJson["nickname"].stringValue
        groupNickname = serverJson["roomNickname"].stringValue
        avatar = serverJson["avatar"].stringValue
        if let level = IMGroupMemberLevel(rawValue: serverJson["memberLevel"].intValue) {
            memberLevel = level
        }
        self.groupId = groupId
        deadline = serverJson["deadline"].doubleValue
        if let banned = IMGroupUserBannedType(rawValue: serverJson["mutedType"].intValue) {
            bannedType = banned
        }
        identification = serverJson["identification"].intValue == 1
        if let user = IMContactManager.shared().getContact(userId: userId),
            user.isFriend,
            !user.remark.isEmpty {
            friendRemark = user.remark
        }
    }
    
    static func < (lhs: IMGroupUserInfoModel, rhs: IMGroupUserInfoModel) -> Bool {
        return lhs.showName < rhs.showName
    }
}

enum IMGroupMemberLevel: Int {
    case none = 0
    case normal = 1
    case manager = 2
    case owner = 3
}

enum IMGroupJoinPermission: Int {
    case need = 1
    case notNeed = 2
    case forbid = 3
    
    func getDescriptionStr() -> String {
        switch self {
        case .need:
            return "需要审批"
        case .notNeed:
            return "无需审批"
        case .forbid:
            return "禁止加群"
        }
    }
}

enum IMGroupBannedType: Int {
    case all = 1 //全员发言
    case blackMap = 2 //黑名单
    case whiteMap = 3 //白名单
    case bannedAll = 4//全员禁言
    
    func getDescriptionStr() -> String {
        switch self {
        case .all:
            return "全员发言"
        case .blackMap:
            return "黑名单"
        case .whiteMap:
            return "白名单"
        case .bannedAll:
            return "全员禁言"
        }
    }
}

enum IMGroupUserBannedType: Int {
    case normal = 1
    case blackMap = 2
    case whiteMap = 3
}


