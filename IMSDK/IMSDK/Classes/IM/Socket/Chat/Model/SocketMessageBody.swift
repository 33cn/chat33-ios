//
//  SocketMessageBody.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/28.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import SwiftyJSON
import Photos


enum SocketLuckyPacketStatus : Int {
    case normal = 1 //正常状态
    case receiveAll//领取完
    case past//过期
    case opened//已领取   
}

// 点赞 打赏 取消点赞 操作
enum UpvoteUpdateAction: String {
    case none = ""
    case admire = "like"
    case cancelAdmire = "cancel_like"
    case reward = "reward"
}

enum SocketNotifyEventType {
    case revokeMsg(json: JSON, msgId: String)//撤回消息
    case createGroup(json: JSON) //创建群聊
    case quitGroup(json: JSON) //退出群聊
    case removeGroup(json: JSON) //移除群聊
    case joinGroup(json: JSON) //加入群聊
    case dissolveGroup(json: JSON) //解散群聊
    case addGroupFriend(json: JSON) //添加群中好友
    case deleteFriend(json: JSON) //删除好友
    case beGroupMaster(json: JSON) //成为群主
    case beGroupManager(json: JSON) //成为管理员
    case updateGroupName(json: JSON) //修改群名
    case receiveRedBag(json: JSON, owner: String,operator: String, packetId: String) //领取红包
    case addFriend(json: JSON) //群外添加好友
    case unUse(json: JSON) //未识别通知，暂存
    case groupBanned(json: JSON,mutedType: IMGroupBannedType)//设置禁言
    case burnMsg(json: JSON, channelType: SocketChannelType, msgId: String)//阅后即焚
    case printScreen(json: JSON)//截屏消息
    case receoptSuceess(json: JSON,logId: String, recordId: String)
    case updataGroupKey(json: JSON,groupId: String, fromKey: String, key: String, keyId: String)
    case rejectJoinGroup(json: JSON) //被加入黑名单后发送入群邀请被拒收
    case rejectReceiveMessage(json: JSON) //被加入黑名单后发送消息被拒收
    case msgUpvoteUpdate(json: JSON, operator: String, action: UpvoteUpdateAction, logId: String, admire: Int, reward: Int)
    init(with serverJson: JSON){
        switch serverJson["type"].intValue {
        case 1:
            self = .revokeMsg(json: serverJson, msgId: serverJson["logId"].stringValue)
        case 2:
            self = .createGroup(json: serverJson)
        case 3:
            self = .quitGroup(json: serverJson)
        case 4:
            self = .removeGroup(json: serverJson)
        case 5:
            self = .joinGroup(json: serverJson)
        case 6:
            self = .dissolveGroup(json: serverJson)
        case 7:
            self = .addGroupFriend(json: serverJson)
        case 8:
            self = .deleteFriend(json: serverJson)
        case 9:
            self = .beGroupMaster(json: serverJson)
        case 10:
            self = .beGroupManager(json: serverJson)
        case 11:
            self = .updateGroupName(json: serverJson)
        case 12:
            self = .receiveRedBag(json: serverJson, owner: serverJson["owner"].stringValue ,operator: serverJson["operator"].stringValue, packetId: serverJson["packetId"].stringValue)
        case 13:
            self = .addFriend(json: serverJson)
        case 14:
            if let type = IMGroupBannedType(rawValue: serverJson["mutedType"].intValue) {
                self = .groupBanned(json: serverJson, mutedType: type)
            }else {
                self = .groupBanned(json: serverJson, mutedType: .all)
            }
        case 15:
            var channelType : SocketChannelType = .group
            if let type = SocketChannelType(rawValue: serverJson["channelType"].intValue) {
                channelType = type
            }
            self = .burnMsg(json: serverJson, channelType: channelType, msgId: serverJson["logId"].stringValue)
        case 16:
            self = .printScreen(json: serverJson)
        case 18:
            self = .receoptSuceess(json: serverJson,logId: serverJson["logId"].stringValue, recordId: serverJson["recordId"].stringValue)
        case 19:
            self = .updataGroupKey(json: serverJson, groupId: serverJson["roomId"].stringValue, fromKey: serverJson["fromKey"].stringValue, key: serverJson["key"].stringValue, keyId: serverJson["kid"].stringValue)
        case 20:
            self = .rejectJoinGroup(json: serverJson)
        case 21:
            self = .rejectReceiveMessage(json: serverJson)
        case 22:
            self = .msgUpvoteUpdate(json: serverJson, operator: serverJson["operator"].stringValue, action: UpvoteUpdateAction.init(rawValue: serverJson["action"].stringValue) ?? .none, logId: serverJson["logId"].stringValue, admire: serverJson["like"].intValue, reward: serverJson["reward"].intValue)
        default:
            self = .unUse(json: serverJson)
        }
    }
    
