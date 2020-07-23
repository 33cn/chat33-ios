//
//  IMSDK.swift
//  Alamofire
//
//  Created by 吴文拼 on 2018/12/27.
//

import UIKit

class IMSDK: NSObject {

    private static let sharedInstance = IMSDK()
    
    class func shared() -> IMSDK {
        return sharedInstance
    }
    
    //注册appid
    func registerAppId(_ appId: String) {
        app_id = appId
    }
    
}
