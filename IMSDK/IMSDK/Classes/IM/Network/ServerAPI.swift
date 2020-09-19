//
//  ServerAPI.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/20.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import Foundation
import Moya

enum ServerAPI {
    //MARK: 用户
    //账号密码登录
    case login(account: String, pwd: String)
    //token登录
    case tokenLogin(token: String, type: Int, clientId: String)
    //退出登录
    case logout
    //编辑头像
    case editHeadImgUrl(headImgUrl: String)
    //编辑自己昵称
    case editUserName(name: String)
    //根据用户id获取用户详情
    case getUserDetailInfo(userId: String)
    //获取未处理申请数量
    case getUndealApplyNumber
    //获取邀请码
    case getInviteCode
    //获取用户配置
    case getConfigure
    //更新推送deviceToken（友盟）
    case setDeviceToken(deviceToken: String)
    
    //MARK: 聊天室
    //获取聊天室列表
    case getChatRoomList(status: Int)
    //获取聊天室聊天记录
    case getChatRoomMsgList(roomId: String, startId: String?, number: Int)
    //获取好友聊天记录
    case getFriendMsgList(friendId: String, startId: String?, number: Int)
    
    //MARK: 群
    //获取群列表 1：普通，2：常用 , 3：全部
    case getGroupList(type:Int)
    //获取群聊天记录
    case getGroupMsgList(roomId: String, startId: String?, number: Int)
    //创建群
    case createGroup(name: String?, avatar: String?, users:[String], encrypt: Int)
    //删除群
    case deleteGroup(groupId:String)
    //踢出群
    case kickOutGroupUsers(groupId:String,users:[String])
    //退出群
    case quitGroup(groupId:String)
    //获取群信息
    case getGroupDetailInfo(groupId:String)
    //管理员设置群
    case groupSetPermission(groupId:String,canAddFriend:Int?,joinPermission:Int?,recordPermission:Int?)
    //获取群成员列表
    case getGroupMemberList(groupId:String)
    //群内用户身份设置
    case setGroupUserLevel(groupId:String,userId:String,level:Int)
    //邀请入群
    case inviteJoinGroup(groupId:String,users:[String])
    //申请入群
    case applyJoinGroup(groupId:String,reason:String?,source:[String: Any])
    //入群申请处理
    case dealGroupApply(groupId:String,userId:String,agree:Bool)
    //修改群头像
    case editGroupAvatar(groupId:String,avatar:String)
    //修改群名称
    case editGroupName(groupId:String,name:String)
    //群成员设置免打扰 1：开启，2：关闭
    case groupSetDisturbing(groupId:String,on:Int)
    //群成员设置群置顶 1 置顶 2 不置顶
    case groupSetOnTop(groupId:String,on:Int)
    //获取所有群未读消息统计
    case groupGetUnreadMsg
    //获取群成员信息
    case groupGetUserInfo(groupId:String,userId:String)
    //群成员设置群内昵称
    case groupSetMyNickname(groupId:String,nickname:String)
    //获取群公告
    case groupGetNotifyList(groupId:String,startId:String?)
    //禁言用户
    case bannedGroupUser(groupId:String,userId:String,deadline:Double)
    //禁言列表设置 listType:1：全员发言 2：黑名单 3：白名单 4：全员禁言
    case groupBannedSet(groupId:String,listType:Int,users:[String],deadline:Double)
    //发布群公告
    case groupReleaseNotify(groupId:String,content:String)
    //判断用户是否在群里
    case isInGroup(groupId:String)
    
