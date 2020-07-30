//
//  FZMMessageBaseVM.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/30.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift
import Photos

class FZMMessageBaseVM: NSObject {
    var message = SocketMessage()
    var msgId = ""
    var sendMsgId = ""
    var channelType : SocketChannelType = .person
    var conversationId = ""
    var msgType : SocketMessageType = .text
    var status : SocketMessageStatus = .succeed {
        didSet{
            statusSubject.onNext(status)
        }
    }
    var senderUid = ""
    var timeStr = ""
    var isShowTime = false
    var selected = false
    var snap : SocketMessageBurnType = .none
    var snapTime : Double = 0 //阅后即焚消息需要销毁的时间，不查看为0，查看后填充时间
    var direction: SocketMessageDirection = .receive
    var identify = ""
    let statusSubject = PublishSubject<SocketMessageStatus>()
    var showName = true
    var name = ""{
        didSet{
            if !avatar.isEmpty {
                infoSubject.onNext((name,avatar))
            }
        }
    }
    var avatar = ""{
        didSet{
            if !name.isEmpty {
                infoSubject.onNext((name,avatar))
            }
        }
    }
    let infoSubject = BehaviorSubject<(String,String)>(value: ("", ""))
    
    var forwardType : IMMessageForwardType = .none
    var forwardUserName = ""
    var forwardFromName = ""
    var forwardFromId = ""
    var forwardChannelType : SocketChannelType = .person
    var forwardDescriptionText = ""
    var showForward = false //基本不用，在展示转发聊天记录详情的时候使用
    var senderName = ""
    var senderAvatar = ""
    
    var isEncryptMsg = false
    var isNeedFold = true
    //文本信息是否需要折叠（赞赏中用到）
    var isTextNeedFold = false
    var needHighlightString = ""
    var upvote = SocketMessageUpvote.init()
    var isShowUpvoteAnimation = false
    
    override init() {
        super.init()
    }
    
    deinit {
        IMNotifyCenter.shared().removeReceiver(receiver: self, type: .contact)
        IMNotifyCenter.shared().removeReceiver(receiver: self, type: .user)
        IMNotifyCenter.shared().removeReceiver(receiver: self, type: .groupUser)
    }
    
