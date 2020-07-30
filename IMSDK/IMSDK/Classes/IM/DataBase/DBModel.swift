//
//  DBModel.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/5.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import Foundation
import SwiftyJSON
import WCDBSwift
import Photos


//MARK: 消息
class DBMessage: TableCodable {
    
    private var identify : Int?
    let msgId : String
    let localId : String
    let senderId : String
    let targetId : String
    let timestamp : Double
    let msgType : Int
    let channelType : Int
    let isSnap : Int
    let snapTime : Double
    let status : Int
    let showTime : Bool
    let jsonData : String
    let firstFrameImgData: Data
    let assetIdentifier: String
    let isEncryptMsg: Bool
    let isDeleted: Bool
    let isRead: Bool
    let contentForSearch: String
    let conversationId: String
    let upvote: String
    let fromKey: String
    let toKey: String
    let keyId: String

    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = DBMessage
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        case identify
        case msgId
        case localId
        case senderId
        case targetId
        case timestamp
        case msgType
        case channelType
        case isSnap
        case snapTime
        case status
        case showTime
        case jsonData
        case firstFrameImgData
        case assetIdentifier
        case isEncryptMsg
        case isDeleted
        case isRead
        case contentForSearch
        case conversationId
        case upvote
        case fromKey
        case toKey
        case keyId
        
        //Column constraints for primary key, unique, not null, default value and so on. It is optional.
        static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
            return [
                .identify : ColumnConstraintBinding(isPrimary: true, isAutoIncrement: true),
            ]
        }
    }
    var isAutoIncrement: Bool = false
    var lastInsertedRowID: Int64 = 0
    
    init(with message: SocketMessage) {
        msgId = message.msgId
        localId = message.sendMsgId
        senderId = message.fromId
        targetId = message.targetId
        timestamp = message.datetime
        msgType = message.msgType.rawValue
        channelType = message.channelType.rawValue
        status = message.status.rawValue
        jsonData = message.body.saveToJsonString()
        showTime = message.showTime
        isSnap = message.snap.rawValue
        snapTime = message.snapTime
        firstFrameImgData = message.body.firstFrameImgData
        assetIdentifier = message.body.asset?.localIdentifier ?? ""
        isEncryptMsg = message.isEncryptMsg
        isDeleted = message.isDeleted
        isRead = message.body.isRead
        contentForSearch = message.body.content
        conversationId = message.conversationId
        upvote = message.upvote.jsonString()
        fromKey = message.fromKey
        toKey = message.toKey
        keyId = message.keyId
    }
    
    class func updateProperties() -> [PropertyConvertible] {
        return [self.Properties.msgId,
                self.Properties.status,
                self.Properties.jsonData,
                self.Properties.showTime,
                self.Properties.isSnap,
                self.Properties.snapTime,
                self.Properties.firstFrameImgData,
                self.Properties.assetIdentifier,
                self.Properties.isEncryptMsg,
                self.Properties.isDeleted,
                self.Properties.isRead,
                self.Properties.contentForSearch,
                self.Properties.upvote,
                self.Properties.fromKey,
                self.Properties.toKey,
                self.Properties.keyId]
    }
}

extension SocketMessage {
    convenience init(with dbMsg: DBMessage) {
        self.init()
        msgId = dbMsg.msgId
        sendMsgId = dbMsg.localId
        fromId = dbMsg.senderId
        targetId = dbMsg.targetId
        datetime = dbMsg.timestamp
        showTime = dbMsg.showTime
        if let snapType = SocketMessageBurnType(rawValue: dbMsg.isSnap) {
            snap = snapType
        }
        snapTime = dbMsg.snapTime
        if let type = SocketMessageType(rawValue: dbMsg.msgType) {
            msgType = type
        }
        if let channel = SocketChannelType(rawValue: dbMsg.channelType) {
            channelType = channel
        }
        if let state = SocketMessageStatus(rawValue: dbMsg.status) {
            status = state
        }
        body = SocketMessageBody(with: dbMsg.jsonData, type: msgType)
        body.firstFrameImgData = dbMsg.firstFrameImgData
        body.asset = PHAsset.fetchAssets(withLocalIdentifiers: [dbMsg.assetIdentifier], options: nil).firstObject
        if (status != .succeed) && (msgType == .image) {
            if let data = FZMLocalFileClient.shared().readData(fileName: .jpg(fileName: body.localImagePath.fileName())) {
                body.imgData = data
            }
        }
        isEncryptMsg = dbMsg.isEncryptMsg
        isDeleted = dbMsg.isDeleted
        upvote = SocketMessageUpvote.init(json: JSON.init(parseJSON: dbMsg.upvote))
        fromKey = dbMsg.fromKey
        toKey = dbMsg.toKey
        keyId = dbMsg.keyId
        self.decryptAgain()
    }
}

