//
//  IMDBManager.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/20.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import WCDBSwift

enum IMTableType: String {
    case user = "t_user"
    case message = "t_message"
    case conversation = "t_conversation"
    case groupKey = "t_groupKey"
    case groupUserInfo = "t_groupUserInfo"
    case virtualMessage = "t_virtualMessage"
}

class IMDBManager: NSObject {

    private static let sharedInstance = IMDBManager()

    class func shared() -> IMDBManager {
        return sharedInstance
    }
    
    class func launchDB() {
        _ = IMDBManager.shared()
    }

    private var db: Database = Database(withPath: "\(DocumentPath)visitor.db")
    private var dbFTS: Database = Database(withPath: "\(DocumentPath)visitorFTS.db")
    private let ftsQueue = DispatchQueue(label: "com.ftsQueue")

    override init() {
        super.init()
        self.create()
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .user)
    }

    private func create() {
        if IMLoginUser.shared().isLogin {
            createLoginUserDB()
        }else {
            createVisitorDB()
        }
    }

    private func createVisitorDB() {
        createDB(with: "visitor")
    }

    private func createLoginUserDB() {
        createDB(with: IMLoginUser.shared().userId)
    }

    private func createDB(with name: String) {
        let documentPath = DocumentPath
        let path = documentPath + name + ".db"
        let pathFTS = documentPath + "FTS" + name + ".db"
        IMLog("---------------------\(path)")
        IMLog("---------------------\(pathFTS)")
        db = Database(withPath: path)
        dbFTS = Database(withPath: pathFTS)
        dbFTS.setTokenizes(.WCDB)
        createTable()
    }

    private func createTable() {
        do {
            //创建记录用户表
            try db.create(table: IMTableType.user.rawValue, of: DBContactUser.self)
            //创建聊天消息表
            try db.create(table: IMTableType.message.rawValue, of: DBMessage.self)
            //创建会话表
            try db.create(table: IMTableType.conversation.rawValue, of: DBUserConversation.self)
            try db.create(table: IMTableType.groupKey.rawValue, of: DBGroupKey.self)
            try db.create(table: IMTableType.groupUserInfo.rawValue, of: DBGroupUserInfoModel.self)
            try dbFTS.create(virtualTable: IMTableType.virtualMessage.rawValue, of: DBVirtualMessage.self)
        } catch let error {
            IMLog("-----------createTable error: \(error)")
        }
    }
    
    //批量插入
    func insertMore<Object: TableEncodable>(_ type: IMTableType, list: [Object]) {
        let tableName = type.rawValue
        IMLog("----insertmore-----")
        try? self.db.insert(objects: list, intoTable: tableName)
        if type == .message {
            self.insertVirtualMore(.virtualMessage, list: list)
        }
    }
    
    //插入或修改多条数据
    func insertOrUpdate<Object: TableEncodable>(_ type: IMTableType, list: [Object]) {
        list.forEach { (data) in
            self.insertOrUpdate(type, data: data)
        }
    }
    
    //插入或修改单条数据
    func insertOrUpdate<Object: TableEncodable>(_ type: IMTableType, data: Object) {
        let tableName = type.rawValue
        do {
            switch type {
            case .user:
                guard let data = data as? DBContactUser else { return }
                let objects : [DBContactUser] = self.queryData(type) { (condition) in
                    condition.condition = DBContactUser.Properties.userId.like(data.userId)
                    condition.limit = 1
                }
                if objects.count > 0 {
                    self.update(type, data: data) { (condition) in
                        condition.condition = DBContactUser.Properties.userId.like(data.userId)
                    }
                }else {
                    try db.insert(objects: data, intoTable: tableName)
                }
            case .message:
                guard let data = data as? DBMessage else { return }
                let queryCondition = data.localId.count > 0 ? DBMessage.Properties.localId.like(data.localId) : DBMessage.Properties.msgId.like(data.msgId)
                let objects : [DBMessage] = self.queryData(type) { (condition) in
                    condition.condition = queryCondition
                    condition.limit = 1
                }
                if objects.count > 0 {
                    self.update(type, data: data) { (condition) in
                        condition.condition = queryCondition
                    }
                }else {
                    try db.insert(objects: data, intoTable: tableName)
                }
                self.insertVirtualData(.virtualMessage, data: data)
            case .conversation:
                guard let data = data as? DBUserConversation else { return }
                let objects : [DBUserConversation] = self.queryData(type) { (condition) in
                    condition.condition = DBUserConversation.Properties.conversationId.like(data.conversationId) && DBUserConversation.Properties.type == data.type
                    condition.limit = 1
                }
                if objects.count > 0 {
                    self.update(type, data: data) { (condition) in
                        condition.condition = DBUserConversation.Properties.conversationId.like(data.conversationId) && DBUserConversation.Properties.type == data.type
                    }
                }else {
                    try db.insert(objects: data, intoTable: tableName)
                }
            case .groupKey:
                guard let data = data as? DBGroupKey else { return }
                let objects: [DBGroupKey] = self.queryData(type) { (condition) in
                    condition.condition = DBGroupKey.Properties.groupId.like(data.groupId) && DBGroupKey.Properties.keyId == data.keyId
                    condition.limit = 1
                }
                if objects.count > 0 {
                    self.update(type, data: data) { (condition) in
                        condition.condition = DBGroupKey.Properties.groupId.like(data.groupId) && DBGroupKey.Properties.keyId == data.keyId
                    }
                } else {
                    try db.insert(objects: data, intoTable: tableName)
                }
            case .groupUserInfo:
                guard let data = data as? DBGroupUserInfoModel else { return }
                let objects: [DBGroupUserInfoModel] = self.queryData(type) { (condition) in
                    condition.condition = DBGroupUserInfoModel.Properties.groupId.like(data.groupId) && DBGroupUserInfoModel.Properties.userId == data.userId
                    condition.limit = 1
                }
                if objects.count > 0 {
                    self.update(type, data: data) { (condition) in
                        condition.condition = DBGroupUserInfoModel.Properties.groupId.like(data.groupId) && DBGroupUserInfoModel.Properties.userId == data.userId
                    }
                } else {
                    try db.insert(objects: data, intoTable: tableName)
                }
            case .virtualMessage:
                break
            }
        } catch {
        }
    }
    
    //修改数据
    func update<Object: TableEncodable>(_ type: IMTableType, data: Object, conditionBlock: TableConditionBlock?) {
        let condition = TableCondition()
        conditionBlock?(condition)
        let tableName = type.rawValue
        do {
            switch type {
            case .user:
                try db.update(table: tableName, on: DBContactUser.updateProperties(), with: data, where: condition.condition, orderBy: condition.orderBy, limit: condition.limit, offset: condition.offset)
            case .message:
                try db.update(table: tableName, on: DBMessage.updateProperties(), with: data, where: condition.condition, orderBy: condition.orderBy, limit: condition.limit, offset: condition.offset)
            case .conversation:
                try db.update(table: tableName, on: DBUserConversation.updateProperties(), with: data, where: condition.condition, orderBy: condition.orderBy, limit: condition.limit, offset: condition.offset)
            case .groupKey:
                try db.update(table: tableName, on:DBGroupKey.updateProperties() , with: data, where: condition.condition, orderBy: condition.orderBy, limit: condition.limit, offset: condition.offset)
            case .groupUserInfo:
                try db.update(table: tableName, on:DBGroupUserInfoModel.updateProperties() , with: data, where: condition.condition, orderBy: condition.orderBy, limit: condition.limit, offset: condition.offset)
            case .virtualMessage:
                break
            }
            
        } catch {
            
        }
    }
    
    //查询数据
    func queryData<Object: TableCodable>(_ tableType: IMTableType, conditionBlock: TableConditionBlock? = nil) -> [Object] {
        let condition = TableCondition()
        conditionBlock?(condition)
        let tableName = tableType.rawValue
        let objects : [Object]?
        let db = tableType == .virtualMessage ? self.dbFTS : self.db
        objects = try? db.getObjects(on: Object.Properties.all,fromTable: tableName, where: condition.condition, orderBy: condition.orderBy, limit: condition.limit, offset: condition.offset)
        return objects ?? [Object]()
    }
    
    //删除数据
    func deleteData(_ tableType: IMTableType, conditionBlock: TableConditionBlock? = nil) {
        let condition = TableCondition()
        conditionBlock?(condition)
        try? db.delete(fromTable: tableType.rawValue, where: condition.condition, orderBy: condition.orderBy, limit: condition.limit, offset: condition.offset)
    }
    
}


