//
//  SocketChatManager.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/11.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import SwiftyJSON
import TZImagePickerController
import RxSwift
import YYWebImage

class SocketChatManager: NSObject {

    private static let sharedInstance = SocketChatManager()
    
    private var timer : Timer?
    
    class func launch() {
        _ = SocketChatManager.shared()
    }
    
    class func shared() -> SocketChatManager {
        return sharedInstance
    }
    
    override init() {
        super.init()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(observeBurnMessage), userInfo: nil, repeats: true)
    }
    private let burnLock = DispatchSemaphore(value: 1)
    private let burnQueue = DispatchQueue(label: "com.burnAfterRead")
    @objc private func observeBurnMessage() {
        burnQueue.async {
            self.burnLock.wait()
            let list = SocketMessage.getBurnMsgs()
            list.forEach({ (msg) in
                msg.delete()
                IMNotifyCenter.shared().postMessage(event: .burnMessage(msg: msg))
            })
            self.burnLock.signal()
        }
    }
    
    //MARK: 聊天消息
    //发送的消息，发送成功后会删除记录
    private var sendMsgMap = [String:SocketMessage]()
    
    private let fetchListQueue = DispatchQueue.init(label: "come.fetchListQueue")
    var isFinishedFetchMsgListSubject = BehaviorSubject<Bool?>(value: nil)
    private var isFinishedFetchMsgList: Bool? = nil {
        didSet{
            if isFinishedFetchMsgList != oldValue {
                DispatchQueue.main.async {
                    self.isFinishedFetchMsgListSubject.onNext(self.isFinishedFetchMsgList)
                }
            }
        }
    }
    
    private var showTimes: Dictionary<String, Double> = Dictionary.init()

}

//MARK: 聊天消息发送
extension SocketChatManager {
    //socket加入聊天室
    func joinChatRoom(with chatRoomId: String) {
        let dic : [String : Any] = ["eventType":1,"groupId":chatRoomId]
        SocketManager.shared().sendInfoToServer(with: dic)
    }
    //发送聊天消息
    func sendMessage(with msg: SocketMessage) {
        sendMsgMap[msg.sendMsgId] = msg
        msg.save()
        switch msg.msgType {
        case .text, .system, .notify, .redBag, .receipt, .transfer:
            self.commitMessage(msg)
        case .image:
            IMLog("图片消息")
            if !msg.body.imageUrl.isEmpty, !msg.body.isEncryptMedia {
                 self.commitMessage(msg)
                return
            }
            msg.uploadMedia(uploadProgressBlock: { (progress) in
                
            }) { (url, success) in
                if success, let url = url {
                    msg.body.imageUrl = url
                    msg.body.imgData = Data.init()
                    self.commitMessage(msg)
                }else {
                    self.failSendMessageOperation(msg)
                }
            }
        case .video:
            if !msg.body.mediaUrl.isEmpty, !msg.body.isEncryptMedia {
                 self.commitMessage(msg)
                return
            }
            msg.uploadMedia(uploadProgressBlock: { (progress) in
                IMNotifyCenter.shared().postMessage(event: .uploadProgress(msgSendID: msg.sendMsgId, progress: progress))
            }) { (url, success) in
                if success, let url = url {
                    msg.body.mediaUrl = url
                    FZM_UserDefaults.set(msg.body.localVideoPath, forKey: url)
                    FZM_UserDefaults.synchronize()
                    self.commitMessage(msg)
                }else {
                    self.failSendMessageOperation(msg)
                }
            }
        case .file:
            if !msg.body.fileUrl.isEmpty, !msg.body.isEncryptMedia {
                 self.commitMessage(msg)
                return
            }
            msg.uploadMedia(uploadProgressBlock: { (progress) in
                IMNotifyCenter.shared().postMessage(event: .uploadProgress(msgSendID: msg.sendMsgId, progress: progress))
            }) { (url, success) in
                if success, let url = url {
                    msg.body.fileUrl = url
                    FZM_UserDefaults.set(msg.body.localFilePath, forKey: url)
                    FZM_UserDefaults.synchronize()
                    self.commitMessage(msg)
                }else {
                    self.failSendMessageOperation(msg)
                }
            }
        case .audio:
            IMLog("语音消息")
            if !msg.body.mediaUrl.isEmpty, !msg.body.isEncryptMedia {
                 self.commitMessage(msg)
                return
            }
            msg.uploadMedia(uploadProgressBlock: nil) { (url, success) in
                if success, let url = url {
                    msg.body.mediaUrl = url
                    self.commitMessage(msg)
                }else {
                    self.failSendMessageOperation(msg)
                }
            }
            
        default:
            IMLog("暂不支持")
        }
    }
    //提交消息去socket，文字消息直接调用此方法，其他文件类消息要先上传文件到阿里云服务器
    private func commitMessage(_ msg: SocketMessage) {

        msg.encryptMsgToDic {[weak msg] (encryptDic) in
            guard let strongMsg = msg else { return }
            strongMsg.save()
            #if DEBUG
            if IMSDK.shared().isEncyptChat,
                strongMsg.isEncryptMsg,
                let dic = encryptDic["msg"] as? Dictionary<String,Any>,
                dic["encryptedMsg"] == nil  {
                UIApplication.shared.keyWindow?.showToast(with: "测试环境下显示:\n 此条消息未加密发送")
            }
            #endif
            SocketManager.shared().sendInfoToServer(with: encryptDic)
            //5s后如果消息还在发送数组里，认为发送失败修改状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.failSendMessageOperation(strongMsg)
            }
        }
    }
    //检查消息，发送失败则处理
    private func failSendMessageOperation(_ msg: SocketMessage) {
        if let message = self.sendMsgMap[msg.sendMsgId] {
            message.status = .failed
            message.save()
            IMNotifyCenter.shared().postMessage(event: .failSendMessage(msg: message))
        }
    }
    
}

