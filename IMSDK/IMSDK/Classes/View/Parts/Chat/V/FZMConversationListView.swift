//
//  FZMConversationListView.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/26.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift

class FZMConversationListView: FZMScrollPageItemBaseView {

    let disposeBag = DisposeBag()
    var conversationArr = [SocketConversationModel]()
    var selectBlock: ((SocketConversationModel)->())?
    
    
    let topViewHeight: CGFloat = 130
    lazy private var topView: UIView = {
       let v = UIView.init(frame: CGRect.init(x: 0, y: 0, width: ScreenWidth, height: topViewHeight))
        v.backgroundColor = FZM_BackgroundColor
        if IMSDK.shared().showWallet {
            v.addSubview(centerView)
        }
        return v
    }()
    
    lazy private var centerView: UIView = {
        let v = UIView.init(frame: CGRect.init(x: 0, y: 0, width: ScreenWidth, height: topViewHeight))
        v.backgroundColor = FZM_BackgroundColor
        
        let transfer = FZMImageTitleView.init(headImage: GetBundleImage("chat_transfer"), imageSize: CGSize.init(width: 60, height: 60), title: "转账", titleColor: FZM_BlackWordColor, clickBlock: {[weak self] in
            self?.hideTopView()
            FZMUIMediator.shared().pushVC(.goTransfer(specifiedAddress: nil))
        })
        
        transfer.frame = CGRect.init(x: ScreenWidth * 0.5 - 60 - 15, y: 25, width: 60, height: 96)
        v.addSubview(transfer)
        
        let receive = FZMImageTitleView.init(headImage: GetBundleImage("chat_receive"), imageSize: CGSize.init(width: 60, height: 60), title: "收款", titleColor: FZM_BlackWordColor, clickBlock: {[weak self] in
            self?.hideTopView()
            FZMUIMediator.shared().pushVC(.goReceive)
        })
        receive.frame = CGRect.init(x: ScreenWidth * 0.5 + 15, y: 25, width: 60, height: 96)
        v.addSubview(receive)
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(hideTopView))
        v.addGestureRecognizer(tap)
        
        return v
    }()
    
    lazy var tapControl: UIControl = {
        let v = UIControl.init()
        v.addTarget(self, action: #selector(hideTopView), for: .touchUpInside)
        v.isHidden = true
        return v
    }()
    
    lazy var navBarCoverControl: UIControl = {
        let v = UIControl.init(frame: CGRect.init(x: 0, y: 0, width: ScreenWidth, height: StatusNavigationBarHeight))
        v.addTarget(self, action: #selector(hideTopView), for: .touchUpInside)
        return v
    }()
    
    lazy var tableView : UITableView = {
        let view = UITableView(frame: CGRect.zero, style: .plain)
        view.backgroundColor = FZM_BackgroundColor
        view.tableHeaderView = topView
        view.tableFooterView = UIView(frame: CGRect.zero)
        view.rowHeight = 70
        view.register(FZMConversationCell.self, forCellReuseIdentifier: "FZMConversationCell")
        view.separatorColor = FZM_LineColor
        view.contentInset = UIEdgeInsets.init(top: -topViewHeight, left: 0, bottom: 0, right: 0);
        view.delegate = self
        view.addSubview(tapControl)
        tapControl.snp.makeConstraints({ (m) in
            m.left.equalTo(view)
            m.top.equalTo(view).offset(topViewHeight)
            m.height.equalTo(ScreenHeight)
            m.width.equalTo(ScreenWidth)
        })
        return view
    }()

    override init(with pageTitle: String) {
        super.init(with: pageTitle)
        self.addSubview(tableView)
        tableView.snp.makeConstraints { (m) in
            m.edges.equalToSuperview()
        }
        self.requestData()
    }
    
    func requestData(){
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var isShowTableHeaderView = false
    var topViewIsHidden = true
    @objc func hideTopView() {
        UIView.animate(withDuration: 0.2) {
            self.tableView.contentInset = UIEdgeInsets.init(top: -self.topViewHeight, left: 0, bottom: 0, right: 0)
        }
        self.tapControl.isHidden = true
        topViewIsHidden = true
        self.navBarCoverControl.removeFromSuperview()
        if let scrollView = self.tableView.superview?.superview?.superview as? UIScrollView {
            scrollView.isScrollEnabled = true
        }
    }
    
    func showTopView() {
        self.tableView.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0);
        self.tapControl.isHidden = false
        self.tableView.bringSubviewToFront(self.tapControl)
        UIApplication.shared.keyWindow?.addSubview(self.navBarCoverControl)
        topViewIsHidden = false
        if let scrollView = self.tableView.superview?.superview?.superview as? UIScrollView {
            scrollView.isScrollEnabled = false
        }
        VoiceMessagePlayerManager.shared().vibrateAction()
    }
}

extension FZMConversationListView: UITableViewDelegate {
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard IMSDK.shared().showWallet && isShowTableHeaderView else { return }
        guard scrollView.contentOffset.y < topViewHeight else {return}
        if scrollView.contentOffset.y <= 50 && topViewIsHidden {
            self.showTopView()
        } else {
            if scrollView.contentOffset.y > 10 && !topViewIsHidden {
                self.hideTopView()
            }
        }
    }
}


