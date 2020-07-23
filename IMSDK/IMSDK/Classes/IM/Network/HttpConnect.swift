//
//  HttpConnect.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/20.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import Foundation
import Moya
import SwiftyJSON
import Result


class HttpConnect: NSObject {
    private let provider = MoyaProvider<ServerAPI>(plugins: [NetworkPlugin()])
    
    static let singleTon = HttpConnect()
    class func shared() -> HttpConnect {
        return singleTon
    }
    override init() {
        super.init()
    }
    
    private func request(_ target: ServerAPI, completion: @escaping ResponseHandler){
        provider.request(target) { (result) in
            var myResponse = HttpResponse()
            if case .success(let response) = result {
                myResponse = HttpResponse(with: response)
            } else if case .failure (let error) = result {
                myResponse = HttpResponse.init(error: error)
            }
            completion(result,myResponse)
        }
    }
    
}

//MARK: 杂事
extension HttpConnect{
    func moduleState(completionBlock: NormalHandler?) {
        self.request(.moduleState) { (_, response) in
            completionBlock?(response)
        }
    }
    
    func requestVersion(completionBlock: NormalHandler?) {
        self.request(.requestVersion) { (_, response) in
            completionBlock?(response)
        }
    }
    
    func refreshCid(cid: String, completionBlock: NormalHandler?) {
        self.request(.refreshCid(cid: cid)) { (_, response) in
            completionBlock?(response)
        }
    }
    
    //撤回消息
    func revokeMessage(msgId: String, type: Int, completionBlock: NormalHandler?) {
        self.request(.revokeMessage(msgId: msgId, type: type)) { (_, response) in
            completionBlock?(response)
        }
    }
    
    //阅后即焚消息
    func burnMessage(msgId: String, type: Int, completionBlock: NormalHandler?) {
        self.request(.burnMessage(msgId: msgId, type: type)) { (_, response) in
            completionBlock?(response)
        }
    }
    
    //转发消息
    func forwardMsgs(sourceId: String, type: Int, forwardType: Int, msgIds: [String], targetRooms: [String], targetUsers: [String], completionBlock: NormalHandler?) {
        self.request(.forwardMsgs(sourceId: sourceId, type: type, forwardType: forwardType, msgIds: msgIds, targetRooms: targetRooms, targetUsers: targetUsers)) { (_, response) in
            completionBlock?(response)
        }
    }
    
    func encryptForwardMsgs(roomLogs: [Any], type: Int, userLogs: [Any], completionBlock: NormalHandler?) {
        self.request(.encryptForwardMsg(roomLogs: roomLogs, type: type, userLogs: userLogs)) { (_, response) in
            completionBlock?(response)
        }
    }
}

//MARK: 用户
extension HttpConnect{
    func userLogin(account: String, pwd: String, completionBlock: UserHandler?) {
        self.request(.login(account: account, pwd: pwd)) { (result, response) in
            var user : UserInfoModel?
            defer{
                if user != nil {
                    IMLoginUser.shared().loginWithUser(user: user!)
                }
                completionBlock?(user,response)
            }
            guard response.success , let dic = response.data else { return }
            user = UserInfoModel(with: dic)
            guard case .success(let loginResponse) = result else {
                return
            }
            let header = loginResponse.response?.allHeaderFields
            guard let sessionId = header?[AnyHashable("Set-Cookie")] else {
                return
            }
            user?.sessionId = "\(sessionId)"
        }
    }
    
    func userTokenLogin(token: String, type: Int, clientId: String, completionBlock: UserHandler?) {
        self.request(.tokenLogin(token: token, type: type, clientId: clientId)) { (result, response) in
            var user : UserInfoModel?
            defer{
                if user != nil {
                    IMLoginUser.shared().loginWithUser(user: user!)
                }
                completionBlock?(user,response)
            }
            guard response.success , let dic = response.data else { return }
            user = UserInfoModel(with: dic)
            guard case .success(let loginResponse) = result else {
                return
            }
            if let firstLogin = response.ocJson?["firstLogin"] as? Bool, firstLogin == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    IMNotifyCenter.shared().postMessage(event: .userFirstLogin)
                })
            }
            let header = loginResponse.response?.allHeaderFields
            guard let sessionId = header?[AnyHashable("Set-Cookie")] else {
                return
            }
            user?.sessionId = "\(sessionId)"
            user?.token = token
        }
    }
    
    func setDeviceToken(_ deviceToken: String, completionBlock: NormalHandler?) {
        self.request(.setDeviceToken(deviceToken: deviceToken)) { (_, response) in
            completionBlock?(response)
        }
    }
    
    func logout(completionBlock: NormalHandler?) {
        self.request(.logout) { (_, response) in
            completionBlock?(response)
        }
    }
    
    func editUserHeadImage(headImageUrl: String, completionBlock: NormalHandler?) {
        self.request(.editHeadImgUrl(headImgUrl: headImageUrl)) { (_, response) in
            if response.success {
                IMLoginUser.shared().currentUser?.avatar = headImageUrl
                IMLoginUser.shared().refreshUserInfo()
            }
            completionBlock?(response)
        }
    }
    
    func editUserName(name: String, completionBlock: NormalHandler?) {
        self.request(.editUserName(name: name)) { (_, response) in
            if response.success {
                IMLoginUser.shared().currentUser?.userName = name
                IMLoginUser.shared().refreshUserInfo()
            }
            completionBlock?(response)
        }
    }
    
    func getUserDetailInfo(userId: String, completionBlock: UserDetailInfoHandler?) {
        self.request(.getUserDetailInfo(userId: userId)) { (_, response) in
            var user : IMUserModel?
            defer{
                completionBlock?(user,response)
            }
            guard response.success, let data = response.data else { return }
            user = IMUserModel(with: data)
        }
    }
    
    func getUndealApplyNumber(completionBlock: IntHandler?) {
        self.request(.getUndealApplyNumber) { (_, response) in
            completionBlock?(response.data?["number"].int,response)
        }
    }
    
    func getInviteCode(completionBlock: StringHandler?) {
        self.request(.getInviteCode) { (_, response) in
            completionBlock?(response.data?["code"].string,response)
        }
    }
    
    func isFriend(userId: String, completionBlock: BoolHandler?) {
        self.request(.isFriend(userId: userId)) { (_, response) in
            var isFriend = false
            defer{
                completionBlock?(isFriend, response)
            }
            guard let data = response.data else { return }
            isFriend = data["isFriend"].boolValue
        }
    }
    
    //获取用户配置
    func getMyConfigure(completionBlock: MyConfigureHandler?) {
        self.request(.getConfigure) { (_, response) in
            var configure : IMUserConfigureModel?
            defer{
                completionBlock?(configure, response)
            }
            guard let data = response.data else { return }
            configure = IMUserConfigureModel(with: data)
        }
    }
    
    func getInviteStatistics(completionBlock: NormalHandler?) {
        self.request(.inviteStatistics) { (_, response) in
            completionBlock?(response)
        }
    }
    
    func singleInviteInfo(page: Int ,size: Int, completionBlock: NormalHandler?) {
        self.request(.singleInviteInfo(page: page, size: size)) { (_, response) in
            completionBlock?(response)
        }
    }
    
    func accumulateInviteInfo(page: Int ,size: Int, completionBlock: NormalHandler?) {
        self.request(.accumulateInviteInfo(page: page, size: size)) { (_, response) in
            completionBlock?(response)
        }
    }
    
    func updataUserPublicKey(_ publicKey: String, seed: String, completionBlock: NormalHandler?) {
        self.request(.uploadSecretKey(pubKey: publicKey, seed: seed)) { (_, response) in
            completionBlock?(response)
        }
    }
    
}

