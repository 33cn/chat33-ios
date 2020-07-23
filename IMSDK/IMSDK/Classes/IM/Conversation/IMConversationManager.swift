//
//  IMConversationManager.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/29.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift


typealias UserGroupInfoModelBlock = (IMGroupUserInfoModel?,Bool,String)->()
typealias BannedInfoBlock = (Bool,Double)->()

class IMConversationManager: NSObject {
    private static let sharedInstance = IMConversationManager()
    
    class func shared() -> IMConversationManager {
        return sharedInstance
    }
    
    override init() {
        super.init()
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .user)
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .chatMessage)
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .appState)
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .burnAfterRead)
    }
    
    class func launchManager() {
        let manager = IMConversationManager.shared()
        manager.reloadData()
    }
    
    private func reloadData() {
        if IMLoginUser.shared().isLogin {
            self.refreshGroupList()
            self.refreshGroupChatList()
            self.refreshPrivateChatList()
            self.refreshUnreadCount()
        }
    }
    
    let disposeBag = DisposeBag.init()
    
    var selectConversation : SocketConversationModel? {
        didSet{
            if selectConversation != nil {
                self.refreshUnreadCount()
            }
        }
    }
    
    //MARK: 群聊和私聊
    var privateAndGroupChatList = [SocketConversationModel]() {
        didSet {
            DispatchQueue.main.async {
                self.privateAndGroupChatListSubject.onNext(self.privateAndGroupChatList)
            }
        }
    }
    let privateAndGroupChatListSubject = BehaviorSubject<[SocketConversationModel]>(value: [])
    
    //MARK: 聊天室
    private var chatRoomArr = [IMChatRoomModel](){
        didSet{
            var arr = [SocketConversationModel]()
            chatRoomArr.forEach { (room) in
                arr.append(SocketConversationModel(chatRoom: room))
            }
            chatRoomList = arr.sorted(by: >)
        }
    }
    private var chatRoomList = [SocketConversationModel]() {
        didSet {
            chatRoomListSubject.onNext(chatRoomList)
        }
    }
    let chatRoomListSubject = BehaviorSubject<[SocketConversationModel]>(value: [])
    //MARK: 群
    private var groupChatList = [SocketConversationModel](){
        didSet{
            DispatchQueue.main.async {
                self.privateAndGroupChatList = (self.groupChatList + self.privateChatList).sorted(by: >)
                self.groupChatListSubject.onNext(self.groupChatList)
            }
        }
    }
    var groupList = [IMGroupModel]() {
        didSet{
            DispatchQueue.main.async {
                self.groupListSubject.onNext(self.groupList)
            }
        }
    }
    let groupChatListSubject = BehaviorSubject<[SocketConversationModel]>(value: [])
    let groupListSubject = BehaviorSubject<[IMGroupModel]>(value: [])
    private var groupMap = [String:IMGroupDetailInfoModel]()
    let groupUnreadCountSubject = BehaviorSubject<Int>(value: 0)
    //MARK: 私聊
    var privateChatList = [SocketConversationModel]() {
        didSet{
            DispatchQueue.main.async {
                self.privateAndGroupChatList = (self.groupChatList + self.privateChatList).sorted(by: >)
                self.privateChatListSubject.onNext(self.privateChatList)
            }
        }
    }
    let privateChatListSubject = BehaviorSubject<[SocketConversationModel]>(value: [])
    
    let privateUnreadCountSubject = BehaviorSubject<Int>(value: 0)
    
    func getConversation(with conversationId: String, type: SocketChannelType) -> SocketConversationModel {
        var conversation : SocketConversationModel?
        if type == .group {
            groupChatList.forEach { (model) in
                if model.conversationId == conversationId {
                    conversation = model
                }
            }
        }else if type == .person {
            privateChatList.forEach { (model) in
                if model.conversationId == conversationId {
                    conversation = model
                }
            }
        }
        if conversation == nil {
            conversation = SocketConversationModel(with: conversationId, type: type)
            if type == .group {
                groupChatList.append(conversation!)
                groupChatList = groupChatList.sorted(by: >)
            }else if type == .person {
                privateChatList.append(conversation!)
                privateChatList = privateChatList.sorted(by: >)
            }
        }
        return conversation!
    }
    
    func convertGroupListToGroupSectionArray(by groupArr:[IMGroupModel]) -> [GroupSection] {        
        let dic = Dictionary(grouping: groupArr) { (group:IMGroupModel)in
            return group.name.findFirstLetterFromString()
        }
        var groupSectionArr = [GroupSection]()
        for key in dic.keys {
            if let groups = dic[key], groups.count > 0 {
                let groupSection = GroupSection(titleKey: key, groupArr: groups)
                groupSectionArr.append(groupSection)
            }
        }
        return groupSectionArr.sorted(by: <)
    }
    
    private let fetchListQueue = DispatchQueue(label: "com.conversationFetchListQueue")
    
}


