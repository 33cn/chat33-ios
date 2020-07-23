//
//  SocketMessage.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/28.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import SwiftyJSON
import Photos
import AliyunOSSiOS
import YYWebImage
import TZImagePickerController


public enum SocketMessageType : Int {
    //系统消息
    case system = 0
    //文字
    case text = 1
    //音频
    case audio = 2
    //图片
    case image = 3
    //红包
    case redBag = 4
    //视频
    case video = 5
    //通知
    case notify = 6
    //转发消息
    case forward = 8
    
    case file = 9
    
    case transfer = 10
    
    case receipt = 11
    case inviteGroup = 12
}

public enum SocketMessageStatus: Int {
    case sending = 0
    case succeed = 1
    case failed = 2
}

public enum SocketMessageDirection: Int {
    case send = 0
    case receive = 1
}

//阅后即焚类型
public enum SocketMessageBurnType: Int {
    case none = 2//非阅后即焚消息
    case burn = 1//阅后即焚消息
    case open = 3//阅后即焚并已打开
}

public class SocketMessage: NSObject, Comparable {
    var msgId = ""//消息id
    var sendMsgId = ""//本地发消息时存在本地的id
    var useId : String {
        if msgId.count > 0 {
            return msgId
        }
        return sendMsgId
    }
    var channelType : SocketChannelType = .person//消息入口类型
    var fromId = ""//发送者id
    var targetId = ""//接受者id
    var datetime : Double = 0//时间
    var status : SocketMessageStatus = .succeed
    var direction: SocketMessageDirection {
        if fromId == IMLoginUser.shared().userId {
            return .send
        } else {
            return .receive
        }
    }
    var conversationId : String {
        if channelType == .person {
            return direction == .send ? targetId : fromId
        }else {
            return targetId
        }
    }
    var showTime = false
    var snap : SocketMessageBurnType = .none//阅后即焚类型
    var snapTime : Double = 0//阅后即焚消息需要销毁的时间，不查看为0，查看后填充时间
    var msgType : SocketMessageType = .text
    var body = SocketMessageBody()
    var senderName = "" //发送者名称
    var senderAvatar = "" //发送者头像
    var isEncryptMsg = false
    var isDeleted = false
    var fromKey = ""
    var toKey = ""
    var keyId = ""
    
    var upvote = SocketMessageUpvote.init()
    
    typealias BodyDescriptionBlock = (String,String,String)->()
    func getBodyDescription(completeBlock: BodyDescriptionBlock?){
        var typeStr = ""
        switch msgType {
        case .text:
            typeStr = body.content
        case .notify:
            typeStr = "[通知] \(body.content)"
            if let event = body.notifyEvent, case .receoptSuceess(_,_,_) = event  {
                typeStr = self.direction == .send ? "[通知] 你已付款" : "[通知] 对方已付款"
            }
            if let event = body.notifyEvent, case.msgUpvoteUpdate(_, _, _, _, _, _) = event {
                typeStr = ""
            }
        case .system:
            typeStr = "[公告] \(body.content)"
        case .audio:
            typeStr = "[语音]"
        case .image:
            typeStr = "[图片]"
        case .redBag:
            typeStr = "[红包] \(body.remark)"
        case .forward:
            typeStr = "[聊天记录]"
        case .video:
            typeStr = "[视频]"
        case .file:
            typeStr = "[文件]"
        case .transfer:
            typeStr = self.direction == .send ? "[转账] 向对方转账" : "[转账] 转账给你"
        case .receipt:
            typeStr = self.direction == .send ? "[收款] 向对方收款" : "[收款] 向你收款"
        case .inviteGroup:
            typeStr = self.direction == .send ? "[邀请对方加入群聊]" : "[邀请你加入群聊]"
        default:
            typeStr = ""
        }
        if snap != .none {
            typeStr = "[阅后即焚]"
        }
        if !self.body.ciphertext.isEmpty {
            typeStr = "[加密消息]"
        }
        self.callback(with: typeStr, completeBlock: completeBlock)
    }
    
    func callback(with typeStr: String, completeBlock: BodyDescriptionBlock?) {
        var statusStr = ""
        if status == .failed {
            statusStr = "[发送失败]"
        }else if status == .sending {
            statusStr = "[发送中]"
        }
        if channelType == .person {
            completeBlock?(self.fromId, self.conversationId, statusStr + typeStr)
            return
        }
        if msgType == .notify || msgType == .system {
            completeBlock?(self.fromId, self.conversationId, typeStr)
        }else {
            if direction == .send {
                completeBlock?(self.fromId, self.conversationId, "\(statusStr) 我: \(typeStr)")
            }else {
                IMContactManager.shared().getUsernameAndAvatar(with: fromId, groupId: self.channelType == .person ? nil : conversationId) { (_, useName, _) in
                    let str = "\(useName): \(typeStr)"
                    completeBlock?(self.fromId, self.conversationId, str)
                }
            }
        }
    }
    
    func getProcessedBodyContent(completeBlock: ((String) -> ())?){
        if msgType == .notify, let event = body.notifyEvent, case .receiveRedBag(_, let owner, let oper, _) = event  {
            if IMLoginUser.shared().currentUser?.userId == owner && (owner == oper) {
                completeBlock?("[通知] " + "你领取了自己的红包")
            } else if IMLoginUser.shared().currentUser?.userId == owner {
                IMContactManager.shared().getUsernameAndAvatar(with: oper, groupId: channelType == .group ? conversationId : nil) { (infoId, name, avatar) in
                    completeBlock?("[通知] " +  "\(name)领取了你的红包")
                }
            } else if IMLoginUser.shared().currentUser?.userId == oper {
                IMContactManager.shared().getUsernameAndAvatar(with: owner, groupId: channelType == .group ? conversationId : nil) { (infoId, name, avatar) in
                    completeBlock?("[通知] " +  "你领取了\(name)的红包")
                }
            } else {
                completeBlock?("[通知] " +  self.body.content)
            }
        } else {
            completeBlock?(body.content)
        }
        
    }
    