extension IMDBManager {
    func deleteVirtualData(_ tableType: IMTableType, conditionBlock: TableConditionBlock? = nil) {
        self.ftsQueue.async {
            let condition = TableCondition()
            conditionBlock?(condition)
            try? self.dbFTS.delete(fromTable: tableType.rawValue, where: condition.condition, orderBy: condition.orderBy, limit: condition.limit, offset: condition.offset)
        }
    }
    
    func insertVirtualMore<Object: TableEncodable>(_ type: IMTableType, list: [Object]) {
        self.ftsQueue.async {
            if type == .virtualMessage, let list = list as? [DBMessage] {
                let virList = list.compactMap { return DBVirtualMessage.init(dbMessage: $0) }
                try? self.dbFTS.insert(objects: virList, intoTable: IMTableType.virtualMessage.rawValue)
            }
        }
    }
    
    func insertVirtualData<Object: TableEncodable>(_ type: IMTableType, data: Object) {
        self.ftsQueue.async {
            //data.snap == .burn
            if type == .virtualMessage, let dbMsg = data as? DBMessage ,let dbVirMsg = DBVirtualMessage.init(dbMessage: dbMsg) {
                try? self.dbFTS.delete(fromTable: IMTableType.virtualMessage.rawValue, where: DBVirtualMessage.Properties.msgId == dbMsg.localId || DBVirtualMessage.Properties.msgId == dbMsg.msgId)
                try? self.dbFTS.insert(objects: dbVirMsg, intoTable: IMTableType.virtualMessage.rawValue)
            }
        }
    }
    
}


