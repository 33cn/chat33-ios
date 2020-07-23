//
//  FZMContactApplyVM.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/25.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit

class FZMContactApplyVM: NSObject {

    var name = ""
    var avatar = ""
    var type : IMContactApplyType = .friend
    var typeStr = ""
    var status : IMContactApplyStatus = .waiting
    var statusStr = ""
    var isSender = false
    var source = ""
    var reason = ""
    var contentHeight : CGFloat = 0
    
    init(with data: IMContactApplyModel) {
        super.init()
        type = data.type
        status = data.status
        source = data.source
        reason = data.reason
        if data.senderInfo.userId == IMLoginUser.shared().userId {
            isSender = true
            name = data.receiveInfo.name
            avatar = data.receiveInfo.avatar
            if type == .friend {
                typeStr = "已发送好友申请"
            }else {
                typeStr = "已发送入群申请"
            }
        }else {
            name = data.senderInfo.name
            avatar = data.senderInfo.avatar
            if type == .friend {
                typeStr = "请求添加您为好友"
            }else {
                typeStr = "申请入群"
            }
        }
        if status == .waiting {
            statusStr = "等待验证"
        }else if status == .reject {
            statusStr = "已拒绝"
        }else {
            statusStr = "已添加"
        }
        var height : CGFloat = 85
        let desHeight = source.getContentHeight(width: ScreenWidth - 175, font: UIFont.regularFont(14))
        if desHeight > 20 {
            height += 20
        }
        let reasonHeight = reason.getContentHeight(width: ScreenWidth - 90, font: UIFont.regularFont(14))
        if reasonHeight > 0 {
            height += 20
            height += (reasonHeight > 60 ? 60 : reasonHeight)
        }
        contentHeight = height
    }
}
