//
//  FZMPromoteHotGroup.swift
//  IMSDK
//
//  Created by .. on 2019/7/4.
//

import UIKit
import SwiftyJSON

class FZMPromoteHotGroup: NSObject {
    let id: String
    let name: String
    let avatar: String
    
    var isSelected = true
    
    init(json: JSON) {
        id = json["id"].stringValue
        name = json["name"].stringValue
        avatar = json["avatar"].stringValue
        super.init()
    }
}