//MARK: 聊天室
extension HttpConnect {
    func getChatRoomList(status: Int, completionBlock: ChatRoomHandler?) {
        self.request(.getChatRoomList(status: status)) { (_, response) in
            var list = [IMChatRoomModel]()
            defer{
                completionBlock?(list,response)
            }
            guard let data = response.data , let jsonList = data["groups"].array else { return }
            jsonList.forEach({ (json) in
                list.append(IMChatRoomModel(with: json))
            })
        }
    }
}

//MARK: 群接口
extension HttpConnect {
    //获取群列表
    func getGroupList(type: Int, completionBlock: GroupHandler?) {
        self.request(.getGroupList(type: type)) { (_, response) in
            var list = [IMGroupModel]()
            defer{
                completionBlock?(list,response)
            }
            guard let data = response.data , let jsonList = data["roomList"].array else { return }
            jsonList.forEach({ (json) in
                list.append(IMGroupModel(with: json))
            })
        }
    }
    //获取群详情
    func getGroupDetailInfo(groupId: String, completionBlock: GroupDetailInfoHandler?) {
        self.request(.getGroupDetailInfo(groupId: groupId)) { (_, response) in
            var infoModel : IMGroupDetailInfoModel?
            defer{
                completionBlock?(infoModel,response)
            }
            guard response.success, let data = response.data else { return }
            infoModel = IMGroupDetailInfoModel(with: data)
        }
    }
    //创建群
    func createGroup(name: String?, avatar: String?, users: [String], encrypt: Int, completionBlock: CreateGroupHandler?) {
        self.request(.createGroup(name: name, avatar: avatar, users: users, encrypt: encrypt)) { (_, response) in
            var group : IMGroupModel?
            defer{
                completionBlock?(group,response)
            }
            guard response.success, let data = response.data else { return }
            group = IMGroupModel(with: data)
        }
    }
    //管理员设置群
    func groupSetPermission(groupId: String, canAddFriend: Int?, joinPermission: Int?, recordPermission: Int?, completionBlock: NormalHandler?) {
        self.request(.groupSetPermission(groupId: groupId, canAddFriend: canAddFriend, joinPermission: joinPermission, recordPermission: recordPermission)) { (_, response) in
            completionBlock?(response)
        }
    }
    //获取群成员列表
    func getGroupMemberList(groupId: String, completionBlock: GroupMemberListHandler?) {
        self.request(.getGroupMemberList(groupId: groupId)) { (_, response) in
            var list = [IMGroupUserInfoModel]()
            defer{
                completionBlock?(list,response)
            }
            guard let data = response.data , let jsonList = data["userList"].array else { return }
            jsonList.forEach({ (json) in
                list.append(IMGroupUserInfoModel(with: json, groupId: groupId))
            })
        }
    }
    //设置群成员等级
    func setGroupUserLevel(groupId: String, userId: String, level: Int, completionBlock: NormalHandler?) {
        self.request(.setGroupUserLevel(groupId: groupId, userId: userId, level: level)) { (_, response) in
            completionBlock?(response)
        }
    }
    //退出群聊
    func quitGroup(groupId: String, completionBlock: NormalHandler?) {
        self.request(.quitGroup(groupId: groupId)) { (_, response) in
            completionBlock?(response)
        }
    }
    //踢成员出群
    func kickOutGroupMember(groupId: String, users: [String], completionBlock: NormalHandler?) {
        self.request(.kickOutGroupUsers(groupId: groupId, users: users)) { (_, response) in
            completionBlock?(response)
        }
    }
    //解散群
    func deleteGroup(groupId: String, completionBlock: NormalHandler?) {
        self.request(.deleteGroup(groupId: groupId)) { (_, response) in
            completionBlock?(response)
        }
    }
    //邀请入群
    func inviteJoinGroup(groupId: String, users: [String], completionBlock: NormalHandler?) {
        self.request(.inviteJoinGroup(groupId: groupId, users: users)) { (_, response) in
            completionBlock?(response)
        }
    }
    //申请入群
    func applyJoinGroup(groupId: String, reason: String? = nil, source: [String : Any], completionBlock: NormalHandler?) {
        self.request(.applyJoinGroup(groupId: groupId, reason: reason, source: source)) { (_, response) in
            completionBlock?(response)
        }
    }
    //修改群名
    func editGroupName(groupId: String, name: String, completionBlock: NormalHandler?) {
        self.request(.editGroupName(groupId: groupId, name: name)) { (_, response) in
            completionBlock?(response)
        }
    }
    //修改群头像
    func editGroupAvatar(groupId: String, avatar: String, completionBlock: NormalHandler?) {
        self.request(.editGroupAvatar(groupId: groupId, avatar: avatar)) { (_, response) in
            completionBlock?(response)
        }
    }
    //群设置免打扰
    func groupSetNoDisturbing(groupId: String, on: Bool, completionBlock: NormalHandler?) {
        self.request(.groupSetDisturbing(groupId: groupId, on: on ? 1 : 2)) { (_, response) in
            completionBlock?(response)
        }
    }
    //群设置置顶
    func groupSetOnTop(groupId: String, on: Bool, completionBlock: NormalHandler?) {
        self.request(.groupSetOnTop(groupId: groupId, on: on ? 1 : 2)) { (_, response) in
            completionBlock?(response)
        }
    }
    //群未读消息
    func groupGetUnreadMsg(completionBlock: ConversationUnreadHandler?) {
        self.request(.groupGetUnreadMsg) { (_, response) in
            var list = [IMConversationUnreadModel]()
            defer{
                completionBlock?(list,response)
            }
            guard response.success, let data = response.data?["infos"].array else { return }
            data.forEach({ (json) in
                let model = IMConversationUnreadModel(with: json)
                list.append(model)
            })
        }
    }
    //获取群成员信息
    func getGroupUserInfo(groupId: String, userId: String, completionBlock: GroupMemberInfoHandler?) {
        self.request(.groupGetUserInfo(groupId: groupId, userId: userId)) { (_, response) in
            guard response.success, let data = response.data, let _ = data["id"].string else {
                completionBlock?(nil,response)
                return
            }
            let member = IMGroupUserInfoModel(with: data, groupId: groupId)
            completionBlock?(member,response)
        }
    }
    //设置群昵称
    func setGroupNickname(groupId: String, nickname: String, completionBlock: NormalHandler?) {
        self.request(.groupSetMyNickname(groupId: groupId, nickname: nickname)) { (_, response) in
            completionBlock?(response)
        }
    }
    //获取群公告列表
    func groupGetNotifyList(groupId: String, startId: String?, completionBlock: GroupNotifyListHandler?) {
        self.request(.groupGetNotifyList(groupId: groupId, startId: startId)) { (_, response) in
            var list = [IMGroupNotifyModel]()
            var nextId = ""
            defer{
                completionBlock?(list,nextId,response)
            }
            guard response.success, let data = response.data, let jsonList = data["list"].array else { return }
            jsonList.forEach({ (json) in
                let model = IMGroupNotifyModel(with: json)
                list.append(model)
            })
            nextId = data["nextLog"].stringValue
        }
    }
    