    //通讯录
    //获取入群/好友申请列表
    case getContactApplyList(lastId: Int?, number: Int)
    //精确搜索用户/群
    case searchContact(searchId: String)
    //获取好友列表 //1：普通，2：常用  3：全部
    case getFriendList(type: Int, time: Int?)
    //添加好友申请
    case addFriendApply(userId: String, remark: String, reason: String, source: [String: Any], answer: String?)
    //删除好友
    case deleteFriend(userId: String)
    //好友申请处理
    case dealFriendApply(userId: String, agree: Bool)
    //修改好友备注
    case editFriendRemark(userId: String, remark: String)
    case editFriendExtRemark(userId: String, remark: String,tels:[[String:String]]?,des: String?,pics:[String]?)
    case editFriendEncryptExtRemark(userId: String, encryptRemark: String,encryptExt: String)
    //好友设置免打扰 1：开启，2：关闭
    case friendSetDisturbing(userId:String,on:Int)
    //好友设置置顶 1 置顶 2 不置顶
    case friendSetOnTop(userId:String,on:Int)
    //获取所有好友未读消息统计
    case friendGetUnreadMsg
    //是否为好友
    case isFriend(userId: String)
    //阅后即焚消息截图
    case printScreen(userId: String)
    //设置是否需要验证
    case setAddNeedAuth(need: Bool)
    //设置问题答案 //tp = 0  修改问题答案  需要同时传入问题答案 //tp = 1  设置需要回答问题  需要同时传入问题答案 //tp = 2  设置不需要回答问题
    case setAuthQuestion(tp: Int, question: String, answer: String)
    //验证答案是否正确
    case checkAnswer(userId: String, answer: String)
    
    //MARK: 红包模块
    //查询账号余额
    case queryRedPacketBalance
    //获取红包信息
    case getRedPacketInfo(packetId: String)
    //发红包
    case sendRedPacket(isGroup:Int,toID: String, coin : Int , type : Int , amount : Double , size : Int , remark : String, toUsers: String, ext:[String: String])
    //领取红包
    case receiveRedPacket(packetId: String)
    //查询用户红包收发记录
    case redPacketRecord(operation:Int, coinId:Int?,type:Int?,startTime:Int?,endTime:Int?,pageNum:Int,pageSize:Int)
    
    //版本更新
    case requestVersion
    //个推更新cid
    case refreshCid(cid: String)
    //撤回消息 managerList
    case revokeMessage(msgId: String, type: Int)
    //阅读指定一条阅后即焚消息
    case burnMessage(msgId: String, type: Int)
    //消息转发
    case forwardMsgs(sourceId: String, type: Int, forwardType: Int, msgIds: [String], targetRooms: [String], targetUsers: [String])
    case encryptForwardMsg(roomLogs:[Any], type: Int, userLogs: [Any])
    case groupFiles(groupId: String,startId: String,number: Int, query: String, owner: String)
    case groupPhotosAndVideos(groupId: String, startId: String, number: Int)
    case friendFiles(firendId: String,startId: String,number: Int, query: String, owner: String)
    case friendPhotosAndVideos(firendId: String, startId: String, number: Int)
    case revokeFiles(fileIds:[String], type: Int)
    case isSetPayPwd
    case setPayPwd(mode: String,type: String,code: String, oldPayPassword:String, payPassword:String)
    case getRedPacketCoinInfo
    case getRedPacketBalance
    case redPacketReceiveDetail(packetId: String)
    case open
    case payment(logId:String, currency: String, amount: String, fee: String, opp_address: String,rid: String, mode: String, payword: String, code: String)
    case getRoomSessionKey(timestamp:Double)
    case getRecommendRoom(number: Int ,times: Int)
    case batchJoinRoomApply(rooms:[String])
    case inviteStatistics
    case singleInviteInfo(page: Int ,size: Int)
    case accumulateInviteInfo(page: Int ,size: Int)
    case moduleState
    case setNeedConfirmInvite(need: Bool)
    case block(userId: String)
    case unBlock(userId: String)
    case blockList
    //上传公钥和加密的助记词
    case uploadSecretKey(pubKey: String, seed: String)
    //获取公司信息
    case workUserInfo
    //打卡
    case workClockIn(address: String, longitude: Double, latitude: Double,content: String)
    //今日打卡信息
    case workTodayRecords
    //撤回打卡申请
    case cancelApply(id: String)
    //编辑外勤申请理由
    case editReason(id: String, reason: String)
    //点赞
    case like(channelType: SocketChannelType, logId: String, isLike: Bool)
    //赞赏列表
    case praiseList(channelType: Int, targetId: String, number: Int?, startId: String?)
    //赞赏详情列表
    case praiseDetailList(channelType: Int, logId: String, number: Int?, startId: String?)
    //赞赏详情
    case praiseDetail(channelType: Int, logId: String)
    //赞赏
    case praiseReward(channelType: SocketChannelType, logId: String,currency:String,amount:Double,password:String)
    //打赏用户
    case rewardUser(userId: String, currency: String, amount: Double, password: String)
    //历史排行
    case rankingHistory(page: Int, number: Int)
    //本周赞赏榜单
    case rewardRaning(type: Int, startTime: Double, endTime: Double, startId: Int, number: Int)
    
