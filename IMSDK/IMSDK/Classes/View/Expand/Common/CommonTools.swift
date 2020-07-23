//
//  CommonTools.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/19.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import Foundation
import UIKit
import DeviceKit
import Photos
import Result
import Moya

let ScreenWidth = UIScreen.main.bounds.width
let ScreenHeight = UIScreen.main.bounds.height
let ScreenBounds = UIScreen.main.bounds
let StatusBarSize = UIApplication.shared.statusBarFrame.size
let StatusBarWidth = max(StatusBarSize.width, StatusBarSize.height)
let StatusBarHeight = min(StatusBarSize.width, StatusBarSize.height)
let currentDevice = Device.current
let DeviceIsFaceID = currentDevice.isFaceIDCapable
let NavigationBarHeight : CGFloat = 44.0
let StatusNavigationBarHeight = StatusBarHeight + NavigationBarHeight
let TabbarHeight : CGFloat = DeviceIsFaceID ? 83.0 : 49.0
let BottomOffset = DeviceIsFaceID ? 34 : 0

//时间
let OnedaySeconds : Double = 60.0 * 60.0 * 24
let forverBannedTime : Double = 7258089600

let DocumentPath = NSHomeDirectory() + "/Documents/"
let TempPath = NSHomeDirectory() + "/tmp"


//MARK: ---- NotificationCenter ----
let FZM_NotificationCenter = NotificationCenter.default
let FZM_Notify_UserLogin = NSNotification.Name(rawValue: "IM_Notify_UserLogin")
let FZM_Notify_File_UploadFile = NSNotification.Name(rawValue: "FZM_Notify_File_UploadFile")
let FZM_Notify_BannedGroup = NSNotification.Name(rawValue: "FZM_Notify_BannedGroup")

//MARK: ---- UserDefaults ----
let FZM_UserDefaults = UserDefaults.standard
let CHAT33_USER_SHOW_WALLET_KEY = "CHAT33_USER_SHOW_WALLET_KEY"




//MARK: ---- Block ---
typealias NormalBlock = ()->()
typealias StringBlock = (String)->()
typealias BoolBlock = (Bool)->()
typealias IntBlock = (Int)->()
typealias FloatBlock = (Float)->()
typealias DoubleBlock = (Double)->()
typealias ImageBlock = (UIImage)->()
typealias OptionImageBlock = (UIImage?)->()
typealias ImageListBlock = ([UIImage])->()
typealias ImageAndVideoListBlock = ([UIImage],[PHAsset]?)->()
typealias StringBoolBlock = (String,Bool)->()
typealias IcloudFileBlock = ([URL])->()

typealias ResponseHandler = (Result<Moya.Response, MoyaError>,HttpResponse)->()

public typealias NormalHandler = (HttpResponse)->()

typealias IntHandler = (Int?,HttpResponse)->()

typealias StringHandler = (String?,HttpResponse)->()

typealias StringsHandler = (String?,String?,HttpResponse)->()

typealias BoolHandler = (Bool?,HttpResponse)->()

typealias UserHandler = (UserInfoModel?,HttpResponse)->()

typealias ChatRoomHandler = ([IMChatRoomModel],HttpResponse)->()

typealias CreateGroupHandler = (IMGroupModel?,HttpResponse)->()

typealias MessageListHandler = ([SocketMessage],String,HttpResponse)->()

typealias UserDetailInfoHandler = (IMUserModel?,HttpResponse)->()

typealias FriendArrHandler = ([IMUserModel],HttpResponse)->()

typealias SearchInfoHandler = ([IMSearchInfoModel],HttpResponse)->()

typealias ContactApplyHandler = ([IMContactApplyModel],HttpResponse)->()

typealias GroupHandler = ([IMGroupModel],HttpResponse)->()

typealias GroupDetailInfoHandler = (IMGroupDetailInfoModel?,HttpResponse)->()

typealias GroupMemberListHandler = ([IMGroupUserInfoModel],HttpResponse)->()

typealias GroupMemberInfoHandler = (IMGroupUserInfoModel?,HttpResponse)->()

typealias GroupNotifyListHandler = ([IMGroupNotifyModel],String,HttpResponse)->()