    //禁言用户
    func bannedGroupUser(groupId: String, userId: String, deadline: Double, completionBlock: NormalHandler?) {
        self.request(.bannedGroupUser(groupId: groupId, userId: userId, deadline: deadline)) { (_, response) in
            completionBlock?(response)
        }
    }
    //群禁言设置
    func groupBannedSet(groupId: String, type: Int, users: [String], deadline: Double, completionBlock: NormalHandler?) {
        self.request(.groupBannedSet(groupId: groupId, listType: type, users: users, deadline: deadline)) { (_, response) in
            completionBlock?(response)
        }
    }
    //发布群公告
    func groupReleaseNotify(groupId: String, content: String, completionBlock: NormalHandler?) {
        self.request(.groupReleaseNotify(groupId: groupId, content: content)) { (_, response) in
            completionBlock?(response)
        }
    }
    //是否在群里
    func isInGroup(groupId: String, completionBlock: BoolHandler?) {
        self.request(.isInGroup(groupId: groupId)) { (_, response) in
            var isInGroup = false
            defer{
                completionBlock?(isInGroup, response)
            }
            guard let data = response.data else { return }
            isInGroup = data["isInRoom"].boolValue
        }
    }
    
    func getRecommendRoom(number: Int, times: Int, completionBlock: NormalHandler?) {
        self.request(.getRecommendRoom(number: number, times: times)) { (_, response) in
            completionBlock?(response)
        }
    }
    
    func batchJoinRoomApply(rooms:[String], completionBlock: NormalHandler?) {
        self.request(.batchJoinRoomApply(rooms: rooms)) { (_, response) in
            completionBlock?(response)
        }
    }
}

//MARK: 聊天消息
extension HttpConnect {
    //获取消息历史记录
    func fetchHistoryMsgList(conversationId: String, type: SocketChannelType, startId: String?, fetchCount: Int ,completionBlock: MessageListHandler?) {
        if type == .chatRoom {
            self.request(.getChatRoomMsgList(roomId: conversationId, startId: startId, number: fetchCount)) { (_, response) in
                var list = [SocketMessage]()
                var nextId = ""
                defer{
                    completionBlock?(list,nextId,response)
                }
                guard let data = response.data , let jsonList = data["logs"].array else { return }
                jsonList.forEach({ (json) in
                    if let msg = SocketMessage(with: json) {
                        list.append(msg)
                    }
                })
                nextId = data["nextLog"].stringValue
            }
        }else if type == .person {
            self.request(.getFriendMsgList(friendId: conversationId, startId: startId, number: fetchCount)) { (_, response) in
                var list = [SocketMessage]()
                var nextId = ""
                defer{
                    completionBlock?(list,nextId,response)
                }
                guard let data = response.data , let jsonList = data["logs"].array else { return }
                jsonList.forEach({ (json) in
                    if let msg = SocketMessage(with: json) {
                        list.append(msg)
                    }
                })
                nextId = data["nextLog"].stringValue
            }
        }else {
            self.request(.getGroupMsgList(roomId: conversationId, startId: startId, number: fetchCount)) { (_, response) in
                var list = [SocketMessage]()
                var nextId = ""
                defer{
                    completionBlock?(list,nextId,response)
                }
                guard let data = response.data , let jsonList = data["logs"].array else { return }
                jsonList.forEach({ (json) in
                    if let msg = SocketMessage(with: json) {
                        list.append(msg)
                    }
                })
                nextId = data["nextLog"].stringValue
            }
        }
    }
}

