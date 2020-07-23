//
//  FZMUIMediator.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/20.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift
import MobileCoreServices
import Photos
import TZImagePickerController
import CryptoSwift
import RTRootNavigationController


enum ForwardSendType {
    case image(image:UIImage)
    case video(videoPath:String)
    case file(filePath:String)
}

enum FZMPushVCType {
    case photoLibrary(selectOne: Bool,maxSelectCount:Int, allowEditing: Bool, showVideo:Bool,selectBlock: ImageAndVideoListBlock?)//相册
    case camera(allowEditing: Bool, selectBlock: ImageAndVideoListBlock?)//相机
    case qrCodeShow(type:FZMQRCodeVCShowType)//二维码展示
    case friendInfo(friendId: String, groupId: String?, source: FZMApplyEntrance?)//好友详情页
    case goChat(chatId: String, type: SocketChannelType,locationMsg: (String, String)? = nil)//去聊天
    case selectFriend(type: FZMSelectFriendGroupShowStyle, completeBlock: NormalBlock?)//选择好友页
    case selectFriendAndGroup(completeBlock: SelectContactBlock?)//选择好友和群聊页面，用于转发
    case search(type: FZMSearchVCShowType)//搜索
    case groupInfo(data: IMSearchInfoModel, type: FZMApplyEntrance)//搜索的群信息
    case groupDetailInfo(groupId: String)//群详情
    case sweepQRCode//扫二维码
    case configureCenter//设置中心
    case inputAddAuthInfo(type: FZMInputAuthInfoVCType, completeBlock: NormalBlock?)//入群或加好友输入验证信息
    case multipleSendMsg(type:ForwardSendType)//发送图片选择聊天窗口
    case multipleSend(msg:SocketMessage)
    case icloudPicker(completeBlock: IcloudFileBlock)
    case goTransfer(specifiedAddress: String?)
    case goReceive
    case goImportSeed(isHideBackBtn: Bool)
    case goCreateSeed
    case goPromoteHotGroup
    case goIdentification(type: Int, roomId: String)
    case goFullTextSearch
    case goSetSeedPwd(isShowForget: Bool)
}

enum FZMImagePickerViewType {
    case photoLibrary
    case camera
}

public class FZMUIMediator: NSObject {

    private static let sharedInstance = FZMUIMediator()
    private let disposeBag = DisposeBag()
    @objc public class func shared() -> FZMUIMediator{
        return sharedInstance
    }
    
    class func launchManager() {
        let _ = FZMUIMediator.shared()
    }
    
