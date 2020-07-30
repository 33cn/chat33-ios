//
//  IMChatRoomModel.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/11.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import SwiftyJSON

class IMChatRoomModel: NSObject {

    var chatRoomId = ""
    var chatRoomName = ""
    var avatar = ""
    var chatRoomDescription = ""
    
    init(with json: JSON) {
        super.init()
        chatRoomId = json["groupId"].stringValue
        chatRoomName = json["groupName"].stringValue
        avatar = json["avatar"].stringValue
        chatRoomDescription = json["description"].stringValue
    }
}
