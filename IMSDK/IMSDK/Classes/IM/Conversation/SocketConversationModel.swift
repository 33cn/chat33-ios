//
//  SocketConversationModel.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/29.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift
import SwiftyJSON

class SocketConversationModel: NSObject,Comparable {
    var isSelected = false
    var type : SocketChannelType = .chatRoom
    var conversationId = ""
    var avatar = "" {
        didSet{
            DispatchQueue.main.async {
                self.infoSubject.onNext((self.unreadCount,self.name,self.avatar))
            }
        }
    }
    var name = "" {
        didSet {
            DispatchQueue.main.async {
                self.infoSubject.onNext((self.unreadCount,self.name,self.avatar))
            }
        }
    }
    var desText = ""
    var unreadCount = 0 {
        didSet{
            DispatchQueue.main.async {
                self.infoSubject.onNext((self.unreadCount,self.name,self.avatar))
                if self.unreadCount == 0 {
                    self.isAtMe = false
                }
            }
            self.update()
        }
    }
    var lastMsg : SocketMessage? {
        didSet{
            DispatchQueue.main.async {
                if let msg = self.lastMsg {
                    self.lastMsgRefreshSubject.onNext(msg)
                    
                    if self.type == .group &&
                        msg.fromId != IMLoginUser.shared().userId &&
                        IMConversationManager.shared().selectConversation != self &&
                        self.lastMsg?.msgId != oldValue?.msgId &&
                        self.isAtMe == false &&
                        (msg.body.aitList.contains("-1") || msg.body.aitList.contains(IMLoginUser.shared().userId)) {
                        self.isAtMe = true
                    }
                }
            }
        }
    }
    
    var lastMsgRefreshSubject = BehaviorSubject<SocketMessage?>(value: nil)
    
    var infoSubject = BehaviorSubject<(Int,String,String)>(value: (0,"",""))
    
    var onTopSubject = PublishSubject<Bool>()
    var onTop = false {
        didSet{
            if onTop != oldValue {
                self.update()
                self.onTopSubject.onNext(self.onTop)
            }
        }
    }
    
    var noDisturbingSubject = PublishSubject<IMDisturbingType>()
    var noDisturbing : IMDisturbingType = .close {
        didSet{
            if noDisturbing != oldValue {
                self.update()
                self.noDisturbingSubject.onNext(self.noDisturbing)
            }
        }
    }
    
    var isEncrypt = false
    
    var identificationSubject = BehaviorSubject<Bool>(value: false)
    private var identification = false {
        didSet {
            identificationSubject.onNext(identification)
        }
    }
    
    let isAtMeSubject = BehaviorSubject<Bool?>.init(value: nil)
    var isAtMe = false {
        didSet {
            if isAtMe != oldValue {
                DispatchQueue.main.async {
                    self.isAtMeSubject.onNext(self.isAtMe)
                }
                self.update()
            }
        }
    }
    var allUpvote = SocketMessageUpvote.init()
    
    override init() {
        super.init()
    }
    
    deinit {
        if self.type == .person {
            IMNotifyCenter.shared().removeReceiver(receiver: self, type: .contact)
        }else if self.type == .group {
            IMNotifyCenter.shared().removeReceiver(receiver: self, type: .group)
            IMNotifyCenter.shared().removeReceiver(receiver: self, type: .groupUser)
        }
    }
    
    init(chatRoom: IMChatRoomModel) {
        super.init()
        type = .chatRoom
        conversationId = chatRoom.chatRoomId
        avatar = chatRoom.avatar
        name = chatRoom.chatRoomName
        desText = chatRoom.chatRoomDescription
        lastMsg = SocketMessage.getMsg(with: type, conversationId: conversationId)
        infoSubject.onNext((unreadCount,name,avatar))
    }
    