    //去中心化
    // 构造并发送不收手续费交易
    case createNoBalanceTransaction(privateKey: String, txHex: String)
    //签名 https://chain.33.cn/document/93
    case sign(privateKey: String, txHex: String, fee: Int)
    //发送交易
    case sendTransaction(data: String)
    //更新好友 https://gitlab.33.cn/chat/contract
    case updateFriends(params: [[String:Any]])
    //获取合约上的好友 index 索引开始地址
    case getFriends(mainAddress: String, count: Int, index: String, time: Int, publicKey: String, signature: String)
    //通过uid(地址)批量获取用户信息
    case getUsersInfo(uids: [String])
    //更新黑名单 https://gitlab.33.cn/chat/contract
    case updateBlockList(params: [[String:Any]])
    //获取合约上的黑名单 index 索引开始地址
    case getBlockList(mainAddress: String, count: Int, index: String, time: Int, publicKey: String, signature: String)
}

extension ServerAPI : TargetType {
    var baseURL: URL {
        switch self {
        case .workUserInfo, .workClockIn, .workTodayRecords, .cancelApply, .editReason:
            return URL.init(string: NetworkDomain + "/work")!
        case .sign, .sendTransaction, .updateFriends, .getFriends, .updateBlockList, .getBlockList, .createNoBalanceTransaction:
            return URL.init(string: ContractDomain)!
        default:
            return URL(string: NetworkDomain + "/chat")!
        }
    }
    