class GroupSection: NSObject, Comparable {
    static func < (lhs: GroupSection, rhs: GroupSection) -> Bool {
        if lhs.titleKey == "#" {
            return false
        }
        if rhs.titleKey == "#" {
            return true
        }
        return lhs.titleKey < rhs.titleKey
    }
    
    static func == (lhs: GroupSection, rhs: GroupSection) -> Bool {
        return lhs.titleKey == rhs.titleKey
    }
    
    let titleKey: String
    let groupArr: [IMGroupModel]
    init(titleKey: String, groupArr: [IMGroupModel]) {
        self.titleKey = titleKey
        self.groupArr = groupArr
    }
    
    
}


//MARK: 聊天室
extension IMConversationManager {
    //获取聊天室列表
    func fetchChatRoomList() {
        HttpConnect.shared().getChatRoomList(status: 1) { (list, _) in
            self.chatRoomArr = list
        }
    }
}

//MARK: 群
extension IMConversationManager {
    
    func refreshGroupChatList() {
        groupChatList = SocketConversationModel.getAll(with: .group).sorted(by: >)
    }
    
    func getGroupConversation(with groupId: String) -> SocketConversationModel? {
        var conversation : SocketConversationModel?
        groupChatList.forEach { (model) in
            if model.conversationId == groupId {
                conversation = model
            }
        }
        return conversation
    }
    
    func refreshGroupList() {
        HttpConnect.shared().getGroupList(type: 3) { (list, response) in
            guard response.success else { return }
            self.groupList.removeAll()
            self.groupList = list
        }
    }
    
    func haveGroup(groupId: String) -> Bool {
        var have = false
        groupList.forEach { (group) in
            if group.groupId == groupId {
                have = true
            }
        }
        return have
    }
    
    func getGroup(with groupId: String, completeBlock: ((IMGroupDetailInfoModel)->())?){
        DispatchQueue.main.async {
            if let group = self.groupMap[groupId] {
                completeBlock?(group)
            }else {
                self.getGroupDetailInfo(groupId: groupId) { (group, response) in
                    if let group = group {
                        completeBlock?(group)
                    }
                }
            }
        }
    }
    
    func getGroupDetailInfo(groupId: String, completeBlock: GroupDetailInfoHandler?) {
        HttpConnect.shared().getGroupDetailInfo(groupId: groupId) { (model, response) in
            guard let model = model else {
                completeBlock?(nil,response)
                return
            }
            if let group = self.groupMap[groupId] {
                group.update(with: model)
                completeBlock?(group,response)
                IMNotifyCenter.shared().postMessage(event: .groupInfoChange(groupId: groupId))
            }else {
                self.groupMap[groupId] = model
                completeBlock?(model,response)
            }
            model.users.forEach({ (user) in
                IMContactManager.shared().saveGroupMember(member: user, groupId: groupId)
            })
        }
    }
    
    func createGroup(name: String?, avatar: String?, users: [String], encrypt: Int, completeBlock: CreateGroupHandler?) {
        HttpConnect.shared().createGroup(name: name, avatar: avatar, users: users, encrypt: encrypt) { (group, response) in
            completeBlock?(group, response)
            guard let group = group else { return }
            self.groupList.append(group)
        }
    }
    
    func groupSetPermission(groupId: String, canAddFriend: Int?, joinPermission: Int?, recordPermission: Int?, completionBlock: NormalHandler?) {
        HttpConnect.shared().groupSetPermission(groupId: groupId, canAddFriend: canAddFriend, joinPermission: joinPermission, recordPermission: recordPermission) { (response) in
            completionBlock?(response)
        }
    }
    
    func getGroupMemberList(groupId: String, completionBlock: GroupMemberListHandler?) {
        if let list = IMGroupUserInfoModel.getGroupMemberList(groupId: groupId) {
            let response = HttpResponse.init()
            response.success = true
             completionBlock?(list,response)
            self.getServerGroupMemberList(groupId: groupId, completionBlock: nil)
        } else {
            self.getServerGroupMemberList(groupId: groupId, completionBlock: completionBlock)
        }
        
    }
    
