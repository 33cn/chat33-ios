//
//  FZMChatHomeVC.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/21.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift
class FZMChatHomeVC: FZMBaseViewController {
    
    var groupUnreadCount = 0 {
        didSet{
            groupHeader.setBadge(groupUnreadCount)
        }
    }
    
    var privateUnreadCount = 0 {
        didSet{
            privateHeader.setBadge(privateUnreadCount)
        }
    }
    
    private lazy var activityIndicatorView: FZMActivityIndicatorView = {
        let v = FZMActivityIndicatorView.init(frame: CGRect.zero, title: "收取中...")
        v.isHidden = true
        v.backgroundColor = FZM_BackgroundColor
        return v
    }()
    lazy var navigationHeaderView : UIView = {
        let view = UIView()
        view.snp.makeConstraints({ (m) in
            m.size.equalTo(CGSize(width: 200, height: 44))
        })
        view.addSubview(selectBackView)
        selectBackView.snp.makeConstraints({ (m) in
            m.left.equalToSuperview().offset(0)
            m.centerY.equalToSuperview()
            m.height.equalTo(35)
            m.width.equalTo(100)
        })
        view.addSubview(groupHeader)
        groupHeader.snp.makeConstraints({ (m) in
            m.left.equalToSuperview()
            m.right.equalTo(view.snp.centerX)
            m.centerY.equalToSuperview()
            m.height.equalTo(35)
        })
        view.addSubview(privateHeader)
        privateHeader.snp.makeConstraints({ (m) in
            m.right.equalToSuperview()
            m.left.equalTo(view.snp.centerX)
            m.centerY.equalToSuperview()
            m.height.equalTo(35)
        })
        
        view.addSubview(activityIndicatorView)
        activityIndicatorView.snp.makeConstraints({ (m) in
            m.edges.equalToSuperview().inset(UIEdgeInsets.init(top: 0, left: -10, bottom: 0, right: -10))
        })
        return view
    }()
    
    lazy var groupHeader : FZMChatHeadSegment = {
        let view = FZMChatHeadSegment(with: "群聊消息")
//        view.enlargeClickEdge(20, 10, 10, 5)
        view.show(true)
        return view
    }()
    
    lazy var privateHeader : FZMChatHeadSegment = {
        let view = FZMChatHeadSegment(with: "好友消息")
//        view.enlargeClickEdge(20, 5, 10, 10)
        return view
    }()
    