    init(with msg: SocketMessage) {
        message = msg
        super.init()
        msgId = msg.useId
        sendMsgId = msg.sendMsgId
        channelType = msg.channelType
        conversationId = msg.conversationId
        msgType = msg.msgType
        status = msg.status
        senderUid = msg.fromId
        isShowTime = msg.showTime
        direction = msg.direction
        snap = msg.snap
        snapTime = msg.snapTime
        timeStr = String.showTimeString(with: msg.datetime)
        if msg.channelType == .person {
            showName = false
        }
        senderName = msg.senderName
        senderAvatar = msg.senderAvatar
        isEncryptMsg = msg.isEncryptMsg
        self.upvote = msg.upvote
        self.refreshSenderInfo()
        
        if (!msg.body.ciphertext.isEmpty) {
            identify = direction == .send ? "FZMMineDecryptFailedCell" : "FZMDecryptFailedCell"
            return
        }
        
        
        switch msgType {
        case .system:
            identify = "FZMSystemMessageCell"
        case .text:
            identify = direction == .send ? "FZMMineTextMessageCell" : "FZMTextMessageCell"
        case .audio:
            if msg.body.forwardType != .none {
                identify = direction == .send ? "FZMMineTextMessageCell" : "FZMTextMessageCell"
            }else {
                identify = direction == .send ? "FZMMineVoiceMessageCell" : "FZMVoiceMessageCell"
            }
        case .image:
            identify = direction == .send ? "FZMMineImageMessageCell" : "FZMImageMessageCell"
        case .redBag:
            if msg.body.forwardType != .none {
                identify = direction == .send ? "FZMMineTextMessageCell" : "FZMTextMessageCell"
            }else {
                if msg.body.isTextPacket {
                    identify = direction == .send ? "FZMMineTextRedbagMessageCell" : "FZMTextRedbagMessageCell"
                } else {
                    identify = direction == .send ? "FZMMineRedbagMessageCell" : "FZMRedbagMessageCell"
                }
            }            
        case .video:
            identify = direction == .send ? "FZMMineVideoMessageCell" : "FZMVideoMessageCell"
        case .file:
            identify = direction == .send ? "FZMMineFileMessageCell" : "FZMFileMessageCell"
        case .notify:
            identify = "FZMNotifyMessageCell"
        case .forward:
            if msg.body.forwardMsgs.count == 0 {
                identify = direction == .send ? "FZMMineTextMessageCell" : "FZMTextMessageCell"
            }else {
                identify =  direction == .send ? "FZMMineForwardMessageCell" : "FZMForwardMessageCell"
            }
        case .transfer:
            identify = direction == .send ? "FZMMineTransferMessageCell" : "FZMTransferMessageCell"
        case .receipt:
            identify = direction == .send ? "FZMMineReceiptMessageCell" : "FZMReceiptMessageCell"
        case .inviteGroup:
            identify = direction == .send ? "FZMMineInviteGroupCell" : "FZMInviteGroupCell"
        }
        forwardType = msg.body.forwardType
        forwardUserName = msg.body.forwardUserName
        forwardFromName = msg.body.forwardFromName
        forwardFromId = msg.body.forwardFromId
        forwardChannelType = msg.body.forwardChannelType
        if forwardType == .detail {
            forwardDescriptionText = forwardChannelType == .person ? "转发：我与[\(forwardFromName)]的聊天" : "转发：群聊[\(forwardFromName)]的聊天"
        }
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .contact)
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .groupUser)
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .user)
    }
    
    func update(with msg: SocketMessage) {
        msgId = msg.msgId.count > 0 ? msg.msgId : msg.sendMsgId
        msgType = msg.msgType
        if status != msg.status {
            status = msg.status
        }
        senderUid = msg.fromId
        isShowTime = msg.showTime
        direction = msg.direction
        snap = msg.snap
        snapTime = msg.snapTime
        timeStr = String.showTimeString(with: msg.datetime)
        senderName = msg.senderName
        senderAvatar = msg.senderAvatar
        forwardType = msg.body.forwardType
        forwardUserName = msg.body.forwardUserName
        forwardFromName = msg.body.forwardFromName
        forwardFromId = msg.body.forwardFromId
        forwardChannelType = msg.body.forwardChannelType
        isEncryptMsg = msg.isEncryptMsg
        self.upvote = msg.upvote
        if forwardType == .detail {
            forwardDescriptionText = forwardChannelType == .person ? "转发：我与[\(forwardFromName)]的聊天" : "转发：群聊[\(forwardFromName)]的聊天"
        }
        
        if (!msg.body.ciphertext.isEmpty) {
            identify = direction == .send ? "FZMMineDecryptFailedCell" : "FZMDecryptFailedCell"
            return
        }
        
        switch msgType {
        case .system:
            identify = "FZMSystemMessageCell"
        case .text:
            identify = direction == .send ? "FZMMineTextMessageCell" : "FZMTextMessageCell"
        case .audio:
            if msg.body.forwardType != .none {
                identify = direction == .send ? "FZMMineTextMessageCell" : "FZMTextMessageCell"
            }else {
                identify = direction == .send ? "FZMMineVoiceMessageCell" : "FZMVoiceMessageCell"
            }
        case .image:
            identify = direction == .send ? "FZMMineImageMessageCell" : "FZMImageMessageCell"
        case .redBag:
            if msg.body.forwardType != .none {
                identify = direction == .send ? "FZMMineTextMessageCell" : "FZMTextMessageCell"
            }else {
                if msg.body.isTextPacket {
                    identify = direction == .send ? "FZMMineTextRedbagMessageCell" : "FZMTextRedbagMessageCell"
                } else {
                    identify = direction == .send ? "FZMMineRedbagMessageCell" : "FZMRedbagMessageCell"
                }
            }
        case .video:
            identify = direction == .send ? "FZMMineVideoMessageCell" : "FZMVideoMessageCell"
        case .file:
            identify = direction == .send ? "FZMMineFileMessageCell" : "FZMFileMessageCell"
        case .notify:
            identify = "FZMNotifyMessageCell"
        case .forward:
            if msg.body.forwardMsgs.count == 0 {
                identify = direction == .send ? "FZMMineTextMessageCell" : "FZMTextMessageCell"
            }else {
                identify =  direction == .send ? "FZMMineForwardMessageCell" : "FZMForwardMessageCell"
            }
        case .transfer:
            identify = direction == .send ? "FZMMineTransferMessageCell" : "FZMTransferMessageCell"
        case .receipt:
            identify = direction == .send ? "FZMMineReceiptMessageCell" : "FZMReceiptMessageCell"
        case .inviteGroup:
            identify = direction == .send ? "FZMMineInviteGroupCell" : "FZMInviteGroupCell"
            
        }
    
    }
    
    class func constructVM(with msg: SocketMessage) -> FZMMessageBaseVM {
        
        if (!msg.body.ciphertext.isEmpty) {
            return FZMDecryptFailedVM.init(with: msg)
        }
        
        let vm : FZMMessageBaseVM
        switch msg.msgType {
        case .system:
            vm = FZMSystemMessageVM(with: msg)
        case .text:
            vm = FZMTextMessageVM(with: msg)
        case .audio:
            vm = msg.body.forwardType != .none ? FZMTextMessageVM(with: msg) : FZMVoiceMessageVM(with: msg)
        case .image:
            vm = FZMImageMessageVM(with: msg)
        case .redBag:
            if msg.body.forwardType != .none {
                vm = FZMTextMessageVM(with: msg)
            } else {
                vm = msg.body.isTextPacket ? FZMTextRedbagMessageVM(with: msg) : FZMRedbagMessageVM(with: msg)
            }
        case .video:
            vm = FZMVideoMessageVM(with: msg)
        case .notify:
            vm = FZMNotifyMessageVM(with: msg)
        case .file:
            vm = FZMFileMessageVM(with: msg)
        case .forward:
            vm = msg.body.forwardMsgs.count == 0 ? FZMTextMessageVM(with: msg) : FZMForwardMessageVM(with: msg)
        case .transfer:
            vm = FZMTransferMessageVM.init(with: msg)
        case .receipt:
            vm = FZMReceiptMessageVM.init(with: msg)
        case .inviteGroup:
            vm = FZMInviteGroupVM.init(with: msg)
        }
        return vm
    }
    
    class func constructForwardVM(with msg: SocketMessage) -> FZMMessageBaseVM {
        var vm : FZMMessageBaseVM
        switch msg.msgType {
        case .image:
            vm = FZMImageMessageVM(with: msg)
            vm.identify = "FZMImageMessageCell"
        case .video:
            vm = FZMVideoMessageVM.init(with: msg, autoDownloadFile: true, isNeedSaveMessage: false)
            vm.identify = "FZMVideoMessageCell"
        case .file:
            vm = FZMFileMessageVM.init(with: msg, autoDownloadFile: true, isNeedSaveMessage: false)
            vm.identify = "FZMFileMessageCell"
        default:
            vm = FZMTextMessageVM(with: msg)
            vm.identify = "FZMTextMessageCell"
        }
        if (!msg.body.ciphertext.isEmpty) {
            vm = FZMDecryptFailedVM.init(with: msg)
            vm.identify = "FZMDecryptFailedCell"
        }
        vm.direction = .receive
        vm.showForward = true
        vm.showName = true
        return vm
    }
    
}