//MARK: 通讯录
extension HttpConnect {
    // 加入黑名单
    func addUserToBlacklist(userId: String, completionBlock: NormalHandler?) {
        self.request(.block(userId: userId)) { (_, response) in
            completionBlock?(response)
        }
    }
    // 移除黑名单
    func deleteUserInBlacklist(userId: String, completionBlock: NormalHandler?) {
        self.request(.unBlock(userId: userId)) { (_, response) in
            completionBlock?(response)
        }
    }
    // 黑名单列表
    func getBlacklist(completionBlock: FriendArrHandler?) {
        self.request(.blockList) { (_, response) in
            var arr = [IMUserModel]()
            if response.success, let data = response.data?["userList"].array  {
                arr = data.compactMap { IMUserModel(with: $0) }
            }
            completionBlock?(arr, response)
        }
    }
    //获取入群/好友申请列表
    func getContactApplyList(lastId: Int?, completionBlock: ContactApplyHandler?) {
        self.request(.getContactApplyList(lastId: lastId, number: 20)) { (_, response) in
            var arr = [IMContactApplyModel]()
            defer{
                completionBlock?(arr,response)
            }
            guard let data = response.data , let jsonList = data["applyList"].array else { return }
            jsonList.forEach({ (json) in
                arr.append(IMContactApplyModel(with: json))
            })
        }
    }
    //精确搜索用户/群
    func searchContact(searchId: String, completionBlock: SearchInfoHandler?) {
        self.request(.searchContact(searchId: searchId)) { (_, response) in
            var list = [IMSearchInfoModel]()
            defer{
                completionBlock?(list,response)
            }
            if let dic = response.data?["userInfo"].dictionary, dic.keys.count > 0 {
                list.append(IMSearchInfoModel(with: response.data!["userInfo"], type: .person))
            }
            if let dic = response.data?["roomInfo"].dictionary, dic.keys.count > 0 {
                list.append(IMSearchInfoModel(with: response.data!["roomInfo"], type: .group))
            }
        }
    }
    //获取好友列表
    func getFriendList(type: Int, time: Date?, completionBlock: FriendArrHandler?) {
        let datetime = time != nil ? Int(time!.timeIntervalSince1970*1000) : nil
        self.request(.getFriendList(type: type, time: datetime)) { (_, response) in
            var arr = [IMUserModel]()
            defer{
                completionBlock?(arr,response)
            }
            guard response.success, let data = response.data?["userList"].array else { return }
            data.forEach({ (json) in
                let user = IMUserModel(with: json)
                user.isFriend = true
                arr.append(user)
            })
        }
    }
    //添加好友申请
    func addFriendApply(userId: String, remark: String, reason: String, source: [String : Any], answer: String? = nil, completionBlock: NormalHandler?) {
        self.request(.addFriendApply(userId: userId, remark: remark, reason: reason, source: source, answer: answer)) { (_, response) in
            completionBlock?(response)
        }
    }
    //删除好友
    func deleteFriend(userId: String, completionBlock: NormalHandler?) {
        self.request(.deleteFriend(userId: userId)) { (_, response) in
            completionBlock?(response)
        }
    }
    //好友申请处理
    func dealFriendApply(userId: String, agree: Bool, completionBlock: NormalHandler?) {
        self.request(.dealFriendApply(userId: userId, agree: agree)) { (_, response) in
            completionBlock?(response)
        }
    }
    //修改好友备注
    func editFriendRemark(userId: String, remark: String, completionBlock: NormalHandler?) {
        self.request(.editFriendRemark(userId: userId, remark: remark)) { (_, response) in
            completionBlock?(response)
        }
    }
    //设置好友备注
    func editFriendExtRemark(userId: String, remark: String,tels: [[String:String]],des: String,pics:[String],completionBlock: NormalHandler?) {
        self.request(.editFriendExtRemark(userId: userId, remark: remark, tels: tels, des: des, pics: pics)) { (_, response) in
            completionBlock?(response)
        }
    }
    //设置好友备注 加密
    func editFriendEncryptExtRemark(userId: String, encryptRemark: String,encryptExt: String, completionBlock: NormalHandler?) {
        self.request(.editFriendEncryptExtRemark(userId: userId, encryptRemark: encryptRemark, encryptExt: encryptExt)) { (_, response) in
            completionBlock?(response)
        }
    }
    
    //好友设置免打扰
    func friendSetNoDisturbing(userId: String, on: Bool, completionBlock: NormalHandler?) {
        self.request(.friendSetDisturbing(userId: userId, on: on ? 1 : 2)) { (_, response) in
            completionBlock?(response)
        }
    }
    //好友设置置顶
    func friendSetOnTop(userId: String, on: Bool, completionBlock: NormalHandler?) {
        self.request(.friendSetOnTop(userId: userId, on: on ? 1 : 2)) { (_, response) in
            completionBlock?(response)
        }
    }
    
