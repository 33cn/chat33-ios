//
//  SocketManager.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/20.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import Starscream
import SwiftyJSON
import MBProgressHUD
import RxSwift

class SocketManager: NSObject {

    private static let sharedInstance = SocketManager()
    private var ws : WebSocket?
    private var shouldReconnect = true
    private let disposeBag = DisposeBag.init()
    private var timer = Timer.init()
    
    
    class func launchManager() {
        _ = self.shared()
        SocketChatManager.launch()
        FZNEncryptKeyManager.launch()
    }
    
    class func shared() -> SocketManager {
        return sharedInstance
    }
    
    private override init() {
        super.init()
        self.timer = Timer.init(timeInterval: 20, target: self, selector: #selector(sendPong), userInfo: nil, repeats: true)
        RunLoop.current.add(self.timer, forMode: .default)
        self.initSocket()
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .user)
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .appState)
        
        SocketChatManager.shared().isFinishedFetchMsgListSubject.subscribe {[weak self] (event) in
            guard case .next(let value) = event, let isFinishedFetchMsgList = value  else { return }
            if isFinishedFetchMsgList {
                self?.beginAckMsgs()
            }
        }.disposed(by: disposeBag)
    }
    
    private func initSocket(){
        self.configureSocket()
    }
    
    func configureSocket(){
        ws?.disconnect()
        ws = nil
        var request = URLRequest.init(url: URL.init(string: SocketServer)!)
        request.setValue(app_id, forHTTPHeaderField: "FZM-APP-ID")
        request.setValue("iOS", forHTTPHeaderField: "FZM-DEVICE")
        request.setValue(currentDevice.description, forHTTPHeaderField: "FZM-DEVICE-NAME")
        request.setValue(UserDefaults.getUUID(), forHTTPHeaderField: "FZM-UUID")
        if IMLoginUser.shared().isLogin {
            request.setValue(IMLoginUser.shared().currentUser?.sessionId, forHTTPHeaderField: "Cookie")
            request.setValue(IMLoginUser.shared().currentUser?.publicKey, forHTTPHeaderField: "FZM-PUBLIC-KEY")
        }
        request.timeoutInterval = 30.0
        ws = WebSocket.init(request: request)
        ws?.delegate = self
        self.connect()
    }
    
    func connect() {
        if IMLoginUser.shared().isLogin,
            let ws = self.ws,
            !ws.isConnected {
           ws.connect()
        }
    }
    func disconnect() {
        ws?.disconnect()
    }
    
    @objc func sendPong() {
        if let ws = self.ws, ws.isConnected {
            ws.write(pong: Data.init())
        }
    }
        
}
extension SocketManager : WebSocketDelegate{
    func websocketDidConnect(socket: WebSocketClient) {
        IMLog("已连接")
        IMNotifyCenter.shared().postMessage(event: .socketConnect)
        self.postTime()
        if IMLoginUser.shared().isLogin,
            let loginUser = IMLoginUser.shared().currentUser,
            !loginUser.publicKey.isEmpty {
            FZNEncryptKeyManager.shared().refreshUserPublicKey(loginUser.publicKey)
        }
    }
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        IMLog("重连中")
        IMNotifyCenter.shared().postMessage(event: .socketDisconnect)
        if let error = error as? WSError, error.code == 4001 || error.code == 4011 {
            HttpConnect.shared().logout(completionBlock: { (_) in
                IMLoginUser.shared().clearUserInfo()
                if let dic = JSON.init(parseJSON: error.message).dictionaryObject, let device = dic["device"] as? String, let time = dic["time"] as? Double {
                    let date = String.yyyyMMddDateString(with: time)
                    var byWay = ""
                    if let way = dic["way"] as? Int {
                        switch way {
                        case 1:
                            byWay = "通过短信验证码"
                        case 2:
                            byWay = "通过密码"
                        case 3:
                            byWay = "通过邮箱验证码"
                        case 4:
                            byWay = "通过邮箱密码"
                        default:
                            break
                        }
                    }
                    var msg = ""
                    if error.code == 4001 {
                        msg = "你的账号于" + date + "在" + device + "设备上" + byWay + "登录"
                    } else if error.code == 4011 {
                        msg = "你的账号于" + date + "在" + device + "设备上更改了密聊密码，请重新登录。"
                    }
                    let alert = FZMAlertView(onlyAlert: msg) { }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        alert.show()
                    }
                }
            })
        }else {
            if shouldReconnect {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0, execute: {
                    self.connect()
                })
            }
        }
    }
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        let dic = json as! [String : Any]
        IMLog(dic)
        self.handleReceiveMessage(with: dic)
    }
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        guard let data = text.data(using: .utf8) else { return }
        let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        guard let dic = json as? [String : Any] else{
            return
        }
        IMLog(dic)
        self.handleReceiveMessage(with: dic)
    }
}