extension FZMMessageBaseVM: ContactInfoChangeDelegate, UserGroupInfoChangeDelegate {
    func contactUserInfoChange(with userId: String) {
        if senderUid == userId {
            self.refreshSenderInfo()
        }
    }
    
    func userGroupInfoChange(groupId: String, userId: String) {
        if senderUid == userId && channelType == .group && conversationId == groupId {
            self.refreshSenderInfo()
        }
    }
    
    private func refreshSenderInfo() {
        IMContactManager.shared().getUsernameAndAvatar(with: senderUid, groupId: channelType == .group ? conversationId : nil) { (infoId, name, avatar) in
            self.name = name
            self.avatar = avatar
            self.message.senderName = name
            self.message.senderAvatar = avatar
        }
    }
}

extension FZMMessageBaseVM: UserInfoChangeDelegate {
    func userLogin() {
        
    }
    func userLogout() {
        
    }
    func userInfoChange() {
        self.refreshSenderInfo()
    }
}


class FZMSystemMessageVM: FZMMessageBaseVM {
    
    var content = ""
    
    override init(with msg: SocketMessage) {
        super.init(with: msg)
        content = msg.body.content
    }
    
    override func update(with msg: SocketMessage) {
        super.update(with: msg)
        content = msg.body.content
    }
}