    init(with conversationId: String, type: SocketChannelType) {
        super.init()
        self.type = type
        self.conversationId = conversationId
        unreadCount = SocketConversationModel.getUnreadCount(with: type, conversationId: conversationId)
        lastMsg = SocketMessage.getMsg(with: type, conversationId: conversationId)
        if self.type == .person {
            IMContactManager.shared().requestUserModel(with: conversationId) { (user, _, _) in
                guard let user = user else { return }
                self.avatar = user.avatar
                self.name = user.showName
                self.onTop = user.onTop
                self.noDisturbing = user.noDisturbing
                self.isEncrypt = IMLoginUser.shared().currentUser?.isEncryptChatWithUser(user) ?? false
                self.identification = user.identification
            }
        }else if self.type == .group {
            IMConversationManager.shared().getGroup(with: conversationId) { (model) in
                self.name = model.showName
                self.avatar = model.avatar
                self.onTop = model.onTop
                self.noDisturbing = model.noDisturbing
                self.isEncrypt = model.isEncryptGroup
                self.identification = model.identification
            }
        }
        self.addReceiver()
    }
    
    init(user: IMUserModel) {
        super.init()
        type = .person
        conversationId = user.userId
        unreadCount = SocketConversationModel.getUnreadCount(with: .person, conversationId: user.userId)
        avatar = user.avatar
        name = user.showName
        noDisturbing = user.noDisturbing
        onTop = user.onTop
        lastMsg = SocketMessage.getMsg(with: type, conversationId: conversationId)
        self.isEncrypt = IMLoginUser.shared().currentUser?.isEncryptChatWithUser(user) ?? false
        infoSubject.onNext((unreadCount,name,avatar))
        self.identification = user.identification
        self.addReceiver()
    }
    
    init(dbConversation: DBUserConversation) {
        super.init()
        if let type = SocketChannelType(rawValue: dbConversation.type) {
            self.type = type
        }
        conversationId = dbConversation.conversationId
        unreadCount = dbConversation.unreadCount
        onTop = dbConversation.onTop
        if let disturb = IMDisturbingType(rawValue: dbConversation.noDisturbing) {
            noDisturbing = disturb
        }
        infoSubject.onNext((unreadCount,name,avatar))
        lastMsg = SocketMessage.getMsg(with: type, conversationId: conversationId)
        if self.type == .person {
            IMContactManager.shared().requestUserModel(with: conversationId) { (user, _, _) in
                guard let user = user else { return }
                self.avatar = user.avatar
                self.name = user.showName
                self.isEncrypt = IMLoginUser.shared().currentUser?.isEncryptChatWithUser(user) ?? false
                self.identification = user.identification
            }
        }else if self.type == .group {
            IMConversationManager.shared().getGroup(with: conversationId) { (model) in
                self.name = model.showName
                self.avatar = model.avatar
                self.isEncrypt = model.isEncryptGroup
                self.identification = model.identification
            }
        }
        if isAtMe != dbConversation.isAtMe {
            isAtMe = dbConversation.isAtMe
            self.isAtMeSubject.onNext(isAtMe)
        }
        self.allUpvote = SocketMessageUpvote.init(json: JSON.init(parseJSON: dbConversation.allUpvote))
        self.addReceiver()
    }
    
    init(msg: SocketMessage) {
        super.init()
        type = msg.channelType
        conversationId = msg.conversationId
        unreadCount = SocketConversationModel.getUnreadCount(with: type, conversationId: conversationId)
        infoSubject.onNext((unreadCount,name,avatar))
        lastMsg = msg
        if msg.msgType == .notify,
            case .msgUpvoteUpdate(_,_,_,_,_,_) = msg.body.notifyEvent {
            lastMsg = SocketMessage.getMsg(with: type, conversationId: conversationId)
        }
        
        if type == .person {
            IMContactManager.shared().requestUserModel(with: conversationId) { (user, _, _) in
                guard let user = user else { return }
                self.avatar = user.avatar
                self.name = user.showName
                self.noDisturbing = user.noDisturbing
                self.onTop = user.onTop
                self.isEncrypt = IMLoginUser.shared().currentUser?.isEncryptChatWithUser(user) ?? false
                self.identification = user.identification
            }
        }else if type == .group {
            IMConversationManager.shared().getGroup(with: conversationId) { (model) in
                self.name = model.showName
                self.avatar = model.avatar
                self.noDisturbing = model.noDisturbing
                self.onTop = model.onTop
                self.isEncrypt = model.isEncryptGroup
                self.identification = model.identification
            }
        }
        self.isAtMe = (msg.body.aitList.contains("-1") || msg.body.aitList.contains(IMLoginUser.shared().userId))
        if self.isAtMe {
            self.isAtMeSubject.onNext(true)
        }
        self.addReceiver()
    }
    
