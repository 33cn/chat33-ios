//
//  FZMGroupMemberListView.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/30.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit

class FZMGroupMemberListVC: FZMBaseViewController {

    let group : IMGroupDetailInfoModel
    var reloadBlock : NormalBlock?
    lazy var headerView : UIView = {
        let view = UIView()
        view.addSubview(titleLab)
        titleLab.snp.makeConstraints({ (m) in
            m.edges.equalToSuperview().inset(UIEdgeInsets(top: 11, left: 15, bottom: 11, right: 15))
        })
        view.frame = CGRect(x: 0, y: 0, width: ScreenWidth, height: 46)
        return view
    }()
    
    lazy var titleLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.mediumFont(17), textColor: FZM_BlackWordColor, textAlignment: .left, text: group.showName)
        return lab
    }()
    
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
        cancelBtn.setTitle("取消", for: .normal)
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
        input.attributedPlaceholder = NSAttributedString(string: "搜索群成员", attributes: [.foregroundColor:FZM_GrayWordColor,.font:UIFont.regularFont(16)])
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
    
    lazy var memberListView : UITableView = {
        let view = UITableView(frame: CGRect.zero, style: .plain)
        view.backgroundColor = FZM_BackgroundColor
        view.dataSource = self
        view.delegate = self
        view.tableHeaderView = headerView
        view.tableFooterView = UIView(frame: CGRect.zero)
        view.rowHeight = 50
        view.register(FZMGroupMemberCell.self, forCellReuseIdentifier: "FZMGroupMemberCell")
        view.separatorColor = FZM_LineColor
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.keyboardDismissMode = .onDrag
        view.sc_indexViewConfiguration = SCIndexViewConfiguration.init(indexViewStyle: .default)
        return view
    }()
    
    var memberList = [FZMGroupMemberListSection]()
    var dealtList = [FZMGroupMemberListSection]()
    var originList = [IMGroupUserInfoModel]()
    private var searchString: String?
    
    init(with gid: IMGroupDetailInfoModel) {
        group = gid
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "群成员"
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: GetBundleImage("tool_more"), style: .plain, target: self, action: #selector(moreClick)),
            UIBarButtonItem(image: GetBundleImage("tool_search"), style: .plain, target: self, action: #selector(showSearchView))]
        self.createUI()
        self.refreshData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.hideSearchView()
    }
    
    @objc func hideSearchView() {
        self.searchInput.text = nil
        self.searchString = nil
        self.noDataView.isHidden = true
        self.searchInput.resignFirstResponder()

        if self.memberList != self.dealtList {
            self.memberList = self.dealtList
            self.memberListView.reloadData()
        }
        memberListView.sc_indexViewDataSource = memberList.compactMap({ (section) -> String? in
            return section.titleKey.count > 1 ? " " : section.titleKey
        })
        
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
        self.memberListView.sc_indexViewDataSource = nil
        self.tapControl.isHidden = false
        self.noDataView.isHidden = true
        UIView.animate(withDuration: 0.3) {
            self.searchBlockView.frame = CGRect.init(x: 0, y: 0, width: ScreenWidth, height: StatusNavigationBarHeight)
            self.tapControl.alpha = 1
        }
    }
    
    @objc func moreClick() {
        let addBlock = {
            FZMUIMediator.shared().pushVC(.selectFriend(type: .exclude(self.group.groupId, self.group.isEncryptGroup), completeBlock: {[weak self] in
                self?.refreshData()
                self?.reloadBlock?()
            }))
        }
        let managerBlock = {
            let vc = FZMGroupManagerSetVC(with: self.group)
            vc.changeBlock = {[weak self] in
                self?.refreshData()
            }
            self.navigationController?.pushViewController(vc, animated: true)
        }
        let deleteBlock = {
            let vc = FZMGroupCtrlMemberVC(with: self.group, ctrlType: .delete)
            vc.reloadBlock = {[weak self] in
                self?.refreshData()
                self?.reloadBlock?()
            }
            self.navigationController?.pushViewController(vc, animated: true)
        }
        if group.isMaster {
            let view = FZMMenuView(with: [FZMMenuItem(title: "添加新成员", block: {
                addBlock()
            }),FZMMenuItem(title: "设置管理员", block: {
                managerBlock()
            }),FZMMenuItem(title: "删除成员", block: {
                deleteBlock()
            })])
            view.show(in: CGPoint(x: ScreenWidth-15, y: StatusNavigationBarHeight))
        }else if group.isManager {
            let view = FZMMenuView(with: [FZMMenuItem(title: "添加新成员", block: {
                addBlock()
            }),FZMMenuItem(title: "删除成员", block: {
                deleteBlock()
            })])
            view.show(in: CGPoint(x: ScreenWidth-15, y: StatusNavigationBarHeight))
        }else {
            addBlock()
        }
    }
    
    private func createUI() {
        self.view.addSubview(memberListView)
        memberListView.snp.makeConstraints { (m) in
            m.edges.equalToSuperview()
        }
        
        self.view.addSubview(tapControl)
        tapControl.snp.makeConstraints({ (m) in
            m.left.equalTo(view)
            m.top.equalTo(view)
            m.height.equalTo(ScreenHeight)
            m.width.equalTo(ScreenWidth)
        })
        self.view.addSubview(noDataView)
        noDataView.snp.makeConstraints({ (m) in
            m.edges.equalTo(tapControl)
        })
    }
    
    func refreshData() {
        self.showProgress(with: nil)
        IMConversationManager.shared().getGroupMemberList(groupId: group.groupId) { (list, response) in
            self.hideProgress()
            guard response.success else {
                self.showToast(with: response.message)
                return
            }
            self.deal(with: list)
        }
    }
    
    func deal(with list: [IMGroupUserInfoModel]) {
        var sectionArr = [FZMGroupMemberListSection]()
        var sectionMap = [String:FZMGroupMemberListSection]()
        let masterSection = FZMGroupMemberListSection(titleKey: "群主、管理员", user: group.master!)
        sectionArr.append(masterSection)
        list.forEach { (member) in
            if member.memberLevel == .manager {
                masterSection.memberArr.append(member)
            }else if member.memberLevel == .normal {
                let titleKey = member.showName.findFirstLetterFromString()
                if let section = sectionMap[titleKey] {
                    section.memberArr.append(member)
                }else {
                    let section = FZMGroupMemberListSection(titleKey: titleKey, user: member)
                    sectionMap[titleKey] = section
                    sectionArr.append(section)
                }
            }
        }
        sectionMap.forEach { (_,section) in
            section.memberArr.sort(by: <)
        }
        sectionArr.sort(by: <)
        sectionArr.forEach { self.originList = self.originList + $0.memberArr }//让originList有序
        dealtList = sectionArr
        memberList = sectionArr
        memberListView.reloadData()
        memberListView.sc_indexViewDataSource = memberList.compactMap({ (section) -> String? in
            return section.titleKey.count > 1 ? " " : section.titleKey
        })
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

extension FZMGroupMemberListVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let memberSection = memberList[section]
        let view = UIView()
        view.backgroundColor = FZM_BackgroundColor
        let lab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .left, text: memberSection.getTitle())
        view.addSubview(lab)
        lab.snp.makeConstraints { (m) in
            m.top.bottom.right.equalToSuperview()
            m.left.equalToSuperview().offset(20)
        }
        return view
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return memberList.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let memberSection = memberList[section]
        return memberSection.memberArr.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FZMGroupMemberCell", for: indexPath) as! FZMGroupMemberCell
        let memberSection = memberList[indexPath.section]
        cell.searchString = searchString
        cell.configure(with: memberSection.memberArr[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let memberSection = memberList[indexPath.section]
        let member = memberSection.memberArr[indexPath.row]
        FZMUIMediator.shared().pushVC(.friendInfo(friendId: member.userId, groupId: group.groupId, source: .group(groupId: group.groupId)))
    }
}

extension FZMGroupMemberListVC {

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
            self.searchString = nil
            self.memberList = self.dealtList
            self.memberListView.reloadData()
            return
        }
        let section = FZMGroupMemberListSection.init()
        section.titleKey = ""
        let lowercasedTest = text.lowercased()
        let searchList = self.originList.filter {(!$0.friendRemark.isEmpty && $0.friendRemark.lowercased().contains(lowercasedTest)) || $0.nickname.lowercased().contains(lowercasedTest) || $0.groupNickname.lowercased().contains(lowercasedTest) }
        searchList.forEach {section.memberArr.append($0)}
        if section.memberArr.isEmpty  {
            self.tapControl.isHidden = true
            self.noDataView.isHidden = false
        } else {
            self.tapControl.isHidden = true
            self.noDataView.isHidden = true
            self.searchString = text
            self.memberList = [section]
            self.memberListView.reloadData()
        }
    }
}


class FZMGroupMemberListSection: NSObject, Comparable {
    
    static func < (lhs: FZMGroupMemberListSection, rhs: FZMGroupMemberListSection) -> Bool {
        if lhs.titleKey.contains("群主") || lhs.titleKey.contains("管理员") {
            return true
        }
        if rhs.titleKey.contains("群主") || rhs.titleKey.contains("管理员") {
            return false
        }
        if lhs.titleKey == "#" {
            return false
        }
        if rhs.titleKey == "#" {
            return true
        }
        return lhs.titleKey < rhs.titleKey
    }
    
    static func == (lhs: FZMGroupMemberListSection, rhs: FZMGroupMemberListSection) -> Bool {
        return lhs.titleKey == rhs.titleKey
    }
    
    var titleKey = ""
    var memberArr = [IMGroupUserInfoModel]()
    
    override init() {
        super.init()
    }
    
    init(titleKey: String, user: IMGroupUserInfoModel) {
        self.titleKey = titleKey
        self.memberArr.append(user)
    }
    
    func getTitle() -> String {
        return "\(titleKey)(\(memberArr.count)人)"
    }
}