    //好友未读消息
    func friendGetUnreadMsg(completionBlock: ConversationUnreadHandler?) {
        self.request(.friendGetUnreadMsg) { (_, response) in
            var list = [IMConversationUnreadModel]()
            defer{
                completionBlock?(list,response)
            }
            guard response.success, let data = response.data?["infos"].array else { return }
            data.forEach({ (json) in
                let model = IMConversationUnreadModel(with: json)
                list.append(model)
            })
        }
    }
    //入群申请处理
    func dealGroupApply(groupId: String, userId: String, agree: Bool, completionBlock: NormalHandler?) {
        self.request(.dealGroupApply(groupId: groupId, userId: userId, agree: agree)) { (_, response) in
            completionBlock?(response)
        }
    }
    //截屏通知
    func printScreen(userId: String, completionBlock: NormalHandler?) {
        self.request(.printScreen(userId: userId)) { (_, response) in
            completionBlock?(response)
        }
    }
    //设置是否需要验证
    func setNeedAuth(need: Bool, completionBlock: NormalHandler?) {
        self.request(.setAddNeedAuth(need: need)) { (_, response) in
            completionBlock?(response)
        }
    }
    //设置问题答案
    func setAuthQuestion(tp: Int, question: String, answer: String, completionBlock: NormalHandler?) {
        self.request(.setAuthQuestion(tp: tp, question: question, answer: answer)) { (_, response) in
            completionBlock?(response)
        }
    }
    //验证答案是否正确
    func checkAnswer(userId: String, answer: String, completionBlock: BoolHandler?) {
        self.request(.checkAnswer(userId: userId, answer: answer)) { (_, response) in
            var success = false
            defer{
                completionBlock?(success, response)
            }
            guard let data = response.data, let result = data["success"].bool else { return }
            success = result
        }
    }
    
    func setNeedConfirmInvite(need: Bool, completionBlock: NormalHandler?) {
        self.request(.setNeedConfirmInvite(need: need)) { (_, response) in
            completionBlock?(response)
        }
    }
}

//MARK: 红包
extension HttpConnect {
    //查询账号余额
    func queryBalance(callBack: StringHandler?){
        self.request(.queryRedPacketBalance) { (_, response) in
            var amountString : String?
            defer{
                callBack?(amountString,response)
            }
            guard response.success else { return }
            guard let balances = response.data?["balances"].array else { return}
            amountString = "0"
            balances.forEach({ (json) in
                if json["coin"].stringValue == "3" {
                    amountString = String(json["amount"].intValue)
                }
            })
        }
    }
    //获取红包信息
    func getRedPacketInfo(packetId: String, callBack: RedPacketHandler?){
        self.request(.getRedPacketInfo(packetId: packetId)) { (_, response) in
            guard response.success else {
                callBack?(nil,response)
                return
            }
            guard let data = response.data else {
                callBack?(nil,response)
                return
            }
            let redPacket = IMRedPacketModel.init(with: data)
            redPacket.packetId = packetId
            callBack?(redPacket,response)
        }
    }
    //发红包
    func sendRedPacket(isGroup: Bool, toId: String, coin: Int, type: Int, amount: Double, size: Int, remark: String, toUsers: String, ext: [String : String], callBack: StringsHandler?){
        self.request(.sendRedPacket(isGroup: isGroup ? 1 : 0 , toID: toId, coin: coin, type: type, amount: amount, size: size, remark: remark, toUsers: toUsers, ext: ext)) { (_, response) in
            guard response.success else {
                callBack?(nil, nil, response)
                return
            }
            let packetId = response.data?["packetId"].stringValue
            let packetUrl = response.data?["packetUrl"].stringValue
            callBack?(packetId,packetUrl,response)
        }
    }
    //已登录收红包
    func receiveRedPacket(packetId: String, callBack: NormalHandler?){
        self.request(.receiveRedPacket(packetId: packetId)) { (_, response) in
            guard response.success else {
                callBack?(response)
                return
            }
            callBack?(response)
        }
    }
    //查询用户红包收发记录
    func getRedPacketRecord(operation:Int, coinId:Int?,type:Int?,startTime:Int?,endTime:Int?,pageNum:Int,pageSize:Int,callBack:RedPacketRecordHandler?){
        self.request(.redPacketRecord(operation:operation, coinId:coinId,type:type,startTime:startTime,endTime:endTime,pageNum:pageNum,pageSize:pageSize)) { (_, response) in
            guard response.success,let data = response.data else {
                callBack?(nil,response)
                return
            }
            let model = IMRedPacketRecordListModel(with: data)
            callBack?(model,response)
        }
    }
    
    func redPacketReceiveDetail(packetId: String, callBack: RedPacketReceiveHandler?) {
        self.request(.redPacketReceiveDetail(packetId: packetId)) { (_, response) in
            guard response.success else {
                callBack?(nil,response)
                return
            }
            guard let data = response.data?["rows"].arrayValue else {
                callBack?(nil,response)
                return
            }
            let arr = data.compactMap({ IMRedPacketReceiveModel.init(with: $0)})
            callBack?(arr,response)
        }
    }
}

//MARK: 赞赏
extension HttpConnect {
    func praiseList(channelType: Int, targetId: String, number: Int?, startId: String?,completionBlock: NormalHandler?) {
        self.request(.praiseList(channelType: channelType, targetId: targetId, number: number, startId: startId)) { (_, response) in
            completionBlock?(response)
        }
    }
    
    func praiseDetailList(channelType: Int, logId: String, number: Int?, startId: String?,completionBlock: NormalHandler?) {
        self.request(.praiseDetailList(channelType: channelType, logId: logId, number: number, startId: startId)) { (_, response) in
            completionBlock?(response)
        }
    }
    
    func praiseDetail(channelType: Int, logId: String,completionBlock: NormalHandler?) {
        self.request(.praiseDetail(channelType: channelType, logId: logId)) { (_, response) in
            completionBlock?(response)
        }
    }
    
    func praiseReward(channelType: SocketChannelType, logId: String,currency:String,amount:Double,password:String,completionBlock: NormalHandler?) {
        self.request(.praiseReward(channelType: channelType, logId: logId, currency: currency, amount: amount, password: password)) { (_, response) in
            completionBlock?(response)
        }
    }
    //打赏用户
    func rewardUser(userId: String, currency: String, amount: Double, password: String, completionBlock: NormalHandler?) {
        self.request(.rewardUser(userId: userId, currency: currency, amount: amount, password: password)) { (_, response) in
            completionBlock?(response)
        }
    }
}