    var path: String {
        switch self {
        case .login:
            return "/user/pwdLogin"
        case .tokenLogin:
            return "/user/tokenLogin"
        case .logout:
            return "/user/logout"
        case .editHeadImgUrl:
            return "/user/editAvatar"
        case .editUserName:
            return "/user/editNickname"
        case .getUserDetailInfo:
            return "/user/userInfo"
        case .getInviteCode:
            return "/chat33/getInviteCode"
        case .getConfigure:
            return "/user/userConf"
        case .setDeviceToken:
            return "/user/set-device-token"
        case .getChatRoomList:
            return "/group/list"
        case .getChatRoomMsgList:
            return "/group/getGroupChatHistory"
        case .getFriendMsgList:
            return "/friend/chatLog"
        case .getContactApplyList:
            return "/chat33/applyList"
        case .searchContact:
            return "/chat33/search"
        case .getFriendList:
            return "/friend/list"
        case .addFriendApply:
            return "/friend/add"
        case .deleteFriend:
            return "/friend/delete"
        case .dealFriendApply:
            return "/friend/response"
        case .editFriendRemark:
            return "/friend/setRemark"
        case .friendSetDisturbing:
            return "/friend/setNoDisturbing"
        case .friendSetOnTop:
            return "/friend/stickyOnTop"
        case .friendGetUnreadMsg:
            return "/friend/unread"
        case .setAddNeedAuth:
            return "/friend/confirm"
        case .setAuthQuestion:
            return "/friend/question"
        case .checkAnswer:
            return "/friend/checkAnswer"
        case .getGroupList:
            return "/room/list"
        case .getGroupMsgList:
            return "/room/chatLog"
        case .createGroup:
            return "/room/create"
        case .deleteGroup:
            return "/room/delete"
        case .kickOutGroupUsers:
            return "/room/kickOut"
        case .quitGroup:
            return "/room/loginOut"
        case .getGroupDetailInfo:
            return "/room/info"
        case .groupSetPermission:
            return "/room/setPermission"
        case .getGroupMemberList:
            return "/room/userList"
        case .setGroupUserLevel:
            return "/room/setLevel"
        case .inviteJoinGroup:
            return "/room/joinRoomInvite"
        case .applyJoinGroup:
            return "/room/joinRoomApply"
        case .editGroupAvatar:
            return "/room/setAvatar"
        case .editGroupName:
            return "/room/setName"
        case .groupSetDisturbing:
            return "/room/setNoDisturbing"
        case .groupSetOnTop:
            return "/room/stickyOnTop"
        case .groupGetUnreadMsg:
            return "/room/unread"
        case .groupGetUserInfo:
            return "/room/userInfo"
        case .getUndealApplyNumber:
            return "/chat33/unreadApplyNumber"
        case .dealGroupApply:
            return "/room/joinRoomApprove"
        case .groupSetMyNickname:
            return "/room/setMemberNickname"
        case .groupGetNotifyList:
            return "/room/systemMsgs"
        case .queryRedPacketBalance:
            return "/red-packet/balance"
        case .getRedPacketInfo:
            return "/red-packet/detail"
        case .sendRedPacket:
            return "/red-packet/send"
        case .receiveRedPacket:
            return "/red-packet/receive-entry"
        case .redPacketRecord:
            return "/red-packet/statistic"
        case .requestVersion:
            return "/version"
        case .refreshCid:
            return "/GTCid"
        case .revokeMessage:
            return "/chat33/RevokeMessage"
        case .bannedGroupUser:
            return "/room/setMutedSingle"
        case .groupBannedSet:
            return "/room/setMutedList"
        case .groupReleaseNotify:
            return "/room/sendSystemMsgs"
        case .burnMessage:
            return "/chat33/readSnapMsg"
        case .isInGroup:
            return "/room/userIsInRoom"
        case .isFriend:
            return "/friend/isFriend"
        case .printScreen:
            return "/friend/printScreen"
        case .forwardMsgs:
            return "/chat33/forward"
        case .encryptForwardMsg:
            return "/chat33/encryptForward"
        case .editFriendExtRemark:
            return "/friend/setExtRemark"
        case .editFriendEncryptExtRemark:
            return "/friend/setExtRemark"
        case .groupFiles:
            return "/room/historyFiles"
        case .groupPhotosAndVideos:
            return "/room/historyPhotos"
        case .friendFiles:
            return "/friend/historyFiles"
        case .friendPhotosAndVideos:
            return "/friend/historyPhotos"
        case .revokeFiles:
            return "/chat33/RevokeFiles"
        case .isSetPayPwd:
            return "/user/isSetPayPwd"
        case .setPayPwd:
            return "/user/setPayPwd"
        case .getRedPacketCoinInfo:
            return "/red-packet/coin"
        case .getRedPacketBalance:
            return "/red-packet/balance"
        case .redPacketReceiveDetail:
            return "/red-packet/receiveDetail"
        case .open:
            return "/open"
        case .payment:
            return "/pay/payment"
        case .getRoomSessionKey:
            return "/chat33/roomSessionKey"
        case .getRecommendRoom:
            return "/room/recommend"
        case .batchJoinRoomApply:
            return "/room/batchJoinRoomApply"
        case .inviteStatistics:
            return "/user/invite-statistics"
        case .singleInviteInfo:
            return "/user/single-invite-info"
        case .accumulateInviteInfo:
            return "/user/accumulate-invite-info"
        case .moduleState:
            return "/public/module-state"
        case .setNeedConfirmInvite:
            return"/user/set-invite-confirm"
        case .block:
            return "/friend/block"
        case .unBlock:
            return "/friend/unblock"
        case .blockList:
            return "/friend/blocked-list"
        case .uploadSecretKey:
            return "/chat33/uploadSecretKey"
        case .workUserInfo:
            return "/user"
        case .workClockIn:
            return "/clockIn"
        case .workTodayRecords:
            return "/todayRecords"
        case .cancelApply:
            return "/outside/cancelApply"
        case .editReason:
            return "/outside/editReason"
        case .like:
            return "/praise/like"
        case .praiseList:
            return "/praise/list"
        case .praiseDetailList:
            return "/praise/detailList"
        case .praiseDetail:
            return "/praise/details"
        case .praiseReward:
            return "/praise/reward"
        case .rewardUser:
            return "/praise/rewardUser"
        case .rankingHistory:
            return "/praise/leaderboardHistory"
        case .rewardRaning:
            return "/praise/leaderboard"
        case .getUsersInfo:
            return "/user/usersInfo"
        case .sign, .sendTransaction, .updateFriends, .getFriends, .updateBlockList, .getBlockList, .createNoBalanceTransaction:
            return "/"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .getInviteCode:
            return .get
        default:
            return .post
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        default:
            guard let parameters = parameters else {return .requestPlain}
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        var headerDic : [String : String]? = [ : ]
        headerDic?["FZM-DEVICE"] = "iOS"
        headerDic?["Content-Type"] = "application/json"
        headerDic?["FZM-APP-ID"] = app_id
        headerDic?["FZM-DEVICE-NAME"] = currentDevice.description
        headerDic?["FZM-UUID"] = UserDefaults.getUUID()
        headerDic?["FZM-VERSION"] = String.getAppVersion()
        headerDic?["Fzm-Request-Source"] = "chat"
        headerDic?["FZM-iOS-CHANNEL"] = IMSDK.shared().channel == .AppleStore ? "appleStore" : "thirdParty"
        if IMLoginUser.shared().isLogin {
            if let user = IMLoginUser.shared().currentUser {
                headerDic?["Cookie"] = user.sessionId
                headerDic?["FZM-AUTH-TOKEN"] = user.token
                headerDic?["Authorization"] = "Bearer " + user.token
            }
        }else {
            headerDic?["Cookie"] = ""
            switch self {
            case .tokenLogin(let token, _, _):
                headerDic?["FZM-AUTH-TOKEN"] = token
            default:
                break
            }
        }
        return headerDic
    }
    
    var parameters: [String : Any]? {
        var dic: [String: Any]?
        switch self {
        case .login(let account, let pwd):
            dic = ["mobile":account,"password":pwd]
        case .tokenLogin( _, let type, let clientId):
            dic = ["type":type,"cid":clientId]
        case .editHeadImgUrl(let headImgUrl):
            dic = ["avatar":headImgUrl]
        case .editUserName(let name):
            dic = ["nickname":name]
        case .getUserDetailInfo(let userId):
            dic = ["id":userId]
        case .getChatRoomList(let status):
            dic = ["groupStatus":status]
        case .getChatRoomMsgList(let roomId, let startId, let number):
            dic = startId == nil ? ["id":roomId,"number":number] : ["id":roomId,"number":number,"startId":startId!]
        case .getFriendMsgList(let friendId, let startId, let number):
            dic = startId == nil ? ["id":friendId,"number":number] : ["id":friendId,"number":number,"startId":startId!]
        case .getContactApplyList(let lastId, let number):
            dic = lastId == nil ? ["number":number] : ["id":String(lastId!),"number":number]
        case .searchContact(let searchId):
            dic = ["markId":searchId]
        case .getFriendList(let type, let time):
            dic = time != nil ? ["type":type,"time":time!] : ["type":type]
        case .addFriendApply(let userId, let remark, let reason, let source, let answer):
            dic = answer == nil ? ["id":userId,"remark":remark,"reason":reason] : ["id":userId,"remark":remark,"reason":reason,"answer":answer!]
            if let sourceType = source["sourceType"] {
                dic!["sourceType"] = sourceType
            }
            if let sourceId = source["sourceId"] {
                dic!["sourceId"] = sourceId
            }
        case .deleteFriend(let userId):
            dic = ["id":userId]
        case .dealFriendApply(let userId, let agree):
            dic = ["id":userId,"agree": agree ? 1 : 2]
        case .editFriendRemark(let userId, let remark):
            dic = ["id":userId,"remark":remark]
        case .setDeviceToken(let deviceToken):
            dic = ["deviceToken": deviceToken]
        case .getGroupList(let type):
            dic = ["type":type]
        case .getGroupMsgList(let roomId, let startId, let number):
            dic = startId == nil ? ["id":roomId,"number":number] : ["id":roomId,"number":number,"startId":startId!]
        case .createGroup(let name, let avatar,let users,let encrypt):
            dic = ["users":users]
            if let name = name {
                dic!["roomName"] = name
            }
            if let avatar = avatar {
                dic!["roomAvatar"] = avatar
            }
            dic!["encrypt"] = encrypt
        case .deleteGroup(let groupId):
            dic = ["roomId":groupId]
        case .kickOutGroupUsers(let groupId, let users):
            dic = ["roomId":groupId,"users":users]
        case .quitGroup(let groupId):
            dic = ["roomId":groupId]
        case .getGroupDetailInfo(let groupId):
            dic = ["roomId":groupId]
        case .groupSetPermission(let groupId, let canAddFriend, let joinPermission, let recordPermission):
            dic = ["roomId":groupId]
            if let canAddFriend = canAddFriend {
                dic!["canAddFriend"] = canAddFriend
            }
            if let joinPermission = joinPermission {
                dic!["joinPermission"] = joinPermission
            }
            if let recordPermission = recordPermission {
                dic!["recordPermission"] = recordPermission
            }
        case .getGroupMemberList(let groupId):
            dic = ["roomId":groupId]
        case .setGroupUserLevel(let groupId, let userId, let level):
            dic = ["roomId":groupId,"userId":userId,"level":level]
        case .inviteJoinGroup(let groupId, let users):
            dic = ["roomId":groupId,"users":users]
        case .applyJoinGroup(let groupId, let reason, let source):
            dic = reason == nil ? ["roomId":groupId] : ["roomId":groupId,"applyReason":reason!]
            if let sourceType = source["sourceType"] {
                dic!["sourceType"] = sourceType
            }
            if let sourceId = source["sourceId"] {
                dic!["sourceId"] = sourceId
            }
        case .editGroupAvatar(let groupId, let avatar):
            dic = ["roomId":groupId,"avatar":avatar]
        case .editGroupName(let groupId, let name):
            dic = ["roomId":groupId,"name":name]
        case .groupSetDisturbing(let groupId, let on):
            dic = ["roomId":groupId,"setNoDisturbing":on]
        case .groupSetOnTop(let groupId, let on):
            dic = ["roomId":groupId,"stickyOnTop":on]
        case .friendSetDisturbing(let userId, let on):
            dic = ["id":userId,"setNoDisturbing":on]
        case .friendSetOnTop(let userId, let on):
            dic = ["id":userId,"stickyOnTop":on]
        case .groupGetUserInfo(let groupId, let userId):
            dic = ["roomId":groupId,"userId":userId]
        case .dealGroupApply(let groupId, let userId, let agree):
            dic = ["roomId":groupId,"userId":userId,"agree": agree ? 1 : 2]
        case .groupSetMyNickname(let groupId, let nickname):
            dic = ["roomId":groupId,"nickname":nickname]
        case .groupGetNotifyList(let groupId, let startId):
            dic = startId == nil ? ["roomId":groupId,"number":20] : ["roomId":groupId,"number":20,"startId":startId!]
        case .bannedGroupUser(let groupId, let userId, let deadline):
            dic = ["roomId":groupId,"userId":userId,"deadline":Int(deadline)]
        case .groupBannedSet(let groupId, let listType, let users, let deadline):
            dic = ["roomId":groupId,"listType":listType,"users":users,"deadline":Int(deadline)]
        case .groupReleaseNotify(let groupId, let content):
            dic = ["roomId":groupId,"content":content]
        case .getRedPacketInfo(let packetId):
            dic = ["packetId":packetId]
        case .sendRedPacket(let isGroup,let toID,let coin,let type,let amount,let size,let remark,let toUsers, let ext):
            dic = ["toId":String(toID),"coin":coin,"type":type,"amount":amount,"size":size,"remark":remark,"cType":isGroup,"toUsers":toUsers,"ext":ext]
        case .receiveRedPacket(let packetId):
            dic = ["packetId":packetId]
        case .redPacketRecord(let operation, let coinId,let type,let startTime,let endTime,let pageNum,let pageSize):
            dic = ["operation":operation,"pageNum":pageNum,"pageSize":pageSize]
            if let coinId = coinId { dic?["coinId"] = coinId }
            if let type = type { dic?["type"] = type }
            if let startTime = startTime { dic?["startTime"] = startTime }
            if let endTime = endTime { dic?["endTime"] = endTime }
        case .requestVersion:
            dic = ["nowVersionName":Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String]
        case .refreshCid(let cid):
            dic = ["cid": cid]
        case .revokeMessage(let msgId, let type):
            dic = ["logId":msgId,"type":type]
        case .burnMessage(let msgId, let type):
            dic = ["logId":msgId,"type":type]
        case .isInGroup(let groupId):
            dic = ["roomId":groupId]
        case .isFriend(let userId):
            dic = ["friendId":userId]
        case .printScreen(let userId):
            dic = ["id":userId]
        case .forwardMsgs(let sourceId, let type, let forwardType, let msgIds, let targetRooms, let targetUsers):
            dic = ["sourceId": sourceId, "type": type, "forwardType": forwardType, "logArray": msgIds, "targetRooms":targetRooms, "targetUsers": targetUsers]
        case .encryptForwardMsg(let roomLogs, let type, let userLogs):
            dic = ["roomLogs":roomLogs, "type": type, "userLogs": userLogs]
        case .setAddNeedAuth(let need):
            dic = ["tp": need ? 1 : 2]
        case .setAuthQuestion(let tp, let question, let answer):
            if tp == 2 {
                dic = ["tp":2]
            }else {
                dic = ["tp":tp,"question":question,"answer":answer]
            }
        case .checkAnswer(let userId, let answer):
            dic = ["friendId":userId,"answer":answer]
        case .editFriendExtRemark(let userId, let remark, let tels, let des, let pics):
            dic = ["id":userId,"remark":remark,"telephones": tels ?? [["":""]],"description":des ?? "","pictures":pics ?? [""]]
        case .editFriendEncryptExtRemark(let userId, let encryptRemark, let encryptExt):
            dic = ["id":userId,"remark": encryptRemark, "encrypt": encryptExt]
        case .groupFiles(let groupId,let startId, let number, let query, let owner):
            dic = ["id":groupId,"startId":startId,"number":number,"query":query,"owner":owner]
        case .groupPhotosAndVideos(let groupId, let startId, let number):
            dic = ["id":groupId,"startId":startId,"number":number]
        case .friendFiles(let firendId,let startId, let number, let query, let owner):
            dic = ["id":firendId,"startId":startId,"number":number,"query":query,"owner":owner]
        case .friendPhotosAndVideos(let firendId, let startId, let number):
            dic = ["id":firendId,"startId":startId,"number":number]
        case .revokeFiles(let fileIds, let type):
            dic = ["logs":fileIds,"type":type]
        case .setPayPwd(let mode,let type,let code, let oldPayPassword, let payPassword):
            dic = ["mode": mode, "type":type,"code": code, "oldPayPassword":oldPayPassword,"payPassword":payPassword ]
        case .redPacketReceiveDetail(let packetId):
            dic = ["packetId":packetId]
        case .payment(let logId, let currency, let amount, let fee, let opp_address, let rid, let mode, let payword, let code):
                dic = ["logId": logId, "currency" : currency, "amount": amount, "fee": fee, "opp_address": opp_address, "rid":rid, "mode": mode, "payword":payword, "code":code]
        case .getRoomSessionKey(let timestamp):
            dic = ["datetime": Int(timestamp)]
        case .getRecommendRoom(let number, let times):
            dic = ["number":number, "times":times]
        case .batchJoinRoomApply(let rooms):
            dic = ["rooms": rooms]
        case .singleInviteInfo(let page ,let size):
            dic = ["page": page, "size": size]
        case .accumulateInviteInfo(let page ,let size):
            dic = ["page": page, "size": size]
        case .setNeedConfirmInvite(let need):
            dic = ["needConfirmInvite":need ? 1 : 2]
        case .block(let userId):
            dic = ["userId": userId]
        case .unBlock(let userId):
            dic = ["userId": userId]
        case .uploadSecretKey(let pubKey, let seed):
            dic = ["publicKey": pubKey, "privateKey": seed]
        case .workClockIn(let address, let longitude, let latitude, let content):
            dic = ["location": ["address": address, "longitude": longitude, "latitude": latitude], "content": content]
        case .editReason(let id, let reason):
            dic = ["id": id,"reason": reason]
        case .cancelApply(let id):
            dic = ["id": id]
        case .like(let channelType, let logId, let isLike):
            dic = ["channelType": channelType.rawValue, "logId": logId, "action": isLike ? "like": "cancel_like"]
        case .praiseList(let channelType,let targetId,let number,let startId):
            dic = ["channelType":channelType,"targetId":targetId,"number":number ?? 20]
            if let startId = startId { dic?["startId"] = startId }
        case .praiseDetail(let channelType,let logId):
            dic = ["channelType":channelType,"logId":logId]
        case .praiseDetailList(let channelType,let logId,let number,let startId):
            dic = ["channelType":channelType,"logId":logId,"number":number ?? 20]
            if let startId = startId { dic?["startId"] = startId }
        case .praiseReward(let channelType,let logId,let currency,let amount,let password):
            dic = ["channelType":channelType.rawValue,"logId":logId,"currency":currency, "amount":amount, "password":password]
        case .rewardUser(let userId, let currency, let amount, let password):
            dic = ["userId": userId, "currency": currency, "amount": amount, "password": password]
        case .rankingHistory(let page, let number):
            dic = ["page": page, "size": number]
        case .rewardRaning(let type, let startTime, let endTime, let startId, let number):
            dic = ["type": type, "startTime": Int(startTime),"endTime": Int(endTime), "startId": startId, "number": number]
        case .createNoBalanceTransaction(let privateKey, let txHex):
            dic = ["jsonrpc": "2.0",
                   "id":12333,
            "method": "Chain33.CreateNoBalanceTransaction",
            "params":[["privkey": privateKey,
                       "txHex": txHex,
                       "index":0]]]
        case .sign(let privateKey, let txHex, let fee):
            dic = ["jsonrpc": "2.0",
                   "id":12333,
            "method": "Chain33.SignRawTx",
            "params":[["privkey": privateKey,
                      "txHex": txHex,
                      "expire": "2h45m",
                      "fee": fee,
                      "index":2]]]
        case .sendTransaction(let data):
            dic = ["jsonrpc": "2.0",
                   "id":12333,
            "method": "Chain33.SendTransaction",
            "params":[["data": data]]]
        case .updateFriends(let params):
            dic = ["jsonrpc": "2.0",
                   "id":12333,
                   "method": "chat.CreateRawUpdateFriendTx",
                   "params":params]
        case .getFriends(let mainAddress, let count, let index, let time, let publicKey, let signature):
            let params = ["execer": "chat",
                          "funcName": "GetFriends",
                          "payload":["mainAddress":mainAddress,
                                     "count": count,
                                     "index": index,
                                     "time":time,
                                     "sign":["publicKey": publicKey,
                                             "signature": signature]]] as [String : Any]
            dic = ["jsonrpc": "2.0",
                   "id":12333,
                   "method": "Chain33.Query",
                   "params":[params]]
        case .getUsersInfo(let uids):
            dic = ["uids": uids]
        case .updateBlockList(let params):
            dic = ["jsonrpc": "2.0",
            "method": "chat.CreateRawUpdateBlockTx",
            "params":params]
        case .getBlockList(let mainAddress, let count, let index, let time, let publicKey, let signature):
            let params = ["execer": "chat",
                          "funcName": "GetBlockList",
                          "payload":["mainAddress":mainAddress,
                                     "count": count,
                                     "index": index,
                                     "time":time,
                                     "sign":["publicKey": publicKey,
                                             "signature": signature]]] as [String : Any]
            dic = ["jsonrpc": "2.0",
                   "method": "Chain33.Query",
                   "params":[params]]
        default:
            dic = nil
        }
        return dic
    }
}