class FZMNotifyMessageVM: FZMMessageBaseVM {
    var notifyEvent : SocketNotifyEventType?
    var content = ""
    
    var logId = ""
    var recordId = ""
    
    var owner = ""
    var oper = ""
    var packetId = ""
    
    override init(with msg: SocketMessage) {
        super.init(with: msg)
        content = msg.body.content
        guard let event = msg.body.notifyEvent else { return }
        self.notifyEvent = msg.body.notifyEvent
        switch event {
        case .printScreen(_):
            content = msg.direction == .send ? "你在聊天中截图了" : "对方在聊天中截图了"
        case .receoptSuceess(_ , let logId, let recordId):
            content = msg.direction == .send ? "你已付款，查看 详情" : "对方已付款，查看 详情"
            self.logId = logId
            self.recordId = recordId
        case .receiveRedBag(_, let owner, let oper, let packetId):
            content = msg.body.content
            self.owner = owner
            self.oper = oper
            self.packetId = packetId
        default:
            content = msg.body.content
        }
    }
    
    override func update(with msg: SocketMessage) {
        super.update(with: msg)
        content = msg.body.content
        guard let event = msg.body.notifyEvent else { return }
        switch event {
        case .printScreen(_):
            content = msg.direction == .send ? "你在聊天中截图了" : "对方在聊天中截图了"
        case .receoptSuceess(_, let logId, let recordId):
            content = msg.direction == .send ? "你已付款，查看 详情" : "对方已付款，查看 详情"
            self.logId = logId
            self.recordId = recordId
        case .receiveRedBag(_, let owner, let oper, let packetId):
            content = msg.body.content
            self.owner = owner
            self.oper = oper
            self.packetId = packetId
        default:
            content = msg.body.content
        }
    }
}

class FZMTextMessageVM: FZMMessageBaseVM {
    
    var content = ""
    
    override init(with msg: SocketMessage) {
        super.init(with: msg)
        content = msg.body.content
    }
    
    override func update(with msg: SocketMessage) {
        super.update(with: msg)
        content = msg.body.content
    }
}

class FZMImageMessageVM: FZMMessageBaseVM {
    
    var imageUrl = ""
    var height : CGFloat = 0
    var width : CGFloat = 0
    var imgData = Data()
    
    override init(with msg: SocketMessage) {
        super.init(with: msg)
        imageUrl = msg.body.imageUrl
        imgData = msg.body.imgData
        height = CGFloat(msg.body.height)
        width = CGFloat(msg.body.width)
    }
    
    override func update(with msg: SocketMessage) {
        super.update(with: msg)
        imageUrl = msg.body.imageUrl
        imgData = msg.body.imgData
        height = CGFloat(msg.body.height)
        width = CGFloat(msg.body.width)
    }
}

class FZMVoiceMessageVM: FZMMessageBaseVM {
    
    var mediaUrl = ""
    var wavFileName = ""
    var duration : Double = 0
    var isRead = false
    
    override init(with msg: SocketMessage) {
        super.init(with: msg)
        mediaUrl = msg.body.mediaUrl
        wavFileName = msg.body.localWavPath
        duration = msg.body.duration
        isRead = msg.body.isRead
    }
    