//MARK: 获取消息
extension SocketManager {
    func postTime() {
        guard IMLoginUser.shared().isLogin else { return }
        let time = (UserDefaults.standard.getUserObject(forKey: "LastGetMessageTime") as? Double) ?? 0
        if let msg = SocketMessage.getNewestMsg(), msg.datetime > time {
            self.sendInfoToServer(with: ["eventType": 42, "time": msg.datetime])
            IMLog("------------postTime-------\(msg.datetime)")
        } else {
            self.sendInfoToServer(with: ["eventType": 42, "time": time])
            IMLog("------------postTime-------\(time)")
        }
        IMLoginUser.shared().currentUser?.setAckMsgTime(timestamp: Int(Date.init().timestamp))
    }
    func saveTime(time: Double, ignoreLock: Bool = false) {
        guard IMLoginUser.shared().isLogin else { return }
        if let oldTime = UserDefaults.standard.getUserObject(forKey: "LastGetMessageTime") as? Double, oldTime > time {
            return
        }
        UserDefaults.standard.setUserValue(time, forKey: "LastGetMessageTime")
    }
    
    func beginAckMsgs() {
        IMLog("开始确认消息")
        if let begin = IMLoginUser.shared().currentUser?.getAckMsgTime() {
            var end = begin + 20 * 1000
            if Double.init(end) > Date.init().timestamp {
                end = -1
            }
            self.ackMsgs(begin: begin, end: end)
        }
    }
    
    func ackMsgs(begin: Int, end: Int) {
        let count = SocketMessage.getMsgsCountToAck(begin: Double.init(begin), end: end == -1 ? Date.init().timestamp : Double.init(end))
        self.sendInfoToServer(with: ["eventType": SocketEventType.beginAckMsgs.rawValue, "begin": begin, "end": end, "total": count])
    }
    
}