typealias TableConditionBlock = (TableCondition)->()

class TableCondition {
    var condition : Condition?
    var orderBy : [OrderBy]?
    var limit : Limit?
    var offset : Offset?
}


//MARK: 面向
extension IMDBManager {
    
    func saveMoreMessage(_ type: IMTableType, list: [SocketMessage]) {
        let arr = list.compactMap { (model) -> DBMessage in
            return DBMessage(with: model)
        }
        self.insertMore(type, list: arr)
    }
    
    func save(_ type: IMTableType, list: [Any]) {
        list.forEach { (data) in
            self.save(type, data: data)
        }
    }
    
    func save(_ type: IMTableType, data: Any) {
        switch type {
        case .user:
            guard let data = data as? IMUserModel else { return }
            let model = DBContactUser(with: data)
            self.insertOrUpdate(type, data: model)
        case .message:
            guard let data = data as? SocketMessage else { return }
            let model = DBMessage(with: data)
            self.insertOrUpdate(type, data: model)
        case .conversation:
            guard let data = data as? SocketMessage else { return }
            let model = DBMessage(with: data)
            self.insertOrUpdate(type, data: model)
        case .groupKey:
            guard let data = data as? FZMGroupKey else { return }
            let model = DBGroupKey.init(groupKey:data)
            self.insertOrUpdate(type, data: model)
        case .groupUserInfo:
            guard let data = data as? IMGroupUserInfoModel else { return }
            let model = DBGroupUserInfoModel.init(groupUserInfoModel: data)
            self.insertOrUpdate(type, data: model)
        case .virtualMessage:
            break
        }
    }
}

extension FZMGroupKey {
    class func save(list: [FZMGroupKey]) {
        let arr = list.compactMap { (model) -> DBGroupKey? in
            return DBGroupKey.init(groupKey: model)
        }
        guard !arr.isEmpty else { return }
        IMDBManager.shared().insertMore(.groupKey, list: arr)
    }
    
    func save() {
        IMDBManager.shared().save(.groupKey, data: self)
    }
    
    class func getLatesGroupKey(groupId: String) -> FZMGroupKey? {
        let objects: [DBGroupKey] = IMDBManager.shared().queryData(.groupKey) { (condition) in
            condition.condition = DBGroupKey.Properties.groupId.like(groupId)
            condition.orderBy = [DBGroupKey.Properties.keyId.asOrder(by: .descending)]
            condition.limit = 1
        }
        if let dbGroupKey = objects.first {
            return FZMGroupKey.init(dbGroupKey: dbGroupKey)
        }
        return nil
    }
    
