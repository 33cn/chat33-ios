//
//  FZMConversationChatVC.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/25.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import MJRefresh
import SwiftyJSON
import MobileCoreServices
import RxCocoa
import RxSwift
import IDMPhotoBrowser
import TZImagePickerController
import MediaPlayer
import YYWebImage.YYWebImageManager
import KeychainAccess


class FZMConversationChatVC: FZMBaseViewController {
    
    private let conversation : SocketConversationModel
    private var locationMsg: (String,String)?
    private var nextMsgId : String?
    fileprivate var lastShowTimeMessage : SocketMessage?
    fileprivate var firstShowTimeMessage : SocketMessage?
    fileprivate var systemMessage : SocketMessage?//记录正在展示systemMessage
    
    lazy var messageListView : UITableView = {
        let view = UITableView(frame: CGRect.zero, style: .plain)
        view.backgroundColor = FZM_BackgroundColor
        view.tableHeaderView = UIView(frame: CGRect.zero)
        view.tableFooterView = UIView(frame: CGRect.zero)
        view.separatorStyle = .none
        view.rowHeight = UITableView.automaticDimension
        view.keyboardDismissMode = .onDrag
        view.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        view.mj_footer = MJRefreshBackNormalFooter(refreshingBlock: {[weak self] in
            self?.loadMore()
        })
        view.mj_footer.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        view.delegate = self
        view.dataSource = self
        view.register(FZMTextMessageCell.self, forCellReuseIdentifier: "FZMTextMessageCell")
        view.register(FZMMineTextMessageCell.self, forCellReuseIdentifier: "FZMMineTextMessageCell")
        view.register(FZMVoiceMessageCell.self, forCellReuseIdentifier: "FZMVoiceMessageCell")
        view.register(FZMMineVoiceMessageCell.self, forCellReuseIdentifier: "FZMMineVoiceMessageCell")
        view.register(FZMImageMessageCell.self, forCellReuseIdentifier: "FZMImageMessageCell")
        view.register(FZMMineImageMessageCell.self, forCellReuseIdentifier: "FZMMineImageMessageCell")
        view.register(FZMRedbagMessageCell.self, forCellReuseIdentifier: "FZMRedbagMessageCell")
        view.register(FZMMineRedbagMessageCell.self, forCellReuseIdentifier: "FZMMineRedbagMessageCell")
        view.register(FZMTextRedbagMessageCell.self, forCellReuseIdentifier: "FZMTextRedbagMessageCell")
        view.register(FZMMineTextRedbagMessageCell.self, forCellReuseIdentifier: "FZMMineTextRedbagMessageCell")
        view.register(FZMSystemMessageCell.self, forCellReuseIdentifier: "FZMSystemMessageCell")
        view.register(FZMNotifyMessageCell.self, forCellReuseIdentifier: "FZMNotifyMessageCell")
        view.register(FZMForwardMessageCell.self, forCellReuseIdentifier: "FZMForwardMessageCell")
        view.register(FZMMineForwardMessageCell.self, forCellReuseIdentifier: "FZMMineForwardMessageCell")
        view.register(FZMVideoMessageCell.self, forCellReuseIdentifier: "FZMVideoMessageCell")
        view.register(FZMMineVideoMessageCell.self, forCellReuseIdentifier: "FZMMineVideoMessageCell")
        view.register(FZMFileMessageCell.self, forCellReuseIdentifier: "FZMFileMessageCell")
        view.register(FZMMineFileMessageCell.self, forCellReuseIdentifier: "FZMMineFileMessageCell")
        view.register(FZMTransferMessageCell.self, forCellReuseIdentifier: "FZMTransferMessageCell")
        view.register(FZMMineTransferMessageCell.self, forCellReuseIdentifier: "FZMMineTransferMessageCell")
        view.register(FZMReceiptMessageCell.self, forCellReuseIdentifier: "FZMReceiptMessageCell")
        view.register(FZMMineReceiptMessageCell.self, forCellReuseIdentifier: "FZMMineReceiptMessageCell")
        view.register(FZMDecryptFailedCell.self, forCellReuseIdentifier: "FZMDecryptFailedCell")
        view.register(FZMMineDecryptFailedCell.self, forCellReuseIdentifier: "FZMMineDecryptFailedCell")
        view.register(FZMInviteGroupCell.self, forCellReuseIdentifier: "FZMInviteGroupCell")
        view.register(FZMMineInviteGroupCell.self, forCellReuseIdentifier: "FZMMineInviteGroupCell")
        return view
    }()
    