    func getForwardDescriptionStr() -> String {
        var typeStr = ""
        switch msgType {
        case .text:
            typeStr = body.content
        case .notify:
            typeStr = "[通知]\(body.content)"
            if let event = body.notifyEvent, case .receoptSuceess(_,_,_) = event  {
                typeStr = self.direction == .send ? "[通知] 你已付款" : "[通知] 对方已付款"
            }
        case .system:
            typeStr = "[公告]\(body.content)"
        case .audio:
            typeStr = "[语音]"
        case .image:
            typeStr = "[图片]"
        case .redBag:
            typeStr = "[红包]"
        case .forward:
            typeStr = "[聊天记录]"
        case .video:
            typeStr = "[视频]"
        case .file:
            typeStr = "[文件]"
        case .transfer:
            typeStr = self.direction == .send ? "[向对方转账]" : "[转账给你]"
        case .receipt:
            typeStr = self.direction == .send ? "[向对方收款]" : "[向你收款]"
        case .inviteGroup:
            typeStr = self.direction == .send ? "[邀请对方加入群聊]" : "[邀请你加入群聊]"
        default:
            typeStr = ""
        }
        if !self.body.ciphertext.isEmpty {
            typeStr = "[加密消息]"
        }
        return "\(senderName)：\(typeStr)"
    }
    
    public static func < (lhs: SocketMessage, rhs: SocketMessage) -> Bool {
        return lhs.datetime < rhs.datetime
    }
}

extension SocketMessage {
    
    func encryptMsgToDic(completionBlcok: (([String: Any]) -> ())?) {
        var dic = self.mapToDic()
        
        if !IMSDK.shared().isEncyptChat ||
            !self.isEncryptMsg ||
            self.msgType == .redBag ||
            self.msgType == .notify ||
            self.msgType == .transfer ||
            self.msgType == .receipt {
            completionBlcok?(dic)
            return
        }
        
        if self.channelType == .person {
            IMContactManager.shared().requestUserModel(with: self.targetId) { (user, _, _) in
                if let toUser = user, toUser.isFriend,
                    let myPrivateKey = IMLoginUser.shared().currentUser?.privateKey,
                    let myPublicKey = IMLoginUser.shared().currentUser?.publicKey,
                    myPrivateKey.count > 0,
                    myPublicKey.count > 0,
                    toUser.publicKey.count > 0,
                    let plainText = try? JSONSerialization.data(withJSONObject: self.body.mapToDic(), options: []),
                    let ciphertext = FZMEncryptManager.encryptSymmetric(privateKey: myPrivateKey, publicKey: toUser.publicKey, plaintext: plainText) {
                    dic["msg"] = ["encryptedMsg": ciphertext.toHexString(),
                                  "fromKey": myPublicKey,
                                  "toKey": toUser.publicKey]
                    self.fromKey = myPublicKey
                    self.toKey = toUser.publicKey
                }
                completionBlcok?(dic)
                return
            }
        }
        
        if self.channelType == .group {
            if let gropuKey = IMLoginUser.shared().currentUser?.getLatestGroupKey(groupId: self.targetId),
                let key = gropuKey.plainTextKey,
                let plainText = try? JSONSerialization.data(withJSONObject: self.body.mapToDic(), options: []),
                let ciphertext = FZMEncryptManager.encryptSymmetric(key: key, plaintext: plainText) {
                dic["msg"] = ["encryptedMsg": ciphertext.toHexString(),
                              "kid": gropuKey.keyId]
                self.keyId = gropuKey.keyId
            }
            completionBlcok?(dic)
            return
        }
    }
    
    
    
    func decrypt(bodyJson: JSON) -> JSON {
        
        if self.msgType == .redBag ||
            self.msgType == .notify ||
            self.msgType == .transfer ||
            self.msgType == .receipt {
            return bodyJson
        }
        
        if self.channelType == .person {
            if let ciphertext = bodyJson["encryptedMsg"].string, !ciphertext.isEmpty,
                let fromPublicKey = bodyJson["fromKey"].string,
                let toPublicKey = bodyJson["toKey"].string {
                self.isEncryptMsg = true
                let publicKey = IMLoginUser.shared().userId == fromId ? toPublicKey : fromPublicKey
                if  let privateKey = IMLoginUser.shared().currentUser?.privateKey,
                    privateKey.count > 0,
                    publicKey.count > 0,
                    let plaintext = FZMEncryptManager.decryptSymmetric(privateKey: privateKey, publicKey: publicKey, ciphertext: Data.init(hex: ciphertext)),
                    let jsonObjec = try? JSONSerialization.jsonObject(with: plaintext, options: []) {
                    self.fromKey = fromPublicKey
                    self.toKey = toPublicKey
                    return JSON.init(jsonObjec)
                } else {
                    return bodyJson
                }
            }
        }
        
        if self.channelType == .group {
            if let ciphertext = bodyJson["encryptedMsg"].string,
                !ciphertext.isEmpty,
                let keyId = bodyJson["kid"].string {
                self.isEncryptMsg = true
                if let groupKey = IMLoginUser.shared().currentUser?.getGroupKey(groupId: self.targetId, keyId: keyId),
                    let key = groupKey.plainTextKey,
                    let plaintext = FZMEncryptManager.decryptSymmetric(key: key, ciphertext: Data.init(hex: ciphertext)),
                    let jsonObjec = try? JSONSerialization.jsonObject(with: plaintext, options: []) {
                    self.keyId = keyId
                    return JSON.init(jsonObjec)
                }
            }
        }
        return bodyJson
    }
    
    
    func decryptAgain() {
        guard !self.body.ciphertext.isEmpty else { return }
        let bodyJson = JSON.init(parseJSON: self.body.ciphertext)
        guard !bodyJson["encryptedMsg"].stringValue.isEmpty else { return }
        
        let body = SocketMessageBody(with: self.decrypt(bodyJson: bodyJson), type: self.msgType)
        if body.ciphertext.isEmpty {
            self.body = body
            DispatchQueue.global().async {
                self.save()
            }
        }
    }
    
