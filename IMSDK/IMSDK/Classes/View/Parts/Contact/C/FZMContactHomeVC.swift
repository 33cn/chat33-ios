//
//  FZMContactHomeVC.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/8.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit

fileprivate let FZMContactHomeVCScrollViewTag = 197493

class FZMContactHomeVC: FZMBaseViewController {
    
    lazy var newFriendBar : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        let imV = UIImageView(image: GetBundleImage("contact_newfriend"))
        view.addSubview(imV)
        imV.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(15)
            m.size.equalTo(CGSize(width: 35, height: 35))
        })
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: "新的朋友")
        lab.isUserInteractionEnabled = true
        view.addSubview(lab)
        lab.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.left.equalTo(imV.snp.right).offset(15)
            m.size.equalTo(CGSize(width: 200, height: 23))
        })
        let moreImageView = UIImageView(image: GetBundleImage("me_more"))
        view.addSubview(moreImageView)
        moreImageView.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.right.equalToSuperview().offset(-15)
            m.size.equalTo(CGSize(width: 3, height: 15))
        }
        view.addSubview(applyNumLab)
        applyNumLab.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.right.equalTo(moreImageView.snp.left).offset(-10)
        })
        view.addSubview(applyImgView)
        applyImgView.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.right.equalTo(applyNumLab.snp.left).offset(-10)
            m.size.equalTo(CGSize(width: 35, height: 35))
        })
        applyNumLab.isHidden = true
        applyImgView.isHidden = true
        return view
    }()
    
    lazy var applyImgView : UIImageView = {
        let view = UIImageView(image: GetBundleImage("chat_normal_head"))
        return view
    }()
    lazy var applyNumLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_RedColor, textAlignment: .center, text: nil)
    }()
    
    lazy var createGroupView : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        let imV = UIImageView(image: GetBundleImage("contact_create_group"))
        view.addSubview(imV)
        imV.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(15)
            m.size.equalTo(CGSize(width: 35, height: 35))
        })
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: "创建群聊")
        lab.isUserInteractionEnabled = true
        view.addSubview(lab)
        lab.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.left.equalTo(imV.snp.right).offset(15)
            m.size.equalTo(CGSize(width: 200, height: 23))
        })
        let moreImageView = UIImageView(image: GetBundleImage("me_more"))
        view.addSubview(moreImageView)
        moreImageView.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.right.equalToSuperview().offset(-15)
            m.size.equalTo(CGSize(width: 3, height: 15))
        }
        return view
    }()
    
    
    
    lazy var blacklistView : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        let imV = UIImageView(image: GetBundleImage("contact_blacklist"))
        view.addSubview(imV)
        imV.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(15)
            m.size.equalTo(CGSize(width: 35, height: 35))
        })
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: "黑名单")
        lab.isUserInteractionEnabled = true
        view.addSubview(lab)
        lab.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.left.equalTo(imV.snp.right).offset(15)
            m.size.equalTo(CGSize(width: 200, height: 23))
        })
        let moreImageView = UIImageView(image: GetBundleImage("me_more"))
        view.addSubview(moreImageView)
        moreImageView.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.right.equalToSuperview().offset(-15)
            m.size.equalTo(CGSize(width: 3, height: 15))
        }
        return view
    }()
    
    lazy var scrollView: UIScrollView = {
        let v = UIScrollView.init()
        v.delaysContentTouches = false
        v.showsVerticalScrollIndicator = false
        v.delegate = self
        v.tag = FZMContactHomeVCScrollViewTag
        return v
    }()
    
    var isScrollEnabled = true
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.scrollView.contentSize = CGSize.init(width: ScreenWidth, height: self.scrollView.bounds.size.height + 195)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "通讯录"
        let searchBtn = UIBarButtonItem(image: GetBundleImage("tool_search")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(searchBtnClick))
        let addBtn = UIBarButtonItem(image: GetBundleImage("contact_add")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(addBtnClick))
        self.navigationItem.rightBarButtonItems = [addBtn,searchBtn]
        if self.tabBarController == nil {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: GetBundleImage("back_arrow")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(dissmissAction))
        } else {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: GetBundleImage("tool_sweep_icon"), style: .plain, target: self, action: #selector(sweepItemClick))
        }
        self.createUI()
        IMContactManager.shared().applyNumSubject.subscribe {[weak self] (event) in
            guard case .next(let applyNum) = event else { return }
            self?.setApplyCount(applyNum)
        }.disposed(by: disposeBag)
 
    }
    
    private func setApplyCount(_ count: Int) {
        if count > 0 {
            applyImgView.isHidden = false
            applyNumLab.isHidden = false
            applyNumLab.text = "\(count)"
        }else {
            applyImgView.isHidden = true
            applyNumLab.isHidden = true
        }
    }
    
    @objc func sweepItemClick() {
        FZMUIMediator.shared().pushVC(.sweepQRCode)
        
    }
    
    @objc func dissmissAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func searchBtnClick() {
        FZMUIMediator.shared().pushVC(.goFullTextSearch)
    }
    
    @objc func addBtnClick() {
        FZMUIMediator.shared().pushVC(.search(type: .addFriendOrGroup))
    }
    
    lazy var view2: FZMFriendContactListView = {
        let v = FZMFriendContactListView(with: "好友")
        v.isScrollEnabled = false
        v.selectBlock = {(model) in
            FZMUIMediator.shared().pushVC(.friendInfo(friendId: model.contactId, groupId: nil, source: nil))
        }
        
        v.didScrollToTopBlock = {[weak self] in
            self?.scrollviewScrollEnabled(enabled: true)
        }
        return v
    }()
    
    lazy var view3: FZMGroupContactListView = {
        let v = FZMGroupContactListView(with: "群聊")
        v.isScrollEnabled = false
        v.selectGroupBlock = { model in
            FZMUIMediator.shared().pushVC(.goChat(chatId: model.groupId, type: .group))
        }
        v.didScrollToTopBlock = {[weak self]  in
            self?.scrollviewScrollEnabled(enabled: true)
        }
        return v
    }()
    
    lazy var pageView: FZMScrollPageView = {
        let param = FZMSegementParam()
        param.textSelectedColor = FZM_TintColor
        var height = ScreenHeight-StatusNavigationBarHeight-TabbarHeight
        if self.tabBarController == nil {
            height = ScreenHeight-StatusNavigationBarHeight
        }
        let view = FZMScrollPageView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: height), dataViews: [view2,view3],param: param)
        return view
    }()
    
    @objc func scrollviewScrollToBottom() {
        self.scrollviewScrollEnabled(enabled: false)
        if self.scrollView.contentOffset.y != CGFloat(195) {
            self.scrollView.scrollRectToVisible(CGRect.init(x: 0, y: 195, width: ScreenWidth, height: ScreenHeight), animated: true)
        }
    }
    
    func scrollviewScrollEnabled(enabled: Bool) {
        if enabled {
            self.isScrollEnabled = true
            self.view2.isScrollEnabled = false
            self.view3.isScrollEnabled = false
        } else {
            self.view2.isScrollEnabled = true
            self.view3.isScrollEnabled = true
            self.isScrollEnabled = false
        }
    }
    
    private func createUI() {
        self.view.addSubview(scrollView)
        self.scrollView.addSubview(newFriendBar)
        self.scrollView.snp.makeConstraints { (m) in
            m.top.left.right.equalToSuperview()
            m.height.equalTo(ScreenHeight - StatusNavigationBarHeight - TabbarHeight)
        }
        newFriendBar.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(10)
            m.left.equalTo(self.view).offset(15)
            m.right.equalTo(self.view).offset(-15)
            m.height.equalTo(50)
        }
        self.scrollView.addSubview(createGroupView)
        createGroupView.snp.makeConstraints { (m) in
            m.top.equalTo(newFriendBar.snp.bottom).offset(10)
            m.left.right.equalTo(newFriendBar)
            m.height.equalTo(50)
        }
        self.scrollView.addSubview(blacklistView)
        blacklistView.snp.makeConstraints { (m) in
            m.top.equalTo(createGroupView.snp.bottom).offset(10)
            m.left.right.equalTo(newFriendBar)
            m.height.equalTo(50)
        }
        
        self.scrollView.addSubview(pageView)
        pageView.snp.makeConstraints { (m) in
            m.top.equalTo(blacklistView.snp.bottom).offset(10)
            m.left.right.equalTo(self.view)
            m.bottom.equalTo(self.safeBottom)
        }

        self.makeActions()
    }
    
   
    private func makeActions() {
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe {[weak self] (_) in
            let vc = FZMContactApplyListVC()
            vc.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(vc, animated: true)
        }.disposed(by: disposeBag)
        newFriendBar.addGestureRecognizer(tap)
        let createTap = UITapGestureRecognizer()
        createTap.rx.event.subscribe { (_) in
            FZMUIMediator.shared().pushVC(.selectFriend(type: .all, completeBlock: nil))
        }.disposed(by: disposeBag)
        createGroupView.addGestureRecognizer(createTap)
        
        let blacklistTap = UITapGestureRecognizer()
        blacklistTap.rx.event.subscribe(onNext: { (_) in
            let vc = FZMBlacklistVC.init()
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }).disposed(by: disposeBag)
        blacklistView.addGestureRecognizer(blacklistTap)
        
        NotificationCenter.default.addObserver(self, selector: #selector(scrollviewScrollToBottom), name: NSNotification.Name.init("SCIndexViewBeginTracking"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(scrollviewScrollToBottom), name: NSNotification.Name.init("SCIndexViewContinueTracking"), object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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


extension FZMContactHomeVC: UITableViewDelegate,UIGestureRecognizerDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !self.isScrollEnabled {
            self.scrollView.contentOffset = CGPoint.init(x: scrollView.contentOffset.x, y: self.scrollView.contentSize.height - self.scrollView.bounds.height)
            return
        }
        if self.scrollView.contentSize.height - self.scrollView.contentOffset.y <= self.scrollView.bounds.height {
            self.scrollviewScrollEnabled(enabled: false)
        }
        if self.scrollView.contentOffset.y <= 0.0001 {
            self.scrollviewScrollEnabled(enabled: true)
        }
    }
}

extension UITableView: UIGestureRecognizerDelegate {
    //让 "好友" 和 "群聊"中的tableview可以和FZMContactHomeVC中的scrollView一起滑动
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let view = otherGestureRecognizer.view,
            view.isKind(of: UIScrollView.self),
            view.tag == FZMContactHomeVCScrollViewTag,
            let superview = view.superview,
            let vc = superview.viewContainingController,
            vc.isKind(of: FZMContactHomeVC.self) {
            return true
        }
        return false
    }
}