    override func update(with msg: SocketMessage) {
        super.update(with: msg)
        mediaUrl = msg.body.mediaUrl
        wavFileName = msg.body.localWavPath
        duration = msg.body.duration
        isRead = msg.body.isRead
    }
}

class FZMRedbagMessageVM: FZMMessageBaseVM {
    var remark = ""
    let updateBagStatusSubject = PublishSubject<SocketLuckyPacketStatus>.init()
    var bagStatus : SocketLuckyPacketStatus = .normal 
    
    override init(with msg: SocketMessage) {
        super.init(with: msg)
        remark = msg.body.remark
        bagStatus = msg.body.status
    }
    
    override func update(with msg: SocketMessage) {
        super.update(with: msg)
        remark = msg.body.remark
        bagStatus = msg.body.status
        updateBagStatusSubject.onNext(bagStatus)
    }
}

class FZMTextRedbagMessageVM: FZMRedbagMessageVM {
    
}

class FZMForwardMessageVM: FZMMessageBaseVM {
    var forwardMsgs = [SocketMessage]()
    var content = ""
    var title = ""
    var detail = ""
    var numberText = ""
    
    override init(with msg: SocketMessage) {
        super.init(with: msg)
        forwardMsgs = msg.body.forwardMsgs
        content = msg.body.content
        title = msg.body.forwardChannelType == .person ? "[\(msg.body.forwardFromName)]和[\(msg.body.forwardUserName)]的聊天记录" : "[\(msg.body.forwardFromName)]的聊天记录"
        numberText = "聊天记录 共\(msg.body.forwardMsgs.count)条"
        let detailText = msg.body.forwardMsgs.reduce("", { $0 + $1.getForwardDescriptionStr() + "\n" })
        detail = detailText.substring(to: detailText.count - 2)
    }
    
    override func update(with msg: SocketMessage) {
        super.update(with: msg)
        forwardMsgs = msg.body.forwardMsgs
        content = msg.body.content
        title = msg.body.forwardChannelType == .person ? "[\(msg.body.forwardFromName)]和[\(msg.body.forwardUserName)]的聊天记录" : "[\(msg.body.forwardFromName)]的聊天记录"
        numberText = "聊天记录 共\(msg.body.forwardMsgs.count)条"
        let detailText = msg.body.forwardMsgs.reduce("", { $0 + $1.getForwardDescriptionStr() + "\n" })
        detail = detailText.substring(to: detailText.count - 2)
    }
}

class FZMVideoMessageVM: FZMMessageBaseVM {
    var videoUrl = ""
    var localVideoPath = ""
    var height : CGFloat = 0
    var width : CGFloat = 0
    var firstFrameImgData = Data()
    var duration = 0.0
    let videoDownloadID = UUID.init().uuidString
    private let requestImageTool = UIImageView()
    
    let widthAndHeightRefreshSubject = PublishSubject<String>()
    let videoDownloadFailedSubject = PublishSubject<String>()
    let isNeedSaveMessage:Bool
    init(with msg: SocketMessage, autoDownloadFile: Bool = true,isNeedSaveMessage: Bool = true) {
        self.isNeedSaveMessage = isNeedSaveMessage
        super.init(with: msg)
        videoUrl = msg.body.mediaUrl
        localVideoPath = msg.body.localVideoPath
        height = CGFloat(msg.body.height)
        width = CGFloat(msg.body.width)
        firstFrameImgData = msg.body.firstFrameImgData
        duration = msg.body.duration
        if duration < 0.001 && msg.body.localVideoPath.count > 0 {
             let asset = AVURLAsset.init(url: URL.init(fileURLWithPath: FZMLocalFileClient.shared().getFilePath(with: .video(fileName: (msg.body.localVideoPath as NSString).lastPathComponent))))
            duration = Double(asset.duration.value) / Double(asset.duration.timescale)
        }
        if msg.body.firstFrameImgData.isEmpty && !msg.body.isEncryptMedia {
            requestImageTool.loadNetworkImage(with: msg.body.mediaUrl + "?x-oss-process=video/snapshot,t_1000,w_0,h_0,m_fast", placeImage: nil) { (image) in
                guard var image = image else { return }
                if (self.height > self.width) && (image.size.height < image.size.width) {
                    image = image.rotateImage(withAngle: 90)
                }
                if self.height == 0 || self.width == 0 {
                    self.height = CGFloat(image.size.height)
                    self.width = CGFloat(image.size.width)
                    msg.body.height = Int(image.size.height)
                    msg.body.width = Int(image.size.width)
                }
                self.firstFrameImgData = image.jpegData(compressionQuality: 1)!
                msg.body.firstFrameImgData = self.firstFrameImgData
                msg.save()
                self.widthAndHeightRefreshSubject.onNext("")
            }
        }
        if localVideoPath.count == 0 && autoDownloadFile {
            downloadVideo()
        }
    }
    
