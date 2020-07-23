//
//  FZMFullTextSearchVC.swift
//  IMSDK
//
//  Created by .. on 2019/9/20.
//

import UIKit
import KeychainAccess

enum FZMFullTextSearchType: Equatable {
    case friend
    case group
    case chatRecord(specificId: String?) // specificId, 指定搜索某个会话的聊天记录
    case all
    var titit: String {
        switch self {
        case .friend:
            return "联系人"
        case .group:
            return "群聊"
        case .chatRecord:
            return "聊天记录"
        case .all:
            return ""
        }
    }
}

class FZMFullTextSearchVC: FZMBaseViewController {
    
    private var searchType: FZMFullTextSearchType
    private var limitCount = 3
    private let friendArrayForSearch: [IMUserModel]
    private let groupArrayForSearch: [IMGroupModel]
    private let refreshQueue = DispatchQueue.init(label: "FZMFullTextSearchVCRefreshQueue")
    private var dataSource = [[IMFullTextSearchVM]]()
    private var searchString: String?
    
    private let SearchHistoryUserDefaultsKey = "SearchHistoryUserDefaultsKey"
    private lazy var searchHistoryView: FZMFullTextSearchHistoryView = {
        let v = FZMFullTextSearchHistoryView.init()
        v.frame = CGRect.init(x: 0, y: 0, width: ScreenWidth, height: ScreenHeight)
        v.clearAllHistoryBlock = {[weak v, weak self] in
            v?.isHidden = true
            self?.clearAllSearchHistories()
        }
        v.deleteHistoryBlock = {[weak self] (title) in
            self?.deleteSearchHistory(searchString: title)
        }
        v.selectedHistoryBlock = {[weak self] (title) in
            self?.searchInput.text = title
            self?.search(title)
        }
        return v
    }()
    
    private var searchHistories = [String]() {
        didSet {
            searchHistoryView.histories = searchHistories
            if searchHistories.isEmpty {
                searchHistoryView.isHidden = true
            }
        }
    }
    
    private lazy var searchTableView : UITableView = {
        let view = UITableView(frame: CGRect.zero, style: .plain)
        view.backgroundColor = FZM_BackgroundColor
        view.dataSource = self
        view.delegate = self
        view.tableHeaderView = UIView(frame: CGRect.zero)
        view.tableFooterView = UIView(frame: CGRect.zero)
        view.rowHeight = 50
        view.register(FZMFullTextSearchCell.self, forCellReuseIdentifier: "FZMFullTextSearchCell")
        view.separatorColor = FZM_LineColor
        view.keyboardDismissMode = .onDrag
        view.showsVerticalScrollIndicator = false
        return view
    }()
    