typealias MessageListFetchHandler = ([SocketMessage])->()

typealias ConversationUnreadHandler = ([IMConversationUnreadModel],HttpResponse)->()



typealias MyConfigureHandler = (IMUserConfigureModel?,HttpResponse)->()
typealias GroupKeysHandler = ([FZMGroupKey]?,HttpResponse)->()
typealias WorkUserHandler = (FZMWorkUser?,HttpResponse)->()
typealias WorkRecordHandler = ([FZMWorkRecord]?,HttpResponse)->()

//红包
typealias RedPacketHandler = (IMRedPacketModel?,HttpResponse)->()
typealias RedPacketRecordHandler = (IMRedPacketRecordListModel?,HttpResponse)->()
typealias RedPacketMarkHandler = (String?,Double?,HttpResponse)->()
typealias RedPacketReceiveHandler = ([IMRedPacketReceiveModel]?,HttpResponse) -> ()


// MARK: - Top level function
/**
 格式化LOG
 
 - parameter items:  输出内容
 - parameter file:   所在文件
 - parameter method: 所在方法
 - parameter line:   所在行
 */
func IMLog(_ items: Any... ,
    file: String = #file,
    method: String = #function,
    line: Int = #line) {
    #if DEBUG
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd hh:mm:ss.SSS"
    var itemStr = ""
    for item in items {
        if let str = item as? String {
            itemStr += str
        } else {
            itemStr += "\(item)"
        }
    }
    var string = "-------------------------- IMLog --------------------------\n"
    string += "[" + formatter.string(from: Date()) + "]"
    string += " <" + (file as NSString).lastPathComponent + ":" + method + "  inLine:\(line)>\n"
    string += itemStr
    print(string)
    #endif
}


// MARK: - Top level function
/**
 格式化LOG
 
 - parameter items:  输出内容
 - parameter file:   所在文件
 - parameter method: 所在方法
 - parameter line:   所在行
 */
func FZMLog(_ items: Any... ,
    file: String = #file,
    method: String = #function,
    line: Int = #line) {
//    #if DEBUG
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd hh:mm:ss.SSS"
    var itemStr = ""
    for item in items {
        if let str = item as? String {
            itemStr += str
        } else {
            itemStr += "\(item)"
        }
    }
    var string = "-------------------------- IMLog --------------------------\n"
    string += "[" + formatter.string(from: Date()) + "]"
    string += " <" + (file as NSString).lastPathComponent + ":" + method + "  inLine:\(line)>\n"
    string += itemStr
    print(string)
//    #endif
}


func CGRectMakeWithCenterAndSize(center: CGPoint, size: CGSize) -> CGRect {
    return CGRect(x: center.x-size.width/2, y: center.y-size.height/2, width: size.width, height: size.height)
}

func IMSDKPath(forResource name: String, ofType type: String) -> String? {
    let bundle = Bundle.init(for: IMSDK.classForCoder())
    if let bundleName = bundle.infoDictionary?["CFBundleExecutable"] as? String {
        let directory = bundle.path(forResource: name + type , ofType: nil, inDirectory: bundleName + ".bundle")
        return directory
    }
    return nil
}


func GetBundleImage(_ name: String) -> UIImage? {
    let currentBundle = Bundle.init(for: IMSDK.classForCoder())
    guard let bundleName = currentBundle.infoDictionary?["CFBundleExecutable"] else {
        return nil
    }
    var scale = Int(UIScreen.main.scale)
    if scale == 1 {
        scale = 2
    }
    let imgName = name + "@\(scale)x.png"
    if let path = currentBundle.path(forResource: imgName, ofType: nil, inDirectory: "\(bundleName).bundle") {
        return UIImage.init(contentsOfFile: path)
    } else if let path = currentBundle.path(forResource: name + ".jpg", ofType: nil, inDirectory: "\(bundleName).bundle") {
         return UIImage.init(contentsOfFile: path)
    } else if let path = currentBundle.path(forResource: name + ".png", ofType: nil, inDirectory: "\(bundleName).bundle") {
        return UIImage.init(contentsOfFile: path)
    }
    return nil
}