    class func getGroupKey(groupId: String, keyId: String) -> FZMGroupKey? {
        let objects: [DBGroupKey] = IMDBManager.shared().queryData(.groupKey) { (condition) in
            condition.condition = DBGroupKey.Properties.groupId.like(groupId) && DBGroupKey.Properties.keyId == keyId
            condition.limit = 1
        }
        if let dbGroupKey = objects.first {
            return FZMGroupKey.init(dbGroupKey: dbGroupKey)
        }
        return nil
    }
}

extension SocketMessage {
    
    class func save(_ list: [SocketMessage]) {
        guard !list.isEmpty else { return }
        list.forEach { (msg) in
            if msg.msgType == .notify, case .msgUpvoteUpdate(_, _, _, _, _,_) = msg.body.notifyEvent {
                 msg.isDeleted = true
            }
        }
        IMDBManager.shared().saveMoreMessage(.message, list: list)
    }
    
    func save() {
        if self.msgType == .notify, case .msgUpvoteUpdate(_, _, _, _, _,_) = self.body.notifyEvent {
            self.isDeleted = true
        }
        
        if let oldMsg = SocketMessage.getMsg(with: self.useId, conversationId: self.conversationId, conversationType: self.channelType) {
            self.update(by: oldMsg)
        }
        IMDBManager.shared().save(.message, data: self)
        if self.channelType == .person || self.channelType == .group {
            let conversation = DBUserConversation(with: self)
            IMDBManager.shared().insertOrUpdate(.conversation, data: conversation)
        }
    }
    func delete(){
        let result = self.deleteLocalFile()
        self.isDeleted = true
        self.save()
        IMDBManager.shared().deleteVirtualData(.virtualMessage) { (condition) in
            condition.condition = DBVirtualMessage.Properties.msgId == self.msgId || DBVirtualMessage.Properties.msgId == self.sendMsgId
        }
    }
    
    class func getMsgsCountToAck(begin: Double, end: Double) -> Int {
        let objects : [DBMessage] = IMDBManager.shared().queryData(.message) { (condition) in
            condition.condition = DBMessage.Properties.timestamp >= begin && DBMessage.Properties.timestamp < end && DBMessage.Properties.isSnap == SocketMessageBurnType.none.rawValue
        }
        return objects.count
    }
    
    class func ackMsgs(_ msgs:[SocketMessage]) -> [SocketMessage] {
        var lossMsgs = [SocketMessage].init()
        msgs.forEach { (msg) in
            let objects : [DBMessage] = IMDBManager.shared().queryData(.message) { (condition) in
                condition.condition =  (DBMessage.Properties.msgId.like(msg.msgId) || DBMessage.Properties.localId.like(msg.msgId)) && DBMessage.Properties.channelType == msg.channelType.rawValue
                condition.orderBy = [DBMessage.Properties.timestamp.asOrder(by: .descending)]
                condition.limit = 1
            }
            if objects.count == 0 {
                lossMsgs.append(msg)
            }
        }
        return lossMsgs
    }
    
    
    //根据id获取单条消息
    class func getMsg(with msgId: String, conversationId: String, conversationType: SocketChannelType) -> SocketMessage? {
        let objects : [DBMessage] = IMDBManager.shared().queryData(.message) { (condition) in
            if conversationType == .person {
                condition.condition =  (DBMessage.Properties.targetId.like(conversationId) || DBMessage.Properties.senderId.like(conversationId)) && DBMessage.Properties.channelType == conversationType.rawValue && (DBMessage.Properties.msgId.like(msgId) || DBMessage.Properties.localId.like(msgId)) && DBMessage.Properties.isDeleted != true
            }else {
                condition.condition =  DBMessage.Properties.targetId.like(conversationId) && DBMessage.Properties.channelType == conversationType.rawValue && (DBMessage.Properties.msgId.like(msgId) || DBMessage.Properties.localId.like(msgId)) && DBMessage.Properties.isDeleted != true
            }
            condition.limit = 1
        }
        if let dbMsg = objects.first {
            return SocketMessage(with: dbMsg)
        }
        return nil
    }
    // 获取时间大于等于指定msgId的所有msg
    class func getLocationMsg(with msgId: String, conversationId: String, conversationType: SocketChannelType) -> [SocketMessage] {
        if let msg = SocketMessage.getMsg(with: msgId, conversationId: conversationId, conversationType: conversationType) {
            let objects : [DBMessage] = IMDBManager.shared().queryData(.message) { (condition) in
                if conversationType == .person {
                    condition.condition =  (DBMessage.Properties.targetId.like(conversationId) || DBMessage.Properties.senderId.like(conversationId)) && DBMessage.Properties.channelType == conversationType.rawValue && DBMessage.Properties.timestamp >= msg.datetime && DBMessage.Properties.isDeleted != true
                }else {
                    condition.condition =  DBMessage.Properties.targetId.like(conversationId) && DBMessage.Properties.channelType == conversationType.rawValue && DBMessage.Properties.timestamp >= msg.datetime && DBMessage.Properties.isDeleted != true
                }
                condition.orderBy = [DBMessage.Properties.timestamp.asOrder(by: .descending)]
            }
            let msgs = objects.compactMap { SocketMessage(with: $0) }
            return msgs
        }
        return [SocketMessage]()
    }
    