class DBVirtualMessage: TableCodable {
    let msgId: String
    let content: String
    let conversationId: String
    enum CodingKeys: String, CodingTableKey {
        typealias Root = DBVirtualMessage
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        case msgId
        case content
        case conversationId
        static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
            return [
                .msgId : ColumnConstraintBinding(isPrimary: true, isAutoIncrement: false),
            ]
        }
        static var virtualTableBinding: VirtualTableBinding? {
            return VirtualTableBinding(with: .fts3, and: ModuleArgument(with: .WCDB))
        }
    }
    
    init?(dbMessage: DBMessage) {
        guard let type = SocketMessageType(rawValue: dbMessage.msgType) else { return nil }
        var msgConten = ""
        if type == .text {
            msgConten = dbMessage.contentForSearch
        } else if type == .forward {
            msgConten = SocketMessageBody(with: dbMessage.jsonData, type: type).forwardMsgs.compactMap { $0.msgType == .text ? $0.body.content : nil }.joined()
        }
        guard !msgConten.isEmpty, dbMessage.isSnap == SocketMessageBurnType.none.rawValue else { return nil }
        content = msgConten
        msgId = !dbMessage.msgId.isEmpty ? dbMessage.msgId : dbMessage.localId
        conversationId = dbMessage.conversationId
        
    }
}


//MARK: 好友会话
class DBUserConversation: TableCodable {
    private var identify : Int?
    var conversationId : String = "" // 对话人的id
    var noDisturbing : Int = 2 //免打扰
    var onTop : Bool = false //置顶
    var msgDate : Double = 0
    var lastMsgId = ""
    var unreadCount = 0
    var type : Int = 3
    var isAtMe = false
    var allUpvote = ""
    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = DBUserConversation
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        case identify
        case conversationId
        case noDisturbing
        case onTop
        case msgDate
        case lastMsgId
        case unreadCount
        case type
        case isAtMe
        case allUpvote
        
        //Column constraints for primary key, unique, not null, default value and so on. It is optional.
        static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
            return [
                .identify : ColumnConstraintBinding(isPrimary: true, isAutoIncrement: true),
            ]
        }
        
        static var tableConstraintBindings: [TableConstraintBinding.Name: TableConstraintBinding]? {
            let multiUniqueBinding =
                MultiUniqueBinding(indexesBy: conversationId, type)
            return [
                "MultiUniqueConstraint": multiUniqueBinding
            ]
        }
    }
    var isAutoIncrement: Bool = false
    var lastInsertedRowID: Int64 = 0
    
    init(with message: SocketMessage) {
        conversationId = message.conversationId
        msgDate = message.datetime
        lastMsgId = message.useId
        type = message.channelType.rawValue
    }
    
    init(with conversation: SocketConversationModel) {
        conversationId = conversation.conversationId
        if let message = conversation.lastMsg {
            msgDate = message.datetime
            lastMsgId = message.useId
        }
        onTop = conversation.onTop
        noDisturbing = conversation.noDisturbing.rawValue
        unreadCount = conversation.unreadCount
        type = conversation.type.rawValue
        isAtMe = conversation.isAtMe
        allUpvote = conversation.allUpvote.jsonString()
    }
    
    class func updateProperties() -> [PropertyConvertible] {
        return [self.Properties.msgDate,
                self.Properties.lastMsgId,
                self.Properties.onTop,
                self.Properties.noDisturbing,
                self.Properties.unreadCount,
                self.Properties.isAtMe,
                self.Properties.allUpvote,]
    }
}


//MARK: 用户
class DBContactUser: TableCodable {
    
    private var identify : Int?
    var userId : String = ""
    var showId : String = ""
    var avatar : String = ""
    var userName : String = ""
    var userRemark : String = ""
    var noDisturbing : Int = 2 //免打扰
    var commonlyUsed : Int = 1 //常用联系人级别
    var onTop : Bool = false //置顶
    var position : String = "" //职位
    var isFriend : Bool = false
    var requestDate : Date = Date()
    var needConfirm : Bool = false
    var needAnswer : Bool = false
    var question : String = ""
    var depositAddress: String = ""
    var publicKey = ""
    var identification = false
    var identificationInfo = ""
    var isBlocked = false
    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = DBContactUser
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        case identify
        case userId
        case showId
        case avatar
        case userName
        case userRemark
        case noDisturbing
        case commonlyUsed
        case onTop
        case position
        case isFriend
        case requestDate
        case needConfirm
        case needAnswer
        case question
        case depositAddress
        case publicKey
        case identification
        case identificationInfo
        case isBlocked
        
