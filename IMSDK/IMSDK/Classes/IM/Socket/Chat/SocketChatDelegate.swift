//
//  SocketChatDelegate.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/20.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import Foundation

protocol SocketChatMsgDelegate: class {
    func receiveMessage(with msg: SocketMessage, isLocal: Bool)
    func receiveHistoryMsgList(with msgs: [SocketMessage], isUnread: Bool)
    func failSendMessage(with msg: SocketMessage)
}

protocol SocketConnectDelegate: class {
    func socketConnect()
    func socketDisConnect()
}