    override init() {
        super.init()
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .user)
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .appState)
        
    }
    
    var homeTabbarVC : UITabBarController?
    
    private var conversationNav : FZMNavigationController?
    func getConversationNavigationController() -> FZMNavigationController {
        if let nav = conversationNav {
            return nav
        }
        let vc = FZMChatHomeVC()
        let nav = FZMNavigationController.init(rootViewController: vc)
        conversationNav = nav
        return nav
    }
    
    private var contactNav : FZMNavigationController?
    func getContactNavigationController() -> FZMNavigationController {
        if let nav = contactNav {
            return nav
        }
        let vc = FZMContactHomeVC()
        let nav = FZMNavigationController.init(rootViewController: vc)
        contactNav = nav
        return nav
    }
    private var meNav : FZMNavigationController?
    func getMeNavigationController() -> FZMNavigationController {
        if let nav = meNav {
            return nav
        }
        let vc = FZMMeCenterVC()
        let nav = FZMNavigationController.init(rootViewController: vc)
        meNav = nav
        return nav
    }
    
    //跳转页面
    func pushVC(_ type: FZMPushVCType) {
        guard let tabBar = homeTabbarVC else { return }
        guard let nav = tabBar.selectedViewController as? UINavigationController else { return }
        let selectNav = (nav is FZMNavigationController) ? nav : UIViewController.current()?.navigationController
        var vc : FZMBaseViewController?
        switch type {
        case .photoLibrary(let selectOne,let maxSelectCount ,let allowEditing, let showVideo ,let selectBlock):
            self.openImagePicker(with: .photoLibrary, selectOne: selectOne, maxSelectCount:maxSelectCount ,allowEditing,showVideo: showVideo, selectBlock: selectBlock)
        case .camera(let allowEditing, let selectBlock):
            self.openImagePicker(with: .camera, selectOne: true, allowEditing, selectBlock: selectBlock)
        case .icloudPicker(let icloudFileBlock):
            self.openDocumentPicker(icloudFileBlock: icloudFileBlock)
        case .qrCodeShow(let type):
            vc = FZMQRCodeShowVC(with: type)
        case .friendInfo(let friendId, let groupId, let source):
            self.goFriendInfo(with: friendId, groupId: groupId, source: source)
        case .goChat(let chatId, let type, let locationMsg):
            self.goChatVC(with: chatId, type: type)
        case .selectFriend(let type, let completeBlock):
            self.goSelectFriendVC(with: type, completeBlock: completeBlock)
        case .selectFriendAndGroup(let completeBlock):
            self.goSelectContactVC(completeBlock: completeBlock)
        case .search(let type):
            vc = FZMSearchVC(with: type)
        case .groupDetailInfo(let groupId):
            vc = FZMGroupDetailInfoVC(with: groupId)
        case .groupInfo(let data, let type):
            vc = FZMGroupInfoVC(with: data, type: type)
        case .sweepQRCode:
            vc = FZMSweepQRCodeVC()
        case .configureCenter:
            vc = FZMConfigureCenterVC()
        case .inputAddAuthInfo(let type, let completeBlock):
            vc = FZMInputAuthInfoVC(with: type, completeBlock: completeBlock)
        case .multipleSendMsg(let type):
            self.multipleSendMsg(type)
        case .multipleSend(let msg):
            self.multipleSend(msg: msg)
        case .goTransfer(let specifiedAddress):
            self.goTransfer(specifiedAddress)
        case .goReceive:
            self.goReceive()
        case .goImportSeed(let isHideBackBtn):
            self.goImportSeed(isHideBackBtn)
        case .goCreateSeed:
            self.goCreateSeed()
        case .goPromoteHotGroup:
            self.goPromoteHotGroup()
        case .goIdentification(let type, let roomId):
            self.goIdentification(type: type, roomId: roomId)
        case .goFullTextSearch:
            vc = FZMFullTextSearchVC.init()
        case .goSetSeedPwd(let isShowForget):
            self.goSetSeedPwd(isShowForget:isShowForget)
        }
        if let vc = vc {
            vc.hidesBottomBarWhenPushed = true
            switch type {
            case .sweepQRCode:
                selectNav?.present(vc, animated: true, completion: nil)
            default:
                selectNav!.pushViewController(vc, animated: true)
            }
        }
    }
    
    func select(with index: Int) {
        guard let tabBar = homeTabbarVC else { return }
        tabBar.selectedIndex = index
    }
    
    func selectConversationNav() {
        guard let tabBar = homeTabbarVC, let nav = contactNav, let index = tabBar.viewControllers?.index(of: nav) else { return }
        tabBar.selectedIndex = index
    }
    
    //设置未读数
    func setTabbarBadge(with index: Int, count: Int) {
        if let tabBarVC = homeTabbarVC as? FZMTabBarController {
            tabBarVC.setTabbarBadge(with: index, count: count)
        }
    }
    
    //登录页
    func goLoginView(type: AccountInputType, account: String? = nil) {
        
    }
    
    //好友详情页
    private func goFriendInfo(with friendId: String, groupId: String? = nil, source: FZMApplyEntrance? = nil) {
        if let tabBar = homeTabbarVC,
            let nav = tabBar.selectedViewController as? UINavigationController {
            let newNav = (nav is FZMNavigationController) ? nav : UIViewController.current()?.navigationController
            if friendId != IMLoginUser.shared().userId {
                IMContactManager.shared().requestUserModel(with: friendId) { (user, _, _) in
                    let vc = FZMFriendInfoVC(with: friendId, groupId: groupId, source: source)
                    vc.hidesBottomBarWhenPushed = true
                    newNav?.pushViewController(vc, animated: true)
                }
            }else {
                self.pushVC(.qrCodeShow(type: .me))
            }
        }
    }
    
    //选择好友页
    private func goSelectFriendVC(with type: FZMSelectFriendGroupShowStyle, completeBlock: NormalBlock?=nil) {
        guard let tabBar = homeTabbarVC else { return }
        let vc = FZMSelectFriendToGroupVC(with: type)
        vc.reloadBlock = {
            completeBlock?()
        }
        let nav = FZMNavigationController.init(rootViewController: vc)
        tabBar.selectedViewController?.present(nav, animated: true) {
            
        }
    }
    //选择好友和群聊页
    private func goSelectContactVC(completeBlock: SelectContactBlock?=nil) {
        guard let tabBar = homeTabbarVC else { return }
        let vc = FZMForwardSelectContactVC()
        vc.completeBlock = completeBlock
        let nav = FZMNavigationController.init(rootViewController: vc)
        tabBar.selectedViewController?.present(nav, animated: true) {
            
        }
    }
    
    //发送图片,视频等选择页
    private func multipleSendMsg(_ type: ForwardSendType) {
        let vc = FZMForwardSelectContactVC()
        vc.autoSendMsgType = type
        let nav = FZMNavigationController.init(rootViewController: vc)
        UIViewController.current()?.present(nav, animated: true) {
            
        }
    }
    private func multipleSend(msg: SocketMessage) {
        let vc = FZMForwardSelectContactVC()
        vc.forwordMsg = msg
        let nav = FZMNavigationController.init(rootViewController: vc)
        UIViewController.current()?.present(nav, animated: true) {
            
        }
    }
    //聊天页
    private func goChatVC(with conversationId: String, type: SocketChannelType) {
        let conversation = IMConversationManager.shared().getConversation(with: conversationId, type: type)
        self.goChatVC(with: conversation)
    }
    private func goChatVC(with conversation: SocketConversationModel) {
        guard let tabBar = homeTabbarVC, let nav = conversationNav, let nowNav = tabBar.selectedViewController as? UINavigationController, let index = tabBar.viewControllers?.index(of: nav) else { return }
        tabBar.selectedIndex = index
        let vc = FZMConversationChatVC(with: conversation, locationMsg: nil)
        vc.hidesBottomBarWhenPushed = true
        nav.popToRootViewController(animated: false)
        if nowNav != nav {
            if nowNav is FZMNavigationController {
                nav.pushViewController(vc, animated: true)
                nowNav.popToRootViewController(animated: false)
            } else {
                //其它工程引用chat33，联系人页面先消失再push，不然返回箭头不渲染。
                nowNav.dismiss(animated: true, completion: nil)
                nav.pushViewController(vc, animated: true)
            }
        }else{
            nav.pushViewController(vc, animated: true)
        }
    }
    
    //解析路径，二维码识别后经过这里
    func parsingUrl(with url: String, isSweep: Bool = false) {
        guard let tabBar = homeTabbarVC, let nav = tabBar.selectedViewController as? UINavigationController else { return }
        var str = url
        if str.contains(qrCodeShareUrl) {
            guard let dic = str.urlParameter else { return }
            var searchStr = ""
            if let gid = dic["gid"] as? String {
                searchStr = gid
            }else if let uid = dic["uid"] as? String {
                searchStr = uid
            }
            self.openInfoVC(with: searchStr, shareId: dic["uid"] as? String, isSweep: isSweep)
        }else if str.contains("fzmchat33://") {
            str = str.replacingOccurrences(of: "fzmchat33://", with: "fzmchat33?")
            guard let dic = str.urlParameter else { return }
            var searchStr = ""
            if let gid = dic["fid"] as? String {
                searchStr = gid
            }else if let uid = dic["gid"] as? String {
                searchStr = uid
            }
            self.openInfoVC(with: searchStr, shareId: dic["shareByUid"] as? String, isSweep: isSweep)
        }else if str.contains("http") {
            self.openUrl(with: str)
            nav.popViewController(animated: true)
        }else {
            if str.contains("//") || str.contains(":") || str.contains("-") || str.contains(".") || str.count < 15 {
                return
            }
            if str.substring(to: 2).contains("wx") {
                return
            }
            self.goTransfer(url)
        }
        
    }
    //打开好友信息页或者群信息页
    func openInfoVC(with searchText: String, shareId: String?, isSweep: Bool = false) {
        guard let tabBar = homeTabbarVC, let nav = tabBar.selectedViewController as? UINavigationController else { return }
        if searchText == IMLoginUser.shared().showId {
            self.pushVC(.qrCodeShow(type: .me))
            return
        }
        HttpConnect.shared().searchContact(searchId: searchText) { (list, response) in
            guard response.success, let model = list.first else {
                UIApplication.shared.keyWindow?.showToast(with: "信息不存在")
                return
            }
            var entranceType : FZMApplyEntrance = .normal
            if let shareId = shareId {
                entranceType = .share(userId: shareId)
            }else {
                entranceType = isSweep ? .sweep : .search
            }
            if model.type == .person {
                self.pushVC(.friendInfo(friendId: model.uid, groupId: nil, source: isSweep ? .sweep : entranceType))
            }else {
                self.pushVC(.groupInfo(data: model, type: entranceType))
            }
            nav.viewControllers = nav.viewControllers.filter({ (controller) -> Bool in
                return !type(of: controller).description().contains("FZMSweepQRCodeVC")
            })
        }
    }
    
    //打开网页
    func openUrl(with path: String) {
        var path = path
        if !(path as NSString).contains("http") {
            path = "http://" + path
        }
        guard let goUrl = URL(string: path) else {return}
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(goUrl, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(goUrl)
        }
    }
    
    //打开系统相册或相机
    private var picker = UIImagePickerController()
    private var selectImageBlock : ImageAndVideoListBlock?
    private var allowEdit = false
    private let operationQueue = OperationQueue()
    private func openImagePicker(with type: FZMImagePickerViewType, selectOne: Bool = true,maxSelectCount:Int = 1, _ allowEditing: Bool, showVideo:Bool = false ,selectBlock: ImageAndVideoListBlock?) {
        guard let tabBar = homeTabbarVC, let nav = tabBar.selectedViewController as? UINavigationController else { return }
        operationQueue.maxConcurrentOperationCount = 1
        selectImageBlock = selectBlock
        if type == .camera {
            picker.delegate = self
            picker.mediaTypes = [kUTTypeImage as String]
            if type == .photoLibrary {
                picker.sourceType = .photoLibrary
            }else if type == .camera {
                picker.sourceType = .camera
            }
            picker.allowsEditing = false
            self.allowEdit = allowEditing
            UIApplication.shared.setStatusBarHidden(true, with: .fade)
            nav.present(picker, animated: true) {
            }
        }else {
            let block = {
                let vc = FZMImagePickerController.init(withSelectOne: selectOne, maxSelectCount: maxSelectCount, allowEditing: allowEditing, showVideo: showVideo)
                vc.didFinishPickingPhotosHandle = {[weak self] (photos, assets, isOrigin) in
                    guard let strongSelf = self, let photos = photos, let assets = assets as? [PHAsset] else { return }
                    strongSelf.selectImageBlock?(photos,assets)
                }
                UIViewController.current()?.present(vc, animated: true) {}
            }
            if PHPhotoLibrary.authorizationStatus() == .notDetermined {
                PHPhotoLibrary.requestAuthorization { (status) in
                    if status == .authorized {
                        block()
                    }else {
                        UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
                    }
                }
            }else if PHPhotoLibrary.authorizationStatus() == .authorized {
                block()
            }else {
                let alert = FZMAlertView.init(with: "系统相册权限未打开，请设置") {
                    UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
                }
                alert.show()
            }
        }
    }
    
     private var icloudFileBlock : IcloudFileBlock?
    func openDocumentPicker(icloudFileBlock: @escaping IcloudFileBlock) {
        guard let tabBar = homeTabbarVC, let nav = tabBar.selectedViewController as? UINavigationController else { return }
        self.icloudFileBlock = icloudFileBlock
        let documentTypes = [
            "public.content",
            "public.text",
            "public.source-code ",
            "public.image",
            "public.audiovisual-content",
            "com.adobe.pdf",
            "com.apple.keynote.key",
            "com.microsoft.word.doc",
            "com.microsoft.excel.xls",
            "com.microsoft.powerpoint.ppt"
        ]
        let documentPicker = UIDocumentPickerViewController(documentTypes: documentTypes, in: .open)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        if #available(iOS 11.0, *) {
            documentPicker.allowsMultipleSelection = true
        } else {
        }
        nav.present(documentPicker, animated: true, completion: nil)
    }
    
    //展示单张图
    func showImage(view: UIImageView, url: String) {
        UIViewController.current()?.present(FZMPhotoBrowser.init(url: url, from: view), animated: true, completion: nil)
    }
    
    //检查更新
    func checkVersion(_ showToast: Bool = false) {
        guard IMSDK.shared().canUpdate else { return }
        for view in UIApplication.shared.keyWindow?.subviews ?? [UIView()] {
            if view.isMember(of: FZMImageAlertView.self) {
                return
            }
        }
        HttpConnect.shared().requestVersion { (response) in
            guard response.success, let data = response.data else {
                if showToast {
                    UIApplication.shared.keyWindow?.showToast(with: response.message)
                }
                return
            }
            if data["forceUpdate"].boolValue {
                UIApplication.shared.keyWindow?.endEditing(true)
                let alert = FZMImageAlertView(image: GetBundleImage("update_top"), title: "发现新版本", des1: "V" + data["versionName"].stringValue + "      " + "\(data["size"].intValue / 1024 / 1024 )" + "M", des2: data["description"].stringValue, confirmTitle: "立即更新", confirmBlock: {
                    self.openUrl(with: data["url"].stringValue)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                        exit(0)
                    })
                })
                alert.show()
            } else {
                guard var localVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String  else {
                    return
                }
                localVersion = localVersion.replacingOccurrences(of: ".", with: "")
                if localVersion.count == 2 {
                    localVersion = localVersion + "0"
                }
                if localVersion.count == 1 {
                    localVersion = localVersion + "00"
                }
                var serverVersion = data["versionName"].stringValue.replacingOccurrences(of: ".", with: "")
                if serverVersion.count == 2 {
                    serverVersion = serverVersion + "0"
                }
                if serverVersion.count == 1 {
                    serverVersion = serverVersion + "00"
                }
                
                if (localVersion as NSString).doubleValue < (serverVersion as NSString).doubleValue {
                    let alert = FZMImageAlertView(image: GetBundleImage("update_top"), title: "发现新版本", des1: "V" + data["versionName"].stringValue + "      " + "\(data["size"].intValue / 1024 / 1024 )" + "M", des2: data["description"].stringValue, confirmTitle: "立即更新",dismissOnTouchBg: true, confirmBlock: {
                        self.openUrl(with: data["url"].stringValue)
                    })
                    alert.show()
                }else if showToast {
                    UIApplication.shared.keyWindow?.showToast(with: "已是最新版本")
                }
            }
        }
    }
    
    func goTransfer(_ specifiedAddress: String?) {
        
    }
    
    func goReceive() {
        
    }
    
    func goImportSeed(_ isHideBackBtn: Bool) {
        
    }
    
    func goCreateSeed() {
        
    }
    
    func goPromoteHotGroup(animated: Bool = true) {
        let vc = FZMPromoteHotGroupVC()
        vc.hidesBottomBarWhenPushed = true
         UIViewController.current()?.navigationController?.pushViewController(vc, animated: animated)
    }
    
    func goIdentification(type: Int, roomId: String) {
        let vc = FZMWebViewController.init(navTintColor: FZM_WhiteColor, navBarColor: FZM_TintColor, navTitleColor: FZM_WhiteColor)
        let dic = ["token": IMLoginUser.shared().currentUser?.token ?? "",
                   "session":IMLoginUser.shared().currentUser?.sessionId ?? "",
                   "type":type,
                   "roomId": roomId,
                   ] as [String : Any]
        if let data = try? JSONSerialization.data(withJSONObject: dic, options: []),
            let str = String.init(data: data, encoding: .utf8),
            let aes = try? AES.init(key: "com.fuzamei.chat".bytes, blockMode: ECB.init()),
            let encryptStr = try? aes.encrypt(str.bytes).toHexString() {
            vc.url = (qrCodeShareUrl as NSString).replacingOccurrences(of: "share.html?", with: "cert/#/?para=") + "\(encryptStr)"
        }
        vc.hidesBottomBarWhenPushed = true
        UIViewController.current()?.navigationController?.pushViewController(vc, animated: true)
    }
    
    func goSetSeedPwd(isShowForget:Bool) {
        if let currentVC = UIViewController.current() as? RTContainerController, !currentVC.contentViewController.isKind(of: FZMSetSeedVC.self) && !currentVC.contentViewController.isKind(of: FZMSetSeedPwdVC.self) {
            let vc = FZMSetSeedVC.init(isShowForget: isShowForget)
                  UIViewController.current()?.present(FZMNavigationController.init(rootViewController: vc), animated: true, completion: nil)
        }
    }
}

