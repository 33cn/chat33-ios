//
//  IMSearchInfoModel.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/22.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import SwiftyJSON

enum IMSearchModelType {
    case person
    case group
}

class IMSearchInfoModel: NSObject {

    var uid = ""
    var name = ""
    var avatar = ""
    var nickName = ""
    var memberNumber = 0
    var showId = ""
    var canAdd = false
    var type : IMSearchModelType = .person
    var needConfirm = false
    var isEncrypt = false
    var identification = false
    var identificationInfo = ""
    
    init(with json: JSON, type: IMSearchModelType) {
        super.init()
        self.type = type
        uid = json["id"].stringValue
        name = json["name"].stringValue
        avatar = json["avatar"].stringValue
        showId = json["markId"].stringValue
        memberNumber = json["memberNumber"].intValue
        canAdd = json["canAddFriend"].boolValue
        needConfirm = json["joinPermission"].intValue == 1
        isEncrypt = json["encrypt"].intValue == 1
        identification = json["identification"].intValue == 1
        identificationInfo = json["identificationInfo"].stringValue
    }
    
}
