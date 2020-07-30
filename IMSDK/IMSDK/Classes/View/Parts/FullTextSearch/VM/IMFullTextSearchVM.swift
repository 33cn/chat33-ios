//
//  IMFullTextSearchVM.swift
//  IMSDK
//
//  Created by .. on 2019/9/20.
//

import UIKit
import RxSwift

class IMFullTextSearchVM: NSObject {
    let type: FZMFullTextSearchType
    let typeId: String
    var avatar: String
    var name: String
    let remark: String
    let msgs: [SocketMessage]
    var showName: String {
        switch type {
        case .friend:
            return remark.isEmpty ? name : remark
        case .group:
            return name
        case .chatRecord:
            return name
        case .all:
            return ""
        }
    }
    
    let nameSubject = BehaviorSubject<String?>.init(value: nil)
    let avatarSubject = BehaviorSubject<String?>.init(value: nil)
    
    init(type: FZMFullTextSearchType, typeId: String , avatar: String, name: String, remark: String, msgs:[SocketMessage] = [SocketMessage]() ) {
        self.type = type
        self.typeId = typeId
        self.avatar = avatar
        self.name = name
        self.remark = remark
        self.msgs = msgs
        if !self.name.isEmpty {
            self.nameSubject.onNext(self.name)
        }
        if !self.avatar.isEmpty {
            self.avatarSubject.onNext(self.avatar)
        }
    }
    
    convenience init(friend: IMUserModel) {
        self.init(type: .friend, typeId: friend.userId ,avatar: friend.avatar, name: friend.name , remark: friend.remark)
    }
    
    convenience init(group: IMGroupModel) {
        self.init(type: .group, typeId: group.groupId, avatar: group.avatar, name: group.name , remark: "")
    }
    
    convenience init?(msgs: [SocketMessage]) {
        guard  let msg = msgs.first else { return nil }
        let remark = msgs.count == 1 ? msg.body.content : "\(msgs.count)条相关聊天记录"
        self.init(type: .chatRecord(specificId: nil), typeId: msg.conversationId, avatar: "", name: "" , remark: remark, msgs: msgs)
        if msg.channelType == .person || (msg.channelType == .group && msgs.count == 1) {
            IMContactManager.shared().requestUserModel(with: msg.fromId) { (user, _, _) in
                guard let user = user else { return }
                self.avatar = user.avatar
                self.name = user.showName
                self.nameSubject.onNext(self.name)
                self.avatarSubject.onNext(self.avatar)
            }
        }else if msg.channelType == .group {
            IMConversationManager.shared().getGroup(with: msg.conversationId) { (model) in
                self.name = model.name
                self.avatar = model.avatar
                self.nameSubject.onNext(self.name)
                self.avatarSubject.onNext(self.avatar)
            }
        }
    }
    
    static func > (lhs: IMFullTextSearchVM, rhs: IMFullTextSearchVM) -> Bool {
        
        if case FZMFullTextSearchType.chatRecord(_) = lhs.type, case FZMFullTextSearchType.chatRecord(_) = rhs.type {
            return lhs.msgs.first?.datetime ?? 0 > rhs.msgs.first?.datetime ?? 0
        }
        return true
    }
    
}