    func encryptMedia(callback: @escaping (Data?) -> ()) {
        guard self.isEncryptMsg, IMSDK.shared().isEncyptChat else {
            callback(nil)
            return
        }
        var mediaData: Data?
        switch self.msgType {
        case .image:
            if !self.body.imgData.isEmpty {
                mediaData = self.body.imgData
            } else if !self.body.imageUrl.isEmpty,
                let image = YYImageCache.shared().getImageForKey(self.body.imageUrl),
                let data = image.jpegData(compressionQuality: 1) {
                mediaData = data
            }
        case .video:
            mediaData = FZMLocalFileClient.shared().readData(fileName: .video(fileName: self.body.localVideoPath))
        case .file:
            mediaData = FZMLocalFileClient.shared().readData(fileName: .file(fileName: self.body.localFilePath))
        case .audio:
            mediaData = FZMLocalFileClient.shared().readData(fileName: .amr(fileName: self.body.localAmrPath.fileName()))
        default:
            break
        }
        guard let plainText = mediaData else {
            callback(nil)
            return
        }
        if self.channelType == .person {
            IMContactManager.shared().requestUserModel(with: self.targetId) { (user, _, _) in
                if let toUser = user, toUser.isFriend,
                    let myPrivateKey = IMLoginUser.shared().currentUser?.privateKey,
                    let myPublicKey = IMLoginUser.shared().currentUser?.publicKey,
                    myPrivateKey.count > 0,
                    myPublicKey.count > 0,
                    toUser.publicKey.count > 0,
                    let ciphertext = FZMEncryptManager.encryptSymmetric(privateKey: myPrivateKey, publicKey: toUser.publicKey, plaintext: plainText) {
                    self.fromKey = myPublicKey
                    self.toKey = toUser.publicKey
                    callback(ciphertext)
                } else {
                    callback(nil)
                }
            }
        } else if self.channelType == .group {
            if let gropuKey = IMLoginUser.shared().currentUser?.getLatestGroupKey(groupId: self.targetId),
                let key = gropuKey.plainTextKey,
                let ciphertext = FZMEncryptManager.encryptSymmetric(key: key, plaintext: plainText){
                self.keyId = gropuKey.keyId
                callback(ciphertext)
            } else {
                callback(nil)
            }
        }
    }
    
    func decryptMedia(ciphertext: Data) -> Data{
        guard self.msgType == .image
            || self.msgType == .video
            || self.msgType == .file
            || self.msgType == .audio,
            !ciphertext.isEmpty else {
                return ciphertext
        }
        if self.channelType == .person, !self.fromKey.isEmpty, !self.toKey.isEmpty {
            let publicKey = IMLoginUser.shared().userId == fromId ? self.toKey : self.fromKey
            if let privateKey = IMLoginUser.shared().currentUser?.privateKey,
                privateKey.count > 0,
                publicKey.count > 0,
                let plaintext = FZMEncryptManager.decryptSymmetric(privateKey: privateKey, publicKey: publicKey, ciphertext: ciphertext) {
                return plaintext
            }
        }
        if self.channelType == .group,
            !self.keyId.isEmpty,
            let groupKey = IMLoginUser.shared().currentUser?.getGroupKey(groupId: self.targetId, keyId: keyId),
            let key = groupKey.plainTextKey,
            let plaintext = FZMEncryptManager.decryptSymmetric(key: key, ciphertext: ciphertext) {
            return plaintext
        }
        return ciphertext
    }
}

