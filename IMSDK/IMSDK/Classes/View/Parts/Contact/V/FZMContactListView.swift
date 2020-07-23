//
//  FZMContactListView.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/9.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift

class FZMContactListView: FZMScrollPageItemBaseView {
    
    let disposeBag = DisposeBag()
    let lock = NSLock()
    var selectBlock : ((FZMContactViewModel)->())?
    var contactArr = [Any]()
    lazy var tableView : UITableView = {
        let view = UITableView(frame: CGRect.zero, style: .plain)
        view.backgroundColor = FZM_BackgroundColor
        view.separatorStyle = .none
        view.dataSource = self
        view.delegate = self
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.tableHeaderView = UIView(frame: CGRect.zero)
        view.tableFooterView = UIView(frame: CGRect.zero)
        view.rowHeight = 50
        view.keyboardDismissMode = .onDrag
        view.register(FZMContactCell.self, forCellReuseIdentifier: "FZMContactCell")
        view.tag = 1888888
        return view
    }()
    
    var isScrollEnabled: Bool = true {
        didSet {
            //            self.tableView.isScrollEnabled = self.isScrollEnabled
        }
    }
    
    var didScrollToTopBlock: (() -> ())?
    
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
    
    fileprivate var vmMap = [String:FZMContactViewModel]()
    fileprivate func getUserVM(with user: IMUserModel) -> FZMContactViewModel {
        if let vm = vmMap[user.userId] {
            return vm
        }
        let useVM = FZMContactViewModel(with: user)
        vmMap[user.userId] = useVM
        return useVM
    }
    fileprivate func getGroupVM(with group: IMGroupModel) -> FZMContactViewModel {
        if let vm = vmMap[group.groupId] {
            return vm
        }
        let useVM = FZMContactViewModel(with: group)
        vmMap[group.groupId] = useVM
        return useVM
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension FZMContactListView: UITableViewDelegate,UITableViewDataSource, UIGestureRecognizerDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.contactArr.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FZMContactCell", for: indexPath) as! FZMContactCell
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !self.isScrollEnabled {
            scrollView.contentOffset = CGPoint.init(x: scrollView.contentOffset.x, y: 0)
        } else if scrollView.contentOffset.y <= 0.0001 {
            self.didScrollToTopBlock?()
        }
    }
    
}

class FZMFriendContactListView: FZMContactListView {
    
    private var selectType : FZMSelectFriendViewShowType = .no
    
    var defaultSelectId: String = ""
    
    var noDataView = FZMNoDataView(image: GetBundleImage("nodata_contact_friend"), imageSize: CGSize(width: 250, height: 200), desText: "暂无好友", btnTitle: "邀请好友", clickBlock: {
        FZMUIMediator.shared().pushVC(.qrCodeShow(type: .me))
    })
    
    private var dataSource = [FriendSection]()
    private var originDataSource = [FriendSection]()
    
    var friendArrayForSearch = [IMUserModel]()
    var searchString: String? = nil
    
    convenience init(with pageTitle: String , _ selectType: FZMSelectFriendViewShowType) {
        self.init(with: pageTitle)
        self.selectType = selectType
        switch self.selectType {
        case .no:
            self.noDataView.hideBottomBtn = false
        default:
            self.noDataView.hideBottomBtn = true
        }
    }
    
    init(with pageTitle: String, isBlacklist: Bool = false) {
        super.init(with: pageTitle)
        self.noDataView.isHidden = true
        self.addSubview(self.noDataView)
        self.noDataView.snp.makeConstraints { (m) in
            m.center.equalToSuperview()
            m.size.equalTo(CGSize(width: ScreenWidth, height: 285))
        }
        
        let configurationc = SCIndexViewConfiguration.init(indexViewStyle: .default)
        configurationc?.indexItemSelectedTextColor = FZM_TintColor
        tableView.sc_indexViewConfiguration = configurationc
        if isBlacklist {
            self.selectType = .no
            self.noDataView.desLab.text = "暂无黑名单"
            self.noDataView.hideBottomBtn = true
            self.reloadBlacklist()
        } else {
            IMContactManager.shared().friendMapSubject.subscribe { (event) in
                guard case .next(let arr) = event, let data = arr else { return }
                data.forEach({self.friendArrayForSearch = self.friendArrayForSearch + $0.friendArr})
                self.originDataSource = data
                self.reloadTableView(dataSource: data)
                
            }.disposed(by: disposeBag)
        }
    }
    