    func getServerGroupMemberList(groupId: String, completionBlock: GroupMemberListHandler?) {
        HttpConnect.shared().getGroupMemberList(groupId: groupId) { (list, response) in
            completionBlock?(list,response)
            guard response.success else { return }
            DispatchQueue.global().async {
                IMGroupUserInfoModel.saveGroupMemberList(list: list, groupId: groupId)
            }
            list.forEach({ (user) in
                IMContactManager.shared().saveGroupMember(member: user, groupId: groupId)
            })
        }
    }
    
    func setGroupUserLevel(groupId: String, userId: String, level: IMGroupMemberLevel, completionBlock: NormalHandler?){
        HttpConnect.shared().setGroupUserLevel(groupId: groupId, userId: userId, level: level.rawValue) { (response) in
            completionBlock?(response)
        }
    }
    
    func quitGroup(groupId: String, completionBlock: NormalHandler?) {
        HttpConnect.shared().quitGroup(groupId: groupId) { (response) in
            completionBlock?(response)
            self.deleteLocalGroup(with: groupId)
        }
    }
    
    func kickOutGroupMember(groupId: String, users: [String], completionBlock: NormalHandler?) {
        HttpConnect.shared().kickOutGroupMember(groupId: groupId, users: users) { (response) in
            completionBlock?(response)
        }
    }
    
    func deleteGroup(groupId: String, completionBlock: NormalHandler?) {
        HttpConnect.shared().deleteGroup(groupId: groupId) { (response) in
            completionBlock?(response)
            self.deleteLocalGroup(with: groupId)
        }
    }
    
    func deleteLocalGroup(with groupId: String) {
        self.groupList = self.groupList.filter({ (group) -> Bool in
            return group.groupId != groupId
        })
        self.deleteConversation(with: groupId, type: .group)
    }
    
    func inviteJoinGroup(groupId: String, users: [String], completionBlock: NormalHandler?) {
        HttpConnect.shared().inviteJoinGroup(groupId: groupId, users: users) { (response) in
            completionBlock?(response)
        }
    }
    
    func applyJoinGroup(groupId: String, reason: String? = nil, source: [String : Any], completionBlock: NormalHandler?) {
        HttpConnect.shared().applyJoinGroup(groupId: groupId, reason: reason, source: source) { (response) in
            completionBlock?(response)
        }
    }
    
    func editGroupName(groupId: String, name: String, completionBlock: NormalHandler?) {
        HttpConnect.shared().editGroupName(groupId: groupId, name: name) { (response) in
            completionBlock?(response)
            self.getGroup(with: groupId, completeBlock: { (model) in
                model.name = name
                IMNotifyCenter.shared().postMessage(event: .groupInfoChange(groupId: groupId))
            })
        }
    }
    
    func editGroupAvatar(groupId: String, avatar: String, completionBlock: NormalHandler?) {
        HttpConnect.shared().editGroupAvatar(groupId: groupId, avatar: avatar) { (response) in
            completionBlock?(response)
            self.getGroup(with: groupId, completeBlock: { (model) in
                model.avatar = avatar
                IMNotifyCenter.shared().postMessage(event: .groupInfoChange(groupId: groupId))
            })
        }
    }
    
    func groupSetNoDisturbing(groupId: String, on: Bool, completionBlock: NormalHandler?) {
        HttpConnect.shared().groupSetNoDisturbing(groupId: groupId, on: on) { (response) in
            completionBlock?(response)
            self.getGroup(with: groupId, completeBlock: { (group) in
                group.noDisturbing = on ? .open : .close
            })
            self.groupList.forEach({ (group) in
                if group.groupId == groupId {
                    group.noDisturbing = on ? .open : .close
                }
            })
            self.groupChatList.forEach({ (group) in
                if group.conversationId == groupId {
                    group.noDisturbing = on ? .open : .close
                }
            })
            self.groupChatList = self.groupChatList.sorted(by: >)
        }
    }
    