//MARK: 聊天接收消息
extension SocketChatManager {
    
    func configureMsgShowTime(msg: SocketMessage) {
        let key = "\(msg.channelType.rawValue)--" + msg.conversationId
        var showTime = self.showTimes[key]
        if showTime == nil,
            let showTimeInDB = SocketMessage.getShowTimeMsg(with: msg.channelType, conversationId: msg.conversationId)?.datetime {
            showTime = showTimeInDB
            self.showTimes[key] = showTimeInDB
        }
        if let showTime = showTime {
            if (msg.datetime - showTime > 600000) {
                msg.showTime = true
                self.showTimes[key] = msg.datetime
            } else {
                msg.showTime = false
            }
        } else {
            msg.showTime = true
            self.showTimes[key] = msg.datetime
        }
    }
    
    func receiveFailSendMessage(with socketJson: JSON) {
        guard let msgId = socketJson["msgId"].string, let msg = self.sendMsgMap[msgId] else { return }
        self.failSendMessageOperation(msg)
        self.sendMsgMap.removeValue(forKey: msg.sendMsgId)
        let notifyMsg = SocketMessage.init(notify: "消息已发出，但被对方拒收了！", from: msg.targetId, to: msg.fromId, channelType: msg.channelType)
        notifyMsg.save()
        IMNotifyCenter.shared().postMessage(event: .receiveMessage(msg: notifyMsg, isLocal: false))
    }
    
    func receiveMessage(with socketJson: JSON) {
        guard let msg = SocketMessage(with: socketJson) else { return }
        //过滤到黑名单消息
        let isBlcokedMsg = IMContactManager.shared().getAllBlockUsers().compactMap { $0.userId }.contains(msg.fromId) &&
            (msg.targetId == IMLoginUser.shared().currentUser?.userId)
        if isBlcokedMsg {
            return
        }
        
        if msg.msgType == .notify, let notifyEvent = msg.body.notifyEvent {
            if case .revokeMsg(_,let revokeId) = notifyEvent {
                if let revokeMsg = SocketMessage.getMsg(with: revokeId, conversationId: msg.conversationId, conversationType: msg.channelType) {
                    revokeMsg.delete()
                }
            }else if case .burnMsg(_, let channelType,let msgId) = notifyEvent {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    guard let burnMsg = SocketMessage.getMsg(with: channelType, msgId: msgId), burnMsg.snap == .burn else { return }
                    burnMsg.delete()
                    IMNotifyCenter.shared().postMessage(event: .burnMessage(msg: burnMsg))
                }
                return
            }else if case .receoptSuceess(_,let logId, let recordId) = notifyEvent {
                if let needUpdateMsg = SocketMessage.getMsg(with: logId, conversationId: msg.conversationId, conversationType: msg.channelType) {
                    needUpdateMsg.body.recordId = recordId
                    needUpdateMsg.save()
                }
            } else if case .updataGroupKey(_,let groupId, let fromKey, let key, let keyId) = notifyEvent {
                if IMSDK.shared().isEncyptChat, msg.targetId == IMLoginUser.shared().userId  {
                    IMLoginUser.shared().currentUser?.setGroupKey(groupId: groupId, fromKey: fromKey, key: key, keyId: keyId)
                }
                return
            }
        }
        