extension SocketMessage {
    func uploadMedia(uploadProgressBlock : OSSProgressHandler? , callBack: OSSFileUploadHandler?) {
        switch self.msgType {
        case .text, .system, .notify, .redBag, .receipt, .transfer:
            callBack?(nil, false)
        case .image:
            self.encryptMedia { (ciphertext) in
                #if DEBUG
                if ciphertext == nil {
                    DispatchQueue.main.async {
                        UIApplication.shared.keyWindow?.showToast(with: "加密失败")
                    }
                }
                #endif
                var data = ciphertext ?? self.body.imgData
                if ciphertext == nil,
                    data.isEmpty,
                    !self.body.imageUrl.isEmpty,
                    let image = YYImageCache.shared().getImageForKey(self.body.imageUrl),
                    let imageData = image.jpegData(compressionQuality: 1) {
                    data = imageData
                }
                let uploadPath = IMOSSClient.shared().getUploadPath(uploadType: .image, ofType: "jpg", isEncryptFile: ciphertext != nil)
                IMOSSClient.shared().uploadImage(file: data, toServerPath: uploadPath, uploadProgressBlock: uploadProgressBlock, callBack: callBack)
            }
        case .video:
            let block = {(filePath: String) in
                self.encryptMedia { (ciphertext) in
                    #if DEBUG
                    if ciphertext == nil {
                        DispatchQueue.main.async {
                            UIApplication.shared.keyWindow?.showToast(with: "加密失败")
                        }
                    }
                    #endif
                    var mediaPath = filePath
                    var uploadPath = IMOSSClient.shared().getUploadPath(uploadType: .video, ofType: (mediaPath as NSString).components(separatedBy: ".").last ?? "mp4", isEncryptFile: false)
                    let ciphertextMediaPath = FZMLocalFileClient.shared().createTempPath(fileName: self.body.localVideoPath)
                    if let ciphertext = ciphertext,
                        FZMLocalFileClient.shared().saveData(ciphertext, filePath: ciphertextMediaPath) == true {
                        mediaPath = ciphertextMediaPath
                        uploadPath =  IMOSSClient.shared().getUploadPath(uploadType: .video, ofType: (mediaPath as NSString).components(separatedBy: ".").last ?? "mp4", isEncryptFile: true)
                    }
                    IMOSSClient.shared().uploadVideo(filePath: mediaPath, toServerPath: uploadPath, uploadProgressBlock: uploadProgressBlock, callBack: callBack)
                }
            }
            if self.body.localVideoPath.count == 0 {
                TZImageManager.default()?.getVideoOutputPath(with: self.body.asset, success: { (outputPath) in
                    if let outputPath = outputPath,
                        let savePath = FZMLocalFileClient.shared().createFile(with: .video(fileName: String.getTimeStampStr() + (outputPath as NSString).lastPathComponent)),
                        FZMLocalFileClient.shared().move(fromFilePath: outputPath, toFilePath: savePath) {
                        self.body.localVideoPath = (savePath as NSString).lastPathComponent
                        block(savePath)
                    } else {
                        callBack?(nil, false)
                    }
                }, failure: { (errorMsg, error) in
                    callBack?(nil, false)
                })
            } else {
                block(FZMLocalFileClient.shared().getFilePath(with: .video(fileName: (self.body.localVideoPath as NSString).lastPathComponent)))
            }
            
        case .file:
            self.encryptMedia { (ciphertext) in
                #if DEBUG
                if ciphertext == nil {
                    DispatchQueue.main.async {
                        UIApplication.shared.keyWindow?.showToast(with: "加密失败")
                    }
                }
                #endif
                var mediaPath = FZMLocalFileClient.shared().getFilePath(with: .file(fileName: (self.body.localFilePath as NSString).lastPathComponent))
                var uploadPath = IMOSSClient.shared().getUploadPath(uploadType: .file, ofType: (mediaPath as NSString).components(separatedBy: ".").last ?? "")
                let ciphertextMediaPath = FZMLocalFileClient.shared().createTempPath(fileName: self.body.localFilePath)
                if let ciphertext = ciphertext,
                    FZMLocalFileClient.shared().saveData(ciphertext, filePath: ciphertextMediaPath) == true {
                    mediaPath = ciphertextMediaPath
                    uploadPath = IMOSSClient.shared().getUploadPath(uploadType: .file, ofType: (mediaPath as NSString).components(separatedBy: ".").last ?? "", isEncryptFile: true)
                }
                IMOSSClient.shared().uploadFile(filePath: mediaPath, toServerPath: uploadPath, uploadProgressBlock: uploadProgressBlock, callBack: callBack)
            }
        case .audio:
            self.encryptMedia { (ciphertext) in
                #if DEBUG
                if ciphertext == nil {
                    DispatchQueue.main.async {
                        UIApplication.shared.keyWindow?.showToast(with: "加密失败")
                    }
                }
                #endif
                let d = ciphertext ?? FZMLocalFileClient.shared().readData(fileName: .amr(fileName: self.body.localAmrPath.fileName()))
                guard let data = d else {
                    callBack?(nil, false)
                    return
                }
                let uploadPath = IMOSSClient.shared().getUploadPath(uploadType: .voice, ofType: "arm", isEncryptFile: ciphertext != nil)
                IMOSSClient.shared().uploadVoice(file: data, toServerPath: uploadPath, uploadProgressBlock: uploadProgressBlock, callBack: callBack)
            }
        default:
            callBack?(nil, false)
        }
    }
}


extension SocketMessage {
    
    class func encyptForwordMsg(type: IMMessageForwardType, roomIds:[String], userIds:[String], forwordMsgs:[SocketMessage], forwardFromName: String, compeletionBlock:@escaping ([String: Any])->())  {
        if type == .merge {
            self.encyptMergeForwordMsg(roomIds: roomIds, userIds: userIds, forwordMsgs: forwordMsgs, forwardFromName: forwardFromName, compeletionBlock: compeletionBlock)
        } else {
            self.encyptOneByOneForwordMsg(roomIds: roomIds, userIds: userIds, forwordMsgs: forwordMsgs, forwardFromName: forwardFromName, compeletionBlock: compeletionBlock)
        }
    }
    
    private class func encyptForwordMedia(targetId:String, channelType: SocketChannelType, mediaMsgs:[SocketMessage], compeletionBlock:@escaping ()->()) {
        let mediaMsgs = mediaMsgs.filter { $0.msgType == .image || $0.msgType == .video || $0.msgType == .audio || $0.msgType == .file
        }
        guard !mediaMsgs.isEmpty else {
            compeletionBlock()
            return
        }
        
