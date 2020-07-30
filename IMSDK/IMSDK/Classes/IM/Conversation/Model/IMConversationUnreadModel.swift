//
//  IMConversationUnreadModel.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/11/5.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import SwiftyJSON

class IMConversationUnreadModel: NSObject {

    var targetId = ""
    var unreadNum = 0
    var lastMsg : SocketMessage?
    
    init(with serverJson: JSON) {
        super.init()
        targetId = serverJson["id"].stringValue
        unreadNum = serverJson["number"].intValue
        if let _ = serverJson["lastLog"].dictionary {
            lastMsg = SocketMessage(with: serverJson["lastLog"])
        }
    }
    
}