    func groupSetOnTop(groupId: String, on: Bool, completionBlock: NormalHandler?) {
        HttpConnect.shared().groupSetOnTop(groupId: groupId, on: on) { (response) in
            completionBlock?(response)
            self.getGroup(with: groupId, completeBlock: { (group) in
                group.onTop = on
            })
            self.groupList.forEach({ (group) in
                if group.groupId == groupId {
                    group.onTop = on
                }
            })
            self.groupChatList.forEach({ (group) in
                if group.conversationId == groupId {
                    group.onTop = on
                }
            })
            self.groupChatList = self.groupChatList.sorted(by: >)
        }
    }
    
    func setMyGroupNickname(groupId: String, nickname: String, completionBlock: NormalHandler?) {
        HttpConnect.shared().setGroupNickname(groupId: groupId, nickname: nickname) { (response) in
            completionBlock?(response)
            guard response.success else { return }
            self.getGroup(with: groupId, completeBlock: { (model) in
                model.groupNickname = nickname
            })
            if let model = IMContactManager.shared().myGroupInfoMap[groupId] {
                model.groupNickname = nickname
            }
            IMNotifyCenter.shared().postMessage(event: .userGroupInfoChange(groupId: groupId, userId: IMLoginUser.shared().userId))
        }
    }
    
    func bannedGroupUser(groupId: String, userId: String, deadline: Double, completionBlock: NormalHandler?) {
        HttpConnect.shared().bannedGroupUser(groupId: groupId, userId: userId, deadline: deadline) { (response) in
            completionBlock?(response)
        }
    }
    
    func groupBannedSet(groupId: String, type: Int, users: [String]? = nil, deadline: Double? = nil, completionBlock: NormalHandler?) {
        HttpConnect.shared().groupBannedSet(groupId: groupId, type: type, users: users ?? [], deadline: deadline ?? 0) { (response) in
            completionBlock?(response)
        }
    }
    
    func groupReleaseNotify(groupId: String, content: String, completionBlock: NormalHandler?) {
        HttpConnect.shared().groupReleaseNotify(groupId: groupId, content: content) { (response) in
            completionBlock?(response)
        }
    }
    
    func requestBannedInfo(userId: String, groupId: String, completionBlock: BannedInfoBlock?) {
        self.getGroup(with: groupId) { (group) in
            IMContactManager.shared().getUserGroupInfo(userId: userId, groupId: groupId, completionBlock: { (user, _, _) in
                guard let user = user else { return }
                let (isBanned, distance) = self.handleBannedInfo(user: user, group: group)
                completionBlock?(isBanned, distance)
            })
        }
    }
    
    func handleBannedInfo(user: IMGroupUserInfoModel, group: IMGroupDetailInfoModel) -> (Bool,Double) {
        guard user.memberLevel == .normal else {
            return (false, 0)
        }
        var isBanned = false
        var distance : Double = 0
        if user.memberLevel == .normal {
            if group.bannedType == .blackMap {
                distance = (user.deadline - Date.timestamp) / 1000
                if user.bannedType == .blackMap && distance > 0 {
                    isBanned = true
                }else {
                    distance = 0
                }
            }else if group.bannedType == .bannedAll {
                isBanned = true
                distance = forverBannedTime
            }else if group.bannedType == .whiteMap {
                if user.bannedType != .whiteMap {
                    isBanned = true
                    distance = forverBannedTime
                }
            }
        }
        return (isBanned, distance)
    }
    
    func getRecommendRoom(number: Int, times: Int, completionBlock: NormalHandler?) {
        HttpConnect.shared().getRecommendRoom(number: number, times: times, completionBlock: completionBlock)
    }
    
    func batchJoinRoomApply(rooms:[String], completionBlock: NormalHandler?) {
        HttpConnect.shared().batchJoinRoomApply(rooms:rooms , completionBlock: completionBlock)
    }
    
    
}

//MARK: 私聊
extension IMConversationManager {
    
    func refreshPrivateChatList() {
        privateChatList = SocketConversationModel.getAll(with: .person).sorted(by: >)
    }
    
    func friendSetNoDisturbing(friendId: String, on: Bool) {
        privateChatList.forEach { (model) in
            if model.conversationId == friendId {
                model.noDisturbing = on ? .open : .close
            }
        }
        privateChatList = privateChatList.sorted(by: >)
    }
    func friendSetOnTop(friendId: String, on: Bool) {
        privateChatList.forEach { (model) in
            if model.conversationId == friendId {
                model.onTop = on
            }
        }
        privateChatList = privateChatList.sorted(by: >)
    }
}