        func setMediaUrl(msg:SocketMessage, url: String) {
            switch msg.msgType {
            case .image:
                msg.body.imageUrl = url
            case .video:
                msg.body.mediaUrl = url
            case .file:
                msg.body.fileUrl = url
            case .audio:
                msg.body.mediaUrl = url
            default:
                break
            }
        }
        let gcdGroup = DispatchGroup.init()
        let conQueue = DispatchQueue.init(label: "com.encyptForwordMediaQueue", attributes: .concurrent)
        for _ in 0..<mediaMsgs.count {
            gcdGroup.enter()
        }
        conQueue.async(group: gcdGroup) {
            for i in 0..<mediaMsgs.count {
                let msg = mediaMsgs[i]
                msg.fromId = IMLoginUser.shared().userId
                msg.targetId = targetId
                msg.channelType = channelType
                msg.uploadMedia(uploadProgressBlock: nil) {[weak msg] (url, success) in
                    #if DEBUG
                    if url == nil {
                        DispatchQueue.main.async {
                            UIApplication.shared.keyWindow?.showToast(with: "上传失败")
                        }
                    }
                    #endif
                    if let url = url, success, let strongMsg = msg {
                        setMediaUrl(msg: strongMsg, url: url)
                    }
                    gcdGroup.leave()
                }
            }
        }
        gcdGroup.notify(queue: .main) {
            compeletionBlock()
        }
        
    }
    
    private class func encyptMergeForwordMsg(roomIds:[String], userIds:[String], forwordMsgs:[SocketMessage], forwardFromName: String, compeletionBlock:@escaping ([String: Any])->())  {
        let gcdGroup = DispatchGroup.init()
        let conQueue = DispatchQueue.init(label: "com.encyptMergeForwordMsgQueue", attributes: .concurrent)
        var roomLogs = Array<Dictionary<String,Any>>.init()
        for _ in 0..<roomIds.count {
            gcdGroup.enter()
        }
        conQueue.async(group: gcdGroup) {
            for i in 0..<roomIds.count {
                let roomId = roomIds[i]
                let forwordMsgs = forwordMsgs.compactMap { $0.copyMsg() }
                self.encyptForwordMedia(targetId: roomId, channelType: .group, mediaMsgs: forwordMsgs) {
                    let forwordMsg = SocketMessage.init()
                    forwordMsg.body.forwardMsgs = forwordMsgs
                    forwordMsg.body.forwardType = .merge
                    forwordMsg.encryptForwordMsgToDic(channelType: .group, targetId: roomId, forwardFromName: forwardFromName, completionBlcok: { (encryptDic) in
                        var message = encryptDic
                        message["msgType"] = SocketMessageType.forward.rawValue
                        roomLogs.append(["messages": [message], "targetId":roomId])
                        gcdGroup.leave()
                    })
                }
            }
        }
        
        var userLogs = Array<Dictionary<String,Any>>.init()
        for _ in 0..<userIds.count {
            gcdGroup.enter()
        }
        conQueue.async(group: gcdGroup) {
            for i in 0..<userIds.count {
                let userId = userIds[i]
                let forwordMsgs = forwordMsgs.compactMap { $0.copyMsg() }
                self.encyptForwordMedia(targetId: userId, channelType: .person, mediaMsgs: forwordMsgs) {
                    let forwordMsg = SocketMessage.init()
                    forwordMsg.body.forwardMsgs = forwordMsgs
                    forwordMsg.body.forwardType = .merge
                    forwordMsg.encryptForwordMsgToDic(channelType: .person, targetId: userId, forwardFromName: forwardFromName, completionBlcok: { (encryptDic) in
                        var message = encryptDic
                        message["msgType"] = SocketMessageType.forward.rawValue
                        userLogs.append(["messages": [message], "targetId":userId])
                        gcdGroup.leave()
                    })
                }
            }
        }
        gcdGroup.notify(queue: .main) {
            compeletionBlock(["roomLogs": roomLogs, "userLogs": userLogs])
        }
    }
    
    private class func encyptOneByOneForwordMsg(roomIds:[String], userIds:[String], forwordMsgs:[SocketMessage], forwardFromName: String, compeletionBlock:@escaping ([String: Any])->())  {
        let gcdGroup = DispatchGroup.init()
        let conQueue = DispatchQueue.init(label: "com.encyptOneByOneForwordMsgQueue", attributes: .concurrent)
        var roomLogs = Array<Dictionary<String,Any>>.init()
        
        for _ in 0..<roomIds.count {
            for _ in 0..<forwordMsgs.count {
                gcdGroup.enter()
            }
        }
        conQueue.async(group: gcdGroup) {
            for i in 0..<roomIds.count {
                let roomId = roomIds[i]
                var messages = Array<Any>.init()
                for j in 0..<forwordMsgs.count {
                    let forwordMsg = forwordMsgs[j].copyMsg()
                    self.encyptForwordMedia(targetId: roomId, channelType: .group, mediaMsgs: [forwordMsg]) {
                        forwordMsg.body.forwardType = .detail
                        var detailForwardDic = forwordMsg.body.mapToDic()
                        detailForwardDic["channelType"] = forwordMsg.channelType.rawValue
                        forwordMsg.body.detailForwardDic = detailForwardDic
                        forwordMsg.encryptForwordMsgToDic(channelType: .group, targetId: roomId, forwardFromName: forwardFromName, completionBlcok: { (encryptDic) in
                            messages.append(encryptDic)
                            if messages.count == forwordMsgs.count {
                                roomLogs.append(["messages": messages, "targetId":roomId])
                            }
                            gcdGroup.leave()
                        })
                    }
                }
            }
        }
        
        var userLogs = Array<Dictionary<String,Any>>.init()
        for _ in 0..<userIds.count {
            for _ in 0..<forwordMsgs.count {
                gcdGroup.enter()
            }
        }
        