    func getJson() -> JSON {
        switch self {
        case .revokeMsg(let json, _):
            return json
        case .createGroup(let json):
            return json
        case .quitGroup(let json):
            return json
        case .removeGroup(let json):
            return json
        case .joinGroup(let json):
            return json
        case .dissolveGroup(let json):
            return json
        case .addGroupFriend(let json):
            return json
        case .deleteFriend(let json):
            return json
        case .beGroupMaster(let json):
            return json
        case .beGroupManager(let json):
            return json
        case .updateGroupName(let json):
            return json
        case .receiveRedBag(let json,_,_,_):
            return json
        case .addFriend(let json):
            return json
        case .groupBanned(let json, _):
            return json
        case .burnMsg(let json, _, _):
            return json
        case .printScreen(let json):
            return json
        case .receoptSuceess(let json,_,_):
            return json
        case .updataGroupKey(let json,_,_,_,_):
            return json
        case .rejectJoinGroup(let json):
            return json
        case .rejectReceiveMessage(let json):
            return json
        case .unUse(let json):
            return json
        case .msgUpvoteUpdate(let json,_,_, _, _, _):
            return json
        }
    }
    
}

class SocketMessageBody: NSObject {
    var ciphertext = ""
    var bodyType : SocketMessageType = .text
    var content = ""//系统消息、文字消息的text
    var mediaUrl = ""//语音和视频消息的url
    var imageUrl = ""//图片和视频消息的url
    var width = 0//图片消息和视频消息才会有
    var height = 0//图片消息和视频消息才会有
    var duration : Double = 0//语音和视频消息的时长
    var imgData = Data()//图片数据
    var localImagePath = ""//本地图片文件地址
    var localWavPath = ""//wav音频本地地址
    var localAmrPath = ""//amr音频本地地址
    var firstFrameImgData = Data()
    var localVideoPath = ""
    var asset: PHAsset? = PHAsset()
    
    var fileUrl = ""
    var size = 0
    var md5 = ""
    var name = ""//文件名
    var localFilePath = ""
    
    var isRead = false//是否已读，暂用于语音和系统消息
    //MARK: 红包
    var packetId = ""
    var remark = ""
    var packetType : IMRedPacketType = .luck
    var packetUrl = ""
    var coin = -1
    var coinName = ""
    var status : SocketLuckyPacketStatus = .normal //状态
    var isTextPacket = false
    
    var notifyEvent : SocketNotifyEventType?
    
    //MARK: 转发相关
    var forwardType : IMMessageForwardType = .none //转发类型
    var forwardUserName = "" //转发人名称
    var forwardFromName = "" //（原消息）转发来源name
    var forwardFromId = "" //（原消息）转发来源id
    var forwardChannelType : SocketChannelType = .person //原消息）表示是转发的群消息还是好友消息
    var forwardMsgs = [SocketMessage]() //合并转发的消息列表
    
    var amount = 0.0
    var recordId = ""
    
    var roomId = ""
    var markId = ""
    var roomName = ""
    var inviterId = ""
    var avatar = ""
    var identificationInfo = ""
    var aitList = Array<String>.init()
    
    var detailForwardDic = Dictionary<String, Any>.init()
    