    private lazy var headerView : UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 50))
        return view
    }()
    
    private lazy var noDataView: UIView = {
        let v = UIView.init(frame: CGRect.init(x: 0, y: 0, width: ScreenWidth, height: ScreenHeight))
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
    
    private lazy var cancelBtn : UIButton = {
        let btn = UIButton()
        btn.setAttributedTitle(NSAttributedString(string: "取消", attributes: [.foregroundColor:FZM_TintColor,.font:UIFont.regularFont(16)]), for: .normal)
        return btn
    }()
    
    private lazy var searchBlockView : UIView = {
        let view = UIView()
        view.layer.backgroundColor = FZM_LineColor.cgColor
        view.layer.cornerRadius = 20
        view.tintColor = FZM_GrayWordColor
        let imageV = UIImageView(image: GetBundleImage("tool_search")?.withRenderingMode(.alwaysTemplate))
        view.addSubview(imageV)
        imageV.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(15)
            m.size.equalTo(CGSize(width: 17, height: 18))
        })
        view.addSubview(searchInput)
        searchInput.snp.makeConstraints({ (m) in
            m.top.bottom.right.equalToSuperview()
            m.left.equalTo(imageV.snp.right).offset(10)
        })
        return view
    }()
    
    private lazy var searchInput : UITextField = {
        let input = UITextField()
        input.tintColor = FZM_TintColor
        input.textAlignment = .left
        input.font = UIFont.regularFont(16)
        input.textColor = FZM_BlackWordColor
        input.attributedPlaceholder = NSAttributedString(string: self.getSearchPlaceholder(with: self.searchType), attributes: [.foregroundColor:FZM_GrayWordColor,.font:UIFont.regularFont(16)])
        input.returnKeyType = .search
        input.addTarget(self, action: #selector(textFiledEditChanged(_:)), for: .editingChanged)
        input.delegate = self
        return input
    }()

    init(searchType: FZMFullTextSearchType = .all, limitCount: Int = 3, isHideHistory: Bool = false) {
        self.searchType = searchType
        var array =  [IMGroupModel]()
        IMConversationManager.shared().convertGroupListToGroupSectionArray(by: IMConversationManager.shared().groupList).forEach { array = array + $0.groupArr
        }
        self.groupArrayForSearch = array // 保持groupArrayForSearch排序和通讯里面的排序一致, 不直接使用IMConversationManager.shared().groupList
        self.friendArrayForSearch = IMContactManager.shared().getAllFriend()
        super.init()
        
        self.limitCount = limitCount
        self.searchHistoryView.isHidden = isHideHistory
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let searchHistoriesCache = FZM_UserDefaults.getUserObject(forKey: SearchHistoryUserDefaultsKey) as? [String], !searchHistoriesCache.isEmpty {
            self.searchHistories = searchHistoriesCache
        }
        
        self.createUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.searchString == nil {
            searchInput.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.global().async {
            let count = (Int((try? Keychain.init().getString(CHAT33_USER_SHOW_WALLET_KEY)) ?? "0") ?? 0)
            if count < 20 {
                try? Keychain.init().set("0", key: (CHAT33_USER_SHOW_WALLET_KEY))
            }
        }
    }
    
    private func createUI() {
        self.view.addSubview(cancelBtn)
        cancelBtn.snp.makeConstraints { (m) in
            m.right.equalToSuperview()
            m.width.equalTo(65)
            m.height.equalTo(40)
            m.top.equalToSuperview().offset(StatusBarHeight + 5)
        }
        self.view.addSubview(searchBlockView)
        searchBlockView.snp.makeConstraints { (m) in
            m.top.bottom.equalTo(cancelBtn)
            m.right.equalTo(cancelBtn.snp.left)
            m.left.equalToSuperview().offset(15)
        }
        self.view.addSubview(searchTableView)
        searchTableView.snp.makeConstraints { (m) in
            m.left.right.bottom.equalToSuperview()
            m.top.equalTo(searchBlockView.snp.bottom).offset(5)
        }
        
        cancelBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            self?.popBack()
        }.disposed(by: disposeBag)
        
        searchTableView.addSubview(searchHistoryView)
    }
    
    private func getSearchPlaceholder(with searchType: FZMFullTextSearchType) -> String {
        switch searchType {
        case .friend:
            return "搜索联系人"
        case .group:
            return "搜索群聊"
        case .chatRecord:
            return "搜索聊天记录"
        case .all:
            return "搜索联系人、群、聊天记录"
        }
    }
    
}

extension FZMFullTextSearchVC {
    private func insertSearchHistory(searchString: String) {
        guard !searchString.isEmpty else { return }
        self.searchHistories.remove(at: searchString)
        self.searchHistories.insert(searchString, at: 0)
        if self.searchHistories.count > 10 {
            self.searchHistories.removeLast()
        }
        FZM_UserDefaults.setUserValue(self.searchHistories, forKey: SearchHistoryUserDefaultsKey)

    }
    
    private func deleteSearchHistory(searchString: String) {
        self.searchHistories.remove(at: searchString)
        FZM_UserDefaults.setUserValue(self.searchHistories, forKey: SearchHistoryUserDefaultsKey)
    }
    
    private func clearAllSearchHistories() {
        self.searchHistories.removeAll()
        FZM_UserDefaults.setUserValue(self.searchHistories, forKey: SearchHistoryUserDefaultsKey)
    }
    
}

extension FZMFullTextSearchVC {
    
    @objc private func textFiledEditChanged(_ textField: UITextField) {
        textField.limitText(with: 30)
        if textField.markedTextRange == nil ||
            textField.markedTextRange?.isEmpty ?? false {
            if let text = textField.text {
                self.search(text)
            }
        }
    }
    