        conQueue.async(group: gcdGroup) {
            for i in 0..<userIds.count {
                let userId = userIds[i]
                var messages = Array<Any>.init()
                for j in 0..<forwordMsgs.count {
                    let forwordMsg = forwordMsgs[j].copyMsg()
                    self.encyptForwordMedia(targetId: userId, channelType: .person, mediaMsgs: [forwordMsg]) {
                        forwordMsg.body.forwardType = .detail
                        var detailForwardDic = forwordMsg.body.mapToDic()
                        detailForwardDic["channelType"] = forwordMsg.channelType.rawValue
                        forwordMsg.body.detailForwardDic = detailForwardDic
                        forwordMsg.encryptForwordMsgToDic(channelType: .person, targetId: userId, forwardFromName: forwardFromName, completionBlcok: { (encryptDic) in
                            messages.append(encryptDic)
                            if messages.count == forwordMsgs.count {
                                userLogs.append(["messages": messages, "targetId":userId])
                            }
                            gcdGroup.leave()
                        })
                    }
                }
            }
        }
        gcdGroup.notify(queue: .main) {
            compeletionBlock(["roomLogs": roomLogs, "userLogs": userLogs])
        }
    }
    
    private func encryptForwordMsgToDic(channelType: SocketChannelType, targetId: String, forwardFromName: String, completionBlcok: @escaping ([String: Any]) -> ()) {
        self.isEncryptMsg = true
        self.channelType = channelType
        self.targetId = targetId
        self.body.bodyType = .forward
        self.body.forwardUserName = IMLoginUser.shared().currentUser?.userName ?? ""
        self.body.forwardFromName = forwardFromName
        self.encryptMsgToDic(completionBlcok: { (encryptDic) in
            var dic = encryptDic
            dic.removeValue(forKey: "targetId")
            dic.removeValue(forKey: "eventType")
            dic.removeValue(forKey: "msgId")
            dic.removeValue(forKey: "channelType")
            dic.removeValue(forKey: "isSnap")
            dic.removeValue(forKey: "ciphertext")
            completionBlcok(dic)
        })
    }
    
    
}


//message解析
extension SocketMessage {
    convenience init?(with serverJson: JSON) {
        self.init()
        msgId = serverJson["logId"].stringValue
        sendMsgId = serverJson["msgId"].stringValue
        if let channel = SocketChannelType(rawValue: serverJson["channelType"].intValue) {
            channelType = channel
        }
        fromId = serverJson["fromId"].stringValue
        targetId = serverJson["targetId"].stringValue
        datetime = serverJson["datetime"].doubleValue
        if let snapType = SocketMessageBurnType(rawValue: serverJson["isSnap"].intValue) {
            snap = snapType
        }
        if let type = SocketMessageType(rawValue: serverJson["msgType"].intValue) {
            msgType = type
        }else {
            return nil
        }
        body = SocketMessageBody(with: self.decrypt(bodyJson: serverJson["msg"]), type: msgType)
        if let senderInfo = serverJson["senderInfo"].dictionary {
            senderName = senderInfo["nickname"]?.stringValue ?? ""
            senderAvatar = senderInfo["avatar"]?.stringValue ?? ""
        }
        upvote = SocketMessageUpvote.init(json: serverJson["praise"])
    }
}

extension SocketMessage {
    func upvoteUpdate(operatorId: String, action: UpvoteUpdateAction, admire: Int, reward: Int) {
        if self.upvote.admire == admire && self.upvote.reward == reward {
            return
        }
        var stateForMe = self.upvote.stateForMe
        if operatorId == IMLoginUser.shared().userId {
            switch action {
            case .admire:
                if stateForMe == .admireReward {
                    break
                } else {
                    stateForMe = stateForMe == .reward ? .admireReward : .admire
                }
            case .reward:
                if stateForMe == .admireReward {
                    break
                } else {
                    stateForMe = stateForMe == .admire ? .admireReward : .reward
                }
            case .cancelAdmire:
                stateForMe = stateForMe == .admireReward ? .reward : .none
            default:
                break
            }
        }
        if self.upvote.admire != admire || self.upvote.reward != reward || self.upvote.stateForMe != stateForMe {
            self.upvote.set(admire: admire, reward: reward, stateForMe: stateForMe)
            self.save()
        }
    }
}

extension SocketMessage {
    func forwardMsg() -> SocketMessage {
        let newMsg = self.copyMsg()
        newMsg.fromId = ""
        newMsg.targetId = ""
        newMsg.datetime = Date.timestamp
        newMsg.channelType = .person
        newMsg.isEncryptMsg = false
        newMsg.senderAvatar = ""
        newMsg.senderName = ""
        newMsg.body = self.body.copyBody()
        return newMsg
    }
    
    func copyMsg() -> SocketMessage {
        let newMsg = SocketMessage.init()
        newMsg.sendMsgId = self.getLocalMessageId()
        newMsg.fromId = self.fromId
        newMsg.targetId = self.targetId
        newMsg.channelType = self.channelType
        newMsg.status = .sending
        newMsg.datetime = self.datetime
        newMsg.msgType = self.msgType
        newMsg.isEncryptMsg = self.isEncryptMsg
        newMsg.senderName = self.senderName
        newMsg.senderAvatar = self.senderAvatar
        newMsg.fromKey = self.fromKey
        newMsg.toKey = self.toKey
        newMsg.keyId = self.keyId
        newMsg.body = self.body.copyBody()
        return newMsg
    }
}


//发消息message生成
extension SocketMessage {
    