        //Column constraints for primary key, unique, not null, default value and so on. It is optional.
        static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
            return [
                .identify : ColumnConstraintBinding(isPrimary: true, isAutoIncrement: true),
            ]
        }
    }
    var isAutoIncrement: Bool = false
    var lastInsertedRowID: Int64 = 0
    
    init(with user: IMUserModel) {
        userId = user.userId
        showId = user.showId
        avatar = user.avatar
        userName = user.name
        userRemark = user.remark
        noDisturbing = user.noDisturbing.rawValue
        commonlyUsed = user.commonlyUsed.rawValue
        onTop = user.onTop
        position = user.position
        isFriend = user.isFriend && !user.isDelete
        requestDate = user.requestDate
        needConfirm = user.needConfirm
        needAnswer = user.needAnswer
        question = user.question
        depositAddress = user.depositAddress
        publicKey = user.publicKey
        identification = user.identification
        identificationInfo = user.identificationInfo
        isBlocked = user.isBlocked
    }
    
    class func updateProperties() -> [PropertyConvertible] {
        return [
            self.Properties.userId,
            self.Properties.showId,
            self.Properties.avatar,
            self.Properties.userName,
            self.Properties.userRemark,
            self.Properties.noDisturbing,
            self.Properties.commonlyUsed,
            self.Properties.onTop,
            self.Properties.position,
            self.Properties.isFriend,
            self.Properties.requestDate,
            self.Properties.needConfirm,
            self.Properties.needAnswer,
            self.Properties.question,
            self.Properties.depositAddress,
            self.Properties.publicKey,
            self.Properties.identification,
            self.Properties.identificationInfo,
            self.Properties.isBlocked,]
    }
}

extension IMUserModel {
    
    convenience init(with dbUser: DBContactUser) {
        self.init()
        userId = dbUser.userId
        showId = dbUser.showId
        avatar = dbUser.avatar
        name = dbUser.userName
        remark = dbUser.userRemark
        if let ndb = IMDisturbingType(rawValue: dbUser.noDisturbing) {
            noDisturbing = ndb
        }
        if let common = IMCommonlyType(rawValue: dbUser.commonlyUsed) {
            commonlyUsed = common
        }
        onTop = dbUser.onTop
        position = dbUser.position
        isFriend = dbUser.isFriend
        requestDate = dbUser.requestDate
        needConfirm = dbUser.needConfirm
        depositAddress = dbUser.depositAddress
        publicKey = dbUser.publicKey
        identification = dbUser.identification
        identificationInfo = dbUser.identificationInfo
        isBlocked = dbUser.isBlocked
    }
    
}


class DBGroupModel: TableCodable {
    private var identify : Int?
    var groupId = ""
    var showId = ""
    var name = ""
    var avatar = ""
    var noDisturbing : Int = 2 //免打扰
    var commonlyUsed : Int = 1 //常用联系人级别
    var onTop = false //置顶
    
    init(groupModel: IMGroupModel) {
        groupId = groupModel.groupId
        showId = groupModel.showId
        name = groupModel.name
        avatar = groupModel.avatar
        noDisturbing = groupModel.noDisturbing.rawValue
        commonlyUsed = groupModel.commonlyUsed.rawValue
        onTop = groupModel.onTop
    }
    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = DBGroupModel
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        case identify
        case groupId
        case showId
        case name
        case avatar
        case noDisturbing
        case commonlyUsed
        case onTop
        //Column constraints for primary key, unique, not null, default value and so on. It is optional.
        static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
            return [
                .identify : ColumnConstraintBinding(isPrimary: true, isAutoIncrement: true),
            ]
        }
    }
    
    var isAutoIncrement: Bool = false
    var lastInsertedRowID: Int64 = 0
    
    class func updateProperties() -> [PropertyConvertible] {
        return [self.Properties.groupId,
                self.Properties.showId,
                self.Properties.name,
                self.Properties.avatar,
                self.Properties.noDisturbing,
                self.Properties.commonlyUsed,
                self.Properties.onTop,]
    }
}

extension IMGroupModel {
    convenience init(dbGroupModel: DBGroupModel) {
        self.init()
        groupId = dbGroupModel.groupId
        showId = dbGroupModel.showId
        name = dbGroupModel.name
        avatar = dbGroupModel.avatar
        noDisturbing = IMDisturbingType(rawValue: dbGroupModel.noDisturbing) ?? .close
        commonlyUsed = IMCommonlyType(rawValue: dbGroupModel.commonlyUsed) ?? .normal
        onTop = dbGroupModel.onTop
    }
}