extension IMConversationManager: UserInfoChangeDelegate {
    func userLogin() {
        self.reloadData()
    }
    func userLogout() {
        self.groupList.removeAll()
        self.groupChatList.removeAll()
        self.privateChatList.removeAll()
        self.privateAndGroupChatList.removeAll()
        self.groupMap.removeAll()
        self.selectConversation = nil
    }
    func userInfoChange() {
        
    }
}

//MARK: 加载历史消息
extension IMConversationManager {
    
    func loadLocationMsg(msgId: String, conversationId: String, type: SocketChannelType, completionBlock: MessageListFetchHandler?) {
        DispatchQueue.global().async {
            let msgs = SocketMessage.getLocationMsg(with: msgId, conversationId: conversationId, conversationType: type)
            if msgs.count < 15 {
                self.loadHistoryMessage(conversationId: conversationId, type: type, lastMessage: nil, completionBlock: completionBlock)
            } else {
                DispatchQueue.main.async {
                    completionBlock?(msgs)
                }
            }
        }
    }
    
    func loadHistoryMessage(conversationId: String, type: SocketChannelType, lastMessage: SocketMessage?, count: Int = 15, completionBlock: MessageListFetchHandler?) {
        DispatchQueue.global().async {
            var arr = [SocketMessage]()
            if let msg = lastMessage {
                let msgList = SocketMessage.getMsg(startTime: msg.datetime, conversationId: conversationId, conversationType: type, count: count)
                arr = msgList
            }else {
                if let msg = SocketMessage.getMsg(with: type, conversationId: conversationId) {
                    let msgList = SocketMessage.getMsg(startTime: msg.datetime, conversationId: conversationId, conversationType: type, count: count)
                    arr = [msg] + msgList
                }
            }
            if arr.count == 0 {
                self.loadServerMessage(conversationId: conversationId, type: type, lastMessage: lastMessage, count: count) { (list) in
                    DispatchQueue.main.async {
                        completionBlock?(list)
                    }
                }
            }else {
                DispatchQueue.main.async {
                    completionBlock?(arr)
                }
            }
        }
        
    }
    
    func loadServerMessage(conversationId: String, type: SocketChannelType, lastMessage: SocketMessage?, count: Int, completionBlock: MessageListFetchHandler?) {
        HttpConnect.shared().fetchHistoryMsgList(conversationId: conversationId, type: type, startId: lastMessage?.msgId, fetchCount: count) { (list, _, response) in
            if let msg = list.first {
                let arr = list.filter({ (model) -> Bool in
                    if let notifyType = model.body.notifyEvent {
                        if case .burnMsg = notifyType {
                            return false
                        } else if case .updataGroupKey = notifyType {
                            return false
                        }
                    }
                    return model != msg
                })
                var lastShowTimeMsg = msg
                arr.forEach({ (model) in
                    if fabs(model.datetime - lastShowTimeMsg.datetime) > 600000 {
                        lastShowTimeMsg = model
                        model.showTime = true
                    } else {
                        model.showTime = false
                    }
                    model.save()
                })
                completionBlock?(arr)
            }else {
                completionBlock?([])
            }
        }
    }
    
}

//MARK: 处理conversation
extension IMConversationManager {
    func conversationChangeOntop(conversation: SocketConversationModel, onTop: Bool) {
        if conversation.type == .person {
            IMContactManager.shared().friendSetOnTop(userId: conversation.conversationId, on: onTop, completionBlock: nil)
        }else if conversation.type == .group {
            self.groupSetOnTop(groupId: conversation.conversationId, on: onTop, completionBlock: nil)
        }
    }
    
    func conversationChangeNoDisturb(conversation: SocketConversationModel, noDisturb: Bool) {
        if conversation.type == .person {
            IMContactManager.shared().friendSetNoDisturbing(userId: conversation.conversationId, on: noDisturb, completionBlock: nil)
        }else if conversation.type == .group {
            self.groupSetNoDisturbing(groupId: conversation.conversationId, on: noDisturb, completionBlock: nil)
        }
    }
    
    func deleteConversation(with conversationId: String, type: SocketChannelType) {
        var unreadCount = 0
        var conversation : SocketConversationModel?
        if type == .group {
            let arr = groupChatList.filter { (model) -> Bool in
                if model.conversationId == conversationId {
                    conversation = model
                    return false
                }
                if model.noDisturbing == .close {
                    unreadCount += model.unreadCount
                }
                return true
            }
            groupChatList = arr.sorted(by: >)
            groupUnreadCountSubject.onNext(unreadCount)
        }else if type == .person {
            let arr = privateChatList.filter { (model) -> Bool in
                if model.conversationId == conversationId {
                    conversation = model
                    return false
                }
                if model.noDisturbing == .close {
                    unreadCount += model.unreadCount
                }
                return true
            }
            privateChatList = arr.sorted(by: >)
            privateUnreadCountSubject.onNext(unreadCount)
        }
        conversation?.delete()
    }
}

