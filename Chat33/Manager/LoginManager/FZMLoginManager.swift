//
//  FZMLoginManager.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/11/14.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import SwiftyJSON
import IMSDK

class FZMLoginManager: NSObject {
    
    private static let sharedInstance = FZMLoginManager()
    
    class func shared() -> FZMLoginManager {
        return sharedInstance
    }
    
    override init() {
        super.init()
    }
    
    
    func showLoginPage() {
        if !IMSDK.shared().isLogin() {
            
            let vc = PWLoginViewController.init()
            vc.modalPresentationStyle = .fullScreen
            vc.loginSuccess = {[weak vc] json in
                if let token = JSON.init(json)["token"].string {
                    UIApplication.shared.keyWindow?.showProgress()
                    IMSDK.shared().login(token: token, type: 1, clientId: FZMPushManager.shared().cid, completeBlock: { (response) in
                        UIApplication.shared.keyWindow?.hideProgress()
                        if response.success {
                            vc?.dismiss(animated: true, completion: nil)
                        }else {
                            if response.code == -2030 {
                                let alert = FZMAlertView(onlyAlert: response.message) {
                                }
                                alert.show()
                            } else {
                                UIApplication.shared.keyWindow?.showToast(with: response.message)
                            }
                        }
                    })
                }
            }
            UIApplication.shared.delegate?.window??.rootViewController?.present(vc, animated: true, completion: nil)
        }
    }
    
}