extension FZMUIMediator: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        if url.startAccessingSecurityScopedResource() {
            NSFileCoordinator().coordinate(readingItemAt: url, options: [.withoutChanges], error: nil) { (newURL) in
               self.icloudFileBlock?([newURL])
            }
           url.stopAccessingSecurityScopedResource()
        }
    }
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        self.icloudFileBlock?(urls)
    }
}

extension FZMUIMediator: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        DispatchQueue.main.async {
            picker.dismiss(animated: true, completion: {
                UIApplication.shared.setStatusBarHidden(false, with: .fade)
            })
            guard let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage else {
                return
            }
            let newImage = image.fixedImageToUpOrientation2()
            if self.allowEdit {
                guard let tabBar = self.homeTabbarVC, let nav = tabBar.selectedViewController as? UINavigationController else { return }
                let vc = FZMImageCropVC(with: newImage)
                vc.confirmBlock = {[weak self] editImg in
                    guard let strongSelf = self else { return }
                    strongSelf.selectImageBlock?([editImg],nil)
                }
                vc.hidesBottomBarWhenPushed = true
                nav.pushViewController(vc, animated: true)
            }else {
                self.selectImageBlock?([newImage],nil)
            }
        }
    }
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        DispatchQueue.main.async {
            picker.dismiss(animated: true) {
                UIApplication.shared.setStatusBarHidden(false, with: .fade)
            }
        }
    }
    
}

