//
//  FZMPromoteDetail.swift
//  IMSDK
//
//  Created by .. on 2019/7/2.
//

import UIKit
import SwiftyJSON

class FZMPromoteDetail: NSObject {
    let uid: String
    let isReal: Int
    let currency: String
    let amount: String
    
    init(json: JSON) {
        self.uid = json["uid"].stringValue
        self.isReal = json["is_real"].intValue
        self.currency = json["currency"].stringValue
        self.amount = json["amount"].stringValue
        super.init()
    }
}