//MARK: 聊天室
class FZMChatRoomListView: FZMConversationListView {
    override func requestData() {
        IMConversationManager.shared().chatRoomListSubject.bind(to: tableView.rx.items(cellIdentifier: "FZMConversationCell", cellType: FZMConversationCell.self)){ (row, element, cell) in
            cell.configure(with: element)
        }.disposed(by: disposeBag)
        
        tableView.rx.modelSelected(SocketConversationModel.self).subscribe {[weak self] (event) in
            guard case .next(let model) = event else { return }
            guard let strongSelf = self else { return }
            strongSelf.unreadCount -= model.unreadCount
            model.unreadCount = 0
            strongSelf.selectBlock?(model)
        }.disposed(by: disposeBag)

    }
    
}


//MARK: 群聊
class FZMGroupChatListView: FZMConversationListView {
    
    lazy var noDataView : FZMNoDataView = {
        if IMSDK.shared().showPromoteHotGroup {
            return FZMNoDataView.init(image: GetBundleImage("nodata_group_conversation"), imageSize: CGSize(width: 250, height: 260), desText: "暂无群消息", btn1Title: "创建群聊", btn1Image: nil, btn2Title: "热门群聊", btn2Image: GetBundleImage("chat_hot_group"), isVertical: true, btn1ClickBlock: {
                FZMUIMediator.shared().pushVC(.selectFriend(type: .all, completeBlock: nil))
            }, btn2ClickBlock: {
                FZMUIMediator.shared().pushVC(.goPromoteHotGroup)
            })
        } else {
            return FZMNoDataView(image: GetBundleImage("nodata_group_conversation"), imageSize: CGSize(width: 250, height: 260), desText: "暂无群消息", btnTitle: "创建群聊", clickBlock: {
                FZMUIMediator.shared().pushVC(.selectFriend(type: .all, completeBlock: nil))
            })
        }
    }()
    
    override func requestData() {
        self.tableView.addSubview(noDataView)
        noDataView.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview().offset(100)
            m.size.equalTo(CGSize(width: ScreenWidth, height: 415))
        }
        IMConversationManager.shared().groupChatListSubject.subscribe {[weak self] (event) in
            guard case .next(let list) = event else { return }
            self?.noDataView.isHidden = list.count > 0
        }.disposed(by: disposeBag)
        
        IMConversationManager.shared().groupChatListSubject.bind(to: tableView.rx.items(cellIdentifier: "FZMConversationCell", cellType: FZMConversationCell.self)){ (row, element, cell) in
            cell.configure(with: element)
        }.disposed(by: disposeBag)
        
        tableView.rx.modelSelected(SocketConversationModel.self).subscribe {[weak self] (event) in
            guard case .next(let model) = event else { return }
            guard let strongSelf = self else { return }
            strongSelf.unreadCount -= model.unreadCount
            strongSelf.selectBlock?(model)
        }.disposed(by: disposeBag)
        
    }
    
}


//MARK: 私聊
class FZMPrivateChatListView: FZMConversationListView {
    
    lazy var noDataView : FZMNoDataView = {
        return FZMNoDataView(image: GetBundleImage("nodata_person_conversation"), imageSize: CGSize(width: 250, height: 260), desText: "暂无好友消息", btnTitle: "开启聊天", clickBlock: {
            FZMUIMediator.shared().selectConversationNav()
        })
    }()
    
    override func requestData() {
        self.tableView.addSubview(noDataView)
        noDataView.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview().offset(100)
            m.size.equalTo(CGSize(width: ScreenWidth, height: 365))
        }
        IMConversationManager.shared().privateChatListSubject.subscribe {[weak self] (event) in
            guard case .next(let list) = event else { return }
            self?.noDataView.isHidden = list.count > 0
            }.disposed(by: disposeBag)
        
        IMConversationManager.shared().privateChatListSubject.bind(to: tableView.rx.items(cellIdentifier: "FZMConversationCell", cellType: FZMConversationCell.self)){ (row, element, cell) in
            cell.configure(with: element)
        }.disposed(by: disposeBag)

        tableView.rx.modelSelected(SocketConversationModel.self).subscribe {[weak self] (event) in
            guard case .next(let model) = event else { return }
            guard let strongSelf = self else { return }
            strongSelf.unreadCount -= model.unreadCount
            strongSelf.selectBlock?(model)
        }.disposed(by: disposeBag)
        
    }
}