extension FZMUIMediator: UserInfoChangeDelegate {
    func userFirstLogin() {
        if IMSDK.shared().showPromoteHotGroup {
            self.goPromoteHotGroup(animated: false)
        }
//        let editNameView = FZMInputAlertView.init(title: "设置昵称", placehoder: "取个名字吧! 20字内", confirmBlock: { (name) in
//            IMSDK.shared().editUsername(name: name, completeBlock: { (response) in
//                if response.success {
//                    UIApplication.shared.keyWindow?.showToast(with: "设置成功")
//                } else {
//                    UIApplication.shared.keyWindow?.showToast(with: "设置失败")
//                }
//            })
//        })
//        editNameView.show()
    }
    
    func userLogin() {

    }
    
    func userLogout() {
        self.goLoginView(type: .mobile)
        self.homeTabbarVC?.selectedIndex = 0
    }
    func userInfoChange() {
        
    }
}

extension FZMUIMediator: AppActiveDelegate {
    func appWillEnterForeground() {
        if IMSDK.shared().isCheckVersion {
            self.checkVersion()
        }
        
        if IMLoginUser.shared().isLogin {
            HttpConnect.shared().open(completionBlock: nil)
        }
    }
    
    func appEnterBackground() {
        
    }
}

extension FZMUIMediator {
    @objc public func multipleSendImageMsg(_ image: UIImage) {
        self.pushVC(.multipleSendMsg(type: .image(image: image)))
    }
    @objc public func sweepQRCode() {
        FZMUIMediator.shared().pushVC(.sweepQRCode)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