extension HttpConnect {
    func groupFiles(groupId: String,startId: String,number: Int, query: String, owner: String,completionBlock: NormalHandler?) {
        self.request(.groupFiles(groupId: groupId, startId: startId, number: number, query: query, owner: owner)) { (_, response) in
            completionBlock?(response)
        }
    }
    
    func groupPhotosAndVideos(groupId: String, startId: String, number: Int ,completionBlock: NormalHandler?) {
        self.request(.groupPhotosAndVideos(groupId: groupId, startId: startId, number: number)) { (_, response) in
            completionBlock?(response)
        }
    }
    
    func friendFiles(friendId: String,startId: String,number: Int, query: String, owner: String ,completionBlock: NormalHandler?) {
        self.request(.friendFiles(firendId: friendId, startId: startId, number: number, query: query, owner: owner)) { (_, response) in
            completionBlock?(response)
        }
    }
    
    func friendPhotosAndVideos(friendId: String, startId: String, number: Int ,completionBlock: NormalHandler?) {
        self.request(.friendPhotosAndVideos(firendId: friendId, startId: startId, number: number)) { (_, response) in
            completionBlock?(response)
        }
    }
    
    func revokeFiles(fileIds:[String], type: Int, completionBlock: NormalHandler?) {
        self.request(.revokeFiles(fileIds: fileIds, type: type)) { (_, response) in
            completionBlock?(response)
        }
    }
}

extension HttpConnect {
    func isSetPayPwd(completionBlock: BoolHandler?) {
        self.request(.isSetPayPwd) { (_, response) in
            let isSetPayPwd = response.data?["IsSetPayPwd"].intValue == 0 ? false : true
            completionBlock?(isSetPayPwd,response)
        }
    }
    
    func setPayPwd(mode: String, type: String, code: String, oldPayPassword: String, payPassword: String, completionBlock: NormalHandler?) {
        self.request(.setPayPwd(mode: mode, type: type, code: code, oldPayPassword: oldPayPassword, payPassword: payPassword)) { (_, response) in
            completionBlock?(response)
        }
    }
}

extension HttpConnect {
    func getRedPacketCoinInfo(completionBlock: NormalHandler?) {
        self.request(.getRedPacketCoinInfo) { (_, response) in
            completionBlock?(response)
        }
    }
    func getRedPacketBalance(completionBlock: NormalHandler?) {
        self.request(.getRedPacketBalance) { (_, response) in
            completionBlock?(response)
        }
    }
}

extension HttpConnect {
    func open(completionBlock: NormalHandler?) {
        self.request(.open) { (_, response) in
            completionBlock?(response)
        }
    }
}

extension HttpConnect {
    func payment(logId: String, currency: String, amount: String, fee: String, opp_address: String, rid: String, mode: String, payword: String, code: String,completionBlock: NormalHandler?) {
        self.request(.payment(logId: logId, currency: currency, amount: amount, fee: fee, opp_address: opp_address, rid: rid, mode: mode, payword: payword, code: code)) { (_, response) in
            completionBlock?(response)
        }
    }
}

extension HttpConnect {
    func getRoomSessionKey(completionBlock:GroupKeysHandler?) {
        guard let loginUserId = IMLoginUser.shared().currentUser?.userId else { return }
        var timestamp = FZM_UserDefaults.double(forKey: "getRoomSessionKeyTime-\(loginUserId)")
        if timestamp < 0.01 {
            timestamp = Date.timestamp
        }
        
        if let msg = SocketMessage.getOldestMsgs() {
            if timestamp == msg.datetime {
                let response = HttpResponse.init()
                response.success = true
                completionBlock?(nil,response)
                return
            } else {
                timestamp = msg.datetime
            }
        }
        //获取起始时间到timestamp之间的所有群秘钥
        self.request(.getRoomSessionKey(timestamp: timestamp)) { (_, response) in
            guard response.success else {
                completionBlock?(nil,response)
                return
            }
            FZM_UserDefaults.set(timestamp, forKey: "getRoomSessionKeyTime-\(loginUserId)")
            FZM_UserDefaults.synchronize()
            
            guard let array = response.data?["logs"].array else {
                completionBlock?(nil,response)
                return
            }
            DispatchQueue.global().async {
                for json in array {
                    if let fromKey = json["msg"]["fromKey"].string,
                        let key = json["msg"]["key"].string,
                        let keyId = json["msg"]["kid"].string,
                        let groupId = json["msg"]["roomId"].string {
                        IMLoginUser.shared().currentUser?.setGroupKey(groupId: groupId, fromKey: fromKey, key: key, keyId: keyId)
                    }
                }
            }
            completionBlock?(nil,response)
        }
    }
}

extension HttpConnect {
    func refreshTodayWorkRecord(completionBlock: NormalHandler?) {
        self.request(.workTodayRecords) { (_, response) in
            completionBlock?(response)
        }
    }
    func workClockIn(address: String, longitude: Double, latitude: Double, content: String,completionBlock: NormalHandler?) {
        self.request(.workClockIn(address: address, longitude: longitude, latitude: latitude, content: content)) { (_, response) in
            completionBlock?(response)
        }
    }
    func getWorkUserInfo(completionBlock: WorkUserHandler?) {
        self.request(.workUserInfo) { (_, response) in
            if  response.success ,
                let name = response.data?["name"].string,
                let company = response.data?["enterpriseName"].string,
                let code = response.data?["code"].string {
                let workUser = FZMWorkUser.init(name: name, company: company, code: code)
                completionBlock?(workUser,response)
            } else {
                completionBlock?(nil,response)
            }
        }
    }
    