    //是否显示多选
    private var showSelect = false {
        didSet{
            self.forwardBar.isHidden = !showSelect
            self.navigationItem.leftBarButtonItem = showSelect ? UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(cancelSelect)) : UIBarButtonItem(customView: leftBarItemView)
            if showSelect {
                self.navigationItem.rightBarButtonItems = nil
                self.inputBar.showState(.normal)
            }else {
                self.vmList.values.forEach { (vm) in
                    vm.selected = false
                }
                self.selectMsgVMArr.removeAll()
                if conversation.type == .group {
                    IMConversationManager.shared().getGroup(with: conversation.conversationId) { (model) in
                        if model.memberLevel == .none {
                            self.navigationItem.rightBarButtonItems = nil
                        }else {
                            self.navigationItem.rightBarButtonItems = self.rightBarItemViews
                        }
                    }
                }else {
                    self.navigationItem.rightBarButtonItems = self.rightBarItemViews
                }
                self.inputBar.showState(.detail)
            }
            self.reloadList()
        }
    }
    
    @objc private func cancelSelect() {
        showSelect = false
    }
    
    private var messageList = [SocketMessage]()
    private var bottomUnReadMessageList = [SocketMessage]()
    private var vmList = [String:FZMMessageBaseVM]()
    
    lazy var inputBar : FZMInputBar = {
        let view = FZMInputBar()
        view.showMoreBlock = {[weak self] in
            guard let self = self else { return }
            self.view.endEditing(false)
            self.showMoreItem()
        }
        view.sendMsgBlock = {[weak self] (text, isSystem, isBurn, atUids) in
            #if DEBUG
            if text[0..<2] == "1-" {
                if let re = text.split(separator: "-").last, let count = Int(re), let strongSelf = self {
                    DispatchQueue.global().async {
                        for i in 0..<count {
                            let msg = SocketMessage(text: String.randomStr(len: Int(arc4random_uniform(UInt32(10))) + 1), from: IMLoginUser.shared().userId, to: strongSelf.conversation.conversationId, channelType: strongSelf.conversation.type, isBurn: false, isEncryptMsg:false)
                            SocketChatManager.shared().sendMessage(with: msg)
                        }
                    }
                }
                return
            }
            #endif
            self?.sendTextMsg(with: text, isSystem: isSystem, isBurn: isBurn, atUids: self?.conversation.type == .group ? atUids : nil)
        }
        view.recordAudioCompleteBlock = {[weak self] (amrPath, wavPath, duration, isBurn) in
            self?.sendAudioMsg(amrPath: amrPath, wavPath: wavPath, duration: duration, isBurn: isBurn)
        }
        view.sendImgsBlock = {[weak self] (list, isBurn) in
            list.forEach({ (image) in
                self?.sendImageMsg(with: image, isBurn: isBurn)
            })
        }
        view.cancelBurnBlock = {[weak self] in
            guard let strongSelf = self else { return }
            FZM_UserDefaults.setConversationInputValue(false, conversation: strongSelf.conversation)
        }
        return view
    }()
    
    lazy var moreItemBar : FZMMoreItemBar = {
        let view = FZMMoreItemBar()
        view.delegate = self
        return view
    }()
    
    lazy var forwardBar : FZMForwardBar = {
        let view = FZMForwardBar.init(normal: true)
        view.eventBlock = {[weak self] (event) in
            guard let strongSelf = self else { return }
            switch event {
            case .forward:
                self?.forwardMsgList(false)
            case .allForward:
                self?.forwardMsgList(true)
            case .delete:
                let alert = FZMAlertView(with: "确认删除？", confirmBlock: {
                    self?.deleteSelectMsgs()
                })
                alert.show()
            default: break
            }
        }
        view.isHidden = true
        return view
    }()
    private var selectMsgVMArr = [FZMMessageBaseVM]()
    
    lazy var systemAlertView : UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: 0xC1E9FF)
        view.clipsToBounds = true
        let lab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .left, text: "公告消息")
        view.addSubview(lab)
        lab.snp.makeConstraints({ (m) in
            m.top.equalToSuperview().offset(10)
            m.left.equalToSuperview().offset(17)
            m.size.equalTo(CGSize(width: 60, height: 17))
        })
        view.addSubview(systemMessageLab)
        systemMessageLab.snp.makeConstraints({ (m) in
            m.edges.equalToSuperview().inset(UIEdgeInsets(top: 33, left: 18, bottom: 12, right: 18))
        })
        let btn = UIButton(type: .custom)
        btn.enlargeClickEdge(20, 20, 20, 20)
        btn.setImage(GetBundleImage("chat_cancel"), for: .normal)
        view.addSubview(btn)
        btn.snp.makeConstraints({ (m) in
            m.top.equalToSuperview().offset(10)
            m.right.equalToSuperview().offset(-16)
            m.size.equalTo(CGSize(width: 16, height: 16))
        })
        btn.rx.controlEvent(.touchUpInside).subscribe(onNext:{[weak self,weak view] (_) in
            view?.isHidden = true
        }).disposed(by: disposeBag)
        return view
    }()
    
    private lazy var systemMessageLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: "")
        lab.numberOfLines = 0
        return lab
    }()
    
    private lazy var leftBarItemView : UIView = {
        let view = UIView()
        view.snp.makeConstraints({ (m) in
            m.size.equalTo(CGSize(width: 60, height: 40))
        })
        let imV = UIImageView(image: GetBundleImage("back_arrow")?.withRenderingMode(.alwaysTemplate))
        view.addSubview(imV)
        imV.snp.makeConstraints({ (m) in
            m.left.centerY.equalToSuperview()
            m.size.equalTo(CGSize(width: 10, height: 17))
        })
        let countLab = UILabel.getLab(font: UIFont.mediumFont(16), textColor: FZM_TintColor, textAlignment: .left, text: nil)
        view.addSubview(countLab)
        countLab.snp.makeConstraints({ (m) in
            m.left.equalTo(imV.snp.right).offset(3)
            m.top.bottom.right.equalToSuperview()
        })
        Observable.combineLatest(IMConversationManager.shared().groupUnreadCountSubject, IMConversationManager.shared().privateUnreadCountSubject).subscribe {[weak countLab] (event) in
            guard case .next(let groupUnreadCount, let privateUnreadCount) = event else { return }
            let count = groupUnreadCount + privateUnreadCount
            if count > 999 {
                countLab?.text = "(...)"
            }else if count <= 0 {
                countLab?.text = ""
            }else {
                countLab?.text = "(\(count))"
            }
        }.disposed(by: disposeBag)
        let tap = UITapGestureRecognizer(target: self, action: #selector(popBack))
        view.addGestureRecognizer(tap)
        return view
    }()
    
    private lazy var rightBarItemViews : [UIBarButtonItem] = {
        let spece = UIBarButtonItem.init(image: nil, style: .plain, target: nil, action: nil)
        spece.width = 30
        let item = UIBarButtonItem.init(image: GetBundleImage("me_more")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(moreItemClick))
        return [item,spece]
    }()
    
    private lazy var rightBarItemView : UIView = {
        let view = UIButton.init(type: .custom)
        view.snp.makeConstraints({ (m) in
            m.size.equalTo(CGSize(width: 60, height: 40))
        })
        let imV = UIImageView(image: GetBundleImage("me_more")?.withRenderingMode(.alwaysTemplate))
        view.addSubview(imV)
        imV.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.right.equalToSuperview().offset(-5)
        })
        view.addTarget(self, action: #selector(moreItemClick), for: .touchUpInside)
        return view
    }()
    
    private var topUnreadCount:Int
    private lazy var topUnreadBtn: UIButton = {
        let btn = FZMUnreadCountButton.init(with: GetBundleImage("top_arrow"), frame: CGRect(x: ScreenWidth, y: 15, width: 125, height: 40))
        btn.setTitle("\(topUnreadCount)条新消息", for: .normal)
        let maskPath = UIBezierPath.init(roundedRect: btn.bounds, byRoundingCorners: [UIRectCorner.topLeft,UIRectCorner.bottomLeft], cornerRadii: CGSize.init(width: btn.bounds.height * 0.5, height: btn.bounds.height * 0.5))
        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        btn.layer.mask = maskLayer
        btn.rx.controlEvent(.touchUpInside).subscribe(onNext: {[weak self] (_) in
            self?.topUnreadBtnPres()
        }).disposed(by: disposeBag)
        return btn
        
    }()
    
    private lazy var bottomUnreadBtn: UIButton = {
       
        let btn = FZMUnreadCountButton.init(with: GetBundleImage("down_arrow"), frame:CGRect(x: (ScreenWidth - 130) * 0.5 , y: ScreenHeight, width: 130, height: 40))
        btn.layer.cornerRadius = 20
        btn.layer.masksToBounds = true;
        btn.alpha = 0;
        btn.rx.controlEvent(.touchUpInside).subscribe(onNext: {[weak self] (_) in
            self?.bottomUnreadBtnPress()
        }).disposed(by: disposeBag)
        return btn
        
    }()
    
    private var bottomUnreadCount = 0 {
        didSet {
            if bottomUnreadCount == 0 {
                bottomUnreadBtn.alpha = 0
            } else {
                bottomUnreadBtn.setTitle("\(bottomUnreadCount)条新消息", for: .normal)
            }
        }
    }
    
    private var admireBtnY: CGFloat {
        return self.topUnreadCount == 0 ? 15 : 85
    }
    
    private lazy var admireBtn: UIButton = {
        let btn = FZMUnreadCountButton.init(with: nil, frame: CGRect(x: ScreenWidth, y: admireBtnY, width: 81, height: 40))
        let maskPath = UIBezierPath.init(roundedRect: btn.bounds, byRoundingCorners: [UIRectCorner.topLeft,UIRectCorner.bottomLeft], cornerRadii: CGSize.init(width: btn.bounds.height * 0.5, height: btn.bounds.height * 0.5))
        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        btn.layer.mask = maskLayer
        btn.rx.controlEvent(.touchUpInside).subscribe(onNext: {[weak self] (_) in
            self?.admireBtnPress()
        }).disposed(by: disposeBag)
        return btn
        
    }()
    
    //列表刷新锁
    private let refreshListLock = NSLock()
    private let imageLoadTool = UIImageView.init()
    
    private lazy var activityIndicatorView: FZMActivityIndicatorView = {
        let v = FZMActivityIndicatorView.init(frame: CGRect.zero, title: "收取中...")
        v.isHidden = true
        v.backgroundColor = FZM_BackgroundColor
        v.tintColor = .white
        return v
    }()
    private lazy var titleLab: UILabel = {
        let titleLab = UILabel.getLab(font: UIFont.boldSystemFont(ofSize: 17), textColor: FZM_TitleColor, textAlignment: .center, text: "")
        return titleLab
    }()
    
    private lazy var navTitleView: UIView = {
        let v = UIView.init()
        v.addSubview(titleLab)
        titleLab.snp.makeConstraints({ (m) in
            m.edges.equalToSuperview()
        })
        v.addSubview(activityIndicatorView)
        activityIndicatorView.snp.makeConstraints({ (m) in
            m.edges.equalToSuperview()
        })
        return v
    }()
    
    
    init(with conversation: SocketConversationModel, locationMsg: (String,String)?) {
        self.conversation = conversation
        self.locationMsg = locationMsg
        topUnreadCount = locationMsg == nil ? conversation.unreadCount : 0
        super.init()
        conversation.unreadCount = 0
        IMConversationManager.shared().selectConversation = conversation
        conversation.infoSubject.subscribe {[weak self] (event) in
            guard case .next(_) = event else { return }
            self?.refreshNavigationTitle()
        }.disposed(by: disposeBag)
        SocketChatManager.shared().isFinishedFetchMsgListSubject.subscribe {[weak self] (event) in
            guard case .next(let value) = event, let isFinishedFetchMsgList = value  else { return }
            if isFinishedFetchMsgList {
                self?.activityIndicatorView.isHidden = true
                if ((self?.messageList.count ?? 0) > 0) {
                    self?.refreshListLock.lock()
                    self?.messageList.removeAll()
                    self?.messageListView.reloadData()
                    self?.refreshListLock.unlock()
                    self?.loadMore()
                }
            } else {
                self?.activityIndicatorView.isHidden = false
            }
        }.disposed(by: disposeBag)
        conversation.allUpvote.upvoteSubject.subscribe(onNext: {[weak self, weak conversation] (upvote) in
            conversation?.update()
            guard let strongSelf = self, let upvote = upvote else { return }
            if upvote.admire != 0 || upvote.reward != 0 {
                strongSelf.setAdmire(info: "\(upvote.admire + upvote.reward)赞赏", isReward: upvote.reward > 0)
                strongSelf.showAdmireBtn()
            } else {
                strongSelf.hideAdmireBtn()
            }
        }).disposed(by: disposeBag)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        IMConversationManager.shared().selectConversation = nil
        FZM_NotificationCenter.removeObserver(self)
        IMNotifyCenter.shared().removeReceiver(receiver: self, type: .chatMessage)
        IMNotifyCenter.shared().removeReceiver(receiver: self, type: .socketConnect)
        IMNotifyCenter.shared().removeReceiver(receiver: self, type: .groupBanned)
        IMNotifyCenter.shared().removeReceiver(receiver: self, type: .burnAfterRead)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItems = self.rightBarItemViews
        self.navigationItem.titleView = self.navTitleView
        self.refreshGroupInfo()
        self.createUI()
        FZM_NotificationCenter.addObserver(self, selector: #selector(self.showKeyBoard(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        FZM_NotificationCenter.addObserver(self, selector: #selector(self.hideKeyboard(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        FZM_NotificationCenter.addObserver(self, selector: #selector(userDidTakeScreenShot), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .chatMessage)
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .socketConnect)
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .groupBanned)
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .burnAfterRead)
        
        
        FZM_NotificationCenter.addObserver(self, selector: #selector(fileVCUploadFileNotify(notification:)), name: FZM_Notify_File_UploadFile, object: nil)
        FZM_NotificationCenter.addObserver(self, selector: #selector(bannedGroup(notification:)), name: FZM_Notify_BannedGroup, object: nil)
    }
    override func rt_customBackItem(withTarget target: Any!, action: Selector!) -> UIBarButtonItem! {
        return UIBarButtonItem.init(customView: leftBarItemView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if topUnreadCount > 0 && messageListView.visibleCells.count < topUnreadCount {
            self.showTopUnreadBtn()
        }
        self.addBlankRowItem()
    }
    
    @objc func userDidTakeScreenShot() {
        guard conversation.type == .person else { return }
        guard let list = messageListView.indexPathsForVisibleRows else { return }
        var haveSecurity = false
        list.forEach({ (indexPath) in
            let msg = messageList[indexPath.row]
            if msg.snap == .open {
                haveSecurity = true
            }
        })
        guard haveSecurity else { return }
        HttpConnect.shared().printScreen(userId: conversation.conversationId) { (response) in
            
        }
    }
    
    private var moreItemBarHeight: Int {
        get {
            if IMSDK.shared().showRedBag ||
                (IMSDK.shared().showWallet && conversation.type == .person) {
                return 200
            }else {
                return 100
            }
        }
    }
    
    private func createUI() {
        self.view.addSubview(messageListView)
        self.view.addSubview(inputBar)
        self.view.addSubview(moreItemBar)
        self.view.addSubview(forwardBar)
        self.view.addSubview(systemAlertView)
        self.view.addSubview(topUnreadBtn)
        self.view.addSubview(bottomUnreadBtn)
        self.view.addSubview(admireBtn)
        inputBar.snp.makeConstraints { (m) in
            m.left.right.equalTo(self.safeArea)
            m.height.equalTo(70)
            m.bottom.equalTo(self.safeBottom)
        }
        moreItemBar.snp.makeConstraints { (m) in
            m.left.right.equalTo(self.safeArea)
            m.height.equalTo(moreItemBarHeight)
            m.top.equalTo(self.safeBottom).offset(50)
        }
        forwardBar.snp.makeConstraints { (m) in
            m.left.right.equalTo(self.safeArea)
            m.height.equalTo(70)
            m.bottom.equalTo(self.safeBottom)
        }
        messageListView.snp.makeConstraints { (m) in
            m.left.right.top.equalTo(self.safeArea)
            m.bottom.equalTo(self.inputBar.snp.top)
        }
        systemAlertView.snp.makeConstraints { (m) in
            m.left.right.top.equalTo(self.safeArea)
        }
        systemAlertView.isHidden = true
        self.loadMore()
        self.makeActions()
        
        self.inputBar.isBurnAfterRead = FZM_UserDefaults.getConversationInputValue(conversation: conversation)
        
        if let msg = SocketMessage.getMsg(with: conversation.type, conversationId: conversation.conversationId, msgType: .system) {
            if !msg.body.isRead {
                msg.body.isRead = true
                msg.save()
                self.showSystemAlert(with: msg.body.content)
            }
        }
    }
    
    private func makeActions() {
        let tap = UITapGestureRecognizer()
        tap.cancelsTouchesInView = false
        tap.rx.event.subscribe(onNext:{[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.view.endEditing(true)
            strongSelf.endBottomBarEditing()
        }).disposed(by: disposeBag)
        messageListView.addGestureRecognizer(tap)
    }
    
    @objc func moreItemClick() {
        self.hideBottomUnreadBtn()
        if conversation.type == .group {
            FZMUIMediator.shared().pushVC(.groupDetailInfo(groupId: conversation.conversationId))
        }else if conversation.type == .person {
            FZMUIMediator.shared().pushVC(.friendInfo(friendId: conversation.conversationId, groupId: nil, source: nil))
        }
    }
    
    fileprivate func showSystemAlert(with text: String) {
        self.systemAlertView.isHidden = false
        self.systemMessageLab.text = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 120) {
            self.systemAlertView.isHidden = true
        }
    }
    
    private var isInPage = true
    private var user: IMUserModel?
    private var group: IMGroupDetailInfoModel?
    private var isEncrypt = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isInPage = true
        if conversation.type == .group {
            
            self.moreItemBar.hideTransferAndReceipt()
            
            IMConversationManager.shared().getGroup(with: conversation.conversationId) { (model) in
                self.group = model
                self.inputBar.group = model
                guard model.disableDeadline == 0 else {
                    let alert = FZMAlertView(onlyAlert: model.disableGroupInfo) {
                        self.navigationController?.popViewController(animated: true)
                    }
                    alert.show()
                    self.inputBar.showState(.hide)
                    self.navigationItem.rightBarButtonItems = nil
                    return
                }
                if model.isMaster || model.isManager {
                    self.inputBar.showSystem(false)
                }
                if model.memberLevel == .none {
                    self.inputBar.showState(.hide)
                    self.navigationItem.rightBarButtonItems = nil
                }else {
                    self.inputBar.showState(.detail)
                    self.navigationItem.rightBarButtonItems = self.rightBarItemViews
                }
                self.isEncrypt = IMSDK.shared().isEncyptChat ? model.isEncryptGroup : false
                self.refreshNavigationTitle()
                if IMSDK.shared().isEncyptChat && self.isEncrypt &&
                    (IMLoginUser.shared().currentUser?.getLatestGroupKey(groupId: self.conversation.conversationId)?.plainTextKey == nil) {
                    FZNEncryptKeyManager.shared().updataGroupKey(groupId: self.conversation.conversationId)
                }
            }
        }else if conversation.type == .person{
            IMContactManager.shared().requestUserDetailInfo(with: conversation.conversationId) { (user, _, _) in
                if let user = user, user.isFriend {
                    self.user = user
                    self.isEncrypt = IMSDK.shared().isEncyptChat ? (IMLoginUser.shared().currentUser?.isEncryptChatWithUser(user) ?? false) : false
                    self.refreshNavigationTitle()
                    self.inputBar.showState(.detail)
                }else {
                    self.inputBar.showState(.hide)
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isInPage = false
        IMConversationManager.shared().refreshUnreadCount()
        VoiceMessagePlayerManager.shared().stopVoice()
        removeBlankRowItem()
    }
    
    private func refreshGroupInfo() {
        if conversation.type == .group {
            IMConversationManager.shared().getGroupDetailInfo(groupId: conversation.conversationId) { (_, _) in
                self.refreshNavigationTitle()
                IMConversationManager.shared().requestBannedInfo(userId: IMLoginUser.shared().userId, groupId: self.conversation.conversationId) { (banned, distance) in
                    self.inputBar.bannedCtrl(with: distance)
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

//MARK:XXX条新消息
extension FZMConversationChatVC {
    
    func topUnreadBtnPres() {
        self.loadAllUnreadMessage(count: self.topUnreadCount - 1) {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.refreshListLock.lock()
            var indexPath: IndexPath
            if strongSelf.topUnreadCount <= strongSelf.messageList.count {
                indexPath = IndexPath(item: strongSelf.topUnreadCount - 1, section: 0)
            } else {
                indexPath = IndexPath(item: strongSelf.messageList.count - 1, section: 0)
            }
            if indexPath.row >= 0 && indexPath.row <= strongSelf.messageList.count - 1 {
                strongSelf.messageListView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
            strongSelf.refreshListLock.unlock()
            strongSelf.hideTopUnreadBtn()
        }
    }
    
    
    func showTopUnreadBtn() {
        guard self.topUnreadBtn.frame.origin.x == ScreenWidth, self.topUnreadCount != 0 else {
            return
        }
        UIView.animate(withDuration: 0.3) {
            self.topUnreadBtn.frame = CGRect.init(x: ScreenWidth - self.topUnreadBtn.bounds.width, y: self.topUnreadBtn.frame.origin.y, width: self.topUnreadBtn.width, height: self.topUnreadBtn.height)
        }
    }
    
    func hideTopUnreadBtn() {
        self.topUnreadCount = 0
        guard self.topUnreadBtn.frame.origin.x != ScreenWidth else {
            return
        }
        UIView.animate(withDuration: 0.3, animations: {
            self.topUnreadBtn.frame = CGRect.init(x: ScreenWidth, y: self.topUnreadBtn.frame.origin.y, width: self.topUnreadBtn.width, height: self.topUnreadBtn.height)
        }) { (_) in
            self.topUnreadBtn.removeFromSuperview()
        }
    }
    
    //bottom
    func bottomUnreadBtnPress() {
        self.refreshListLock.lock()
        self.messageListView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        self.refreshListLock.unlock()
        self.hideBottomUnreadBtn()
    }
    
    func showBottomUnreadBtn() {
        guard self.bottomUnreadBtn.frame.origin.y == ScreenHeight, self.bottomUnreadCount != 0 else {
            return
        }
        UIView.animate(withDuration: 0.4) {
            self.bottomUnreadBtn.alpha = 1
            self.bottomUnreadBtn.frame = CGRect.init(x: self.bottomUnreadBtn.frame.origin.x, y:self.inputBar.frame.origin.y - self.bottomUnreadBtn.height - 15 , width: self.bottomUnreadBtn.width, height: self.bottomUnreadBtn.height)
        }
    }
    
    func hideBottomUnreadBtn() {
        if (self.bottomUnreadBtn.frame.origin.y == ScreenHeight) && (self.bottomUnReadMessageList.count == 0) {
            return
        }
        if self.bottomUnReadMessageList.count > 0 {
            self.refreshListLock.lock()
            self.messageList = self.bottomUnReadMessageList + self.messageList
            self.bottomUnReadMessageList.removeAll()
            self.refreshListLock.unlock()
        }
        self.reloadList {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.refreshListLock.lock()
            strongSelf.messageListView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .bottom, animated: true)
            strongSelf.refreshListLock.unlock()
            UIView.animate(withDuration: 0.4, animations: {
                strongSelf.bottomUnreadBtn.alpha = 0
                strongSelf.bottomUnreadBtn.frame = CGRect.init(x: strongSelf.bottomUnreadBtn.frame.origin.x, y: ScreenHeight, width: strongSelf.bottomUnreadBtn.width, height: strongSelf.bottomUnreadBtn.height)
            }, completion: { (_) in
                strongSelf.bottomUnreadCount = 0
            })
        }
    }
    
    func setAdmire(info: String, isReward: Bool) {
        self.admireBtn.setTitle(info, for: .normal)
        self.admireBtn.setBackgroundColor(color: (isReward ? FZM_FCF3E2Color : FZM_EA6Color), state: .normal)
        self.admireBtn.setBackgroundColor(color: (isReward ? FZM_FCF3E2Color : FZM_EA6Color), state: .highlighted)
        self.admireBtn.setTitleColor((isReward ? FZM_EFA019Color : FZM_TintColor), for: .normal)
        
    }
    
    func showAdmireBtn() {
        guard self.admireBtn.frame.origin.x == ScreenWidth else { return }
        UIView.animate(withDuration: 0.3) {
            self.admireBtn.frame = CGRect.init(x: ScreenWidth - self.admireBtn.bounds.width, y: self.admireBtnY, width: self.admireBtn.width, height: self.admireBtn.height)
        }
    }
    func hideAdmireBtn() {
        guard self.admireBtn.frame.origin.x != ScreenWidth else { return }
        UIView.animate(withDuration: 0.3, animations: {
            self.admireBtn.frame = CGRect.init(x: ScreenWidth, y: self.admireBtnY, width: self.admireBtn.width, height: self.admireBtn.height)
        }) { (_) in
            
        }
    }
    
    func admireBtnPress() {
        
    }
}

//MARK:底部输入相关
extension FZMConversationChatVC{
    @objc private func showKeyBoard(_ noti: NSNotification) {
        guard isInPage else { return }
        guard let rectValue = noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {return}
        let height = rectValue.cgRectValue.size.height
        self.view.updateConstraints(with: 0.3) {
            self.inputBar.snp.updateConstraints { (m) in
                m.bottom.equalTo(self.safeBottom).offset(-height)
            }
            self.moreItemBar.snp.updateConstraints { (m) in
                m.top.equalTo(self.safeBottom).offset(50)
            }
        }
        messageListView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    @objc private func hideKeyboard(_ noti: NSNotification) {
        guard isInPage else { return }
        guard noti.userInfo != nil,!inputBar.showMore else {
            return
        }
        self.view.updateConstraints(with: 0.3) {
            self.inputBar.snp.updateConstraints { (m) in
                m.bottom.equalTo(self.safeArea)
            }
        }
    }
    private func showMoreItem() {
        self.view.updateConstraints(with: 0.3) {
            self.inputBar.snp.updateConstraints { (m) in
                m.bottom.equalTo(self.safeBottom).offset(-self.moreItemBarHeight)
            }
            self.moreItemBar.snp.updateConstraints { (m) in
                m.top.equalTo(self.safeBottom).offset(-self.moreItemBarHeight)
            }
        }
        messageListView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    private func endBottomBarEditing() {
        self.inputBar.showMore = false
        self.view.updateConstraints(with: 0.3) {
            self.inputBar.snp.updateConstraints { (m) in
                m.bottom.equalTo(self.safeBottom)
            }
            self.moreItemBar.snp.updateConstraints { (m) in
                m.top.equalTo(self.safeBottom).offset(50)
            }
        }
    }
}



//MARK:tableview代理事件
extension FZMConversationChatVC: UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageList.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messageList[indexPath.row]
        let vm = self.getVM(with: message)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: vm.identify, for: indexPath) as? FZMBaseMessageCell else {
            return UITableViewCell()
        }
        cell.actionDelegate = self
        cell.configure(with: vm)
        cell.showSelect = self.showSelect
        cell.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row >= topUnreadCount - 1 {
            hideTopUnreadBtn()
        }
        if indexPath.row == 0 {
            hideBottomUnreadBtn()
        }
    }
    
    private func getVM(with msg: SocketMessage) -> FZMMessageBaseVM {
        if let vm = vmList[msg.msgId] {
            vm.update(with: msg)
            return vm
        }
        if let vm = vmList[msg.sendMsgId] {
            vm.update(with: msg)
            return vm
        }
        let vm = FZMMessageBaseVM.constructVM(with:msg)
        vmList[vm.msgId] = vm
        return vm
    }
    
}


extension FZMConversationChatVC: CellActionProtocol {
    func openTransfer(msgId: String) {
        guard let msg = self.getMessage(with: msgId) else { return }
        self.goTradeDetail(msg: msg)
        
        //self.admire(msgId: msgId)
    }
    
    func openReceipt(msgId: String) {
        
    }
    
    func clickReceipyNotifyCell(msgId: String, logId: String, recordId: String) {
        if let msg = self.getMessage(with: logId)  {
            self.goTradeDetail(msg: msg)
        } else if let msg = self.getDMMessage(with: logId) {
            self.goTradeDetail(msg: msg)
        }
    }
    
    func clickReceiveRedBagNotifyCell(owner: String, operator: String, packetId: String) {
        self.goToRedBagInfoVC(with: packetId)
    }
    
    
    func openFile(msgId: String, filePath: String, fileName:String) {
        let filePath = FZMLocalFileClient.shared().getFilePath(with: .file(fileName: filePath.lastPathComponent()))
        self.previewDocument(url:URL.init(fileURLWithPath: filePath),name: fileName)
       
        //self.admire(msgId: msgId)
    }
    
    func playVideo(msgId: String, videlPath: String) {
        let playerVC = FZMVideoPlayerController.init(videoPath: FZMLocalFileClient.shared().getFilePath(with: .video(fileName: (videlPath as NSString).lastPathComponent)))
        self.present(playerVC, animated: true, completion: nil)
        
        //self.admire(msgId: msgId)
    }
    
    func forwardSelectMessage(msgId: String) -> Bool {
        guard let msg = self.getMessage(with: msgId) else { return false }
        let vm = self.getVM(with: msg)
        guard self.selectMsgVMArr.count < 50 || vm.selected else {
            let alert = FZMAlertView.init(onlyAlert: "最多选择50条消息", confirmBlock: nil)
            alert.show()
            return false
        }
        if vm.selected {
            vm.selected = false
            self.selectMsgVMArr.remove(at: vm)
        }else {
            vm.selected = true
            self.selectMsgVMArr.append(vm)
        }
        return vm.selected
    }
    
    func forwardMessageDetail(msgId: String) {
        guard !showSelect else { return }
        guard let msg = self.getMessage(with: msgId) else { return }
        let vc = FZMForwardMsgListVC(with: msg)
        self.navigationController?.pushViewController(vc, animated: true)
        
        //self.admire(msgId: msgId)
    }
    
    func clickUserHeadImage(userId: String) {
        guard !showSelect else { return }
        FZMUIMediator.shared().pushVC(.friendInfo(friendId: userId, groupId: conversation.type == .person ? nil : conversation.conversationId, source: conversation.type == .person ? nil : .group(groupId: conversation.conversationId)))
    }
    
    func playVoice(msgId: String) {
        guard !showSelect else { return }
        guard let msg = self.getMessage(with: msgId) else { return }
        msg.body.isRead = true
        msg.snapTime = 0
        msg.save()
        self.reloadMsg(with: msg)
        
        //self.admire(msgId: msgId)
    }
    
    private func getMessage(with msgId: String) -> SocketMessage? {
        var selectMsg : SocketMessage?
        messageList.forEach { (msg) in
            if msg.msgId == msgId || msg.sendMsgId == msgId {
                selectMsg = msg
            }
        }
        if !bottomUnReadMessageList.isEmpty, selectMsg == nil {
            bottomUnReadMessageList.forEach { (msg) in
                if msg.msgId == msgId || msg.sendMsgId == msgId {
                    selectMsg = msg
                }
            }
        }
        return selectMsg
    }
    
    private func getDMMessage(with msgId: String) -> SocketMessage? {
        return SocketMessage.getMsg(with: self.conversation.type, msgId: msgId)
    }
    
    func browserImage(from imageView: UIImageView, msgId: String) {
        guard !showSelect else { return }
        guard let msg = self.getMessage(with: msgId) else { return }
        if msg.snap == .open {
            self.present(FZMPhotoBrowser.init(burnBrowserWith: msg, from: imageView), animated: true, completion: nil)
            
        } else {
            self.present(FZMPhotoBrowser.init(msg: msg, conversation: conversation, from: imageView), animated: true, completion: nil)
        }
        
        //self.admire(msgId: msgId)
    }
    
    func clickLuckyPacket(msgId: String) {
        
    }
    
    private func goToRedBagInfoVC(with packetId:String){
        
    }
    
    func reSendMessage(msgId: String) {
        guard let msg = self.getMessage(with: msgId) else { return }
        if msg.status == .failed {
            msg.status = .sending
            conversation.lastMsg = msg
            self.reloadMsg(with: msg)
            SocketChatManager.shared().sendMessage(with: msg)
        }
    }
    
    func longTapOnHeaderImageView(msgId: String) {
        guard !self.inputBar.isBurnAfterRead, self.conversation.type == .group, let msg = self.getMessage(with: msgId), msg.direction == .receive else { return }
        let uid = msg.fromId
        IMContactManager.shared().getUsernameAndAvatar(with: uid, groupId: self.conversation.type == .group ? self.conversation.conversationId : nil) { (_, name, _) in
            let atItem = FZMInputAtItem.init(uid: uid, name: name)
            self.inputBar.addAt(atItem)
        }
    }
    
    func showMenu(in targetView: UIView, msgId: String) {
        guard !showSelect else { return }
        guard let msg = self.getMessage(with: msgId), let window = UIApplication.shared.keyWindow,msg.status == .succeed else { return }
        
        self.view.endEditing(true)
        var itemArr = [FZMMenuItem]()
        
        let cancelAdmireItem = FZMMenuItem(title: "取消点赞", block: {[weak self] in
            self?.admire(msg: msg, isAdmire: false)
        })
        let admireItem = FZMMenuItem(title: "点赞", block: {[weak self] in
            self?.admire(msg: msg, isAdmire: true)
        })
        let rewardItem = FZMMenuItem(title: "打赏", block: {[weak self] in
            self?.reward(msg: msg)
        })
        
        let pasteItem = FZMMenuItem(title: "复制", block: {
            if (msg.msgType == .redBag && msg.body.isTextPacket) {
                UIPasteboard.general.string = msg.body.remark
            } else {
                UIPasteboard.general.string = msg.body.content
            }
        })
        let seeItem = FZMMenuItem(title: "查看资料", block: {
            FZMUIMediator.shared().pushVC(.friendInfo(friendId: msg.fromId, groupId: self.conversation.type == .person ? nil : self.conversation.conversationId, source: self.conversation.type == .person ? nil : .group(groupId: self.conversation.conversationId)))
        })
        let revokeItem = FZMMenuItem(title: "撤回", block: {
            self.showProgress()
            IMConversationManager.shared().revokeMessage(msgId: msgId, channelType: msg.channelType, completionBlock: { (response) in
                self.hideProgress()
                guard response.success else {
                    self.showToast(with: response.message)
                    return
                }
            })
        })
        let forbidChat = FZMMenuItem(title: "禁言", block: {
            if msg.channelType == .group {
                let view = FZMCtrlUserAlertView(with: msg.fromId, groupId: msg.conversationId)
                view.show()
            }
        })
        let voiceItem = FZMMenuItem(title: VoiceMessagePlayerManager.shared().playMode ? "扬声器" : "听筒") {
            VoiceMessagePlayerManager.shared().exchangePlayMode()
            self.showToast(with: "已切换为\(VoiceMessagePlayerManager.shared().playMode ? "听筒" : "扬声器")播放")
        }
        let forwardItem = FZMMenuItem(title: "转发") {
            self.forwardMsg(msg: msg)
        }
        let moreSelectItem = FZMMenuItem(title: "多选") {
            let vm = self.getVM(with: msg)
            vm.selected = true
            self.showSelect = true
            self.selectMsgVMArr.append(vm)
        }
        let shareItem = FZMMenuItem(title: "分享") {
            self.shareMsg(msg: msg)
        }
        let deleteItem = FZMMenuItem(title: "删除") {
            let alert = FZMAlertView(with: "确认删除？", confirmBlock: {
                msg.delete()
                self.deleteMsg(with: msg)
            })
            alert.show()
        }
        if (msg.direction == .receive)
            && (msg.snap == .none)
            && (msg.msgType == .text
                || msg.msgType == .image
                || msg.msgType == .audio
                || msg.msgType == .video
                || msg.msgType == .file
                || msg.body.forwardType == .detail
                || msg.body.forwardType == .merge
                || msg.msgType == .redBag
                || msg.msgType == .receipt
                || msg.msgType == .transfer) {
            if msg.upvote.stateForMe == .admire || msg.upvote.stateForMe == .admireReward {
//                itemArr.append(cancelAdmireItem)
            } else {
               itemArr.append(admireItem)
            }
            if IMSDK.shared().showWallet {
                itemArr.append(rewardItem)
            }
        }
        if (msg.msgType == .text && msg.snap == .none) || msg.msgType == .system || (msg.msgType == .redBag && msg.body.isTextPacket) {
            itemArr.append(pasteItem)
        }
        if msg.msgType == .audio {
            itemArr.append(voiceItem)
        }
        if msg.direction == .receive && !(msg.msgType == .notify || msg.msgType == .system) {
            itemArr.append(seeItem)
        }else {
            let timeDifference = abs(msg.datetime - Date.timestamp)
            if timeDifference <= 600000 && msg.msgType != .redBag {
                itemArr.append(revokeItem)
            }
        }
        if msg.snap == .none {
            if msg.msgType != .audio && msg.msgType != .forward && msg.msgType != .receipt && msg.msgType != .transfer {
                itemArr.append(forwardItem)
            }
            itemArr.append(moreSelectItem)
        }
        if msg.snap == .none && (msg.msgType == .text || msg.msgType == .image) {
            if IMSDK.shared().showShare {
                itemArr.append(shareItem)
            }
        }
        itemArr.append(deleteItem)
        VoiceMessagePlayerManager.shared().vibrateAction()
        if conversation.type == .group {
            IMConversationManager.shared().getGroup(with: conversation.conversationId) { (model) in
                if (model.isMaster || model.isManager) && msg.msgType != .redBag {
                    if !itemArr.contains(revokeItem) {
                        itemArr.append(revokeItem)
                    }
                    if msg.direction == .receive {
                        IMContactManager.shared().requestUserGroupInfo(userId: msg.fromId, groupId: self.conversation.conversationId, completionBlock: { (userGroupInfo, _, _) in
                            guard let userGroupInfo = userGroupInfo else { return }
                            if userGroupInfo.memberLevel == .normal {
                                itemArr.append(forbidChat)
                            }
                        })
                    }
                }
                if itemArr.count > 0 {
                    let fixedRect = targetView.superview!.convert(targetView.frame, to: window)
                    let view = FZMMenuView(with: itemArr)
                    if msg.msgType == .text || msg.msgType == .audio {
                        if let targetView = targetView as? UIImageView {
                            let inset = UIEdgeInsets.init(top: 30, left: 30, bottom: 30, right: 30)
                            targetView.image = msg.direction == .send ? GetBundleImage("message_text_mine_longpress")?.resizableImage(withCapInsets: inset, resizingMode: .stretch) : GetBundleImage("message_text_longpress")?.resizableImage(withCapInsets: inset, resizingMode: .stretch)
                            view.hideBlock = {
                                targetView.image = msg.direction == .send ? GetBundleImage("message_text_mine")?.resizableImage(withCapInsets: inset, resizingMode: .stretch) : GetBundleImage("message_text")?.resizableImage(withCapInsets: inset, resizingMode: .stretch)
                            }
                        }
                    }
                    view.show(in: CGPoint(x: fixedRect.minX, y: fixedRect.midY))
                }
            }
        }else {
            if itemArr.count > 0 {
                let fixedRect = targetView.superview!.convert(targetView.frame, to: window)
                let view = FZMMenuView(with: itemArr)
                if msg.msgType == .text || msg.msgType == .audio {
                    if let targetView = targetView as? UIImageView {
                        let inset = UIEdgeInsets.init(top: 30, left: 30, bottom: 30, right: 30)
                        targetView.image = msg.direction == .send ? GetBundleImage("message_text_mine_longpress")?.resizableImage(withCapInsets: inset, resizingMode: .stretch) : GetBundleImage("message_text_longpress")?.resizableImage(withCapInsets: inset, resizingMode: .stretch)
                        view.hideBlock = {
                            targetView.image = msg.direction == .send ? GetBundleImage("message_text_mine")?.resizableImage(withCapInsets: inset, resizingMode: .stretch) : GetBundleImage("message_text")?.resizableImage(withCapInsets: inset, resizingMode: .stretch)
                        }
                    }
                }
                view.show(in: CGPoint(x: fixedRect.minX, y: fixedRect.midY))
            }
        }
    }
    
    func burnAfterMessage(msgId: String) {
        guard let msg = self.getMessage(with: msgId) else { return }
        self.showProgress()
        msg.burnAfterRead { (response) in
            self.hideProgress()
            guard response.success else {
                self.showToast(with: response.message)
                return
            }
            if msg.msgType == .audio {
                msg.body.isRead = true
                msg.save()
                VoiceMessagePlayerManager.shared().playVoice(msg:msg)
            }
            self.reloadMsg(with: msg)
        }
    }
    
    func shouldBurnData(msgId: String) {
        guard let msg = self.getMessage(with: msgId), msg.snap == .open else { return }
        if msg.msgType == .image, msg.snapTime > 0 {
            return
        }
        msg.burnConfigure()
        self.reloadMsg(with: msg)
    }
    
    
    func decryptFailedCellClick(msgId: String) {
//        FZMUIMediator.shared().pushVC(.goImportSeed(isHideBackBtn: false))
    }
    
    func inviteGroupCellClick(msgId: String, inviterId: String, inviteGroupId: String, inviteMarkId: String) {
        self.showProgress()
        HttpConnect.shared().isInGroup(groupId: inviteGroupId) { (isInGroup, response) in
            guard let isInGroup = isInGroup, response.success else {
                self.showToast(with: response.message)
                return
            }
            if isInGroup {
                self.hideProgress()
                FZMUIMediator.shared().pushVC(.goChat(chatId: inviteGroupId, type: .group))
            }else {
                HttpConnect.shared().searchContact(searchId: inviteMarkId) { (list, response) in
                    guard response.success, let model = list.first else {
                        UIApplication.shared.keyWindow?.showToast(with: "信息不存在")
                        return
                    }
                    self.hideProgress()
                    FZMUIMediator.shared().pushVC(.groupInfo(data: model, type: .invite(inviterId: inviterId)))
                }
            }
        }
    }
    
    
    func admireInfoTap(msgId: String) {
        
    }
    
    func textTapAdmire(msgId: String) {
        self.admire(msgId: msgId)
    }
    
    func textTapReward(msgId: String) {
        guard let msg = self.getMessage(with: msgId)else { return }
        self.reward(msg: msg)
    }
    
}


extension FZMConversationChatVC {

    func goTradeDetail(msg: SocketMessage) {
        
    }
    
    func getAbsolutelyRecordId(msg: SocketMessage) -> String? {
        guard msg.body.recordId.count != 0 else { return nil }
        let recordIds = msg.body.recordId.split(separator: ",")
        if let first = recordIds.first, let last = recordIds.last {
            let fromRecordId = String.init(first)
            let toRecordId = String.init(last)
            if msg.msgType == .receipt {
                return msg.direction == .receive ? fromRecordId : toRecordId
            }
            if msg.msgType == .transfer {
                return msg.direction == .send ? fromRecordId : toRecordId
            }
        }
        return nil
    }
}


extension FZMConversationChatVC: MoreItemClickDelegate{
    func sendPhoto() {
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
    
    func goCamera() {
        FZMUIMediator.shared().pushVC(.camera(allowEditing: false, selectBlock: { (list,_) in
            guard let image = list.first else { return }
            self.sendImageMsg(with: image)
        }))
    }
    
    func sendRedBag() {
        
    }
    
    func sendRedBagMsg() {
        
    }
    
    func burnCtrl() {
        self.endBottomBarEditing()
        FZM_UserDefaults.setConversationInputValue(true, conversation: conversation)
        inputBar.isBurnAfterRead = true
    }
    
    func sendFile() {
        FZMUIMediator.shared().pushVC(.icloudPicker { (fileUrls) in
            for url in fileUrls {
                self.sendFileMsg(fileURL: url)
            }
        })
    }
    
    func transfer() {
        
    }
    
    func receipt() {
        
        
    }
    
    func admire(msgId: String) {
        guard let msg = self.getMessage(with: msgId), msg.snap == .none else { return }
        if msg.upvote.stateForMe == .admire || msg.upvote.stateForMe == .admireReward {
            //            self.admire(msg: msg, isAdmire: false)
        } else {
            self.admire(msg: msg, isAdmire: true)
        }
    }
    
    func admire(msg: SocketMessage, isAdmire: Bool) {
        guard msg.fromId != IMLoginUser.shared().userId else { return }
        let vm = self.getVM(with: msg)
        vm.isShowUpvoteAnimation = true
        msg.upvoteUpdate(operatorId: IMLoginUser.shared().userId, action: isAdmire ? .admire : .cancelAdmire, admire: isAdmire ? msg.upvote.admire + 1 : msg.upvote.admire - 1 , reward: msg.upvote.reward)
        HttpConnect.shared().like(channelType: self.conversation.type, logId: msg.msgId, isLike: isAdmire) { (response) in
        }
    }
    
    func reward(msg: SocketMessage) {
        
    }
}



//MARK: 获取历史消息记录
extension FZMConversationChatVC {
    
    func loadAllUnreadMessage(count:Int, compeletionBlock:@escaping NormalBlock) {
        if self.messageList.count >= count {
            compeletionBlock()
        } else {
            IMConversationManager.shared().loadHistoryMessage(conversationId: conversation.conversationId, type: conversation.type, lastMessage: nil, count: count)  { (list) in
                self.refreshListLock.lock()
                self.messageList.removeAll()
                self.conversation.lastMsg = self.messageList.first
                self.messageList = list
                self.refreshListLock.unlock()
                self.reloadList(completionBlock: {
                    compeletionBlock()
                })
            }
        }
    }
    
    func loadMore() {
        if let locationMsgId = self.locationMsg?.0, !locationMsgId.isEmpty, self.messageList.isEmpty {
            //从搜索来的聊天记录定位
            IMConversationManager.shared().loadLocationMsg(msgId: locationMsgId, conversationId: conversation.conversationId, type: conversation.type) { (list) in
                self.locationMsg = nil //暂时不需要对搜索的文字jx进行高亮, self.locationMsg?.1 不使用
                self.refreshListLock.lock()
                self.messageList += list
                self.conversation.lastMsg = self.messageList.first
                self.refreshListLock.unlock()
                self.reloadList {
                    if let locationMsg = self.getMessage(with: locationMsgId), let locationMsgIndex = self.messageList.index(of: locationMsg) {
                        self.refreshListLock.lock()
                        let indexPath = IndexPath(item: locationMsgIndex, section: 0)
                        self.messageListView.scrollToRow(at: indexPath, at: .bottom, animated: false)
                        self.refreshListLock.unlock()
                    }
                }
            }
        } else {
            IMConversationManager.shared().loadHistoryMessage(conversationId: conversation.conversationId, type: conversation.type, lastMessage: messageList.last) { (list) in
                self.messageListView.mj_footer.endRefreshing()
                self.messageListView.mj_footer.isHidden = list.count == 0

                self.refreshListLock.lock()
                self.messageList += list
                self.conversation.lastMsg = self.messageList.first
                self.refreshListLock.unlock()
                self.reloadList()
            }
        }
    }
}

//MARK: 消息在插入数组前进行加工 #弃用
extension FZMConversationChatVC {
    //历史消息加工
    fileprivate func makeHistoryMessage(messages:[SocketMessage]){
        let _ = messages.reduce([SocketMessage]()) {
            if let lastMsg = lastShowTimeMessage {
                let timeDifference = abs(lastMsg.datetime - $1.datetime)
                if timeDifference > 600000 {
                    self.lastShowTimeMessage = $1
                    $0.last?.showTime = true
                }
            }else {
                let timeDifference = abs(messages.first!.datetime - $1.datetime)
                if timeDifference > 600000 {
                    self.lastShowTimeMessage = $1
                    $0.last?.showTime = true
                    if self.firstShowTimeMessage == nil {
                        self.firstShowTimeMessage = $0.last
                    }
                }
            }
            if $1 == messages.last {
                self.lastShowTimeMessage = $1
                $1.showTime = true
                if self.firstShowTimeMessage == nil {
                    self.firstShowTimeMessage = $1
                }
            }
            $1.save()
            return $0 + [$1]
        }
    }
    //新增消息加工
    fileprivate func makeInsertNewMessage(_ message : SocketMessage){
        if let firstMsg = firstShowTimeMessage {
            let timeDifference = abs(firstMsg.datetime - message.datetime)
            if timeDifference > 600000 {
                self.firstShowTimeMessage = message
                message.showTime = true
                message.save()
            }
        }else{
            firstShowTimeMessage = message
            message.showTime = true
            message.save()
        }
    }
}

//MARK: 转发消息
extension FZMConversationChatVC {
    private func forwardMsg(msg: SocketMessage) {
        if self.isEncrypt {
            let newMsg = msg.forwardMsg()
            newMsg.body.forwardType = .detail
            newMsg.body.forwardChannelType = newMsg.channelType
            newMsg.body.forwardFromName = self.conversation.name
            FZMUIMediator.shared().pushVC(.multipleSend(msg: newMsg))
        } else {
            self.selectContact { (roomIds, userIds) in
                self.showProgress()
                HttpConnect.shared().forwardMsgs(sourceId: self.conversation.conversationId, type: self.conversation.type == .group ? 1 : 2, forwardType: 1, msgIds: [msg.msgId], targetRooms: roomIds, targetUsers: userIds, completionBlock: { (response) in
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
                })
            }
        }        
    }
    
    
    private func shareMsg(msg:SocketMessage) {
        if msg.msgType == .text {
            IMSDK.shared().shareDelegate?.share(text: msg.body.content, platment: .wxFriend)
            return
        }
        if msg.msgType == .image {
            imageLoadTool.loadNetworkImage(with: msg.body.imageUrl, placeImage: nil) { (image) in
                guard let image = image else {return}
                IMSDK.shared().shareDelegate?.share(image: image, platment: .wxFriend)

            }
        }
    }
    
    private func forwardMsgList(_ isAll: Bool) {
        if IMSDK.shared().isEncyptChat {
            let forwordMsgs = self.selectMsgVMArr.filter { $0.selected == true}.compactMap { $0.message.copyMsg()}
            self.selectContact { (roomIds, userIds) in
                self.showProgress()
                SocketMessage.encyptForwordMsg(type: isAll ? .merge : .detail, roomIds: roomIds, userIds: userIds, forwordMsgs: forwordMsgs, forwardFromName: (self.conversation.type == .group ? self.group?.name : self.user?.name) ?? "", compeletionBlock: { (dic) in
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
                            self.cancelSelect()
                        })
                    } else {
                        self.hideProgress()
                    }
                })
            }
            
        } else {
            var msgIds = [String]()
            self.selectMsgVMArr.forEach { (vm) in
                if vm.selected {
                    msgIds.append(vm.msgId)
                }
            }
            self.selectContact { (roomIds, userIds) in
                self.showProgress()
                HttpConnect.shared().forwardMsgs(sourceId: self.conversation.conversationId, type: self.conversation.type == .group ? 1 : 2, forwardType: isAll ? 2 : 1, msgIds: msgIds, targetRooms: roomIds, targetUsers: userIds, completionBlock: { (response) in
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
                    self.cancelSelect()
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
    
    //删除选中消息
    private func deleteSelectMsgs() {
        let msgs = vmList.values.compactMap { (vm) -> SocketMessage? in
            if vm.selected {
                return self.getMessage(with: vm.msgId)
            }
            return nil
        }
        guard msgs.count > 0 else { return }
        self.refreshListLock.lock()
        let indexPaths = msgs.compactMap { (msg) -> IndexPath? in
            if let index = self.messageList.index(of: msg) {
                return IndexPath(row: index, section: 0)
            }
            return nil
        }
        self.messageList = self.messageList.filter({ (msg) -> Bool in
            return !msgs.contains(msg)
        })
        msgs.forEach { (msg) in
            msg.delete()
        }
        self.messageListView.deleteRows(at: indexPaths, with: .fade)
        self.cancelSelect()
        self.refreshListLock.unlock()
    }
}

//MARK: 发消息
extension FZMConversationChatVC {
    func sendTextMsg(with text: String, isSystem: Bool, isBurn: Bool, atUids: [String]?) {
        let msg = isSystem ? SocketMessage(systemText: text, from: IMLoginUser.shared().userId, to: self.conversation.conversationId, channelType: self.conversation.type, isEncryptMsg:self.isEncrypt) : SocketMessage(text: text, from: IMLoginUser.shared().userId, to: self.conversation.conversationId, channelType: self.conversation.type, isBurn: isBurn, isEncryptMsg:self.isEncrypt)
        if let atUids = atUids, !atUids.isEmpty {
            msg.body.aitList = atUids
        }
        self.sendMsg(msg:msg)
    }
    
    func sendVideoMsg(firstFrameImg:UIImage, asset: PHAsset,isBurn: Bool = false) {
        if #available(iOS 9.0, *) {
            guard let size = (PHAssetResource.assetResources(for: asset).first?.value(forKey: "fileSize") as? Int), (size / 1024 / 1024) < 100 else {
                self.showToast(with: "视频不能大于100M")
                return
            }
        }
        let msg = SocketMessage(firstFrameImg: firstFrameImg, asset: asset, filePath: "", from: IMLoginUser.shared().userId, to: self.conversation.conversationId, channelType: self.conversation.type, isBurn: isBurn, isEncryptMsg:self.isEncrypt)
        self.sendMsg(msg:msg)
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
                    let msg = SocketMessage.init(filePath: filePath, fileSize: data.count, from: IMLoginUser.shared().userId, to: self.conversation.conversationId, channelType: self.conversation.type,isBurn: false, isEncryptMsg:self.isEncrypt)
                    self.sendMsg(msg:msg)
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
            let msg = SocketMessage(image: image, filePath: savePath.formatFileName(), from: IMLoginUser.shared().userId, to: self.conversation.conversationId, channelType: self.conversation.type, isBurn: isBurn, isEncryptMsg:self.isEncrypt)
            self.sendMsg(msg:msg)
            return
        }
    }
    
    func sendAudioMsg(amrPath: String, wavPath: String, duration: Double, isBurn: Bool) {
        let msg = SocketMessage(amrPath: amrPath.formatFileName(), wavPath: wavPath.formatFileName(), duration: duration, from: IMLoginUser.shared().userId, to: self.conversation.conversationId, channelType: self.conversation.type, isBurn: isBurn, isEncryptMsg:self.isEncrypt)
        self.sendMsg(msg:msg)
    }
    
    func sendRedBagMsg(coin: Int, coinName: String, packetType: IMRedPacketType, packetId: String, packetUrl: String, remark: String, isTextRedBag: Bool) {
        let msg = SocketMessage(coin: coin, coinName: coinName, packetType: packetType,packetId: packetId, remark: remark, packetUrl: packetUrl, from: IMLoginUser.shared().userId, to: self.conversation.conversationId, channelType: self.conversation.type, isEncryptMsg:self.isEncrypt, isTextRedBag: isTextRedBag)
        self.sendMsg(msg:msg)
    }
    
    func sendTransferMsg(currency: String,amount: String,recordId: String) {
        guard currency.count > 0, amount.count > 0, recordId.count > 0, let amount = Double(amount) else { return }
        
        let msg = SocketMessage.init(transferCoinName: currency, amount: amount, recordId: recordId, from: IMLoginUser.shared().userId, to: self.conversation.conversationId, isEncryptMsg:self.isEncrypt)
        self.sendMsg(msg:msg)
    }
    
    func sendReceiptMsg(currency: String,amount: String) {
        guard currency.count > 0, amount.count > 0, let amount = Double(amount) else { return }
        let msg = SocketMessage.init(receiptCoinName: currency, amount: amount, recordId: "", from: IMLoginUser.shared().userId, to: self.conversation.conversationId, isEncryptMsg:self.isEncrypt)
        self.sendMsg(msg:msg)
    }
    
    
    func insertMsg(with msg: SocketMessage) {
        DispatchQueue.main.async {
            SocketChatManager.shared().configureMsgShowTime(msg: msg)
            self.conversation.lastMsg = msg
            self.refreshListLock.lock()
            if self.messageListView.contentOffset.y > 0 {
                if msg.msgType != .notify {
                    self.bottomUnreadCount += 1
                }
                self.bottomUnReadMessageList.insert(msg, at: 0)
                self.showBottomUnreadBtn()
            } else {
                self.messageList.insert(msg, at: 0)
                self.messageListView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
            }
            if msg.msgType == .notify, let type = msg.body.notifyEvent {
                switch type {
                case .quitGroup, .joinGroup, .removeGroup, .beGroupMaster, .beGroupManager:
                    self.refreshGroupInfo()
                default: break
                }
            }
            self.refreshListLock.unlock()
        }
    }
    
    func deleteMsg(with msg: SocketMessage, animation: UITableView.RowAnimation = .fade) {
        DispatchQueue.main.async {
            self.refreshListLock.lock()
            if let index = self.messageList.index(of: msg) {
                self.messageList.remove(at: index)
                self.messageListView.reloadData()
            } else if let index = self.bottomUnReadMessageList.index(of: msg) {
                self.bottomUnReadMessageList.remove(at: index)
            }
            self.refreshListLock.unlock()
        }
    }
    
    func reloadMsg(with msg: SocketMessage) {
        DispatchQueue.main.async {
            self.refreshListLock.lock()
            if let index = self.messageList.index(of: msg) {
                self.messageListView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
            }
            self.refreshListLock.unlock()
        }
    }
    
    func reloadList(completionBlock:NormalBlock? = nil) {
        DispatchQueue.main.async {
            self.refreshListLock.lock()
            self.messageListView.reloadData()
            self.refreshListLock.unlock()
            completionBlock?()
        }
    }
    
}

extension FZMConversationChatVC {
    
    func sendMsg(msg: SocketMessage) {
        self.hideBottomUnreadBtn()
        if self.messageListView.contentOffset.y > 0 {
            messageListView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        }
        
        if self.isEncrypt &&
        ((IMLoginUser.shared().currentUser?.privateKey.isEmpty ?? true) ||  (IMLoginUser.shared().currentUser?.publicKey.isEmpty ?? true)) {
            self.endBottomBarEditing()
            self.view.endEditing(true)
            let alert = FZMAlertView.init(attributedTitle: NSAttributedString.init(string:"提示"), attributedText: NSAttributedString.init(string: "你尚未设置密聊私钥，无法发送加密消息，请先设置密聊私钥。", attributes: [NSAttributedString.Key.foregroundColor: FZM_BlackWordColor]), btnTitle: "设置") {
                FZMUIMediator.shared().pushVC(.goImportSeed(isHideBackBtn: false))
            }
            alert.show()
            return
        }
        self.insertMsg(with: msg)
        SocketChatManager.shared().sendMessage(with: msg)
    }
}


//MARK: 接收消息
extension FZMConversationChatVC: SocketConnectDelegate {
    func socketConnect() {
        self.navigationItem.titleView = self.navTitleView
    }
    func socketDisConnect() {
        self.navigationItem.titleView = UILabel.getLab(font: UIFont.boldSystemFont(ofSize: 17), textColor: FZM_TitleColor, textAlignment: .center, text: "连接中...")
    }
    func refreshNavigationTitle() {
        if conversation.type == .group {
            IMConversationManager.shared().getGroup(with: conversation.conversationId) { (group) in
                self.titleLab.text = group.showName + "(\(group.memberNumber))"
            }
        }else {
            self.titleLab.text = conversation.name
        }
    }
}

extension FZMConversationChatVC: SocketChatMsgDelegate {
    
    func failSendMessage(with msg: SocketMessage) {
        if conversation.type == msg.channelType && conversation.conversationId == msg.conversationId {
            self.refreshMessageInfo(msgId: msg.useId)
        }
    }
    
    func receiveMessage(with msg: SocketMessage, isLocal: Bool) {
        if msg.msgType == .notify, case .msgUpvoteUpdate(_, let operatorId, let action, let logId, let admire, let reward) = msg.body.notifyEvent {
            let needUpdateMsg = self.getMessage(with: logId)
            needUpdateMsg?.upvoteUpdate(operatorId: operatorId, action: action, admire: admire, reward: reward)
            return
        }
        if conversation.type == msg.channelType && conversation.conversationId == msg.conversationId {
            if isLocal {
                self.refreshMessageInfo(msgId: msg.msgId)
            }else {
                self.insertMsg(with: msg)
            }
            if msg.msgType == .notify, let notifyEvent = msg.body.notifyEvent {
                if case .revokeMsg(_,let revokeId) = notifyEvent {
                    if let revokeMsg = self.getMessage(with: revokeId) {
                        self.deleteMsg(with: revokeMsg)
                    }
                }else if case .groupBanned(_, let type) = notifyEvent {
                    if type == .all {
                        self.inputBar.bannedCtrl(with: 0)
                    }
                } else if case .receoptSuceess(_,let logId, let recordId) = notifyEvent {
                    if let needUpdateMsg = self.getMessage(with: logId) {
                        needUpdateMsg.body.recordId = recordId
                        self.reloadMsg(with: needUpdateMsg)
                    }
                }
            }
            if msg.msgType == .system {
                msg.body.isRead = true
                msg.save()
            }
        }
    }
    
    func receiveHistoryMsgList(with msgs: [SocketMessage], isUnread: Bool) {
        guard self.activityIndicatorView.isHidden else { return }
        let lossMsgs = msgs.filter { $0.conversationId == self.conversation.conversationId && $0.channelType == self.conversation.type
            }.filter { (msg) -> Bool in
                if msg.msgType == .notify, case .msgUpvoteUpdate(_, let operatorId, let action, let logId, let admire, let reward) = msg.body.notifyEvent {
                    let needUpdateMsg = self.getMessage(with: logId)
                    needUpdateMsg?.upvoteUpdate(operatorId: operatorId, action: action, admire: admire, reward: reward)
                    return false
                } else if let localMsg = self.getMessage(with: msg.useId) {
                    self.reloadMsg(with: localMsg)
                    return false
                } else {
                    return msg.datetime > (self.messageList.last?.datetime ?? 0) ? true :false
                }
        }
        guard !lossMsgs.isEmpty else { return }
        self.refreshListLock.lock()
        self.messageList = lossMsgs + self.messageList
        self.refreshListLock.unlock()
        self.reloadList()
    }
    
    func refreshMessageInfo(msgId: String) {
        guard let message = self.getMessage(with: msgId) else { return }
        let _ = self.getVM(with: message)
    }
}

extension FZMConversationChatVC: UserGroupBannedChangeDelegate {
    func groupBanned(groupId: String, type: Int, deadline: Double) {
        if conversation.type == .group && conversation.conversationId == groupId {
            IMConversationManager.shared().requestBannedInfo(userId: IMLoginUser.shared().userId, groupId: self.conversation.conversationId) { (banned, distance) in
                self.inputBar.bannedCtrl(with: distance)
            }
        }
    }
}

extension FZMConversationChatVC: BurnAfterReadDelegate {
    func burnMessage(_ msg: SocketMessage) {
        if msg.conversationId == conversation.conversationId && msg.channelType == conversation.type {
            guard let message = self.getMessage(with: msg.msgId) else { return }
            self.deleteMsg(with: message, animation: message.direction == .send ? .right : .left)
        }
    }
}

extension FZMConversationChatVC {
    @objc func fileVCUploadFileNotify(notification:NSNotification) {
        if let userInfor = notification.userInfo as? Dictionary<String, SocketMessage>,
            let msg = userInfor["msg"] {
            self.insertMsg(with: msg)
        }
    }
    
    @objc func bannedGroup(notification: NSNotification) {
        guard self.conversation.type == .group else { return }
        if let roomId = notification.userInfo?["roomId"] as? String,
            let disableDeadline = notification.userInfo?["disableDeadline"] as? Int,
            conversation.conversationId == roomId  {
            self.view.endEditing(true)
            var content = ""
            let forever: Int64 = 7258089600000
            if disableDeadline == forever {
                content = "该群聊已被永久查封，如需解封可联系客服：" + FZM_Service
            } else if disableDeadline != 0 {
                let date = Date.init(timeIntervalSince1970: TimeInterval(disableDeadline / 1000))
                let formatter = DateFormatter.init()
                formatter.dateFormat = "yyyy年MM月dd号HH:mm"
                let dateStr = formatter.string(from: date)
                content = "该群聊已被查封至\(dateStr)，如需解封可联系客服：" + FZM_Service
            }
            let alert = FZMAlertView(onlyAlert: content) {
                self.navigationController?.popViewController(animated: true)
            }
            alert.show()
            self.inputBar.showState(.hide)
            self.navigationItem.rightBarButtonItems = nil
        }
    }
}


extension FZMConversationChatVC {
    func addBlankRowItem() {
         let item = UIMenuItem.init(title: "换行", action: #selector(addBlankRow))
         let menuC = UIMenuController.shared
         menuC.menuItems = [item]
    }
    
    func removeBlankRowItem() {
        UIMenuController.shared.menuItems = nil
    }
    
    @objc func addBlankRow() {
        if (UIResponder.fzm_firstResponder() as? UIView) == self.inputBar.textView {
            self.inputBar.addBlankRow()
        }
    }
}
