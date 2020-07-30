//
//  FZMSelectFriendToGroupVC.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/18.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit

enum FZMSelectFriendGroupShowStyle {
    case all
    case exclude(String,Bool)
}

class FZMSelectFriendToGroupVC: FZMBaseViewController {

    lazy var selectView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets.init(top: 0, left: 15, bottom: 0, right: 15)
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        layout.itemSize = CGSize(width: 35, height: 35)
        let view = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        view.backgroundColor = UIColor.clear
        view.showsHorizontalScrollIndicator = false
        view.register(FZMGroupUserCell.self, forCellWithReuseIdentifier: "FZMGroupUserCell")
        view.dataSource = self
        view.delegate = self
        return view
    }()
    
    private var selectArr = [FZMContactViewModel]()
    
    private lazy var numberLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_TintColor, textAlignment: .center, text: nil)
    }()
    
    lazy var confirmBtn : UIButton = {
        let btn = UIButton.getNormalBtn(with: "邀请")
        return btn
    }()
    
    
    lazy var encryptGroup : UIButton = {
        let btn = UIButton.getNormalBtn(with: "跳过")
        return btn
    }()
    
    lazy var bottomView: UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        view.backgroundColor = FZM_WhiteColor
        view.addSubview(encryptGroup)
        encryptGroup.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.size.equalTo(CGSize(width: (ScreenWidth - 30) , height: 40))
            m.left.equalToSuperview().offset(15)
        }
        return view
    }()
    
    private var friendArrayForSearch = [IMUserModel]()
    
    lazy var listView : FZMFriendContactListView = {
        let type : FZMSelectFriendViewShowType
        switch showType {
        case .all:
            type = .all
        case .exclude:
            type = .exclude(excludeUsers)
        }
        let view = FZMFriendContactListView(with: "", type)
        self.friendArrayForSearch = view.friendArrayForSearch
        view.defaultSelectId = self.defaultSelectId
        view.selectBlock = {[weak self] (model) in
            self?.deal(contact: model)
        }
        return view
    }()
    
    private var excludeUsers = [String]()
    var reloadBlock : NormalBlock?
    private let showType : FZMSelectFriendGroupShowStyle
    
    var defaultSelectId = "" {
        didSet {
            self.listView.defaultSelectId = self.defaultSelectId
        }
    }
    
    lazy var searchBlockView : UIView = {
        let view = UIView.init(frame: CGRect.init(x: 0, y: -100, width: ScreenWidth, height: StatusNavigationBarHeight))
        view.backgroundColor = FZM_BackgroundColor
        
        let circleView = UIView.init()
        circleView.layer.backgroundColor = FZM_LineColor.cgColor
        circleView.layer.cornerRadius = 20
        circleView.tintColor = FZM_GrayWordColor
        view.addSubview(circleView)
        circleView.snp.makeConstraints({ (m) in
            m.height.equalTo(40)
            m.left.equalToSuperview().offset(15)
            m.bottom.equalToSuperview()
            m.right.equalToSuperview().offset(-65)
        })
        
        let cancelBtn = UIButton.init(type: .custom)
        cancelBtn.enlargeClickEdge(10, 10, 10, 15)
        cancelBtn.setTitle("完成", for: .normal)
        cancelBtn.setTitleColor(FZM_TintColor, for: .normal)
        cancelBtn.titleLabel?.font = UIFont.boldFont(16)
        cancelBtn.addTarget(self, action: #selector(hideSearchView), for: .touchUpInside)
        view.addSubview(cancelBtn)
        cancelBtn.snp.makeConstraints({ (m) in
            m.centerY.equalTo(circleView)
            m.right.equalToSuperview().offset(-15)
            m.size.equalTo(CGSize(width: 40, height: 25))
        })
        
        let imageV = UIImageView(image: GetBundleImage("tool_search")?.withRenderingMode(.alwaysTemplate))
        circleView.addSubview(imageV)
        imageV.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(5)
            m.size.equalTo(CGSize(width: 17, height: 18))
        })
        circleView.addSubview(searchInput)
        searchInput.snp.makeConstraints({ (m) in
            m.top.bottom.right.equalToSuperview()
            m.left.equalTo(imageV.snp.right).offset(10)
        })
        return view
    }()
    
    lazy var searchInput : UITextField = {
        let input = UITextField.init()
        input.tintColor = FZM_TintColor
        input.textAlignment = .left
        input.font = UIFont.regularFont(16)
        input.textColor = FZM_BlackWordColor
        input.attributedPlaceholder = NSAttributedString(string: "搜索好友", attributes: [.foregroundColor:FZM_GrayWordColor,.font:UIFont.regularFont(16)])
        input.returnKeyType = .search
        input.addTarget(self, action: #selector(textFiledEditChanged(_:)), for: .editingChanged)
        return input
    }()
    
    lazy var tapControl: UIControl = {
        let v = UIControl.init()
        v.isHidden = true
        v.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.5)
        v.isHidden = true
        v.addTarget(self, action: #selector(hideSearchView), for: .touchUpInside)
        return v
    }()
    
    lazy var noDataView: UIView = {
        let v = UIView.init()
        v.isHidden = true
        v.backgroundColor = FZM_BackgroundColor
        var imgView = FZMNoDataView(image: GetBundleImage("nodata_search"), imageSize: CGSize(width: 250, height: 200), desText: "没有匹配的对象", btnTitle: nil, clickBlock: nil)
        v.addSubview(imgView)
        imgView.snp.makeConstraints({ (m) in
            m.top.equalToSuperview().offset(65)
            m.left.right.equalToSuperview()
            m.bottom.equalToSuperview()
        })
        return v
    }()
    
    init(with type: FZMSelectFriendGroupShowStyle) {
        showType = type
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(cancelBtnPress))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: GetBundleImage("tool_search"), style: .plain, target: self, action: #selector(showSearchView))
        
        if case .exclude(let groupId, let isEncrypt) = showType {
            self.navigationItem.title = "选择好友"
            self.showProgress(with: nil)
            IMConversationManager.shared().getGroupMemberList(groupId: groupId) { (list, response) in
                self.hideProgress()
                guard response.success else {
                    self.showToast(with: response.message)
                    return
                }
                list.forEach({ (user) in
                    self.excludeUsers.append(user.userId)
                })
                self.createUI()
            }
        }else {
            self.navigationItem.title = "创建群聊"
            self.createUI()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.hideSearchView()
    }
    
    @objc func hideSearchView() {
        self.searchInput.text = nil
        self.noDataView.isHidden = true
        self.searchInput.resignFirstResponder()
        
        self.listView.reloadTableViewForSearch()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.searchBlockView.frame = CGRect.init(x: 0, y: -100, width: ScreenWidth, height: StatusNavigationBarHeight)
            self.tapControl.alpha = 0
        }) { (_) in
            self.searchBlockView.removeFromSuperview()
        }
    }
    
    @objc func showSearchView() {
        UIApplication.shared.keyWindow?.addSubview(self.searchBlockView)
        self.searchInput.becomeFirstResponder()
        self.tapControl.isHidden = false
        self.noDataView.isHidden = true
        UIView.animate(withDuration: 0.3) {
            self.searchBlockView.frame = CGRect.init(x: 0, y: 0, width: ScreenWidth, height: StatusNavigationBarHeight)
            self.tapControl.alpha = 1
        }
    }
    
    @objc private func cancelBtnPress() {
        if let nav = self.navigationController {
            nav.dismiss(animated: true) {
            }
        }else {
            self.dismiss(animated: true) {
            }
        }
    }
    
    private func dismissClick(completion: (() -> Void)?) {
        if let nav = self.navigationController {
            nav.dismiss(animated: true) {
                completion?()
            }
        }else {
            self.dismiss(animated: true) {
                completion?()
            }
        }
    }
    
    private func createUI() {
        self.view.addSubview(selectView)
        selectView.snp.makeConstraints { (m) in
            m.left.equalToSuperview()
            m.top.equalToSuperview().offset(8)
            m.height.equalTo(35)
            m.right.equalToSuperview().offset(-60)
        }
        self.view.addSubview(numberLab)
        numberLab.snp.makeConstraints { (m) in
            m.right.equalToSuperview()
            m.left.equalTo(selectView.snp.right)
            m.top.bottom.equalTo(selectView)
        }
        
        if case .all = showType {
            self.view.addSubview(bottomView)
            bottomView.snp.makeConstraints { (m) in
                m.bottom.left.right.equalTo(self.safeArea)
                m.height.equalTo(70)
            }
        } else {
            let view = UIView()
            view.makeOriginalShdowShow()
            view.backgroundColor = FZM_WhiteColor
            self.view.addSubview(view)
            view.snp.makeConstraints { (m) in
                m.bottom.left.right.equalTo(self.safeArea)
                m.height.equalTo(70)
            }
            view.addSubview(confirmBtn)
            confirmBtn.snp.makeConstraints { (m) in
                m.center.equalToSuperview()
                m.size.equalTo(CGSize(width: ScreenWidth - 30 , height: 40))
            }
        }
        
        
        self.view.addSubview(listView)
        listView.snp.makeConstraints { (m) in
            m.left.right.equalToSuperview()
            m.bottom.equalTo(self.safeArea).offset(-70)
            m.top.equalToSuperview().offset(50)
        }
        
        confirmBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            self?.commitInfo()
        }.disposed(by: disposeBag)
        
        
        encryptGroup.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            self?.createEncryptGroup()
        }.disposed(by: disposeBag)
        
        self.view.addSubview(tapControl)
        tapControl.snp.makeConstraints({ (m) in
            m.left.equalTo(self.view)
            m.top.equalTo(self.view)
            m.height.equalTo(ScreenHeight)
            m.width.equalTo(ScreenWidth)
        })
        self.view.addSubview(noDataView)
        noDataView.snp.makeConstraints({ (m) in
            m.edges.equalTo(tapControl)
        })
    }
    
    private func commitInfo() {
        self.showProgress()
        var users = [String]()
        var encryptUsers = [String]()
        selectArr.forEach { (contact) in
            users.append(contact.contactId)
            if let pubKey = contact.user?.publicKey, !pubKey.isEmpty {
                encryptUsers.append(contact.contactId)
            }
        }
        
        if users.isEmpty {
            self.showToast(with: "请选择好友")
            return
        }
        
        if case .exclude(let groupId,let isEncrypt) = showType {
            if IMSDK.shared().isEncyptChat && isEncrypt {
                if !users.isEmpty && encryptUsers.isEmpty {
                    let alert = FZMAlertView.init(attributedTitle: NSAttributedString.init(string:"提示"), attributedText: NSAttributedString.init(string: "你邀请的好友未设置密聊私钥, 不能邀请进入加密群聊", attributes: [NSAttributedString.Key.foregroundColor: FZM_BlackWordColor]), btnTitle: "确定") {
                    }
                    self.view.hideProgress()
                    alert.show()
                    return
                }
                if users.count > encryptUsers.count {
                    let alert = FZMAlertView.init(attributedTitle: NSAttributedString.init(string:"提示"), attributedText: NSAttributedString.init(string: "你邀请的好友中有\(users.count - encryptUsers.count)个未设置密聊私钥, 继续邀请将去除该部分成员", attributes: [NSAttributedString.Key.foregroundColor: FZM_BlackWordColor]), btnTitle: "确定") {
                        self.inviteJoinGroup(groupId: groupId, users: encryptUsers)
                    }
                    self.view.hideProgress()
                    alert.show()
                    return
                } else {
                    self.inviteJoinGroup(groupId: groupId, users: encryptUsers)
                }
            } else {
                self.inviteJoinGroup(groupId: groupId, users: users)
            }
        }
    }
    
    private func inviteJoinGroup(groupId: String, users: [String]) {
        self.showProgress(with: nil)
        IMConversationManager.shared().inviteJoinGroup(groupId: groupId, users: users) { (response) in
            self.hideProgress()
            guard response.success else {
                self.showToast(with: response.message)
                return
            }
            if response.data?["state"].intValue == 1 {
                FZNEncryptKeyManager.shared().updataGroupKey(groupId: groupId)
            }
            self.reloadBlock?()
            self.dismissClick(completion: nil)
        }
    }
    
    private func createGroup(users:[String]) {
        self.showProgress()
        IMConversationManager.shared().createGroup(name: nil, avatar: nil , users: users, encrypt:2) { (group, response) in
            guard response.success, let group = group else {
                self.showToast(with: response.message)
                return
            }
            self.hideProgress()
            self.dismissClick(completion: {
                FZMUIMediator.shared().pushVC(.goChat(chatId: group.groupId, type: .group))
            })
        }
    }
    
    private func createEncryptGroup(encryptUsers: [String]) {
        self.showProgress()
        IMConversationManager.shared().createGroup(name: nil, avatar: nil , users: encryptUsers, encrypt:1) { (group, response) in
            guard response.success, let group = group else {
                self.showToast(with: response.message)
                return
            }
            FZNEncryptKeyManager.shared().updataGroupKey(groupId: group.groupId)
            self.hideProgress()
            self.dismissClick(completion: {
                FZMUIMediator.shared().pushVC(.goChat(chatId: group.groupId, type: .group))
            })
        }
    }
    
    private func createGroup(isEncrypt: Bool = false) {
        self.showProgress()
        var users = [String]()
        var encryptUsers = ([String]())
        selectArr.forEach { (contact) in
            users.append(contact.contactId)
            if let pubKey = contact.user?.publicKey, !pubKey.isEmpty {
                encryptUsers.append(contact.contactId)
            }
        }
        
        if IMSDK.shared().isEncyptChat && isEncrypt {
            if users.count > encryptUsers.count {
                let alert = FZMAlertView.init(onlyAlert: "有\(users.count - encryptUsers.count)个成员未升级或未开启加密功能，无法加入加密群聊，继续创建将去除该部分成员。", btnTitle: "继续创建") {
                    self.createEncryptGroup(encryptUsers: encryptUsers)
                }
                self.view.hideProgress()
                alert.show()
            } else {
                 self.createEncryptGroup(encryptUsers: encryptUsers)
            }
        } else {
            self.createGroup(users: users)
        }
    }
    
    
    private func createEncryptGroup() {
        if !IMSDK.shared().isEncyptChat {
            self.createGroup(isEncrypt: false)
            return
        }
        guard let pubKey = IMLoginUser.shared().currentUser?.publicKey,let priKey = IMLoginUser.shared().currentUser?.privateKey, !pubKey.isEmpty, !priKey.isEmpty else {
            let alert = FZMAlertView.init(attributedTitle: NSAttributedString.init(string:"提示"), attributedText: NSAttributedString.init(string: "你尚未设置密聊私钥，不能创建私密聊天，请先设置密聊私钥。", attributes: [NSAttributedString.Key.foregroundColor: FZM_BlackWordColor]), btnTitle: "设置") {
                FZMUIMediator.shared().pushVC(.goImportSeed(isHideBackBtn: false))
            }
            alert.show()
            return
        }
        self.createGroup(isEncrypt: true)
    }
    
    private func deal(contact: FZMContactViewModel) {
        defer {
            self.numberLab.text = selectArr.count > 0 ? "\(selectArr.count)" : ""
        }
        if contact.isSelected {
            selectArr.append(contact)
            selectView.reloadData()
        }else {
            if let index = selectArr.index(of: contact) {
                selectArr.remove(at: contact)
                selectView.deleteItems(at: [IndexPath(item: index, section: 0)])
            }
        }
        
        self.encryptGroup.setAttributedTitle(NSAttributedString(string: selectArr.count > 0 ? "创建" : "跳过", attributes: [.foregroundColor: UIColor.white,.font:UIFont.regularFont(16)]), for: .normal)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension FZMSelectFriendToGroupVC {
    
    @objc func textFiledEditChanged(_ textField: UITextField) {
        if textField.markedTextRange == nil ||
            textField.markedTextRange?.isEmpty ?? false {
            if let text = textField.text {
                self.search(text)
            }
        }
    }
    
    private func search(_ text: String) {
        if text.isEmpty {
            self.noDataView.isHidden = true
            self.tapControl.isHidden = false
            self.listView.reloadTableViewForSearch()
            return
        }
        
        let section = FriendSection.init()
        section.titleKey = ""
        let searchList = self.friendArrayForSearch.filter { $0.name.lowercased().contains(text.lowercased()) || $0.remark.lowercased().contains(text.lowercased()) }
        searchList.forEach {section.friendArr.append($0)}
        
        if section.friendArr.isEmpty  {
            self.tapControl.isHidden = true
            self.noDataView.isHidden = false
        } else {
            self.tapControl.isHidden = true
            self.noDataView.isHidden = true
            self.listView.reloadTableViewForSearch(dataSource: [section], searchString: text)
        }
    }
}


extension FZMSelectFriendToGroupVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FZMGroupUserCell", for: indexPath) as! FZMGroupUserCell
        cell.nameLab.isHidden = true
        let model = selectArr[indexPath.item]
        IMContactManager.shared().requestUserModel(with: model.contactId) { (user, _, _) in
            guard let user = user else { return }
            cell.headImageView.loadNetworkImage(with: user.avatar.getDownloadUrlString(width: 35), placeImage: GetBundleImage("chat_normal_head"))
        }
        return cell
    }
}