    var isEncryptMedia: Bool {
        get{
            switch self.bodyType {
            case .image:
                return self.imageUrl.contains("%24ENC%24")
            case .file:
                return self.fileUrl.contains("%24ENC%24")
            case .video, .audio:
                return self.mediaUrl.contains("%24ENC%24")
            default:
                return false
            }
        }
    }
    
    override init() {
        super.init()
    }
    
    init(with dataJson: JSON, type: SocketMessageType) {
        super.init()
        bodyType = type
        if let encryptedMsg = dataJson["encryptedMsg"].string, !encryptedMsg.isEmpty {
            ciphertext = dataJson.rawString() ?? ""
        }
        if let ciphertext = dataJson["ciphertext"].string, !ciphertext.isEmpty {
            self.ciphertext = ciphertext
        }
        switch bodyType {
        case .text,.system:
            content = dataJson["content"].stringValue
            aitList = dataJson["aitList"].arrayValue.compactMap({$0.string})
        case .notify:
            content = dataJson["content"].stringValue
            notifyEvent = SocketNotifyEventType(with: dataJson)
            if content.isEncryptString() {
                var encryptGroupName = ""
                if case .updateGroupName(_) = notifyEvent {
                    let spt = content.components(separatedBy: "\"")
                    if spt.count == 3 {
                        encryptGroupName = spt[1]
                    }
                } else if case .createGroup(_) = notifyEvent {
                    //将好友拉入群聊 发给我和好友的通知 服务端走的创建群聊的接口
                    if let str = content.components(separatedBy: "[").last?.components(separatedBy: "]").first {
                        encryptGroupName = str
                    }
                }
                let groupNameSpt = encryptGroupName.components(separatedBy: String.getEncryptStringPrefix())
                if groupNameSpt.count == 3  {
                    let encryptContent = groupNameSpt[0]
                    let keyId = groupNameSpt[1]
                    let groupId = groupNameSpt[2]
                    if let groupKey = IMLoginUser.shared().currentUser?.getGroupKey(groupId: groupId, keyId: keyId),
                    let key = groupKey.plainTextKey,
                    let plaintext = FZMEncryptManager.decryptSymmetric(key: key, ciphertext: Data.init(hex: encryptContent)),
                        let plaintextContent = String.init(data: plaintext, encoding: .utf8) {
                        content = content.replacingOccurrences(of: encryptGroupName, with:plaintextContent)
                        var dataJson = dataJson
                        dataJson["content"] = JSON.init(stringLiteral: content)
                        notifyEvent = SocketNotifyEventType(with: dataJson)
                    }
                }
            }
        case .image:
            imageUrl = dataJson["imageUrl"].stringValue
            width = dataJson["width"].intValue
            height = dataJson["height"].intValue
        case .audio:
            mediaUrl = dataJson["mediaUrl"].stringValue
            duration = dataJson["time"].doubleValue
            content = "[语音]"
        case .video:
            mediaUrl = dataJson["mediaUrl"].stringValue
            duration = dataJson["time"].doubleValue
            width = dataJson["width"].intValue
            height = dataJson["height"].intValue
            content = "[视频]"
        case .file:
            fileUrl = dataJson["fileUrl"].stringValue
            size = dataJson["size"].intValue
            md5 = dataJson["md5"].stringValue
            name = dataJson["name"].stringValue
            content = "[文件]"
        case .redBag:
            packetId = dataJson["packetId"].stringValue
            packetUrl = dataJson["packetUrl"].stringValue
            remark = dataJson["remark"].stringValue
            coin = dataJson["coin"].intValue
            coinName = dataJson["coinName"].stringValue
            isTextPacket = dataJson["packetMode"].intValue == 1
            if let type = IMRedPacketType(rawValue: dataJson["type"].intValue) {
                packetType = type
            }
            if let num = dataJson["status"].int, let useStatus = SocketLuckyPacketStatus(rawValue: num) {
                status = useStatus
            }
            content = "[红包]"
        case .forward:
            if let type = IMMessageForwardType(rawValue: dataJson["forwardType"].intValue) {
                forwardType = type
            }
            if let channelType = SocketChannelType(rawValue: dataJson["channelType"].intValue) {
                forwardChannelType = channelType
            }
            forwardUserName = dataJson["forwardUserName"].stringValue
            forwardFromName = dataJson["fromName"].stringValue
            forwardFromId = dataJson["fromId"].stringValue
            if let data = dataJson["data"].array {
                forwardMsgs = data.compactMap { (json) -> SocketMessage? in
                    return SocketMessage.init(with: json)
                }.sorted(by: <)
            }
            content = "[聊天记录]"
        case .transfer:
            coinName = dataJson["coinName"].stringValue
            amount = dataJson["amount"].doubleValue
            recordId = dataJson["recordId"].stringValue
            content = "[转账]"
        case .receipt:
            coinName = dataJson["coinName"].stringValue
            amount = dataJson["amount"].doubleValue
            recordId = dataJson["recordId"].stringValue
            content = "[收款]"
        case .inviteGroup:
            roomId = dataJson["roomId"].stringValue
            markId = dataJson["markId"].stringValue
            roomName = dataJson["roomName"].stringValue
            inviterId = dataJson["inviterId"].stringValue
            avatar = dataJson["avatar"].stringValue
            identificationInfo = dataJson["identificationInfo"].stringValue
        default:
            IMLog("暂不支持")
        }
        
        if let value = dataJson["forwardType"].int, let type = IMMessageForwardType(rawValue: value) {
            forwardType = type
            if let channelType = SocketChannelType(rawValue: dataJson["channelType"].intValue) {
                forwardChannelType = channelType
            }
            forwardUserName = dataJson["forwardUserName"].stringValue
            forwardFromName = dataJson["fromName"].stringValue
            forwardFromId = dataJson["fromId"].stringValue
        }
    }
    