    //根据起始时间和条数获取需要记录(不包含起始时间的list)
    class func getMsg(startTime: Double, conversationId: String, conversationType: SocketChannelType, count: Int) -> [SocketMessage] {
        let objects : [DBMessage] = IMDBManager.shared().queryData(.message) { (condition) in
            if conversationType == .person {
                condition.condition =  (DBMessage.Properties.targetId.like(conversationId) || DBMessage.Properties.senderId.like(conversationId)) && DBMessage.Properties.channelType == conversationType.rawValue && DBMessage.Properties.timestamp < startTime && DBMessage.Properties.isDeleted != true
            }else {
                condition.condition =  DBMessage.Properties.targetId.like(conversationId) && DBMessage.Properties.channelType == conversationType.rawValue && DBMessage.Properties.timestamp < startTime && DBMessage.Properties.isDeleted != true
            }
            condition.orderBy = [DBMessage.Properties.timestamp.asOrder(by: .descending)]
            condition.limit = count
        }
        var list = [SocketMessage]()
        objects.forEach { (dbMsg) in
            if dbMsg.timestamp != startTime {
                list.append(SocketMessage(with: dbMsg))
            }
        }
        return list
    }
    
    
    //根据会话获取最新一条消息
    class func getMsg(with type: SocketChannelType, conversationId: String) -> SocketMessage? {
        let objects : [DBMessage] = IMDBManager.shared().queryData(.message) { (condition) in
            if type == .person {
                condition.condition =  (DBMessage.Properties.targetId.like(conversationId) || DBMessage.Properties.senderId.like(conversationId)) && DBMessage.Properties.channelType == type.rawValue && DBMessage.Properties.isDeleted != true
            }else {
                condition.condition =  DBMessage.Properties.targetId.like(conversationId) && DBMessage.Properties.channelType == type.rawValue && DBMessage.Properties.isDeleted != true
            }
            condition.orderBy = [DBMessage.Properties.timestamp.asOrder(by: .descending)]
            condition.limit = 1
        }
        if let dbMsg = objects.first {
            return SocketMessage(with: dbMsg)
        }
        return nil
    }
    
    //获取最新的消息
    class func getNewestMsg() -> SocketMessage? {
        let objects : [DBMessage] = IMDBManager.shared().queryData(.message) { (condition) in
            condition.condition = DBMessage.Properties.isDeleted != true
            condition.orderBy = [DBMessage.Properties.timestamp.asOrder(by: .descending)]
            condition.limit = 1
        }
        if let dbMsg = objects.first {
            return SocketMessage(with: dbMsg)
        }
        return nil
    }
    