//MARK: 消息
extension IMConversationManager {
    func revokeMessage(msgId: String, channelType: SocketChannelType, completionBlock: NormalHandler?) {
        let type = channelType == .group ? 1 : 2
        HttpConnect.shared().revokeMessage(msgId: msgId, type: type) { (response) in
            completionBlock?(response)
        }
    }
}

//MARK: 接收消息处理
extension IMConversationManager: SocketChatMsgDelegate {
    func receiveMessage(with msg: SocketMessage, isLocal: Bool) {
        self.refreshLastMsg(with: msg)
    }
    
    func failSendMessage(with msg: SocketMessage) {
        self.refreshLastMsg(with: msg)
    }
    
    private func refreshLastMsg(with msg: SocketMessage) {
        var conversationArr = [SocketConversationModel]()
        if msg.channelType == .person {
            //私聊
            conversationArr = privateChatList
        }else if msg.channelType == .group {
            //群聊
            conversationArr = groupChatList
        }else if msg.channelType == .chatRoom {
            //聊天室
            conversationArr = chatRoomList
        }
        var conversation = SocketConversationModel(msg: msg)
        var isNewConversation = true
        for model in conversationArr {
            if model == conversation {
                conversation = model
                isNewConversation = false
                break
            }
        }
        if msg.msgType == .notify,
        case .msgUpvoteUpdate(_, let operatorId, let action, let logId, let admire, let reward) = msg.body.notifyEvent {
            let needUpdateMsg = SocketMessage.getMsg(with: logId, conversationId: msg.conversationId, conversationType: msg.channelType)
            needUpdateMsg?.upvoteUpdate(operatorId: operatorId, action: action, admire: admire, reward: reward)
            if needUpdateMsg?.direction == .send || msg.fromId == IMLoginUser.shared().userId {
                conversation.allUpvoteUpdate(action: action)
            }
        } else {
            conversation.lastMsg = msg
            if self.selectConversation != conversation && (msg.direction == .receive || msg.msgType == .notify) {
                conversation.unreadCount += 1
            }
        }
        if msg.channelType == .group && msg.msgType == .notify {
            if let event = msg.body.notifyEvent, case .updateGroupName = event {
                let str = msg.body.content
                let left = str.positionOf(sub: "\"") + 1
                let right = str.positionOf(sub: "\"", backwards: true) - 1
                if left >= 0 && right > left {
                    conversation.name = str.substring(from: left, to: right)
                }
            }
        }
        if isNewConversation {
            conversationArr.insert(conversation, at: 0)
            conversation.update()
            conversation.noDisturbingSubject.subscribe({[weak self] (_) in
                self?.refreshUnreadCount()
            }).disposed(by: self.disposeBag)
            conversation.onTopSubject.subscribe({[weak self] (_) in
                if conversation.type == .person {
                    self?.privateChatList = conversationArr.sorted(by: >)
                } else {
                    self?.groupChatList = conversationArr.sorted(by: >)
                }
            }).disposed(by: self.disposeBag)
        }
        
        if msg.msgType == .notify, case .msgUpvoteUpdate(_, _, _, _, _,_) = msg.body.notifyEvent {
            //
        } else if conversation.noDisturbing == .close && (msg.direction == .receive || msg.msgType == .notify) {
            VoiceMessagePlayerManager.shared().alertAction()
        }
        
        switch msg.channelType {
        case .person:
            privateChatList = conversationArr.sorted(by: >)
        case .group:
            groupChatList = conversationArr.sorted(by: >)
        case .chatRoom:
            chatRoomList = conversationArr.sorted(by: >)
        }
        self.refreshUnreadCount()
    }
    