    func downloadVideo() {
        if self.message.body.mediaUrl.count > 0 {
            if let url = URL.init(string: self.message.body.mediaUrl) {
                IMOSSClient.shared().download(with: url, downloadProgressBlock: { (progress) in
                    IMNotifyCenter.shared().postMessage(event: .downloadProgress(msgID: self.videoDownloadID, progress: progress))
                }) { (data, result) in
                    if result, var data = data {
                        if self.message.body.isEncryptMedia {
                            data = self.message.decryptMedia(ciphertext: data)
                        }
                        if let savePath = FZMLocalFileClient.shared().createFile(with: .video(fileName: String.getTimeStampStr() + (self.message.body.mediaUrl as NSString).lastPathComponent)) {
                            let saveResult = FZMLocalFileClient.shared().saveData(data, filePath: savePath)
                            if saveResult {
                                self.message.body.localVideoPath = (savePath as NSString).lastPathComponent
                                if self.isNeedSaveMessage {
                                    self.message.save()
                                }
                                self.localVideoPath = self.message.body.localVideoPath
                                FZM_UserDefaults.set(self.message.body.localVideoPath, forKey: self.message.body.mediaUrl)
                                FZM_UserDefaults.synchronize()
                                UIImage.getFirstFrame(URL.init(fileURLWithPath: savePath), compeletion: { (image) in
                                    if let image = image {
                                        self.height = CGFloat(image.size.height)
                                        self.width = CGFloat(image.size.width)
                                        self.firstFrameImgData = image.jpegData(compressionQuality: 1)!
                                        self.message.body.height = Int(image.size.height)
                                        self.message.body.width = Int(image.size.width)
                                        self.message.body.firstFrameImgData = self.firstFrameImgData
                                        DispatchQueue.main.async {
                                            self.widthAndHeightRefreshSubject.onNext("")
                                        }
                                        if self.isNeedSaveMessage {
                                            self.message.save()
                                        }
                                    }
                                })
                            }
                        }
                    } else {
                        self.videoDownloadFailedSubject.onNext(self.message.msgId)
                    }
                }
            }
        }
    }

    
    
    override func update(with msg: SocketMessage) {
        super.update(with: msg)
        videoUrl = msg.body.mediaUrl
        firstFrameImgData = msg.body.firstFrameImgData
        height = CGFloat(msg.body.height)
        width = CGFloat(msg.body.width)
    }
}


class FZMFileMessageVM: FZMMessageBaseVM {
    var fileUrl = ""
    var size = 0
    var md5 = ""
    var fileName = ""
    var localFilePath = ""
    var iconImageName: String = ""
    let fileDownloadFailedSubject = PublishSubject<String>()
    let fileDownloadID = UUID.init().uuidString
    let isNeedSaveMessage:Bool
    init(with msg: SocketMessage, autoDownloadFile: Bool = true,isNeedSaveMessage: Bool = true) {
        self.isNeedSaveMessage = isNeedSaveMessage
        super.init(with: msg)
        fileUrl = msg.body.fileUrl
        size = msg.body.size
        md5 = msg.body.md5
        fileName = msg.body.name
        localFilePath = msg.body.localFilePath
        iconImageName = (fileUrl.count > 0 ? (fileUrl as NSString).pathExtension : (localFilePath as NSString).pathExtension).matchingFileType()
        if localFilePath.count == 0 && autoDownloadFile {
            downloadFile()
        }
    }
    