    class func getOldestMsgs() -> SocketMessage? {
        let objects : [DBMessage] = IMDBManager.shared().queryData(.message) { (condition) in
            condition.condition = DBMessage.Properties.isDeleted != true
            condition.orderBy = [DBMessage.Properties.timestamp.asOrder(by: .ascending)]
            condition.limit = 1
        }
        if let dbMsg = objects.first {
            return SocketMessage(with: dbMsg)
        }
        return nil
    }
    
    //根据会话获取最新一条消息
    class func getMsg(with type: SocketChannelType, conversationId: String, msgType: SocketMessageType) -> SocketMessage? {
        let objects : [DBMessage] = IMDBManager.shared().queryData(.message) { (condition) in
            if type == .person {
                condition.condition =  (DBMessage.Properties.targetId.like(conversationId) || DBMessage.Properties.senderId.like(conversationId)) && DBMessage.Properties.channelType == type.rawValue && DBMessage.Properties.msgType == msgType.rawValue && DBMessage.Properties.isDeleted != true
            }else {
                condition.condition =  DBMessage.Properties.targetId.like(conversationId) && DBMessage.Properties.channelType == type.rawValue && DBMessage.Properties.msgType == msgType.rawValue && DBMessage.Properties.isDeleted != true
            }
            condition.orderBy = [DBMessage.Properties.timestamp.asOrder(by: .descending)]
            condition.limit = 1
        }
        if let dbMsg = objects.first {
            return SocketMessage(with: dbMsg)
        }
        return nil
    }
    
    //根据会话获取最新的显示时间的一条消息
    class func getShowTimeMsg(with type: SocketChannelType, conversationId: String) -> SocketMessage? {
        let objects : [DBMessage] = IMDBManager.shared().queryData(.message) { (condition) in
            if type == .person {
                condition.condition =  (DBMessage.Properties.targetId.like(conversationId) || DBMessage.Properties.senderId.like(conversationId)) && DBMessage.Properties.channelType == type.rawValue && DBMessage.Properties.showTime == true && DBMessage.Properties.isDeleted != true
            }else {
                condition.condition =  DBMessage.Properties.targetId.like(conversationId) && DBMessage.Properties.channelType == type.rawValue && DBMessage.Properties.showTime == true && DBMessage.Properties.isDeleted != true
            }
            condition.orderBy = [DBMessage.Properties.timestamp.asOrder(by: .descending)]
            condition.limit = 1
        }
        if let dbMsg = objects.first {
            return SocketMessage(with: dbMsg)
        }
        return nil
    }
    
    //根据id获取消息
    class func getMsg(with type: SocketChannelType, msgId: String) -> SocketMessage? {
        let objects : [DBMessage] = IMDBManager.shared().queryData(.message) { (condition) in
            condition.condition =  (DBMessage.Properties.msgId.like(msgId) || DBMessage.Properties.localId.like(msgId)) && DBMessage.Properties.channelType == type.rawValue && DBMessage.Properties.isDeleted != true
            condition.orderBy = [DBMessage.Properties.timestamp.asOrder(by: .descending)]
            condition.limit = 1
        }
        if let dbMsg = objects.first {
            return SocketMessage(with: dbMsg)
        }
        return nil
    }
    
    //获取会话所有各类型消息
    class func getAllMsg(with type: SocketChannelType, conversationId: String, msgType: SocketMessageType) -> [SocketMessage] {
        let objects : [DBMessage] = IMDBManager.shared().queryData(.message) { (condition) in
            if type == .person {
                condition.condition =  (DBMessage.Properties.targetId.like(conversationId) || DBMessage.Properties.senderId.like(conversationId)) && DBMessage.Properties.channelType == type.rawValue && DBMessage.Properties.msgType == msgType.rawValue && DBMessage.Properties.isDeleted != true
            }else {
                condition.condition =  DBMessage.Properties.targetId.like(conversationId) && DBMessage.Properties.channelType == type.rawValue && DBMessage.Properties.msgType == msgType.rawValue && DBMessage.Properties.isDeleted != true
            }
            condition.orderBy = [DBMessage.Properties.timestamp.asOrder(by: .ascending)]
        }
        var list = [SocketMessage]()
        objects.forEach { (dbMsg) in
            list.append(SocketMessage(with: dbMsg))
        }
        return list
    }
    
    
    //获取阅后即焚完成倒计时消息
    class func getBurnMsgs() -> [SocketMessage] {
        let time = Date.timestamp
        let objects : [DBMessage] = IMDBManager.shared().queryData(.message) { (condition) in
            condition.condition = DBMessage.Properties.isSnap == 3 && DBMessage.Properties.snapTime < time && DBMessage.Properties.snapTime > 0 && DBMessage.Properties.isDeleted != true
            condition.orderBy = [DBMessage.Properties.timestamp.asOrder(by: .ascending)]
        }
        var list = [SocketMessage]()
        objects.forEach { (dbMsg) in
            list.append(SocketMessage(with: dbMsg))
        }
        return list
    }
    