    func mapToDic() -> [String: Any] {
        var dic = [String: Any]()
        switch bodyType {
        case .text,.system,.notify:
            dic = ["content":content]
        case .image:
            dic = ["imageUrl":imageUrl,"width":width,"height":height]
        case .audio:
            dic = ["mediaUrl":mediaUrl,"time":duration]
        case .redBag:
            dic = ["coin":coin,"coinName":coinName,"packetId":packetId,"packetType":packetType.rawValue,"packetUrl":packetUrl,"remark":remark,"type":packetType.rawValue, "packetMode": isTextPacket ? 1 : 0]
        case .video:
            dic = ["width":width,"height":height,"mediaUrl":mediaUrl,"time":duration]
        case .file:
            dic = ["fileUrl":fileUrl,"size":size,"md5":md5,"name":name]
        case .transfer:
            dic = ["coinName":coinName,"amount":amount,"recordId":recordId]
        case .receipt:
             dic = ["coinName":coinName,"amount":amount,"recordId":recordId]
        case .inviteGroup:
            dic = ["roomId":roomId, "markId": markId, "roomName":roomName,"inviterId":inviterId,"identificationInfo":identificationInfo,"avatar":avatar]
        case .forward:
            if self.forwardType == .merge {
                let data = forwardMsgs.compactMap { $0.forwordMapToDic()}
                dic = ["data":data]
                if let cType = forwardMsgs.first?.channelType.rawValue {
                    dic["channelType"] = cType
                }
            } else {
                dic = self.detailForwardDic
            }
            dic["forwardType"] = forwardType.rawValue
            dic["forwardUserName"] =  forwardUserName
            dic["fromName"] = forwardFromName
            
        default: break
        }
        if bodyType == .text && !aitList.isEmpty {
            dic["aitList"] = aitList
        }
        dic["ciphertext"] = self.ciphertext
        return dic
    }
    
