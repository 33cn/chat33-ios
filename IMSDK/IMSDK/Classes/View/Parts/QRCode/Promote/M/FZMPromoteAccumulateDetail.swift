//
//  FZMPromoteAccumulateDetail.swift
//  IMSDK
//
//  Created by .. on 2019/7/10.
//

import UIKit
import SwiftyJSON

class FZMPromoteAccumulateDetail: NSObject {
    let type: String
    let num: String
    let updatedAt: String
    let currency: String
    let amount: String
    
    init(json: JSON) {
        self.type = json["type"].stringValue
        self.num = json["num"].stringValue
        self.currency = json["currency"].stringValue
        self.amount = json["amount"].stringValue
        self.updatedAt = json["updated_at"].stringValue
        super.init()
    }

}