    class func getNextUnreadVoiceMsg(timestamp: Double, type: SocketChannelType, conversationId: String) -> SocketMessage? {
        //DBMessage.Properties.msgType == SocketMessageType.audio.rawValue
        let objects : [DBMessage] = IMDBManager.shared().queryData(.message) { (condition) in
            if type == .person {
                condition.condition = (DBMessage.Properties.targetId.like(conversationId) || DBMessage.Properties.senderId.like(conversationId)) && DBMessage.Properties.channelType == type.rawValue && DBMessage.Properties.senderId != IMLoginUser.shared().userId && (DBMessage.Properties.timestamp > timestamp && DBMessage.Properties.isRead == false && DBMessage.Properties.msgType == SocketMessageType.audio.rawValue) && DBMessage.Properties.isDeleted != true
            }else {
                condition.condition = DBMessage.Properties.targetId.like(conversationId) && DBMessage.Properties.channelType == type.rawValue && DBMessage.Properties.senderId != IMLoginUser.shared().userId && (DBMessage.Properties.timestamp > timestamp && DBMessage.Properties.isRead == false && DBMessage.Properties.msgType == SocketMessageType.audio.rawValue) && DBMessage.Properties.isDeleted != true
            }
            condition.orderBy = [DBMessage.Properties.timestamp.asOrder(by: .ascending)]
            condition.limit = 1
        }
        if let dbMsg = objects.first {
            return SocketMessage(with: dbMsg)
        }
        return nil
    }
    
    class func isHaveAtMeMsgInConversation(conversationId: String, unreadMsgCount: Int) -> Bool {
        let objects : [DBMessage] = IMDBManager.shared().queryData(.message) { (condition) in
            condition.condition =  DBMessage.Properties.targetId.like(conversationId) && DBMessage.Properties.channelType == SocketChannelType.group.rawValue && DBMessage.Properties.isDeleted != true
            condition.orderBy = [DBMessage.Properties.timestamp.asOrder(by: .descending)]
            condition.limit = unreadMsgCount
        }
        var msg: SocketMessage
        var isHaveAtMe = false
        for i in 0..<objects.count {
            msg = SocketMessage.init(with: objects[i])
            if msg.fromId != IMLoginUser.shared().userId &&
                (msg.body.aitList.contains("-1") ||
                msg.body.aitList.contains(IMLoginUser.shared().userId)) {
                isHaveAtMe = true
                break
            }
        }
        return isHaveAtMe
    }
    
    class func searchMsg(searchString: String, conversationId: String? = nil) -> [SocketMessage] {
        let objects: [DBVirtualMessage] = IMDBManager.shared().queryData(.virtualMessage) { (condition) in
            if let conversationId = conversationId {
                condition.condition = DBVirtualMessage.Properties.conversationId == conversationId && DBVirtualMessage.Properties.content.match(searchString + "*")
            } else {
                condition.condition = DBVirtualMessage.Properties.content.match(searchString + "*")
            }
        }
        if !objects.isEmpty {
            let dbMessages: [DBMessage] = IMDBManager.shared().queryData(.message) { (condition) in
                condition.condition = DBMessage.Properties.msgId.in(objects.compactMap {$0.msgId}) || DBMessage.Properties.localId.in(objects.compactMap {$0.msgId})
                condition.orderBy = [DBMessage.Properties.timestamp.asOrder(by: .descending)]
            }
            return dbMessages.compactMap { SocketMessage.init(with: $0)}
        }
        return [SocketMessage]()
    }
    
}

extension IMUserModel {
    