    private func search(_ text: String) {
        if text.isEmpty {
            self.noDataView.removeFromSuperview()
        } else if noDataView.superview == nil {
            self.searchTableView.addSubview(self.noDataView)
        }
        self.noDataView.isHidden = true
        self.searchHistoryView.isHidden = !text.isEmpty
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if text == self.searchInput.text, !text.isEmpty {
                self.insertSearchHistory(searchString: text)
            }
        }
        self.refreshSearchTableView(searchString: text.isEmpty ? nil : text)
    }
    
    private func refreshSearchTableView(searchString: String?) {
        self.refreshQueue.async {
            self.dataSource.removeAll()
            if let searchString = searchString, !searchString.isEmpty {
                if let friendSearchModelList = self.searchFrend(searchString) {
                     self.dataSource.append(friendSearchModelList)
                }
                if let groupSearchModelList = self.searchGroup(searchString) {
                    self.dataSource.append(groupSearchModelList)
                }
                if let chatRecordSearchModelList = self.searchChatRecord(searchString) {
                    self.dataSource.append(chatRecordSearchModelList)
                }
            }
            DispatchQueue.main.sync {
                self.searchString = searchString
                self.searchTableView.reloadData()
            }
        }
    }
    
    private func searchFrend(_ text: String) -> [IMFullTextSearchVM]? {
        guard self.searchType == .all || self.searchType == .friend else { return nil }
        let friendSearchModelList = self.friendArrayForSearch.filter { $0.name.lowercased().contains(text.lowercased()) || $0.remark.lowercased().contains(text.lowercased()) }.compactMap { return IMFullTextSearchVM.init(friend: $0) }
        return friendSearchModelList.isEmpty ? nil : friendSearchModelList
    }
    
    private func searchGroup(_ text: String) -> [IMFullTextSearchVM]? {
        guard self.searchType == .all || self.searchType == .group else { return nil }
        let groupSearchModelList = self.groupArrayForSearch.filter { $0.name.lowercased().contains(text.lowercased()) }.compactMap { return IMFullTextSearchVM.init(group: $0)
        }
        return groupSearchModelList.isEmpty ? nil : groupSearchModelList
        
    }
    
    private func searchChatRecord(_ text: String) -> [IMFullTextSearchVM]? {
        guard self.searchType != .friend && self.searchType != .group else { return nil }
        var specificId: String? = nil
        if case let FZMFullTextSearchType.chatRecord(sId) = self.searchType {
            specificId = sId
        }
        var chatRecordSearchModelList: [IMFullTextSearchVM]
        let msgs = SocketMessage.searchMsg(searchString: text, conversationId: specificId)
        if specificId == nil {
            let divideMsgs = Array.init(msgs.reduce(into: Dictionary<String,[SocketMessage]>.init(), { (into, msg) in
                let key = msg.conversationId + "key" + String.init(msg.channelType.rawValue)
                if into[key] == nil {
                    var arr = Array<SocketMessage>.init()
                    arr.append(msg)
                    into[key] = arr
                } else {
                    into[key]?.append(msg)
                }
            }).values)
            chatRecordSearchModelList = divideMsgs.compactMap { IMFullTextSearchVM.init(msgs: $0) }.sorted(by: >)
        } else {
            chatRecordSearchModelList = msgs.compactMap{ IMFullTextSearchVM.init(msgs: [$0]) }
        }
        return chatRecordSearchModelList.isEmpty ? nil : chatRecordSearchModelList
    }
}


extension FZMFullTextSearchVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
}

