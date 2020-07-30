//
//  FZMGoupKey.swift
//  IMSDK
//
//  Created by .. on 2019/6/5.
//

import UIKit

class FZMGroupKey: NSObject {
    let groupId: String
    let fromKey: String
    let key: String
    let keyId: String
    var plainTextKey: String?
    
    init(groupId: String,fromKey: String,key: String,keyId: String) {
        self.groupId = groupId
        self.fromKey = fromKey
        self.key = key
        self.keyId = keyId
        super.init()
        if let privateKey = IMLoginUser.shared().currentUser?.privateKey,
            let plainTextKey = FZMEncryptManager.decryptSymmetric(privateKey: privateKey, publicKey: fromKey, ciphertext: Data.init(hex: key)) {
            self.plainTextKey = String.init(data: plainTextKey, encoding: .utf8)
        }
    }
    
}