    class func save(list: [IMUserModel]) {
        let array = list.compactMap { (userModel) -> DBContactUser? in
            return DBContactUser(with: userModel)
        }
        guard !array.isEmpty else { return }
        IMDBManager.shared().save(.user, list: array)
    }
    
    func save() {
        IMDBManager.shared().save(.user, data: self)
    }
    
    class func getAll() -> [IMUserModel] {
        let objects : [DBContactUser] = IMDBManager.shared().queryData(.user)
        let list = objects.map { (dbUser) -> IMUserModel in
            return IMUserModel(with: dbUser)
        }
        return list
    }
}

extension SocketConversationModel {
    class func getAll(with type: SocketChannelType) -> [SocketConversationModel] {
        let objects : [DBUserConversation] = IMDBManager.shared().queryData(.conversation) { (condition) in
            condition.condition = DBUserConversation.Properties.type == type.rawValue
            condition.orderBy = [DBUserConversation.Properties.msgDate.asOrder(by: .descending)]
        }
        let list = objects.map { (dbConversation) -> SocketConversationModel in
            return SocketConversationModel(dbConversation: dbConversation)
        }
        
        return list
    }
    
    class func getUnreadCount(with type: SocketChannelType, conversationId: String) -> Int {
        var unreadCount = 0
        let objects : [DBUserConversation] = IMDBManager.shared().queryData(.conversation) { (condition) in
            condition.condition = DBUserConversation.Properties.type == type.rawValue && DBUserConversation.Properties.conversationId == conversationId
            condition.orderBy = [DBUserConversation.Properties.msgDate.asOrder(by: .descending)]
        }
        if let object = objects.first {
            unreadCount = object.unreadCount
        }
        return unreadCount
    }
    
    func update() {
        if self.type == .person || self.type == .group {
            let dbConversation : DBUserConversation = DBUserConversation(with: self)
            IMDBManager.shared().insertOrUpdate(.conversation, data: dbConversation)
        }
    }
    
    func delete() {
        IMDBManager.shared().deleteData(.conversation) { (condition) in
            condition.condition = DBUserConversation.Properties.type == self.type.rawValue && DBUserConversation.Properties.conversationId.like(self.conversationId)
        }
    }
    
    
}


extension IMGroupUserInfoModel {
    class func saveGroupMemberList(list: [IMGroupUserInfoModel], groupId: String) {
        let arr = list.filter{ $0.groupId == groupId}.compactMap { (model) -> DBGroupUserInfoModel? in
            return DBGroupUserInfoModel.init(groupUserInfoModel: model)
        }
        guard !arr.isEmpty else { return }
        IMDBManager.shared().deleteData(.groupUserInfo) { (condition) in
            condition.condition = DBGroupUserInfoModel.Properties.groupId == groupId
        }
        IMDBManager.shared().insertMore(.groupUserInfo, list: arr)
    }
    
    class func getGroupMemberList(groupId: String) -> [IMGroupUserInfoModel]? {
        let objects : [DBGroupUserInfoModel] = IMDBManager.shared().queryData(.groupUserInfo) { (condition) in
            condition.condition = DBGroupUserInfoModel.Properties.groupId == groupId
        }
        let list = objects.map { (dbGroupUserInfoModel) -> IMGroupUserInfoModel in
            return IMGroupUserInfoModel.init(dbGroupUserInfoModel: dbGroupUserInfoModel)
        }
        return list.isEmpty ? nil : list
    }
    
    func save() {
        IMDBManager.shared().save(.groupUserInfo, data: self)
    }
    
    func delete() {
        IMDBManager.shared().deleteData(.groupUserInfo) { (condition) in
            condition.condition = DBGroupUserInfoModel.Properties.groupId == self.groupId && DBGroupUserInfoModel.Properties.userId.like(self.userId)
        }
    }
}

extension IMDBManager: UserInfoChangeDelegate {
    func userLogin() {
        self.create()
    }
    func userLogout() {
        db.close()
        db = Database(withPath: "\(DocumentPath)visitor.db")
        dbFTS.close()
        dbFTS = Database(withPath: "\(DocumentPath)visitorFTS.db")
    }
    func userInfoChange() {

    }
}
