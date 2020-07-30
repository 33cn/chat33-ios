//
//  FZMFileViewController.swift
//  IMSDK
//
//  Created by .. on 2019/2/21.
//

import UIKit

class FZMFileViewController: FZMBaseViewController {
    private var isSelect = false
    private lazy var forwardBar : FZMForwardBar = {
        let view = FZMForwardBar.init(withDownload: true)
        view.eventBlock = {[weak self] (event) in
            guard let strongSelf = self else { return }
            switch event {
            case .forward:
                strongSelf.forwardMsgList(false)
            case .allForward:
                strongSelf.forwardMsgList(true)
            case .delete:
                FZMBottomSelectView.show(with: [
                    FZMBottomOption(title: strongSelf.conversationType == .group ? "从群文件中删除" : "从聊天文件中删除", block: {
                        strongSelf.deleteSelectMsgs(onlyDeleteLocalMeg: false)
                    }),FZMBottomOption(title: "从本设备中删除", block: {[weak self] in
                        strongSelf.deleteSelectMsgs(onlyDeleteLocalMeg: true)
                    })])
            case .download:
                strongSelf.downloadSelected()
            default: break
            }
        }
        view.isHidden = true
        return view
    }()
    
        
    var view1: FZMFlieListView?
    var view2: FZMVideoListView?
    
    var senderNameCanTouch = true
    
    private var fileMessagArr: [SocketMessage]? {
        get {
            return self.view1?.fileMessagArr
        }
        set {
            self.view1?.fileMessagArr = newValue ?? [SocketMessage]()
        }
    }
    private var fileListVMArr: [FZMFileListVM]? {
        get {
            return self.view1?.fileListVMArr
        }
        set {
            self.view1?.fileListVMArr = newValue ?? [FZMFileListVM]()
        }
    }
    private var videoAndImageMessageArr: [SocketMessage]? {
        get {
            return self.view2?.videoAndImageMessageArr
        }
    }
    private var videoListVmArr: [FZMVideoListVM]? {
        get {
            return self.view2?.videoListVMArr
        }
    }
    