//MARK: 私聊和群聊
class FZMPrivateAndGroupChatListView: FZMConversationListView, UITableViewDataSource {

    lazy var noDataView : FZMNoDataView = {
        return FZMNoDataView(image: GetBundleImage("nodata_person_conversation"), imageSize: CGSize(width: 250, height: 260), desText: "暂无消息", btnTitle: "开启聊天", clickBlock: {
            FZMUIMediator.shared().pushVC(.selectFriend(type: .all, completeBlock: nil))
        })
    }()
    var showSelect = false
    var showGroup = true
    var privateAndGroupChatList = [SocketConversationModel]() {
        didSet {
            if !self.showGroup {
                privateAndGroupChatList = privateAndGroupChatList.filter({$0.type == .person})
            }
        }
    }
    init(with pageTitle: String , showSelect: Bool = false, showGroup: Bool = true) {
        self.showSelect = showSelect
        self.showGroup = showGroup
        super.init(with: pageTitle)
        tableView.tableHeaderView?.isHidden = true
        tableView.register(FZMConversationCell.self, forCellReuseIdentifier: "FZMConversationCell")
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func requestData() {
        self.addSubview(noDataView)
        noDataView.snp.makeConstraints { (m) in
            m.center.equalToSuperview()
            m.size.equalTo(CGSize(width: ScreenWidth, height: 365))
        }
        
        IMConversationManager.shared().privateAndGroupChatListSubject.subscribe {[weak self] (event) in
            guard case .next(let list) = event else { return }
            self?.noDataView.isHidden = list.count > 0
            self?.privateAndGroupChatList = list
            for model in list {
                model.isSelected = false
            }
            self?.tableView.reloadData()
        }.disposed(by: disposeBag)
        
    }
    
    func selectOrDeselect(model:FZMContactViewModel) {
        for i in 0..<privateAndGroupChatList.count {
            if privateAndGroupChatList[i].conversationId == model.contactId {
                privateAndGroupChatList[i].isSelected = model.isSelected
                tableView.reloadRows(at: [IndexPath(item: i, section: 0)], with: .none)
            }
        }
    }
    
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.privateAndGroupChatList.count
    }

     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FZMConversationCell", for: indexPath) as! FZMConversationCell
        let model = self.privateAndGroupChatList[indexPath.row]
        cell.configure(with: model)
        if showSelect {
            cell.showSelect()
            cell.selectStyle = model.isSelected ? .select : .disSelect
        }
        return cell
    }

     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if showSelect {
           let model = self.privateAndGroupChatList[indexPath.row]
           model.isSelected = !model.isSelected
           tableView.reloadRows(at: [indexPath], with: .none)
        }
        self.selectBlock?(self.privateAndGroupChatList[indexPath.row])
    }
    
//    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        return
//    }
}

//MARK: 接收消息处理
extension FZMConversationListView: SocketChatMsgDelegate {
    func receiveMessage(with msg: SocketMessage, isLocal: Bool) {
        self.refreshLastMsg(with: msg)
    }
    
    func failSendMessage(with msg: SocketMessage) {
        self.refreshLastMsg(with: msg)
    }
    
    private func refreshLastMsg(with msg: SocketMessage) {
        if let _ = self as? FZMPrivateChatListView {
            //私聊
            guard msg.channelType == .person else { return }
        }else if let _ = self as? FZMGroupChatListView {
            //群聊
            guard msg.channelType == .group else { return }
        }else if let _ = self as? FZMChatRoomListView {
            //聊天室
            guard msg.channelType == .chatRoom else { return }
        }
        let conversation = SocketConversationModel(msg: msg)
        var oldIndex : Int?
        var unreadCount = 0
        conversationArr.forEach { (model) in
            if model == conversation {
                model.lastMsg = msg
                oldIndex = conversationArr.index(of: model)
                if IMConversationManager.shared().selectConversation != model && msg.direction == .receive {
                    model.unreadCount += 1
                }
                unreadCount += model.unreadCount
            }
        }
        if let useIndex = oldIndex {
            let model = conversationArr[useIndex]
            conversationArr.remove(at: useIndex)
            conversationArr.insert(model, at: 0)
            tableView.moveRow(at: IndexPath(row: useIndex, section: 0), to: IndexPath(row: 0, section: 0))
        }else {
            if IMConversationManager.shared().selectConversation != conversation && msg.direction == .receive {
                conversation.unreadCount += 1
                unreadCount += 1
            }
            conversationArr.insert(conversation, at: 0)
            tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
        }
        self.unreadCount = unreadCount
    }
    
    func receiveHistoryMsgList(with msgs: [SocketMessage], isUnread: Bool) {
        
    }
    
}

