//
//  FZMPromoteDetailVM.swift
//  IMSDK
//
//  Created by .. on 2019/7/2.
//

import UIKit

class FZMPromoteDetailVM: NSObject {
    let isTotalPromote: Bool
    let isRegister: Bool
    let isCertification: Bool
    let uidInfo: String
    let promoteInfo: String
    let timeInfo: String
    
    init(data: FZMPromoteDetail) {
        self.isTotalPromote = false
        self.isRegister = true
        self.isCertification = data.isReal == 1
        self.uidInfo = "UID " + data.uid
        self.promoteInfo = "+" + "\((Double.init(data.amount) ?? 0))" + " " + data.currency
        self.timeInfo = ""
        super.init()
    }
    
    init(accumulateData: FZMPromoteAccumulateDetail) {
        self.isTotalPromote = true
        self.isRegister = false
        self.isCertification = false
        if accumulateData.type == "standard_reward" {
            self.uidInfo = "邀请" + "\((Int.init(accumulateData.num) ?? 0))" + "人"
        } else {
            self.uidInfo = "实名"
        }
        self.promoteInfo = "+" + "\((Double.init(accumulateData.amount) ?? 0))" + " " + accumulateData.currency
        self.timeInfo = accumulateData.updatedAt
        super.init()
    }
}
