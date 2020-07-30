//
//  IMUserConfigureModel.swift
//  IMSDK
//
//  Created by 吴文拼 on 2019/1/11.
//

import UIKit
import SwiftyJSON

class IMUserConfigureModel: NSObject {

    var needAnswer = false //是否需要回答问题
    var needConfirm = false //是否需要验证
    var question = "" //问题
    var answer = "" //答案
    var needConfirmInvite = false
    
    init(with json: JSON) {
        super.init()
        needAnswer = json["needAnswer"].intValue == 1
        needConfirm = json["needConfirm"].intValue == 1
        question = json["question"].stringValue
        answer = json["answer"].stringValue
        needConfirmInvite = json["needConfirmInvite"].intValue == 1
    }
    
}
