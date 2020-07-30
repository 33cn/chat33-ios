//
//  FZMShareManager.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/11/12.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import IMSDK

//分享平台
enum FZMSharePlatment {
    case wxFriend //微信好友
    case wxTimeline //朋友圈
}

//分享类型
enum FZMShareType {
    case picture(image: UIImage)
    case text(text:String)
    case web(url: String, image: UIImage, title: String, content: String)
}

let wx_appKey = "wxee2742e706bdceed"

class FZMShareManager: NSObject {

    private static let sharedInstance = FZMShareManager()
    
    @discardableResult class func shared() -> FZMShareManager {
        return sharedInstance
    }
    
    class func launch() {
        FZMShareManager.shared()
    }
    
    override init() {
        super.init()
        WXApi.registerApp(wx_appKey)
        IMSDK.shared().shareDelegate = self
    }
    private var shareCallBack : ((String,Bool)->())?
    
    func share(platment: FZMSharePlatment, content: FZMShareType, callBackBlock: ((String,Bool)->())? = nil) {
        shareCallBack = nil
        shareCallBack = callBackBlock
        let req = SendMessageToWXReq()
        switch platment {
        case .wxFriend:
            req.scene = 0
        case .wxTimeline:
            req.scene = 1
        }
        let message = WXMediaMessage()
        req.message = message
        switch content {
        case .picture(let image):
            message.thumbData = image.compressImage(maxLength: 32 * 1024)
            let object = WXImageObject()
            object.imageData = image.compressImage(maxLength: 10 * 1024 * 1024)
            message.mediaObject = object
        case .web(let url, let image, let title, let content):
            message.thumbData = image.compressImage(maxLength: 32 * 1024)
            message.title = title
            message.description = content
            let object = WXWebpageObject()
            object.webpageUrl = url
            message.mediaObject = object
        case .text(let str):
            req.bText = true
            req.text = str
        }
        WXApi.send(req)
    }
}

extension FZMShareManager : WXApiDelegate {
    func onReq(_ req: BaseReq!) {
        
    }
    func onResp(_ resp: BaseResp!) {
        if resp.errCode == 0 {
            shareCallBack?("分享成功",true)
        }else if resp.errCode == -2 {
            shareCallBack?("分享取消",false)
        }
    }
}

extension FZMShareManager : IMSDKShareInfoDelegate {
    
    func shareQRCode(url: String, image: UIImage, platment: IMSharePlatment) {
        var usePlament : FZMSharePlatment = .wxFriend
        switch platment {
        case .wxTimeline:
            usePlament = .wxTimeline
        default:
            usePlament = .wxFriend
        }
        FZMShareManager.shared().share(platment: usePlament, content: .web(url: url, image: #imageLiteral(resourceName: "qrcode_center"), title: "好友邀请您加入区块链聊天——Chat33", content: "Chat33是一款基于区块链技术的聊天应用，可发送比特元BTY等数字资产!")) { (message, success) in
            UIApplication.shared.keyWindow?.showToast(with: message)
        }
    }
    
    func shareRedBag(url: String, coinName:String,platment: IMSharePlatment) {
        var usePlament : FZMSharePlatment = .wxFriend
        switch platment {
        case .wxTimeline:
            usePlament = .wxTimeline
        default:
            usePlament = .wxFriend
        }
        FZMShareManager.shared().share(platment: usePlament, content: .web(url: url, image: #imageLiteral(resourceName: "qrcode_center"), title: "好友邀请一起抢\(coinName)红包——Chat33", content: "Chat33是一款基于区块链技术的聊天应用，可发送比特元BTY等数字资产!")) { (message, success) in
            UIApplication.shared.keyWindow?.showToast(with: message)
        }
    }
    
    func shareWeb(url: String,title: String,content: String,platment: IMSharePlatment) {
        var usePlament : FZMSharePlatment = .wxFriend
        switch platment {
        case .wxTimeline:
            usePlament = .wxTimeline
        default:
            usePlament = .wxFriend
        }
        FZMShareManager.shared().share(platment: usePlament, content: .web(url: url, image: #imageLiteral(resourceName: "qrcode_center"), title: title, content: content)) { (message, success) in
            UIApplication.shared.keyWindow?.showToast(with: message)
        }
    }
    
    func share(image:UIImage, platment: IMSharePlatment) {
        var usePlament : FZMSharePlatment = .wxFriend
        switch platment {
        case .wxTimeline:
            usePlament = .wxTimeline
        default:
            usePlament = .wxFriend
        }
        FZMShareManager.shared().share(platment: usePlament, content: .picture(image: image)) { (message, sucess) in
            UIApplication.shared.keyWindow?.showToast(with: message)
        }
    }
    
    func share(text:String, platment: IMSharePlatment)  {
        var usePlament : FZMSharePlatment = .wxFriend
        switch platment {
        case .wxTimeline:
            usePlament = .wxTimeline
        default:
            usePlament = .wxFriend
        }
        FZMShareManager.shared().share(platment: usePlament, content: .text(text: text)) { (message, sucess) in
            UIApplication.shared.keyWindow?.showToast(with: message)
        }
    }
    
}

extension UIImage {
   fileprivate func compressImage(maxLength: Int) -> Data {
        let tempMaxLength: Int = maxLength / 8
        var compression: CGFloat = 1
        guard var data = self.jpegData(compressionQuality: compression), data.count > tempMaxLength else { return self.jpegData(compressionQuality: compression)! }
        
        var max: CGFloat = 1
        var min: CGFloat = 0
        for _ in 0..<6 {
            compression = (max + min) / 2
            data = self.jpegData(compressionQuality: compression)!
            if CGFloat(data.count) < CGFloat(tempMaxLength) * 0.9 {
                min = compression
            } else if data.count > tempMaxLength {
                max = compression
            } else {
                break
            }
        }
        var resultImage: UIImage = UIImage(data: data)!
        if data.count < tempMaxLength { return data }
        
        var lastDataLength: Int = 0
        while data.count > tempMaxLength && data.count != lastDataLength {
            lastDataLength = data.count
            let ratio: CGFloat = CGFloat(tempMaxLength) / CGFloat(data.count)
            #if DEBUG
            print("Ratio =", ratio)
            #endif
            let size: CGSize = CGSize(width: Int(resultImage.size.width * sqrt(ratio)),
                                      height: Int(resultImage.size.height * sqrt(ratio)))
            UIGraphicsBeginImageContext(size)
            resultImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            resultImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            data = resultImage.jpegData(compressionQuality: compression)!
        }
        return data
    }
}