    init(group: IMGroupModel) {
        super.init()
        type = .group
        conversationId = group.groupId
        unreadCount = SocketConversationModel.getUnreadCount(with: type, conversationId: conversationId)
        lastMsg = SocketMessage.getMsg(with: type, conversationId: conversationId)
        avatar = group.avatar
        name = group.name
        noDisturbing = group.noDisturbing
        onTop = group.onTop
        infoSubject.onNext((unreadCount,name,avatar))
        IMConversationManager.shared().getGroup(with: conversationId) { (model) in
            self.name = model.showName
            self.avatar = model.avatar
            self.isEncrypt = model.isEncryptGroup
            self.identification = model.identification
        }
        self.addReceiver()
    }
    
    func refreshLastMsg() {
        lastMsg = SocketMessage.getMsg(with: type, conversationId: conversationId)
    }
    
    func refreshIsAtMe() {
        guard self.type == .group, self.isAtMe == false, IMConversationManager.shared().selectConversation != self, self.unreadCount > 0 else { return }
        DispatchQueue.global().async {
            self.isAtMe = SocketMessage.isHaveAtMeMsgInConversation(conversationId: self.conversationId, unreadMsgCount: self.unreadCount)
        }
    }
    
    private func addReceiver() {
        if type == .person {
            IMNotifyCenter.shared().addReceiver(receiver: self, type: .contact)
        }else if type == .group {
            IMNotifyCenter.shared().addReceiver(receiver: self, type: .group)
            IMNotifyCenter.shared().addReceiver(receiver: self, type: .groupUser)
        }
    }
    
    public static func == (lhs: SocketConversationModel, rhs: SocketConversationModel) -> Bool {
        return lhs.conversationId == rhs.conversationId && lhs.type == rhs.type
    }
    
    static func < (lhs: SocketConversationModel, rhs: SocketConversationModel) -> Bool {
        if lhs.onTop != rhs.onTop {
            return !lhs.onTop
        }
        guard let lmsg = lhs.lastMsg else { return true }
        guard let rmsg = rhs.lastMsg else { return false }
        return lmsg.datetime < rmsg.datetime
    }
}

extension SocketConversationModel {
    func allUpvoteUpdate(action: UpvoteUpdateAction) {
        var admire = self.allUpvote.admire
        var reward = self.allUpvote.reward
        switch action {
        case .admire:
            admire = admire + 1
        case .reward:
            reward = reward + 1
        case .cancelAdmire:
            if admire > 0 {
                admire = admire - 1
            }
        default:
            break
        }
        if admire != self.allUpvote.admire || reward != self.allUpvote.reward {
            self.allUpvote.set(admire: admire, reward: reward, stateForMe: self.allUpvote.stateForMe)
            self.update()
        }
    }
}

extension SocketConversationModel: ContactInfoChangeDelegate, UserGroupInfoChangeDelegate{
    func contactUserInfoChange(with userId: String) {
        if userId == self.conversationId && self.type == .person {
            IMContactManager.shared().requestUserModel(with: userId) { (user, _, _) in
                guard let user = user else { return }
                self.avatar = user.avatar
                self.name = user.showName
            }
        }
    }
    
    func userGroupInfoChange(groupId: String, userId: String) {
        if self.type == .group && groupId == conversationId {
            guard let msg = SocketMessage.getMsg(with: type, conversationId: conversationId) else { return }
            lastMsg = msg
        }
    }
    
}

extension SocketConversationModel: GroupInfoChangeDelegate {
    func groupInfoChange(with groupId: String) {
        if groupId == self.conversationId && self.type == .group {
            IMConversationManager.shared().getGroup(with: groupId) { (model) in
                self.name = model.showName
                self.avatar = model.avatar
            }
        }
    }
}