    // 通知消息
    public convenience init(notify content: String, from: String, to: String, channelType: SocketChannelType, isEncryptMsg: Bool = false) {
        self.init()
        self.sendMsgId = self.getLocalMessageId()
        self.fromId = from
        self.targetId = to
        self.channelType = channelType
        self.status = .succeed
        self.datetime = Date.timestamp
        self.msgType = .notify
        self.body.bodyType = .notify
        self.body.content = content
        self.body.notifyEvent = .rejectReceiveMessage(json: JSON.init(["content": content]))
        self.isEncryptMsg = isEncryptMsg
    }
    
    //发系统消息
    public convenience init(systemText msg: String, from: String, to: String, channelType: SocketChannelType, isEncryptMsg: Bool = false) {
        self.init()
        self.sendMsgId = self.getLocalMessageId()
        self.fromId = from
        self.targetId = to
        self.channelType = channelType
        self.status = .sending
        self.datetime = Date.timestamp
        self.msgType = .system
        self.body.bodyType = .system
        self.body.content = msg
        self.isEncryptMsg = isEncryptMsg
    }
    
    //发文本消息
    public convenience init(text msg: String, from: String, to: String, channelType: SocketChannelType, isBurn: Bool = false, isEncryptMsg: Bool = false) {
        self.init()
        self.sendMsgId = self.getLocalMessageId()
        self.fromId = from
        self.targetId = to
        self.channelType = channelType
        self.snap = isBurn ? .burn : .none
        self.status = .sending
        self.datetime = Date.timestamp
        self.msgType = .text
        self.body.bodyType = .text
        self.body.content = msg
        self.isEncryptMsg = isEncryptMsg
    }
    
    //发图片消息
    public convenience init(image img: UIImage, filePath: String, from: String, to: String, channelType: SocketChannelType, isBurn: Bool = false, isEncryptMsg: Bool = false) {
        self.init()
        self.sendMsgId = self.getLocalMessageId()
        self.fromId = from
        self.targetId = to
        self.channelType = channelType
        self.snap = isBurn ? .burn : .none
        self.status = .sending
        self.datetime = Date.timestamp
        self.msgType = .image
        self.body.bodyType = .image
        self.body.imgData = img.jpegData(compressionQuality: 0.6)!
        self.body.width = Int(img.size.width)
        self.body.height = Int(img.size.height)
        self.body.localImagePath = filePath
        self.isEncryptMsg = isEncryptMsg
    }
    //发视频消息
    public convenience init(firstFrameImg:UIImage, asset:PHAsset, filePath: String, from: String, to: String, channelType: SocketChannelType, isBurn: Bool = false, isEncryptMsg: Bool = false) {
        self.init()
        self.sendMsgId = self.getLocalMessageId()
        self.fromId = from
        self.targetId = to
        self.channelType = channelType
        self.snap = isBurn ? .burn : .none
        self.status = .sending
        self.datetime = Date.timestamp
        self.msgType = .video
        self.body.bodyType = .video
        self.body.width = Int(firstFrameImg.size.width)
        self.body.height = Int(firstFrameImg.size.height)
        self.body.firstFrameImgData = firstFrameImg.jpegData(compressionQuality: 1)!
        self.body.localVideoPath = filePath
        self.body.asset = asset
        self.body.duration = asset.duration
        self.isEncryptMsg = isEncryptMsg
    }
    
    //发音频消息
    public convenience init(amrPath: String, wavPath: String, duration: Double, from: String, to: String, channelType: SocketChannelType, isBurn: Bool = false, isEncryptMsg: Bool = false) {
        self.init()
        self.sendMsgId = self.getLocalMessageId()
        self.fromId = from
        self.targetId = to
        self.channelType = channelType
        self.snap = isBurn ? .burn : .none
        self.status = .sending
        self.datetime = Date.timestamp
        self.msgType = .audio
        self.body.bodyType = .audio
        self.body.duration = duration
        self.body.localAmrPath = amrPath
        self.body.localWavPath = wavPath
        self.isEncryptMsg = isEncryptMsg
    }
    
    public convenience init(filePath:String,fileSize:Int,from: String, to: String, channelType: SocketChannelType, isBurn: Bool = false, isEncryptMsg: Bool = false) {
        self.init()
        self.sendMsgId = self.getLocalMessageId()
        self.fromId = from
        self.targetId = to
        self.channelType = channelType
        self.snap = isBurn ? .burn : .none
        self.status = .sending
        self.datetime = Date.timestamp
        self.msgType = .file
        self.body.bodyType = .file
        self.body.localFilePath = (filePath as NSString).lastPathComponent
        self.body.size = fileSize
        self.body.name = (filePath as NSString).lastPathComponent
        self.body.md5 = OSSUtil.fileMD5String(filePath)
        self.isEncryptMsg = isEncryptMsg
        
    }
    
    //发红包消息
    public convenience init(coin: Int, coinName: String, packetType: IMRedPacketType, packetId: String, remark: String, packetUrl: String, from: String, to: String, channelType: SocketChannelType, isEncryptMsg: Bool = false, isTextRedBag: Bool) {
        self.init()
        self.sendMsgId = self.getLocalMessageId()
        self.fromId = from
        self.targetId = to
        self.channelType = channelType
        self.status = .sending
        self.datetime = Date.timestamp
        self.msgType = .redBag
        self.body.bodyType = .redBag
        self.body.isTextPacket = isTextRedBag
        self.body.packetId = packetId
        self.body.remark = remark
        self.body.packetUrl = packetUrl
        self.body.coin = coin
        self.body.coinName = coinName
        self.body.packetType = packetType
        self.isEncryptMsg = isEncryptMsg
    }
    
    
    public convenience init(transferCoinName: String, amount: Double, recordId: String, from: String, to: String, isEncryptMsg: Bool = false) {
        self.init()
        self.sendMsgId = self.getLocalMessageId()
        self.fromId = from
        self.targetId = to
        self.status = .sending
        self.datetime = Date.timestamp
        self.msgType = .transfer
        self.body.bodyType = .transfer
        self.body.coinName = transferCoinName
        self.body.amount = amount
        self.body.recordId = recordId
        self.isEncryptMsg = isEncryptMsg
    }
    