    func editReason(id: String, reason: String, completionBlock: NormalHandler?) {
        self.request(.editReason(id: id, reason: reason)) { (_, response) in
            completionBlock?(response)
        }
    }
    
    func cancelApply(id: String, completionBlock: NormalHandler?) {
        self.request(.cancelApply(id: id)) { (_, response) in
            completionBlock?(response)
        }
    }
}

extension HttpConnect {
    // 点赞:isLike = true, 取消点赞: isLike = false
    func like(channelType: SocketChannelType, logId: String, isLike: Bool, completionBlock: NormalHandler?) {
        self.request(.like(channelType: channelType, logId: logId, isLike: isLike)) { (_, response) in
            completionBlock?(response)
        }
    }
}


//MARK:合约
extension HttpConnect {
    //构造并发送不收手续费交易
    func createNoBalanceTransaction(txHex: String, completionBlock: NormalHandler?) {
        let privateKey = NoBalanceTransactionPrivKey
        self.request(.createNoBalanceTransaction(privateKey: privateKey, txHex: txHex)) { (_, response) in
            completionBlock?(response)
        }
    }
    
    //签名
    func sign(privateKey: String, txHex: String, fee: Int, completionBlock: NormalHandler?) {
        self.request(.sign(privateKey: privateKey, txHex: txHex, fee: fee)) { (_, response) in
            completionBlock?(response)
        }
    }
    
    //发送交易
    func sendTransaction(data: String, completionBlock: NormalHandler?) {
        self.request(.sendTransaction(data: data)) {(_, response) in
            completionBlock?(response)
        }
    }
    
    //签名并发送交易
    func signAndSendTransaction(privateKey: String, txHex: String, fee: Int, completionBlock: NormalHandler?) {
        HttpConnect.shared().sign(privateKey: privateKey, txHex:txHex, fee: fee) { (response2) in
            if response2.success,
                let data = response2.data?.dictionaryValue["result"]?.string {
                HttpConnect.shared().sendTransaction(data: data) { (response3) in
                    if response3.success {
                        completionBlock?(response3)
                    }
                }
            }
        }
    }
    
    //构造不收手续费交易, 签名并发送交易
    func createAndSignAndSendTransaction(privateKey: String, txHex: String, fee: Int, completionBlock: NormalHandler?) {
        HttpConnect.shared().createNoBalanceTransaction(txHex: txHex) { (response) in
            if response.success,
                let data = response.data?.dictionaryValue["result"]?.string {
                HttpConnect.shared().signAndSendTransaction(privateKey: privateKey, txHex: data, fee: fee, completionBlock: completionBlock)
            }
        }
    }
    
    //添加联系人
    func addFriends(address: [String], completionBlock: NormalHandler?) {
        guard let privateKey = IMLoginUser.shared().currentUser?.privateKey else {
            let response = HttpResponse.init(failMsg: "私钥错误,添加联系人上链失败")
            completionBlock?(response)
                return
        }
        let friends = address.compactMap { ["friendAddress": $0, "type": 1]}
        let params = ["friends": friends] as [String: Any]
        self.request(.updateFriends(params: [params])) { (_, response) in
            if response.success,
                let result = response.data?.dictionaryValue["result"]?.string {
                HttpConnect.shared().createAndSignAndSendTransaction(privateKey: privateKey, txHex: result, fee: 0) { (response2) in
                    completionBlock?(response2)
                }
            }
        }
    }
    //删除联系人
    func deleteFriends(address: [String], completionBlock: NormalHandler?) {
        guard let privateKey = IMLoginUser.shared().currentUser?.privateKey else {
            let response = HttpResponse.init(failMsg: "私钥错误,删除联系人上链失败")
            completionBlock?(response)
                return
        }
        let friends = address.compactMap { ["friendAddress": $0, "type": 2]}
        let params = ["friends": friends] as [String: Any]
        self.request(.updateFriends(params: [params])) { (_, response) in
            if response.success,
                let result = response.data?.dictionaryValue["result"]?.string {
                HttpConnect.shared().createAndSignAndSendTransaction(privateKey: privateKey, txHex: result, fee: 0) { (response2) in
                    completionBlock?(response2)
                }
            }
        }
    }
    
    //从合约拉取好友列表
    func getFriends(count: Int, index: String, completionBlock: NormalHandler?) {
        
        guard let publicKey = IMLoginUser.shared().currentUser?.publicKey,
            let privateKey = IMLoginUser.shared().currentUser?.privateKey,
            !publicKey.isEmpty,
            !privateKey.isEmpty else {
                completionBlock?(HttpResponse.init(failMsg: "获取好友失败"))
            return
        }
        let mainAddress = FZMEncryptManager.publicKeyToAddress(publicKey: publicKey)
        let time = Int(Date.timestamp)
        //按照字典key升序排序拼接字符串
        //拼接结果 "count=10000&index=&mainAddress=1NQSfNVefAf7yxQZEGxSbqc8NFBQRbRLWj&time=1581676678815"
        let dic = (["index": index, "mainAddress": mainAddress, "time": time,"count": count] as [String : Any])
        let str = dic.sorted { $0.key < $1.key }.compactMap { "\($0.key)=\($0.value)"}.joined(separator: "&")
        
        guard let rawValue = str.data(using: .utf8),
            let signature =  FZMEncryptManager.sign(data: rawValue, privateKey: privateKey) else {
                completionBlock?(HttpResponse.init(failMsg: "获取好友失败,签名错误"))
            return
        }
        self.request(.getFriends(mainAddress: mainAddress, count: count, index: index, time: time, publicKey: publicKey, signature: signature)) { (_, response) in
            completionBlock?(response)
        }
    }
    
    func getUsersInfo(uids: [String], completionBlock: FriendArrHandler?) {
        self.request(.getUsersInfo(uids: uids)) { (_, response) in
            guard response.success,
                let data = response.data?["userList"].array else {
                    completionBlock?([], response)
                    return
            }
            let users = data.map {IMUserModel(with: $0)}
            completionBlock?(users, response)
        }
    }
    
    
    