    lazy var selectBackView : UIView = {
        let view = UIView()
        view.backgroundColor = FZM_EA6Color
        view.layer.cornerRadius = 17.5
        view.clipsToBounds = true
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.titleView = self.navigationHeaderView
        SocketChatManager.shared().isFinishedFetchMsgListSubject.subscribe {[weak self] (event) in
            guard case .next(let value) = event, let isFinishedFetchMsgList = value  else { return }
            self?.activityIndicatorView.isHidden = isFinishedFetchMsgList
        }.disposed(by: disposeBag)
        let searchItem = UIBarButtonItem(image: GetBundleImage("tool_search")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(searchItemClick))
        let moreItem = UIBarButtonItem(image: GetBundleImage("tool_more")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(moreItemClick))
        self.navigationItem.rightBarButtonItems = [moreItem,searchItem]
        if self.tabBarController == nil {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: GetBundleImage("back_arrow")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(dissmissAction))
        } else {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: GetBundleImage("tool_sweep_icon")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(sweepItemClick))
        }
        self.createUI()
    }
    
    @objc func searchItemClick() {
        FZMUIMediator.shared().pushVC(.goFullTextSearch)
    }
    
    @objc func sweepItemClick() {
        FZMUIMediator.shared().pushVC(.sweepQRCode)
    }
    @objc func dissmissAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func moreItemClick() {
        let view = FZMImageMenuView(with: [FZMImageMenuItem(title: "扫一扫", image: GetBundleImage("tool_sweep"), size: CGSize(width: 17, height: 17), block: {
            FZMUIMediator.shared().pushVC(.sweepQRCode)
        }),FZMImageMenuItem(title: "创建群聊", image: GetBundleImage("tool_create_group"), size: CGSize(width: 19, height: 17), block: {
            FZMUIMediator.shared().pushVC(.selectFriend(type: .all, completeBlock: nil))
        }),FZMImageMenuItem(title: "添加朋友/群", image: GetBundleImage("tool_add_friend"), size: CGSize(width: 17, height: 17), block: {
            FZMUIMediator.shared().pushVC(.search(type: .addFriendOrGroup))
        })])
        view.show(in: CGPoint(x: ScreenWidth-15, y: StatusNavigationBarHeight))
    }
    
    private func createUI() {
        let block : (SocketConversationModel)->() = { conversation in
            FZMUIMediator.shared().pushVC(.goChat(chatId: conversation.conversationId, type: conversation.type))
        }
//        let view1 = FZMChatRoomListView(with: "聊天室")
//        view1.selectBlock = block
        let view2 = FZMGroupChatListView(with: "群聊消息")
        view2.isShowTableHeaderView = true
        view2.selectBlock = block
        let view3 = FZMPrivateChatListView(with: "好友消息")
        view3.isShowTableHeaderView = true
        view3.selectBlock = block
        let param = FZMSegementParam()
        param.headerHeight = 0
        var height = ScreenHeight-TabbarHeight-StatusNavigationBarHeight
        if self.tabBarController == nil {
            height = ScreenHeight-StatusNavigationBarHeight
        }
        let view = FZMScrollPageView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: height), dataViews: [view2,view3], param: param)
        view.selectBlock = {[weak self] index in
            guard let strongSelf = self else { return }
            if index == 0 {
                strongSelf.groupHeader.show(true)
                strongSelf.privateHeader.show(false)
                strongSelf.selectBackView.snp.updateConstraints({ (m) in
                    m.left.equalToSuperview().offset(0)
                })
            }else {
                strongSelf.groupHeader.show(false)
                strongSelf.privateHeader.show(true)
                strongSelf.selectBackView.snp.updateConstraints({ (m) in
                    m.left.equalToSuperview().offset(100)
                })
            }
        }
        self.view.addSubview(view)
        view.snp.makeConstraints { (m) in
            m.edges.equalToSuperview()
        }
        
        let groupTap = UITapGestureRecognizer()
        groupTap.rx.event.subscribe {[weak self, weak view] (_) in
            guard let _ = self else { return }
            view?.select(with: 0)
        }.disposed(by: disposeBag)
        groupHeader.addGestureRecognizer(groupTap)
        
        let privateTap = UITapGestureRecognizer()
        privateTap.rx.event.subscribe {[weak self, weak view] (_) in
            guard let _ = self else { return }
            view?.select(with: 1)
        }.disposed(by: disposeBag)
        privateHeader.addGestureRecognizer(privateTap)
        
        IMConversationManager.shared().groupUnreadCountSubject.subscribe {[weak self] (event) in
            guard case .next(let count) = event else { return }
            self?.groupUnreadCount = count
        }.disposed(by: disposeBag)
        IMConversationManager.shared().privateUnreadCountSubject.subscribe {[weak self] (event) in
            guard case .next(let count) = event else { return }
            self?.privateUnreadCount = count
        }.disposed(by: disposeBag)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}


class FZMChatHeadSegment: UILabel {
    
    lazy var unreadLab : FZMUnreadLab = {
        return FZMUnreadLab(frame: CGRect.zero)
    }()
    
    init(with title: String) {
        super.init(frame: CGRect.zero)
        self.addSubview(unreadLab)
        unreadLab.snp.makeConstraints { (m) in
            m.bottom.equalTo(self.snp.top).offset(13)
            m.centerX.equalTo(self.snp.right).offset(-8)
            m.size.equalTo(CGSize.zero)
        }
        self.text = title
        self.textAlignment = .center
        self.isUserInteractionEnabled = true
        self.show(false)
    }
    
    func show(_ selected: Bool) {
        self.font = UIFont.mediumFont(17)
        self.textColor = selected ? FZM_TitleColor : FZM_GrayWordColor
    }
    
    func setBadge(_ badge: Int) {
        self.unreadLab.setUnreadCount(badge)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