    lazy var searchBtn: UIButton = {
        let btn = UIButton.init(type: .custom)
        btn.setImage(GetBundleImage("file_search")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.setImage(GetBundleImage("file_search"), for: .highlighted)
        btn.tintColor = FZM_TintColor
        btn.enlargeClickEdge(10, 10, 10, 10)
        btn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            if let strongSelf = self  {
                let vc = FZMFileSearchController.init(conversationType: strongSelf.conversationType, conversationID: strongSelf.conversationID)
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        }.disposed(by: disposeBag)
        return btn
    }()
    
    
    let conversationType:SocketChannelType
    let conversationID:String
    private let refreshListLock = NSLock()
    private var currentIndex = 0
    
    var uploadBarBtn: UIBarButtonItem?
    var forwardFromName = ""
    
    init(conversationType:SocketChannelType, conversationID:String) {
        
        self.conversationType = conversationType
        self.conversationID = conversationID
        super.init()
        if conversationType == .person {
            IMContactManager.shared().requestUserModel(with: conversationID) { (model, _, _) in
                self.forwardFromName = model?.name ?? ""
            }
        } else {
            IMConversationManager.shared().getGroup(with: conversationID) { (model) in
                self.forwardFromName = model.name
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let uploadBtn = UIBarButtonItem.init(image: GetBundleImage("file_upload"), style: .done, target: self, action: #selector(uploadFileOrVideo))
        let selectBtn = UIBarButtonItem.init(title: "选择", style: .done, target: self, action: #selector(selectFileOrCancel))
        self.navigationItem.rightBarButtonItems = [selectBtn,uploadBtn]
        self.uploadBarBtn = uploadBtn
        
        self.createUI()
        
        self.view.addSubview(forwardBar)
        forwardBar.snp.makeConstraints { (m) in
            m.left.right.equalTo(self.safeArea)
            m.height.equalTo(70)
            m.bottom.equalTo(self.safeBottom)
        }
    }
    
    
    func createUI() {
        
        self.navBarColor = FZM_BackgroundColor
        
        self.view1 = FZMFlieListView.init(with: "文件", conversationType: conversationType, conversationId: conversationID)
        self.view1?.loadData()
        self.fileMessagArr = self.view1?.fileMessagArr
        self.fileListVMArr = self.view1?.fileListVMArr
        self.view2 = FZMVideoListView.init(with: "图片/视频", conversationType: conversationType, conversationId: conversationID)
        self.view2?.loadData()
        let param = FZMSegementParam()
        if let view1 = self.view1, let view2 = self.view2 {
            view1.selectBlock = {[weak self] (vm) in
                if let filePath = FZM_UserDefaults.object(forKey: vm.fileUrl) as? String, !filePath.isEmpty {
                    self?.openFile(msgId: vm.msgId, filePath: filePath, fileName: vm.fileName)
                }
            }
            view2.selectBlock = {[weak self] (vm,imageview) in
                if vm.msgType == .image {
                    self?.browserImage(from: imageview, msgId: vm.msgId)
                    return
                }
                if vm.msgType == .video {
                    if let videoPath = FZM_UserDefaults.object(forKey: vm.videoUrl) as? String, !videoPath.isEmpty {
                        self?.playVideo(msgId: vm.msgId, videlPath: videoPath)
                        return
                    }
                }
            }
            let pageView = FZMScrollPageView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: ScreenHeight-StatusNavigationBarHeight), dataViews: [view1,view2], param: param)
            pageView.selectBlock = {[weak self] index in
                self?.currentIndex = index
                self?.forwardBar.disableDelete = (index == 0 ? false : true)
                self?.searchBtn.isHidden = (index == 0 ? false : true)
                self?.videoListVmArr?.forEach { (vm) in
                    if vm.selected == true {
                        self?.forwardBar.disableDelete = true
                    }
                }
            }
            self.view.addSubview(pageView)
            
            view1.senderLabBlock = {[weak self] (vm) in
                guard let strongSelf = self,strongSelf.isSelect == false else {return}
                let vc = FZMSenderFileController.init(conversationType: strongSelf.conversationType, conversationID: strongSelf.conversationID, owner: vm.senderUid,ownerName:vm.name)
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
            if senderNameCanTouch {
                view1.senderLabBlock = {[weak self] (vm) in
                    guard let strongSelf = self,strongSelf.isSelect == false else {return}
                    let vc = FZMSenderFileController.init(conversationType: strongSelf.conversationType, conversationID: strongSelf.conversationID, owner: vm.senderUid,ownerName:vm.name)
                    strongSelf.navigationController?.pushViewController(vc, animated: true)
                }
            }
            
            self.view.addSubview(searchBtn)
            searchBtn.snp.makeConstraints { (m) in
                m.top.equalTo(pageView).offset(13)
                m.right.equalToSuperview().offset(-14)
                m.width.height.equalTo(26)
            }
        }
    }
    
    @objc private func uploadFileOrVideo() {
        if self.currentIndex == 0 {
            self.goFile()
        } else {
            self.goPhoto()
        }
    }
    
    @objc func selectFileOrCancel() {
        if let fileArr = self.fileListVMArr,
            let videoArr = self.videoListVmArr,
            fileArr.isEmpty && videoArr.isEmpty {
            return
        }
        if let fileArr = self.fileListVMArr,
            self.view2 == nil && fileArr.isEmpty  {
            return
        }
        
        if self.navigationItem.rightBarButtonItem?.title == "选择" {
            
            self.uploadBarBtn?.isEnabled = false
            self.uploadBarBtn?.image = nil
            
            self.navigationItem.rightBarButtonItem?.title = "取消"
            self.selectFile()
            self.forwardBar.isHidden = false
        } else {
            
            self.uploadBarBtn?.isEnabled = true
            self.uploadBarBtn?.image = GetBundleImage("file_upload")
            
            self.navigationItem.rightBarButtonItem?.title = "选择"
            self.cancelSelectFile()
            self.forwardBar.isHidden = true
        }
    }
    
    private func selectFile() {
        self.isSelect = true

        self.view1?.isSelect = true
        self.view1?.edgeInset(true)

        self.view2?.isSelect = true
        self.view2?.edgeInset(true)
        self.reloadListViews()
    }
    
    private func cancelSelectFile() {
        self.isSelect = false
        self.fileListVMArr?.forEach { (vm) in
            vm.isShowSelect = false
            vm.selected = false
        }
        self.view1?.isSelect = false
        self.view1?.edgeInset(false)
        
        self.videoListVmArr?.forEach { (vm) in
            vm.isShowSelect = false
            vm.selected = false
        }
        self.view2?.isSelect = false
        self.view1?.edgeInset(false)
        
        self.reloadListViews()
    }
    
    func reloadListViews() {
        self.refreshListLock.lock()
        self.view1?.refresh()
        self.view2?.refresh()
        self.refreshListLock.unlock()
    }
    
    private func downloadSelected() {
        var noDataDownload = true
        self.fileListVMArr?.forEach { (vm) in
            if vm.selected {
                noDataDownload = false
                if let filePath = FZM_UserDefaults.object(forKey: vm.fileUrl) as? String, !filePath.isEmpty {
                    
                } else {
                    vm.downloadFile()
                }
            }
        }
        self.videoListVmArr?.forEach { (vm) in
            if vm.selected {
                noDataDownload = false
                if let videoPath = FZM_UserDefaults.object(forKey: vm.videoUrl) as? String, !videoPath.isEmpty {
                    
                } else {
                    vm.downloadVideo()
                }
            }
        }
        if noDataDownload {
            self.showToast(with: "请选择下载内容")
        } else {
            self.showToast(with: "已开始下载")
            self.selectFileOrCancel()
        }
    }
    
    private func forwardMsgList(_ isAll: Bool) {
        
        var msgs = [SocketMessage]()
        self.fileListVMArr?.forEach { (vm) in
            if vm.selected {
                msgs.append(vm.message)
            }
        }
        self.videoListVmArr?.forEach { (vm) in
            if vm.selected {
                msgs.append(vm.message)
            }
        }
        if msgs.isEmpty {
            self.showToast(with: "转发消息不能为空")
            return
        }
        if msgs.count > 50 {
            let alert = FZMAlertView.init(onlyAlert: "最多选择50条消息") {
                return
            }
            alert.show()
        }
        
        if IMSDK.shared().isEncyptChat {
            let forwordMsgs = msgs
            self.selectContact { (roomIds, userIds) in
                self.showProgress()
                SocketMessage.encyptForwordMsg(type: isAll ? .merge : .detail, roomIds: roomIds, userIds: userIds, forwordMsgs: forwordMsgs, forwardFromName: self.forwardFromName, compeletionBlock: { (dic) in
                    if let roomLogs = dic["roomLogs"] as? [Any], let userLogs = dic["userLogs"] as? [Any]  {
                        HttpConnect.shared().encryptForwardMsgs(roomLogs: roomLogs, type: isAll ? 2 : 1, userLogs: userLogs, completionBlock: { (response) in
                            self.hideProgress()
                            guard response.success, let data = response.data else {
                                self.showToast(with: response.message)
                                return
                            }
                            let failNum = data["failsNumber"].intValue
                            if failNum > 0 {
                                self.showToast(with: "转发的好友/群聊中包含\(failNum)个禁言、解除关系、黑名单的好友/群聊，无法收到转发的消息")
                            }else {
                                self.showToast(with: "转发成功")
                            }
                            self.selectFileOrCancel()
                        })
                    } else {
                        self.hideProgress()
                    }
                })
            }
        } else {
            self.selectContact { (roomIds, userIds) in
                self.showProgress()
                let msgIds = msgs.compactMap({ $0.msgId})
                HttpConnect.shared().forwardMsgs(sourceId: self.conversationID, type: self.conversationType == .group ? 1 : 2, forwardType: isAll ? 2 : 1, msgIds: msgIds, targetRooms: roomIds, targetUsers: userIds, completionBlock: { (response) in
                    self.hideProgress()
                    guard response.success, let data = response.data else {
                        self.showToast(with: response.message)
                        return
                    }
                    let failNum = data["failsNumber"].intValue
                    if failNum > 0 {
                        self.showToast(with: "转发的好友/群聊中包含\(failNum)个禁言、解除关系、黑名单的好友/群聊，无法收到转发的消息")
                    }else {
                        self.showToast(with: "转发成功")
                    }
                    self.selectFileOrCancel()
                })
            }
        }
    }
    
    private func selectContact(completeBlock: @escaping ([String],[String])->()) {
        FZMUIMediator.shared().pushVC(.selectFriendAndGroup(completeBlock: { (list) in
            var roomIds = [String]()
            var userIds = [String]()
            list.forEach { (model) in
                if model.type == .person {
                    userIds.append(model.contactId)
                }else {
                    roomIds.append(model.contactId)
                }
            }
            completeBlock(roomIds, userIds)
        }))
    }
    
    private func deleteSelectMsgs(onlyDeleteLocalMeg:Bool) {
        var msgIds = [String]()
        self.fileListVMArr?.forEach { (vm) in
            if vm.selected {
                msgIds.append(vm.msgId)
            }
        }
       
        if onlyDeleteLocalMeg {
            msgIds.forEach { (msgId) in
                if let msg = SocketMessage.getMsg(with: msgId, conversationId: conversationID, conversationType: conversationType) {
                    msg.delete()
                }
            }
        } else {
            self.showProgress()
            FZMFileManager.shared().revokeFiles(fileIds: msgIds, type: conversationType.rawValue - 1) { (response) in
                self.hideProgress()
                guard response.success else { return }
                if let fails = response.data?["fails"].arrayObject as? [String], !fails.isEmpty {
                    self.showToast(with: "有\(fails.count)个文件删除失败! 除群主和管理员外,只能删除自己上传的文件")
                    for failId in fails {
                        msgIds.remove(at: failId)
                    }
                }
                
                for deletedId in msgIds {
                    if let msg = self.getMessage(with: deletedId) {
                        self.fileMessagArr?.remove(at: msg)
                    }
                }
                self.fileListVMArr = self.fileMessagArr?.sorted{$0 > $1}.compactMap{FZMFileListVM.init(with: $0, autoDownloadFile: false, isNeedSaveMessage: false)}
            }
        }
        self.selectFileOrCancel()
    }
    
    
    private func openFile(msgId: String, filePath: String,fileName:String) {
        let filePath = FZMLocalFileClient.shared().getFilePath(with: .file(fileName: filePath.lastPathComponent()))
        self.previewDocument(url:URL.init(fileURLWithPath: filePath),name: fileName)
        
    }
    
    private func playVideo(msgId: String, videlPath: String) {
        let playerVC = FZMVideoPlayerController.init(videoPath: FZMLocalFileClient.shared().getFilePath(with: .video(fileName: (videlPath as NSString).lastPathComponent)))
        self.present(playerVC, animated: true, completion: nil)
        
    }
    
    private func browserImage(from imageView: UIImageView, msgId: String) {
        guard let msg = self.getMessage(with: msgId) else { return }
        if msg.snap == .open {
            self.present(FZMPhotoBrowser.init(burnBrowserWith: msg, from: imageView), animated: true, completion: nil)
            
        } else {
            if let arr = videoAndImageMessageArr?.filter({$0.msgType == .image}) {
                self.present(FZMPhotoBrowser.init(msg: msg, msgList:arr , from: imageView), animated: true, completion: nil)
            }
        }
    }
    
    private func getMessage(with msgId: String) -> SocketMessage? {
        var selectMsg : SocketMessage?
        let messageList = (fileMessagArr ?? [SocketMessage]()) + (videoAndImageMessageArr ?? [SocketMessage]())
        messageList.forEach { (msg) in
            if msg.msgId == msgId || msg.sendMsgId == msgId {
                selectMsg = msg
            }
        }
        return selectMsg
    }
}

import Photos
extension FZMFileViewController {
    
    func goPhoto() {
        FZMUIMediator.shared().pushVC(.photoLibrary(selectOne: false, maxSelectCount: 9, allowEditing: false, showVideo: true, selectBlock: { (list,assets) in
            if let assets = assets, list.count == assets.count {
                for i in 0..<assets.count {
                    if assets[i].mediaType == PHAssetMediaType.video {
                        self.sendVideoMsg(firstFrameImg: list[i], asset: assets[i])
                    }else {
                        self.sendImageMsg(with: list[i])
                    }
                }
            }
        }))
    }
    
    func goFile() {
        FZMUIMediator.shared().pushVC(.icloudPicker { (fileUrls) in
            for url in fileUrls {
                self.sendFileMsg(fileURL: url)
            }
            })
    }
    
    func sendFileMsg(fileURL:URL,isBurn: Bool = false) {
        if fileURL.startAccessingSecurityScopedResource() {
            NSFileCoordinator().coordinate(readingItemAt: fileURL, options: [.withoutChanges], error: nil) { (newURL) in
                guard let data = try? Data.init(contentsOf: newURL),
                    let filePath = FZMLocalFileClient.shared().createFile(with: .file(fileName: newURL.lastPathComponent)) else {
                        self.showToast(with: "文件选取失败,请重试")
                        return
                }
                guard (data.count / 1024 / 1024) < 100 else {
                    self.showToast(with: "文件不能大于100M")
                    return
                }
                if FZMLocalFileClient.shared().saveData(data, filePath: filePath) {
                    let msg = SocketMessage.init(filePath: filePath, fileSize: data.count, from: IMLoginUser.shared().userId, to: self.conversationID, channelType: self.conversationType,isBurn: false)
                    FZM_NotificationCenter.post(name: FZM_Notify_File_UploadFile, object: self, userInfo: ["msg":msg])
                    self.showToast(with: "文件上传中,请返回聊天页面查看")
                    SocketChatManager.shared().sendMessage(with: msg)
                }
            }
            fileURL.stopAccessingSecurityScopedResource()
        } else {
            self.showToast(with: "文件选取失败,请重试")
        }
    }
    
    func sendImageMsg(with image: UIImage, isBurn: Bool = false) {
        guard let savePath = FZMLocalFileClient.shared().createFile(with: .jpg(fileName: String.getTimeStampStr())) else {
            self.showToast(with: "图片保存错误，请重试")
            return
        }
        let result = FZMLocalFileClient.shared().saveData(image.jpegData(compressionQuality: 0.4)!, filePath: savePath)
        if result {
            let msg = SocketMessage(image: image, filePath: savePath.formatFileName(), from: IMLoginUser.shared().userId, to: self.conversationID, channelType: self.conversationType, isBurn: isBurn)
            FZM_NotificationCenter.post(name: FZM_Notify_File_UploadFile, object: self, userInfo: ["msg":msg])
            self.showToast(with: "图片上传中,请返回聊天页面查看")
            SocketChatManager.shared().sendMessage(with: msg)
            return
        }
    }
    
    func sendVideoMsg(firstFrameImg:UIImage, asset: PHAsset,isBurn: Bool = false) {
        if #available(iOS 9.0, *) {
            guard let size = (PHAssetResource.assetResources(for: asset).first?.value(forKey: "fileSize") as? Int), (size / 1024 / 1024) < 100 else {
                self.showToast(with: "视频不能大于100M")
                return
            }
        }
        let msg = SocketMessage(firstFrameImg: firstFrameImg, asset: asset, filePath: "", from: IMLoginUser.shared().userId, to: self.conversationID, channelType: self.conversationType, isBurn: isBurn)
        FZM_NotificationCenter.post(name: FZM_Notify_File_UploadFile, object: self, userInfo: ["msg":msg])
        self.showToast(with: "视频上传中,请返回聊天页面查看")
        SocketChatManager.shared().sendMessage(with: msg)
    }
}