    func saveToJsonString() -> String {
        var dic = [String: Any]()
        switch bodyType {
        case .text,.system:
            dic = ["content":content]
        case .notify:
            if let event = notifyEvent, let jsonDic = event.getJson().dictionaryObject {
                dic = jsonDic
            }
        case .image:
            dic = ["imageUrl":imageUrl,"width":width,"height":height,"localImagePath":localImagePath]
        case .audio:
            dic = ["mediaUrl":mediaUrl,"time":duration,"localWavPath":localWavPath,"localAmrPath":localAmrPath]
        case .redBag:
            dic = ["coin":coin,"coinName":coinName,"packetId":packetId,"packetType":packetType.rawValue,"packetUrl":packetUrl,"remark":remark,"type":packetType.rawValue,"status":status.rawValue, "packetMode": isTextPacket ? 1 : 0]
        case .video:
            dic = ["localVideoPath":localVideoPath, "width":width,"height":height,"mediaUrl":mediaUrl,"time":duration]
        case .file:
            dic = ["localFilePath":localFilePath, "fileUrl":fileUrl,"size":size,"md5":md5,"name":name]
        case .forward:
            let data = forwardMsgs.compactMap { (msg) -> [String: Any]? in
                return msg.subSaveDic()
            }
            dic = ["forwardUserName":forwardUserName,"data":data]
        case .transfer:
            dic = ["coinName":coinName,"amount":amount,"recordId":recordId]
        case .receipt:
            dic = ["coinName":coinName,"amount":amount,"recordId":recordId]
        case .inviteGroup:
            dic = ["roomId":roomId,"markId": markId, "roomName":roomName,"inviterId":inviterId,"identificationInfo":identificationInfo,"avatar":avatar]
        }
        dic["isRead"] = isRead
        if forwardType != .none {
            dic["forwardType"] = forwardType.rawValue
            dic["fromName"] = forwardFromName
            dic["fromId"] = forwardFromId
            dic["channelType"] = forwardChannelType.rawValue
        }
        dic["aitList"] = aitList
        dic["ciphertext"] = self.ciphertext
        return JSON.init(dic).rawString() ?? ""
    }
    
    init(with localJsonStr: String, type: SocketMessageType) {
        super.init()
        bodyType = type
        let dataJson = JSON(parseJSON: localJsonStr)
        ciphertext = dataJson["ciphertext"].stringValue
        isRead = dataJson["isRead"].boolValue
        aitList = dataJson["aitList"].arrayValue.compactMap({$0.string})
        switch bodyType {
        case .text,.system:
            content = dataJson["content"].stringValue
        case .notify:
            content = dataJson["content"].stringValue
            notifyEvent = SocketNotifyEventType(with: dataJson)
        case .image:
            imageUrl = dataJson["imageUrl"].stringValue
            width = dataJson["width"].intValue
            height = dataJson["height"].intValue
            localImagePath = dataJson["localImagePath"].stringValue
        case .audio:
            mediaUrl = dataJson["mediaUrl"].stringValue
            duration = dataJson["time"].doubleValue
            localAmrPath = dataJson["localAmrPath"].stringValue
            localWavPath = dataJson["localWavPath"].stringValue
            content = "[语音]"
        case .video:
            mediaUrl = dataJson["mediaUrl"].stringValue
            duration = dataJson["time"].doubleValue
            width = dataJson["width"].intValue
            height = dataJson["height"].intValue
            localVideoPath = dataJson["localVideoPath"].stringValue
            content = "[视频]"
        case .file:
            fileUrl = dataJson["fileUrl"].stringValue
            size = dataJson["size"].intValue
            md5 = dataJson["md5"].stringValue
            name = dataJson["name"].stringValue
            localFilePath = dataJson["localFilePath"].stringValue
            content = "[文件]"
        case .redBag:
            packetId = dataJson["packetId"].stringValue
            packetUrl = dataJson["packetUrl"].stringValue
            remark = dataJson["remark"].stringValue
            coin = dataJson["coin"].intValue
            coinName = dataJson["coinName"].stringValue
            isTextPacket = dataJson["packetMode"].intValue == 1
            if let type = IMRedPacketType(rawValue: dataJson["type"].intValue) {
                packetType = type
            }
            if let useStatus = SocketLuckyPacketStatus(rawValue: dataJson["status"].intValue) {
                status = useStatus
            }
            content = "[红包]"
        case .forward:
            if let type = IMMessageForwardType(rawValue: dataJson["forwardType"].intValue) {
                forwardType = type
            }
            if let channelType = SocketChannelType(rawValue: dataJson["channelType"].intValue) {
                forwardChannelType = channelType
            }
            forwardUserName = dataJson["forwardUserName"].stringValue
            forwardFromName = dataJson["fromName"].stringValue
            forwardFromId = dataJson["fromId"].stringValue
            if let data = dataJson["data"].array {
                forwardMsgs = data.compactMap { (json) -> SocketMessage? in
                    return SocketMessage.init(with: json)
                }.sorted(by: <)
            }
            content = "[聊天记录]"
        case .transfer:
            coinName = dataJson["coinName"].stringValue
            amount = dataJson["amount"].doubleValue
            recordId = dataJson["recordId"].stringValue
            content = "[转账]"
        case .receipt:
            coinName = dataJson["coinName"].stringValue
            amount = dataJson["amount"].doubleValue
            recordId = dataJson["recordId"].stringValue
            content = "[收款]"
        case .inviteGroup:
            roomId = dataJson["roomId"].stringValue
            markId = dataJson["markId"].stringValue
            roomName = dataJson["roomName"].stringValue
            inviterId = dataJson["inviterId"].stringValue
            avatar = dataJson["avatar"].stringValue
            identificationInfo = dataJson["identificationInfo"].stringValue
        default:
            IMLog("暂不支持")
        }
        
        if let value = dataJson["forwardType"].int, let type = IMMessageForwardType(rawValue: value) {
            forwardType = type
            if let channelType = SocketChannelType(rawValue: dataJson["channelType"].intValue) {
                forwardChannelType = channelType
            }
            forwardUserName = dataJson["forwardUserName"].stringValue
            forwardFromName = dataJson["fromName"].stringValue
            forwardFromId = dataJson["fromId"].stringValue
        }
    }
    