class DBGroupUserInfoModel: TableCodable {
    private var identify : Int?
    let userId: String
    let publicKey: String
    let nickname: String
    let groupNickname: String
    let avatar: String
    let memberLevel: Int
    let showName: String
    let lastTime: Double
    let groupId: String
    let deadline: Double
    let bannedType: Int
    let identification: Bool
    let friendRemark: String
    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = DBGroupUserInfoModel
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        case identify
        case userId
        case publicKey
        case nickname
        case groupNickname
        case avatar
        case memberLevel
        case showName
        case lastTime
        case groupId
        case deadline
        case bannedType
        case identification
        case friendRemark
        //Column constraints for primary key, unique, not null, default value and so on. It is optional.
        static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
            return [
                .identify : ColumnConstraintBinding(isPrimary: true, isAutoIncrement: true),
            ]
        }
    }
    
    var isAutoIncrement: Bool = false
    var lastInsertedRowID: Int64 = 0
    
    class func updateProperties() -> [PropertyConvertible] {
        return [self.Properties.userId,
                self.Properties.publicKey,
                self.Properties.nickname,
                self.Properties.groupNickname,
                self.Properties.avatar,
                self.Properties.memberLevel,
                self.Properties.showName,
                self.Properties.lastTime,
                self.Properties.groupId,
                self.Properties.deadline,
                self.Properties.bannedType,
                self.Properties.identification,
                self.Properties.friendRemark,]
    }
    
    init(groupUserInfoModel: IMGroupUserInfoModel) {
        self.userId = groupUserInfoModel.userId
        self.publicKey = groupUserInfoModel.publicKey
        self.nickname = groupUserInfoModel.nickname
        self.groupNickname = groupUserInfoModel.groupNickname
        self.avatar = groupUserInfoModel.avatar
        self.memberLevel = groupUserInfoModel.memberLevel.rawValue
        self.showName = groupUserInfoModel.showName
        self.lastTime = groupUserInfoModel.lastTime.timestamp
        self.groupId = groupUserInfoModel.groupId
        self.deadline = groupUserInfoModel.deadline
        self.bannedType = groupUserInfoModel.bannedType.rawValue
        self.identification = groupUserInfoModel.identification
        self.friendRemark = groupUserInfoModel.friendRemark
    }
}

extension IMGroupUserInfoModel {
    convenience init(dbGroupUserInfoModel: DBGroupUserInfoModel) {
        self.init()
        self.userId = dbGroupUserInfoModel.userId
        self.publicKey = dbGroupUserInfoModel.publicKey
        self.nickname = dbGroupUserInfoModel.nickname
        self.groupNickname = dbGroupUserInfoModel.groupNickname
        self.avatar = dbGroupUserInfoModel.avatar
        self.memberLevel = IMGroupMemberLevel.init(rawValue: dbGroupUserInfoModel.memberLevel) ?? .normal
        self.lastTime = Date.init(timeIntervalSince1970: dbGroupUserInfoModel.lastTime)
        self.groupId = dbGroupUserInfoModel.groupId
        self.deadline = dbGroupUserInfoModel.deadline
        self.bannedType = IMGroupUserBannedType.init(rawValue:dbGroupUserInfoModel.bannedType) ?? .normal
        self.identification = dbGroupUserInfoModel.identification
        self.friendRemark = dbGroupUserInfoModel.friendRemark
        if let user = IMContactManager.shared().getContact(userId: self.userId),
            user.isFriend,
            !user.remark.isEmpty,
            user.remark != self.friendRemark {
            self.friendRemark = user.remark
            DispatchQueue.global().async { self.save() }
        }
    }
}

class DBGroupKey: TableCodable {
    private var identify : Int?
    let groupId: String
    let fromKey: String
    let key: String
    let keyId: String
    
    init(groupKey: FZMGroupKey) {
        self.groupId = groupKey.groupId
        self.fromKey = groupKey.fromKey
        self.key = groupKey.key
        self.keyId = groupKey.keyId
    }
    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = DBGroupKey
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        case identify
        case groupId
        case fromKey
        case key
        case keyId
        //Column constraints for primary key, unique, not null, default value and so on. It is optional.
        static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
            return [
                .identify : ColumnConstraintBinding(isPrimary: true, isAutoIncrement: true),
            ]
        }
    }
    class func updateProperties() -> [PropertyConvertible] {
        return [self.Properties.groupId,
                self.Properties.fromKey,
                self.Properties.key,
                self.Properties.keyId]
    }
}

extension FZMGroupKey {
    convenience init(dbGroupKey: DBGroupKey) {
        self.init(groupId: dbGroupKey.groupId, fromKey: dbGroupKey.fromKey, key: dbGroupKey.key, keyId: dbGroupKey.keyId)
    }
}