        if let sendMsg = self.sendMsgMap[msg.sendMsgId] {
            sendMsg.msgId = msg.msgId
            sendMsg.status = .succeed
            sendMsg.save()
            IMNotifyCenter.shared().postMessage(event: .receiveMessage(msg: sendMsg, isLocal: true))
            self.sendMsgMap.removeValue(forKey: sendMsg.sendMsgId)
        }else{
            self.configureMsgShowTime(msg: msg)
            msg.save()
            IMNotifyCenter.shared().postMessage(event: .receiveMessage(msg: msg, isLocal: false))
        }
        
    }
    
    
    func receiveMessageList(with socketJson: JSON, isUnread: Bool, showState: Bool = true) {
        fetchListQueue.async {
            if showState {
                self.isFinishedFetchMsgList = false
            }
            let msgList = socketJson["list"].arrayValue.compactMap { (json) -> SocketMessage? in
                guard let msg = SocketMessage(with: json) else { return nil }
                //过滤到黑名单消息
                let isBlcokedMsg = IMContactManager.shared().getAllBlockUsers().compactMap { $0.userId }.contains(msg.fromId) &&
                    (msg.targetId == IMLoginUser.shared().currentUser?.userId)
                if isBlcokedMsg {
                    return nil
                }
                if msg.msgType == .notify, let notifyEvent = msg.body.notifyEvent {
                    if case .revokeMsg(_,let revokeId) = notifyEvent {
                        if let revokeMsg = SocketMessage.getMsg(with: revokeId, conversationId: msg.conversationId, conversationType: msg.channelType) {
                            revokeMsg.delete()
                        }
                    }else if case .burnMsg(_, let channelType,let msgId) = notifyEvent {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            guard let burnMsg = SocketMessage.getMsg(with: channelType, msgId: msgId), burnMsg.snap == .burn else { return }
                            burnMsg.delete()
                            IMNotifyCenter.shared().postMessage(event: .burnMessage(msg: burnMsg))
                        }
                        return nil
                    }else if case .receoptSuceess(_,let logId, let recordId) = notifyEvent {
                        if let needUpdateMsg = SocketMessage.getMsg(with: logId, conversationId: msg.conversationId, conversationType: msg.channelType) {
                            needUpdateMsg.body.recordId = recordId
                            needUpdateMsg.save()
                        }
                    }else if case .updataGroupKey(_ ,let groupId, let fromKey, let key, let keyId) = notifyEvent {
                        if IMSDK.shared().isEncyptChat, msg.targetId == IMLoginUser.shared().userId {
                            IMLoginUser.shared().currentUser?.setGroupKey(groupId: groupId, fromKey: fromKey, key: key, keyId: keyId)
                        }
                        return nil
                    }
                }
                return msg
            }
            msgList.forEach({self.configureMsgShowTime(msg: $0)})
            SocketMessage.save(msgList)
            if let msg = SocketMessage.getNewestMsg() {
                SocketManager.shared().saveTime(time: msg.datetime)
            }
            IMNotifyCenter.shared().postMessage(event: .receiveHistoryMsgList(msgs: msgList, isUnread: isUnread))
        }
    }
    
    func receiveMessageListCompleting() {
        fetchListQueue.async(flags: .barrier) {
            IMConversationManager.shared().receiveMessageListCompleting()
            self.isFinishedFetchMsgList = true
        }
    }
    
    func receiveAckMessageList(with socketJson: JSON) {
        fetchListQueue.async {
            guard let arr = socketJson["list"].array else { return }
            let ackMsgs = arr.compactMap { (json) -> SocketMessage? in
                guard let msg = SocketMessage(with: json) else { return nil }
                if msg.msgType == .notify, let notifyEvent = msg.body.notifyEvent {
                    if case .burnMsg(_, _,_) = notifyEvent {
                        return nil
                    } else if case .updataGroupKey(_,_,_,_,_) = notifyEvent {
                        return nil
                    }
                    return msg
                }
                return msg
            }
            let lossMsgs = SocketMessage.ackMsgs(ackMsgs)
            if lossMsgs.count > 0 {
                SocketMessage.save(lossMsgs)
                IMNotifyCenter.shared().postMessage(event: .receiveHistoryMsgList(msgs: lossMsgs, isUnread: true))
            }
        }
    }
}