    override func update(with msg: SocketMessage) {
        super.update(with: msg)
    }
    
    func downloadFile() {
        if self.message.body.fileUrl.count > 0 {
            if let url = URL.init(string: self.message.body.fileUrl) {
                IMOSSClient.shared().download(with: url, downloadProgressBlock: { (progress) in
                    IMNotifyCenter.shared().postMessage(event: .downloadProgress(msgID: self.fileDownloadID, progress: progress))
                }) { (data, result) in
                    if result , var data = data {
                        if self.message.body.isEncryptMedia {
                            data = self.message.decryptMedia(ciphertext: data)
                        }
                        if let savePath = FZMLocalFileClient.shared().createFile(with: .file(fileName: String.getTimeStampStr() + (self.message.body.fileUrl as NSString).lastPathComponent)) {
                            let saveResult = FZMLocalFileClient.shared().saveData(data, filePath: savePath)
                            if saveResult {
                                self.message.body.localFilePath = (savePath as NSString).lastPathComponent
                                if self.isNeedSaveMessage {
                                    self.message.save()
                                }
                                self.localFilePath = self.message.body.localFilePath
                                FZM_UserDefaults.set(self.message.body.localFilePath, forKey: self.message.body.fileUrl)
                                FZM_UserDefaults.synchronize()
                            }
                        }
                    } else {
                        self.fileDownloadFailedSubject.onNext(self.message.msgId)
                    }
                }
            }
        }
    }

    
}


class FZMTransferMessageVM: FZMMessageBaseVM {
    var money = ""
    var infor = ""
    
    override init(with msg: SocketMessage) {
        super.init(with: msg)
        if let amount = String.getStringFrom(double: msg.body.amount) {
            self.money = amount + msg.body.coinName
        }
        self.infor = msg.direction == .send ? "转账给对方" : "转账给你"
    }
    
    override func update(with msg: SocketMessage) {
        super.update(with: msg)
    }
}

class FZMReceiptMessageVM: FZMMessageBaseVM {
    var money = ""
    var infor = ""
    var recordId = ""
    
    override init(with msg: SocketMessage) {
        super.init(with: msg)
        if let amount = String.getStringFrom(double: msg.body.amount) {
            self.money = amount + msg.body.coinName
        }
        self.recordId = msg.body.recordId
        if recordId.isEmpty {
            self.infor = msg.direction == .send ? "向对方收款" : "向你收款"
        } else {
            self.infor = msg.direction == .send ? "对方已付款" : "你已付款"
        }
    }
    
    
    override func update(with msg: SocketMessage) {
        super.update(with: msg)
        if let amount = String.getStringFrom(double: msg.body.amount) {
            self.money = amount + msg.body.coinName
        }
        self.recordId = msg.body.recordId
        if recordId.isEmpty {
            self.infor = msg.direction == .send ? "向对方收款" : "向你收款"
        } else {
            self.infor = msg.direction == .send ? "对方已付款" : "你已付款"
        }
    }
}


class FZMDecryptFailedVM: FZMMessageBaseVM {
    var content = "无法解密的消息"    
    override init(with msg: SocketMessage) {
        super.init(with: msg)
        
    }
    
    override func update(with msg: SocketMessage) {
        super.update(with: msg)
    }
}

class FZMInviteGroupVM: FZMMessageBaseVM {
    var title = ""
    var groupAvatar = ""
    var roomId = ""
    var markId = ""
    var roomName = ""
    var inviterId = ""
    var identificationInfo = ""
    
    override init(with msg: SocketMessage) {
        super.init(with: msg)
        title = msg.direction == .send ? "邀请对方加入群聊" : "邀请你加入群聊"
        groupAvatar = msg.body.avatar
        roomId = msg.body.roomId
        markId = msg.body.markId
        roomName = msg.body.roomName
        inviterId = msg.body.inviterId
        identificationInfo = msg.body.identificationInfo
    }
    
    override func update(with msg: SocketMessage) {
        super.update(with: msg)
    }
}