    public convenience init(receiptCoinName: String, amount: Double, recordId: String, from: String, to: String, isEncryptMsg: Bool = false) {
        self.init()
        self.sendMsgId = self.getLocalMessageId()
        self.fromId = from
        self.targetId = to
        self.status = .sending
        self.datetime = Date.timestamp
        self.msgType = .receipt
        self.body.bodyType = .receipt
        self.body.coinName = receiptCoinName
        self.body.amount = amount
        self.body.recordId = recordId
        self.isEncryptMsg = isEncryptMsg
    }
    
    func getLocalMessageId() -> String {
        return UUID.init().uuidString
    }
    
    func mapToDic() -> [String: Any] {
        var dic: [String: Any] = ["msgId": self.sendMsgId,"eventType":0]
        dic["msgType"] = self.msgType.rawValue
        dic["channelType"] = self.channelType.rawValue
        dic["targetId"] = self.targetId
        dic["msg"] = self.body.mapToDic()
        dic["isSnap"] = self.snap.rawValue
        return dic
    }
    
    //用于转发消息的子消息存储
    func subSaveDic() -> [String: Any] {
        var dic: [String: Any] = ["msgId": self.sendMsgId,"eventType":0]
        dic["msgType"] = self.msgType.rawValue
        dic["channelType"] = self.channelType.rawValue
        dic["targetId"] = self.targetId
        dic["msg"] = self.body.mapToDic()
        dic["datetime"] = self.datetime
        dic["isSnap"] = self.snap.rawValue
        dic["senderInfo"] = ["nickname":senderName,"avatar":senderAvatar]
        dic["isEncryptMsg"] = self.isEncryptMsg
        return dic
    }
    
    func forwordMapToDic() -> [String: Any] {
        var dic = Dictionary<String, Any>.init()
        dic["msgType"] = self.msgType.rawValue
        dic["logId"] = self.getLocalMessageId()
        var bodyDic = self.body.mapToDic()
        bodyDic.removeValue(forKey: "ciphertext")
        dic["msg"] = bodyDic
        dic["datetime"] = round(self.datetime)
        dic["senderInfo"] = ["nickname":senderName,"avatar":senderAvatar]
        return dic
    }
}


//根据消息修改信息
extension SocketMessage {
    func update(by oldMsg: SocketMessage) {
        self.body.update(by: oldMsg.body)
    }
}

//阅后即焚
extension SocketMessage {
    func burnAfterRead(completeBlock: NormalHandler?) {
        let type = self.channelType == .group ? 1 : 2
        HttpConnect.shared().burnMessage(msgId: self.msgId, type: type) { (response) in
            if response.success {
                self.snap = .open
                if self.msgType == .text {
                    self.snapTime = Date.timestamp + self.calcuTextTime()
                }
                self.save()
            }
            completeBlock?(response)
        }
    }
    
    func burnConfigure() {
        switch self.msgType {
        case .text:
            self.snapTime = Date.timestamp + self.calcuTextTime()
        case .image:
            self.snapTime = Date.timestamp + 30000
        case .audio:
            self.snapTime = Date.timestamp + 10000
        default: break
        }
        self.save()
    }
    
    func calcuTextTime() -> Double {
        if self.body.content.count < 20 {
            return 10 * 1000
        }
        let count = self.body.content.count / 50 + 1
        return Double(count * 30) * 1000
    }
}

extension SocketMessage {
    func deleteLocalFile() -> Bool {
        switch self.msgType {
        case .image:
            if !self.body.imageUrl.isEmpty {
                let result1 =  FZMLocalFileClient.shared().deleteFile(atFilePath: FZMLocalFileClient.shared().getFilePath(with: .jpg(fileName: self.body.localImagePath.lastPathComponent())))
                let result2 =  FZMLocalFileClient.shared().deleteFile(atFilePath: FZMLocalFileClient.shared().getFilePath(with: .png(fileName: self.body.localImagePath.lastPathComponent())))
                if result1 || result2 {
                    self.body.localImagePath = ""
                    FZM_UserDefaults.removeObject(forKey: self.body.imageUrl)
                }
                return result1 || result2
            }
            
        case .file:
            if !self.body.fileUrl.isEmpty {
                let result = FZMLocalFileClient.shared().deleteFile(atFilePath: FZMLocalFileClient.shared().getFilePath(with: .file(fileName: self.body.localFilePath.lastPathComponent())))
                if result {
                    self.body.localFilePath = ""
                    FZM_UserDefaults.removeObject(forKey: self.body.fileUrl)
                }
                return result
            }
            
        case .video:
            if !self.body.mediaUrl.isEmpty {
                let result = FZMLocalFileClient.shared().deleteFile(atFilePath: FZMLocalFileClient.shared().getFilePath(with: .video(fileName: self.body.localVideoPath.lastPathComponent())))
                if result {
                    self.body.localVideoPath = ""
                    FZM_UserDefaults.removeObject(forKey: self.body.mediaUrl)
                }
                return result
            }
        default:
            return false
        }
        return false
    }
}