    func update(by oldBody: SocketMessageBody) {
        switch bodyType {
        case .image:
            localImagePath = oldBody.localImagePath
        case .audio:
            localAmrPath = oldBody.localAmrPath
            localWavPath = oldBody.localWavPath
        default:
            break
        }
    }
    
    func copyBody() -> SocketMessageBody {
        let newBody = SocketMessageBody.init()
        newBody.ciphertext = self.ciphertext
        newBody.bodyType = self.bodyType
        newBody.content = self.content
        newBody.mediaUrl = self.mediaUrl
        newBody.imageUrl = self.imageUrl
        newBody.width = self.width
        newBody.height = self.height
        newBody.duration = self.duration
        newBody.imgData = self.imgData
        newBody.localImagePath = self.localImagePath
        newBody.localWavPath = self.localWavPath
        newBody.localAmrPath = self.localAmrPath
        newBody.firstFrameImgData = self.firstFrameImgData
        newBody.localVideoPath = self.localVideoPath
        newBody.asset = self.asset
        newBody.fileUrl = self.fileUrl
        newBody.size = self.size
        newBody.md5 = self.md5
        newBody.name = self.name
        newBody.localFilePath = self.localFilePath
        newBody.isRead = self.isRead
        newBody.packetId = self.packetId
        newBody.remark = self.remark
        newBody.packetType = self.packetType
        newBody.isTextPacket = self.isTextPacket
        newBody.packetUrl = self.packetUrl
        newBody.coin = self.coin
        newBody.coinName = self.coinName
        newBody.status = self.status
        newBody.notifyEvent = self.notifyEvent
        newBody.forwardType = self.forwardType
        newBody.forwardUserName = self.forwardUserName
        newBody.forwardFromName = self.forwardFromName
        newBody.forwardFromId = self.forwardFromId
        newBody.forwardChannelType = self.forwardChannelType
        newBody.forwardMsgs = self.forwardMsgs
        newBody.amount = self.amount
        newBody.recordId = self.recordId
        newBody.roomId = self.roomId
        newBody.markId = self.markId
        newBody.roomName = self.identificationInfo
        newBody.inviterId = self.identificationInfo
        newBody.avatar = self.avatar
        newBody.identificationInfo = self.identificationInfo
        return newBody
    }
}

enum IMMessageForwardType : Int {
    case none = 0 //不是转发消息
    case detail = 1 //逐条转发
    case merge = 2 //合并转发
}