extension SocketManager {
    func handleReceiveMessage(with dic : [String : Any]){
        guard let event = dic["eventType"] as? Int else { return  }
        guard let eventType = SocketEventType(rawValue:event) else {
            IMLog("未知消息类型")
            return
        }
        let json : JSON = JSON.init(dic)
        switch eventType {
        case .message:
            IMLog("聊天消息")
            if json["code"].intValue == 0 {
                SocketChatManager.shared().receiveMessage(with: json)
                self.saveTime(time: json["datetime"].doubleValue)
            }
            if json["code"].intValue == -2032 {
                SocketChatManager.shared().receiveFailSendMessage(with: json)
            }
        case .raceAccount:
            IMLog("被顶号")
            HttpConnect.shared().logout(completionBlock: { (_) in
                IMLoginUser.shared().clearUserInfo()
            })
            let alert = FZMAlertView(onlyAlert: json["content"].string) {
                
            }
            alert.show()
        case .bannedGroup:
            IMLog("被封群")
            let dic = ["roomId": json["roomId"].stringValue,
                       "disableDeadline":json["disableDeadline"].intValue,
                       "datetime":json["datetime"].intValue] as [String : Any]
            FZM_NotificationCenter.post(name: FZM_Notify_BannedGroup, object: nil, userInfo: dic)
        case .bannedAccount:
            IMLog("被封号")
            HttpConnect.shared().logout(completionBlock: { (_) in
                IMLoginUser.shared().clearUserInfo()
            })
            let disableDeadline = json["disableDeadline"].intValue
            var content = ""
            let forever: Int64 = 7258089600000
            if disableDeadline == forever {
                content = "你的账号已被永久查封，如需解封可联系客服：" + FZM_Service
            } else if disableDeadline != 0 {
                let date = Date.init(timeIntervalSince1970: TimeInterval(disableDeadline / 1000))
                let formatter = DateFormatter.init()
                formatter.dateFormat = "yyyy年MM月dd号HH:mm"
                let dateStr = formatter.string(from: date)
                content = "你的账号已被查封至\(dateStr)，如需解封可联系客服：" + FZM_Service
            }
            
            let alert = FZMAlertView(onlyAlert: content) {
                HttpConnect.shared().logout(completionBlock: { (_) in
                    IMLoginUser.shared().clearUserInfo()
                })
            }
            alert.show()
        case .joinRoom:
            IMLog("加入聊天室成功")
        case .joinGroup:
            IMLog("入群通知")
            IMConversationManager.shared().refreshGroupList()
        case .quitGroup:
            IMLog("退群通知")
            if json["type"].intValue == 2 {
                IMConversationManager.shared().refreshGroupList()
            }
        case .dissolveGroup:
            IMLog("解散群通知")
            IMConversationManager.shared().refreshGroupList()
        case .pulledGroup:
            IMLog("入群请求")
            IMContactManager.shared().refreshApplyNumber()
        case .groupBanned:
            IMLog("群禁言")
            IMNotifyCenter.shared().postMessage(event: .groupBanned(groupId: json["roomId"].stringValue, type: json["type"].intValue, deadline: json["deadline"].doubleValue))
        case .addApplyOrReply:
            IMLog("添加好友申请和回复通知")
            let status = json["status"].intValue
            if status == 1 {
                if json["senderInfo"]["id"].stringValue != IMLoginUser.shared().userId {
                    IMContactManager.shared().applyNumber += 1
                }
            }else if status == 3 {
                IMContactManager.shared().fetchFriendList()
                IMContactManager.shared().refreshApplyNumber()
            }
        case .refreshFriendList:
            IMLog("好友新增或删除")
            IMContactManager.shared().fetchFriendList()
            IMContactManager.shared().refreshApplyNumber()
        case .fetchMsgList:
            IMLog("消息列表")
            if self.timer.fireDate == Date.distantFuture {
                self.timer.fireDate = Date.init()
            }
            SocketChatManager.shared().receiveMessageList(with: json, isUnread: false)
        case .fetchUnreadMsgList:
            IMLog("未读消息列表")
            if self.timer.fireDate == Date.distantFuture {
                self.timer.fireDate = Date.init()
            }
            SocketChatManager.shared().receiveMessageList(with: json, isUnread: true)
        case .completeGetMsg:
            IMLog("消息接收完成")
            self.timer.fireDate = Date.distantFuture
            if let msg = SocketMessage.getNewestMsg() {
                SocketManager.shared().saveTime(time: msg.datetime)
            }
            SocketChatManager.shared().receiveMessageListCompleting()
        case .fetchForwardMsgs:
            IMLog("逐条转发消息")
            SocketChatManager.shared().receiveMessageList(with: json, isUnread: true, showState: false)
        case .ackMsgs:
            IMLog("消息确认")
            SocketChatManager.shared().receiveAckMessageList(with: json)
        case .ackMsgsCompleting:
            IMLog("消息确认完成")
            let _ = json["begin"].intValue
            let end = json["end"].intValue
            var nextEnd = end + 20 * 1000
            if Double.init(nextEnd) > Date.init().timestamp {
                nextEnd = -1
                DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
                    self.ackMsgs(begin: end, end: nextEnd)
                }
            } else {
                self.ackMsgs(begin: end, end: nextEnd)
            }
        case .userUpdataPublicKey:
            IMLog("收到用户更新公钥")
            guard IMSDK.shared().isEncyptChat else { return }
            let userId = json["userId"].stringValue
            let publicKey = json["publicKey"].stringValue
            if !userId.isEmpty && !publicKey.isEmpty {
                IMContactManager.shared().updateUserPublicKey(userId: userId, publicKey: publicKey)
            }
        default:
            IMLog("未处理消息")
        }
    }
}

extension SocketManager {
    
    //socket发消息给服务端
    func sendInfoToServer(with dic: [String : Any]) {
        let data = try? JSONSerialization.data(withJSONObject: dic, options: [])
        guard let writeData = data else { return }
        ws?.write(data: writeData)
    }
    
}

extension SocketManager: UserInfoChangeDelegate {
    func userLogin() {
        self.configureSocket()
    }
    
    func userLogout() {
        self.configureSocket()
    }
    func userInfoChange() {
        
    }
}

extension SocketManager: AppActiveDelegate {
    func appEnterBackground() {
        self.shouldReconnect = false
        self.disconnect()
    }
    func appWillEnterForeground() {
        if IMLoginUser.shared().isLogin {
            self.shouldReconnect = true
            self.connect()
        }
    }
}
