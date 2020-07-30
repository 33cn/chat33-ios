//
//  FZMEncryptManager.swift
//  隐私
//
//  Created by .. on 2019/5/21.
//  Copyright © 2019 ... All rights reserved.
//

import Foundation
import SwiftyJSON
import Chatapi

class FZMEncryptManager: NSObject {
    
    
    class func encryptSymmetric(privateKey: String, publicKey: String, plaintext: Data) -> Data? {
        if let symmetricKey = FZMEncryptManager.generateDHSessionKey(privateKey: privateKey, publicKey: publicKey), let ciphertext = FZMEncryptManager.encryptSymmetric(key: symmetricKey, plaintext: plaintext) {
            return ciphertext
        }
        return nil
    }
    
    class func decryptSymmetric(privateKey: String, publicKey: String, ciphertext: Data) -> Data? {
        if let symmetricKey = FZMEncryptManager.generateDHSessionKey(privateKey: privateKey, publicKey: publicKey), let plaintext = FZMEncryptManager.decryptSymmetric(key: symmetricKey, ciphertext: ciphertext) {
            return plaintext
        }
        return nil
    }
    
    private class func generateDHSessionKey(privateKey: String, publicKey: String) -> String? {
        var error: NSError?
        if let keyData = ChatapiGenerateDHSessionKey(privateKey, publicKey, &error),
            error == nil, let symmetricKey = ChatapiByteTohex(keyData)  {
            return symmetricKey
        }
        return nil
    }
    
    class func encryptSymmetric(key: String, plaintext: Data) -> Data? {
        var error: NSError?
        if let ciphertext = ChatapiEncryptSymmetric(key, plaintext, &error),
            error == nil {
            return ciphertext
        }
        return nil
    }
    
    class func decryptSymmetric(key: String, ciphertext: Data) -> Data? {
        var error: NSError?
        if let plaintext = ChatapiDecryptSymmetric(key, ciphertext, &error),
            error == nil {
            return plaintext
        }
        return nil
    }
    
    class func publicKeyToAddress(publicKey: String) -> String {
        return ChatapiPublicKeyToAddress(Data.init(hex: publicKey))
    }
    
    class func sign(data: Data, privateKey: String) -> String? {
        guard let result = ChatapiChatSign(data, Data.init(hex: privateKey)), let resultStr = ChatapiByteTohex(result) else {
            return nil
        }
        return resultStr
    }
    
}