    func receiveHistoryMsgList(with msgs: [SocketMessage], isUnread: Bool) {
        fetchListQueue.async {
            let divideMsgs = Array.init(msgs.reduce(into: Dictionary<String,[SocketMessage]>.init(), { (into, msg) in
                let key = msg.conversationId + "key" + String.init(msg.channelType.rawValue)
                if into[key] == nil {
                    var arr = Array<SocketMessage>.init()
                    arr.append(msg)
                    into[key] = arr
                } else {
                    into[key]?.append(msg)
                }
            }).values)
            
            divideMsgs.forEach({ (msgs) in
                var msgsConversation: SocketConversationModel?
                if let msg = msgs.last {
                    let conversationArr = msg.channelType == .person ? self.privateChatList : self.groupChatList
                    var conversation = SocketConversationModel(msg: msg)
                    var isNewConversation = true
                    for model in conversationArr {
                        if model == conversation {
                            conversation = model
                            isNewConversation = false
                            break
                        }
                    }
                    msgsConversation = conversation
                    if isNewConversation {
                        conversation.update()
                        if msg.channelType == .person {
                            self.privateChatList.insert(conversation, at: 0)
                        }else if msg.channelType == .group {
                            self.groupChatList.insert(conversation, at: 0)
                        }
                        conversation.noDisturbingSubject.subscribe({[weak self] (_) in
                            self?.refreshUnreadCount()
                        }).disposed(by: self.disposeBag)
                        conversation.onTopSubject.subscribe({[weak self] (_) in
                            guard let strongSelf = self else { return }
                            if conversation.type == .person {
                                strongSelf.privateChatList = strongSelf.privateChatList.sorted(by: >)
                            } else {
                                strongSelf.groupChatList = strongSelf.groupChatList.sorted(by: >)
                            }
                        }).disposed(by: self.disposeBag)
                    }
                    conversation.refreshLastMsg()
                    if isUnread && self.selectConversation != conversation {
                        let count = msgs.filter { (msg) -> Bool in
                            if msg.msgType == .notify, case .msgUpvoteUpdate(_, _, _, _, _,_) = msg.body.notifyEvent {
                                return false
                            }
                            return msg.direction == .receive || msg.msgType == .notify
                        }.count
                        conversation.unreadCount += count
                    }
                }
                msgs.forEach { (msg) in
                    if msg.msgType == .notify,
                        case .msgUpvoteUpdate(_, let operatorId, let action, let logId, let admire, let reward) = msg.body.notifyEvent{
                        let needUpdateMsg = SocketMessage.getMsg(with: logId, conversationId: msg.conversationId, conversationType: msg.channelType)
                        needUpdateMsg?.upvoteUpdate(operatorId: operatorId, action: action, admire: admire, reward: reward)
                        if (needUpdateMsg?.direction == .send || msg.fromId == IMLoginUser.shared().userId), let conversation = msgsConversation {
                            conversation.allUpvoteUpdate(action: action)
                        }
                    }
                }
            })
            if isUnread {
                self.refreshUnreadCount()
            }
        }
    }
    
    func receiveMessageListCompleting() {
        fetchListQueue.async {
            self.privateChatList = self.privateChatList.sorted(by: >)
            self.groupChatList = self.groupChatList.sorted(by: >)
            
            self.privateChatList.forEach({$0.refreshIsAtMe()})
            self.groupChatList.forEach({$0.refreshIsAtMe()})
        }
    }
    
    func refreshUnreadCount() {
        let privateUnread = privateChatList.compactMap {$0.noDisturbing == .close ? $0 : nil}.reduce(0) {
            return $0 + $1.unreadCount
        }
        let groupUnread = groupChatList.compactMap {$0.noDisturbing == .close ? $0 : nil}.reduce(0) {
            return $0 + $1.unreadCount
        }
        DispatchQueue.main.async {
            self.privateUnreadCountSubject.onNext(privateUnread)
            self.groupUnreadCountSubject.onNext(groupUnread)
        }
        
    }
}

extension IMConversationManager: AppActiveDelegate {
    func appEnterBackground() {
        
    }
    
    func appWillEnterForeground() {
        if IMLoginUser.shared().isLogin {
            self.refreshGroupList()
        }
    }
    
}

extension IMConversationManager: BurnAfterReadDelegate {
    func burnMessage(_ msg: SocketMessage) {
        var conversation : SocketConversationModel?
        if msg.channelType == .group {
            groupChatList.forEach { (model) in
                if model.conversationId == msg.conversationId {
                    conversation = model
                }
            }
        }else if msg.channelType == .person {
            privateChatList.forEach { (model) in
                if model.conversationId == msg.conversationId {
                    conversation = model
                }
            }
        }
        conversation?.refreshLastMsg()
    }
}
