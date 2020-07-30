//
//  FZMPromoteHeader.swift
//  IMSDK
//
//  Created by .. on 2019/7/9.
//

import UIKit
import SwiftyJSON

class FZMPromoteHeader: NSObject {
    let inviteNum: String
    let primary: FZMPromoteCoin
    let statistics: [FZMPromoteCoin]
    init(json:JSON) {
        self.inviteNum = json["invite_num"].stringValue
        self.primary = FZMPromoteCoin.init(dic: json["primary"].dictionaryValue)
        self.statistics = json["statistics"].arrayValue.compactMap({ (json) -> FZMPromoteCoin? in
            return FZMPromoteCoin.init(dic: json.dictionaryValue)
        })
        super.init()
    }
}

class FZMPromoteCoin: NSObject {
    let currency: String
    let total: String
    init(dic: [String: JSON]) {
        self.currency = dic["currency"]?.stringValue ?? ""
        self.total = dic["total"]?.stringValue ?? ""
        super.init()
    }
}
