//
//  IMLoginUserManager.swift
//  IMSDK
//
//  Created by .. on 2019/3/14.
//

import UIKit

@objc public class IMLoginUserManager: NSObject {
    private static let sharedInstance = IMLoginUserManager.init()
    @objc public class func shared() -> IMLoginUserManager {
        return sharedInstance
    }
    
    @objc public func isSetPayPwd(completionBlock: (([Any])->())?) {
        if IMLoginUser.shared().currentUser?.isSetPayPwd ?? false {
            let response = HttpResponse.init()
            response.success = true
            completionBlock?([true,response])
        } else {
            HttpConnect.shared().isSetPayPwd { (isSetPayPwd, response) in
                let isSetPwd = isSetPayPwd ?? false
                IMLoginUser.shared().currentUser?.isSetPayPwd = isSetPwd
                IMLoginUser.shared().refreshUserInfo()
                completionBlock?([isSetPwd,response])
            }
        }
    }
    
    @objc public func setPayPwd(mode: String, type: String, code: String, oldPayPassword: String, payPassword: String, completionBlock: NormalHandler?) {
        HttpConnect.shared().setPayPwd(mode: mode, type: type, code: code, oldPayPassword: oldPayPassword, payPassword: payPassword) { (response) in
            if response.success {
                IMLoginUser.shared().currentUser?.isSetPayPwd = true
                IMLoginUser.shared().refreshUserInfo()
            }
            completionBlock?(response)
        }
    }
    
}