    //添加黑名单
    func addBlockList(address: [String], completionBlock: NormalHandler?) {
        guard let privateKey = IMLoginUser.shared().currentUser?.privateKey else {
            let response = HttpResponse.init(failMsg: "私钥错误,添加黑名单上链失败")
            completionBlock?(response)
                return
        }
        let friends = address.compactMap { ["targetAddress": $0, "type": 1]}
        let params = ["list": friends] as [String: Any]
        self.request(.updateBlockList(params: [params])) { (_, response) in
            if response.success,
                let result = response.data?.dictionaryValue["result"]?.string {
                HttpConnect.shared().createAndSignAndSendTransaction(privateKey: privateKey, txHex: result, fee: 0) { (response2) in
                    completionBlock?(response2)
                }
            }
        }
    }
    //删除黑名单
    func deleteBlockList(address: [String], completionBlock: NormalHandler?) {
        guard let privateKey = IMLoginUser.shared().currentUser?.privateKey else {
            let response = HttpResponse.init(failMsg: "私钥错误,删除黑名单上链失败")
            completionBlock?(response)
                return
        }
        let friends = address.compactMap { ["targetAddress": $0, "type": 2]}
        let params = ["list": friends] as [String: Any]
        self.request(.updateBlockList(params: [params])) { (_, response) in
            if response.success,
                let result = response.data?.dictionaryValue["result"]?.string {
                HttpConnect.shared().createAndSignAndSendTransaction(privateKey: privateKey, txHex: result, fee: 0) { (response2) in
                    completionBlock?(response2)
                }
            }
        }
    }
    
    
    
    
    //从合约拉取黑名单列表
    func getBlockList(count: Int, index: String, completionBlock: NormalHandler?) {
        
        guard let publicKey = IMLoginUser.shared().currentUser?.publicKey,
            let privateKey = IMLoginUser.shared().currentUser?.privateKey,
            !publicKey.isEmpty,
            !privateKey.isEmpty else {
                completionBlock?(HttpResponse.init(failMsg: "获取黑名单失败"))
            return
        }
        let mainAddress = FZMEncryptManager.publicKeyToAddress(publicKey: publicKey)
        let time = Int(Date.timestamp)
        //按照字典key升序排序拼接字符串
        //拼接结果 "count=10000&index=&mainAddress=1NQSfNVefAf7yxQZEGxSbqc8NFBQRbRLWj&time=1581676678815"
        let dic = (["index": index, "mainAddress": mainAddress, "time": time,"count": count] as [String : Any])
        let str = dic.sorted { $0.key < $1.key }.compactMap { "\($0.key)=\($0.value)"}.joined(separator: "&")
        
        guard let rawValue = str.data(using: .utf8),
            let signature =  FZMEncryptManager.sign(data: rawValue, privateKey: privateKey) else {
                completionBlock?(HttpResponse.init(failMsg: "获取黑名单失败,签名错误"))
            return
        }
        self.request(.getBlockList(mainAddress: mainAddress, count: count, index: index, time: time, publicKey: publicKey, signature: signature)) { (_, response) in
            completionBlock?(response)
        }
    }
}


extension Response {
    var responseJSON: JSON? {
//        guard self.statusCode == 200 else {return nil}
        guard let responseMapJSON = try? self.mapJSON() else {return nil}
        return JSON(responseMapJSON)
    }
    
    var responseMessage : String {
        guard let responseJson = self.responseJSON else {return noResponseFail}
        return responseJson["message"].stringValue
    }
}

let noResponseFail = "服务器异常"

public class HttpResponse: NSObject {
    var data : JSON?
    @objc public var code : Int = 0
    @objc public var message :String = noResponseFail
    @objc public var success : Bool = false
    @objc public var ocJson : [String:Any]? {
        return data?.dictionaryObject
    }
    init(with response : Response) {
        super.init()
        self.message = response.responseMessage
        self.data = response.responseJSON?["data"]
        if let code = response.responseJSON?["result"].int {
            self.code = code
            if code == 0 {
                self.success = true
            }
            if code == -1004 {
                self.success = false
                IMLoginUser.shared().clearUserInfo()
                let alert = FZMAlertView(onlyAlert: "登录失效, 请重新登录") { }
                alert.tag = -1004
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if UIApplication.shared.keyWindow?.viewWithTag(-1004) == nil {
                        alert.show()
                    }
                }
            }
        }else if let otherCode = response.responseJSON?["code"].int {
            self.code = otherCode
            if otherCode == 200 {
                self.success = true
            }
        }else if let error = response.responseJSON?["error"] {
            if let null = error.null {
                self.success = true
                self.data = response.responseJSON
            } else {
                self.success = false
                self.message = error.stringValue
            }
        }     
    }
    
    init(failMsg: String) {
        super.init()
        self.success = false
        self.message = failMsg
    }
    
    init(error: MoyaError) {
        super.init()
        self.success = false
        #if DEBUG
        self.message = error.localizedDescription
        #else
        if let error = error.errorUserInfo[NSUnderlyingErrorKey] as? NSError {
            if (error.code == NSURLErrorNotConnectedToInternet) {
                self.message = "无网络,请检查网络连接"
            } else if (error.code == NSURLErrorTimedOut) {
                self.message = "请求超时,请检查网络连接"
            } else if (error.code == NSURLErrorDNSLookupFailed) {
                self.message = "请求失败,请稍后再试"
            } else if (error.code == NSURLErrorBadServerResponse) {
                self.message = "未找到服务，请稍后再试"
            } else if (error.code == NSURLErrorCannotConnectToHost) {
                self.message = "连接错误,请稍后再试"
            }
        }
        if self.message.isEmpty {
            self.message = "网络连接错误,请稍后再试"
        }
        #endif
    }
    
    override init() {
        super.init()
    }
}
