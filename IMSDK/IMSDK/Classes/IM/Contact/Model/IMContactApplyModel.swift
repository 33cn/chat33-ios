//
//  IMContactApplyModel.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/18.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import SwiftyJSON

enum IMContactApplyType: Int {
    case group = 1
    case friend = 2
}

//申请状态
enum IMContactApplyStatus: Int {
    case waiting = 1//等待
    case reject = 2//拒绝
    case agree = 3//同意
}

class IMContactApplyModel: NSObject {

    var applyId = 0
    var reason = ""
    var type : IMContactApplyType = .friend
    var status : IMContactApplyStatus = .waiting
    var dateTime = Date()
    var dateTimeOnlyYM = ""
    var senderInfo = IMContactApplierInfoModel(with: nil)
    var receiveInfo = IMContactApplierInfoModel(with: nil)
    var isSender : Bool {
        return senderInfo.userId == IMLoginUser.shared().userId
    }
    var source = ""
    
    init(with serverJson: JSON) {
        super.init()
        applyId = serverJson["id"].intValue
        reason = serverJson["applyReason"].stringValue
        if let applyType = IMContactApplyType(rawValue: serverJson["type"].intValue) {
            type = applyType
        }
        if let applyStatus = IMContactApplyStatus(rawValue: serverJson["status"].intValue) {
            status = applyStatus
        }
        dateTime = Date.timeStampToString(timeStamp: serverJson["datetime"].doubleValue)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY/MM"
        dateTimeOnlyYM = dateFormatter.string(from: dateTime)
        senderInfo = IMContactApplierInfoModel(with: serverJson["senderInfo"])
        receiveInfo = IMContactApplierInfoModel(with: serverJson["receiveInfo"])
        source = serverJson["source"].stringValue
    }
}

class IMContactApplierInfoModel: NSObject {
    var userId = ""
    var name = ""
    var avatar = ""
    var position = ""
    var markId = ""
    
    init(with serverJson: JSON?) {
        super.init()
        if let serverJson = serverJson {
            userId = serverJson["id"].stringValue
            name = serverJson["name"].stringValue
            avatar = serverJson["avatar"].stringValue
            position = serverJson["position"].stringValue
            markId = serverJson["markId"].stringValue
        }
    }
}

