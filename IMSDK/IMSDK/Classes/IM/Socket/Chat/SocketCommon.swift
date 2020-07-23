//
//  SocketCommon.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/28.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import Foundation

enum SocketEventType : Int {
    //聊天消息
    case message = 0
    //登录聊天室
    case joinRoom = 1
    //公告
    case announcement = 2
    //踢出聊天室
    case kickoutRoom = 3
    //关闭聊天室
    case closeRoom = 4
    //删除聊天室
    case deleteRoom = 5
    //开启聊天室
    case openNewRoom = 7
    //被顶号
    case raceAccount = 9
    //消息操作有关
    case bannedAccount = 10
    case bannedGroup = 11
    //入群通知
    case joinGroup = 20
    //退群通知
    case quitGroup = 21
    //解散群通知
    case dissolveGroup = 22
    //入群请求
    case pulledGroup = 23
    //群禁言
    case groupBanned = 25
    case updataGroupKey = 26
    //添加好友申请和回复通知
    case addApplyOrReply = 31
    //好友新增或删除
    case refreshFriendList = 32
    case updataUserPublicKey = 33
    case userUpdataPublicKey = 34
    //以往消息队列
    case fetchMsgList = 40
    //未读消息队列
    case fetchUnreadMsgList = 41
    //开始同步
    case startSynchronousMessage = 42
    //接收消息完成
    case completeGetMsg = 43
    //转发消息批量推送
    case fetchForwardMsgs = 44
    case beginAckMsgs = 45
    case ackMsgs = 46
    case ackMsgsCompleting = 47
}

public enum SocketChannelType : Int {
    //聊天室
    case chatRoom = 1
    //群组
    case group = 2
    //好友私聊
    case person = 3
}