extension FZMFullTextSearchVC {
    private func getSecitonHeaderView(section: Int, title: String, isShowMore: Bool) -> UIView {
        let view = UIView()
        view.backgroundColor = FZM_BackgroundColor
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: title)
        if case let FZMFullTextSearchType.chatRecord(specificId) = self.searchType, specificId != nil {
            self.dataSource[section].first?.nameSubject.subscribe(onNext: { (name) in
                if let name = name {
                    lab.text = "\"\(name)\"" + "的记录"
                }
            }).disposed(by: disposeBag)
        }
        view.addSubview(lab)
        lab.snp.makeConstraints { (m) in
            m.left.equalToSuperview().offset(15)
            m.bottom.equalToSuperview()
            m.height.equalTo(30)
        }
        if isShowMore {
            let btn = UIButton.init(type: .custom)
            btn.setTitle("查看更多", for: .normal)
            btn.setTitleColor(FZM_TintColor, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            btn.titleLabel?.textAlignment = .right
            btn.enlargeClickEdge(5, 0, 0, 25)
            let moreData = self.dataSource[section]
            btn.rx.controlEvent(.touchUpInside).subscribe(onNext: {[weak self] (_) in
                self?.showMore(searchType: moreData[0].type, dataSource: [moreData])
                self?.view.endEditing(true)
            }).disposed(by: disposeBag)
            view.addSubview(btn)
            btn.snp.makeConstraints { (m) in
                m.centerY.equalTo(lab)
                m.height.equalTo(20)
                m.width.equalTo(70)
                m.right.equalToSuperview().offset(-25)
            }
            let imV = UIImageView(image: GetBundleImage("me_more"))
            view.addSubview(imV)
            imV.snp.makeConstraints { (m) in
                m.centerY.equalTo(btn)
                m.right.equalToSuperview().offset(-16)
                m.size.equalTo(CGSize(width: 4, height: 15))
            }
        }
        return view
    }
    
    private func showMore(searchType: FZMFullTextSearchType, dataSource: [[IMFullTextSearchVM]]?) {
        let vc = FZMFullTextSearchVC.init(searchType: searchType)
        vc.dataSource = dataSource ?? [[IMFullTextSearchVM]]()
        vc.searchString = self.searchString
        vc.searchInput.text = searchString
        vc.searchHistoryView.isHidden = true
        vc.limitCount = NSInteger.max
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func goChat(chatId: String, type: SocketChannelType, locationMsg:(String, String)? = nil ) {
        let conversation = IMConversationManager.shared().getConversation(with: chatId, type: type)
        let vc = FZMConversationChatVC(with: conversation, locationMsg: locationMsg)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension FZMFullTextSearchVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < self.dataSource.count else { return nil}
        let title = self.dataSource[section].first?.type.titit ?? ""
        let isShowMore = self.dataSource[section].count > limitCount
        let v = self.getSecitonHeaderView(section: section, title: title, isShowMore: isShowMore)
        return v
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 15
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView.init(frame: CGRect.init(x: 0, y: 0, width: ScreenWidth, height: 15))
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        self.noDataView.isHidden = !self.dataSource.isEmpty
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < self.dataSource.count else { return 0 }
        let count = self.dataSource[section].count
        return count > self.limitCount ? self.limitCount : count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FZMFullTextSearchCell", for: indexPath) as! FZMFullTextSearchCell
        if indexPath.section < self.dataSource.count,
            indexPath.row < self.dataSource[indexPath.section].count {
            let model = self.dataSource[indexPath.section][indexPath.row]
            cell.searchString = self.searchString
            cell.configure(with: model)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section < self.dataSource.count,
            indexPath.row < self.dataSource[indexPath.section].count
        else { return }
        let model = self.dataSource[indexPath.section][indexPath.row]
        switch model.type {
        case .friend:
             FZMUIMediator.shared().pushVC(.goChat(chatId: model.typeId, type: .person))
        case .group:
            FZMUIMediator.shared().pushVC(.goChat(chatId: model.typeId, type: .group))
        case .chatRecord:
            if model.msgs.count == 1,
                let chatId = model.msgs.first?.conversationId,
                let type = model.msgs.first?.channelType {
                self.goChat(chatId: chatId, type: type, locationMsg: (model.msgs.first?.msgId ?? "", self.searchString ?? ""))
            } else if let chatId = model.msgs.first?.conversationId {
                self.showMore(searchType: .chatRecord(specificId: chatId), dataSource: [model.msgs.compactMap({IMFullTextSearchVM.init(msgs: [$0])})])
            }
            break
        case .all:
            break
        }
    }
    
    
}