    private func reloadTableView(dataSource: [FriendSection]) {
        self.reloadTableViewForSearch(dataSource: dataSource, searchString: nil)
    }
    
    func reloadTableViewForSearch(dataSource: [FriendSection]? = nil, searchString: String? = nil) {
        DispatchQueue.main.async {
            self.lock.lock()
            if let d = dataSource {
                self.dataSource = d
            } else {
                self.dataSource = self.originDataSource
            }
            self.searchString = searchString
            self.tableView.reloadData()
            let list = self.dataSource.compactMap({ (section) -> String? in
                return section.titleKey
            })
            self.tableView.sc_indexViewDataSource = list
            self.lock.unlock()
        }
    }
    
    func reloadBlacklist() {
        self.showProgress()
        let blockList = IMContactManager.shared().blockList
        HttpConnect.shared().getUsersInfo(uids: blockList) { (friendArr, response) in
            guard response.success else {
                self.showToast(with: response.message)
                return
            }
            
            let dic = Dictionary(grouping: friendArr) { (friend:IMUserModel)in
                return friend.showName.findFirstLetterFromString()
            }
            var friendSectionArr = [FriendSection]()
            for key in dic.keys {
                if let friends = dic[key], friends.count > 0 {
                    let friendSection = FriendSection.init(titleKey: key, users: friends)
                    friendSectionArr.append(friendSection)
                }
            }
            friendSectionArr = friendSectionArr.sorted(by: <)
            friendSectionArr.forEach { (section) in
                section.friendArr = section.friendArr.sorted(by: <)
            }
            self.originDataSource = friendSectionArr
            self.reloadTableView(dataSource: friendSectionArr)
            self.hideProgress()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func selectOrDeselect(model:FZMContactViewModel) {
        for i in 0..<self.dataSource.count {
            let friendSection = self.dataSource[i]
            for j in 0..<friendSection.friendArr.count {
                if friendSection.friendArr[j].userId == model.contactId {
                    let vm = getUserVM(with: friendSection.friendArr[j])
                    vm.isSelected = model.isSelected
                    let indexPath = IndexPath(item: j, section: i)
                    tableView.reloadRows(at: [indexPath], with: .none)
                    return
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 20))
        view.backgroundColor = FZM_BackgroundColor
        let friendSection = self.dataSource[section]
        let lab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .left, text: friendSection.titleKey)
        view.addSubview(lab)
        lab.snp.makeConstraints { (m) in
            m.top.bottom.equalToSuperview()
            m.left.equalToSuperview().offset(20)
        }
        return view
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        self.noDataView.isHidden = self.dataSource.count > 0
        return self.dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section >= self.dataSource.count {
            return 0
        }
        let friendSection = self.dataSource[section]
        return friendSection.friendArr.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FZMContactCell", for: indexPath) as! FZMContactCell
        if indexPath.section >= self.dataSource.count
            || indexPath.row >= self.dataSource[indexPath.section].friendArr.count {
            return cell
        }
        let friendSection = self.dataSource[indexPath.section]
        let user = friendSection.friendArr[indexPath.row]
        let vm = getUserVM(with: user)
        vm.searchString = self.searchString
        if vm.contactId == self.defaultSelectId {
            vm.isSelected = true
            selectBlock?(vm)
            self.defaultSelectId = ""
        }
        cell.configure(with: vm)
        switch selectType {
        case .all:
            cell.showSelect()
            cell.selectStyle = vm.isSelected ? .select : .disSelect
        case .exclude(let users):
            cell.showSelect()
            if users.contains(vm.contactId) {
                cell.selectStyle = .cantSelect
            }else {
                cell.selectStyle = vm.isSelected ? .select : .disSelect
            }
        default: break
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let friendSection = self.dataSource[indexPath.section]
        let user = friendSection.friendArr[indexPath.row]
        let vm = self.getUserVM(with: user)
        switch selectType {
        case .all:
            vm.isSelected = !vm.isSelected
            selectBlock?(vm)
            tableView.reloadRows(at: [indexPath], with: .fade)
        case .exclude(let users):
            if !users.contains(vm.contactId) {
                vm.isSelected = !vm.isSelected
                selectBlock?(vm)
                tableView.reloadRows(at: [indexPath], with: .fade)
            }
        default:
            selectBlock?(vm)
        }
        
    }
}

class FZMGroupContactListView: FZMContactListView {
    var groupSectionArr = [GroupSection]()
    var showSelect = false
    var selectGroupBlock : ((IMGroupModel)->())?
    lazy var noDataView : FZMNoDataView = {
        if IMSDK.shared().showPromoteHotGroup {
            return FZMNoDataView.init(image: GetBundleImage("nodata_contact_group"), imageSize: CGSize(width: 250, height: 200), desText: "暂无群聊", btn1Title: "创建群聊", btn1Image: nil, btn2Title: "热门群聊", btn2Image: GetBundleImage("chat_hot_group"), isVertical: false, btn1ClickBlock: {
                FZMUIMediator.shared().pushVC(.selectFriend(type: .all, completeBlock: nil))
            }, btn2ClickBlock: {
                FZMUIMediator.shared().pushVC(.goPromoteHotGroup)
            })
        } else {
            return FZMNoDataView(image: GetBundleImage("nodata_contact_group"), imageSize: CGSize(width: 250, height: 200), desText: "暂无群聊", btnTitle: "创建群聊", clickBlock: {
                FZMUIMediator.shared().pushVC(.selectFriend(type: .all, completeBlock: nil))
            })
        }
    }()
    
    convenience init(with pageTitle: String , _ showSelect: Bool = false) {
        self.init(with: pageTitle)
        self.showSelect = showSelect
        self.noDataView.hideBottomBtn = showSelect
    }
    
    override func requestData() {
        self.addSubview(noDataView)
        noDataView.snp.makeConstraints { (m) in
            m.center.equalToSuperview()
            m.size.equalTo(CGSize(width: ScreenWidth, height: 285))
        }
        IMConversationManager.shared().groupListSubject.subscribe {[weak self] (event) in
            guard case .next(let list) = event else { return }
            
            self?.groupSectionArr = IMConversationManager.shared().convertGroupListToGroupSectionArray(by: list)
            let sectionArr = self?.groupSectionArr.compactMap({ (section) -> String? in
                return section.titleKey
            })
            let configurationc = SCIndexViewConfiguration.init(indexViewStyle: .default)
            configurationc?.indexItemSelectedTextColor = FZM_TintColor
            self?.tableView.sc_indexViewConfiguration = configurationc
            self?.tableView.sc_indexViewDataSource = sectionArr
            
            self?.contactArr = list
            self?.tableView.reloadData()
            self?.noDataView.isHidden = list.count > 0
        }.disposed(by: disposeBag)
    }
    
    func selectOrDeselect(model:FZMContactViewModel) {
        for i in 0..<self.groupSectionArr.count {
            let groupSection = self.groupSectionArr[i]
            for j in 0..<groupSection.groupArr.count {
                if groupSection.groupArr[j].groupId == model.contactId {
                    let vm = getGroupVM(with: groupSection.groupArr[j])
                    vm.isSelected = model.isSelected
                    let indexPath = IndexPath(item: j, section: i)
                    tableView.reloadRows(at: [indexPath], with: .none)
                    return
                }
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 20))
        view.backgroundColor = FZM_BackgroundColor
        let groupSection = self.groupSectionArr[section]
        let lab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .left, text: groupSection.titleKey)
        view.addSubview(lab)
        lab.snp.makeConstraints { (m) in
            m.top.bottom.equalToSuperview()
            m.left.equalToSuperview().offset(20)
        }
        return view
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        self.noDataView.isHidden = self.groupSectionArr.count > 0
        return self.groupSectionArr.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let groupSection = self.groupSectionArr[section]
        return groupSection.groupArr.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FZMContactCell", for: indexPath) as! FZMContactCell
        let group = self.groupSectionArr[indexPath.section].groupArr[indexPath.row]
        let vm = getGroupVM(with: group)
        cell.configure(with: vm)
        if showSelect {
            cell.showSelect()
            cell.selectStyle = vm.isSelected ? .select : .disSelect
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let group = self.groupSectionArr[indexPath.section].groupArr[indexPath.row]
        if showSelect {
            let vm = getGroupVM(with: group)
            vm.isSelected = !vm.isSelected
            selectBlock?(vm)
            tableView.reloadRows(at: [indexPath], with: .fade)
        }else {
            selectGroupBlock?(group)
        }
    }
}


enum FZMSelectFriendViewShowType {
    case no //不显示可选
    case all //所有都可
    case exclude([String]) //排除一部分
}
