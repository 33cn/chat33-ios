//
//  FZMAtPeopleVC.swift
//  IMSDK
//  
//  Created by .. on 2019/9/3.
//

import UIKit

class FZMAtPeopleVC: FZMGroupMemberListVC {
    override var headerView: UIView {
        get {
            if !(group.isMaster || group.isManager)  {
                return UIView.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            }
            let v = UIView.init(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 50))
            let imV = UIImageView(image: GetBundleImage("at_all_prople"))
            imV.layer.cornerRadius = 5
            imV.clipsToBounds = true
            imV.contentMode = .scaleAspectFill
            imV.isUserInteractionEnabled = true
            v.addSubview(imV)
            imV.snp.makeConstraints { (m) in
                m.centerY.equalToSuperview()
                m.left.equalToSuperview().offset(15)
                m.size.equalTo(CGSize(width: 35, height: 35))
            }
            let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: "所有人")
            v.addSubview(lab)
            lab.snp.makeConstraints { (m) in
                m.centerY.equalToSuperview()
                m.left.equalTo(imV.snp.right).offset(11)
            }
            let tap = UITapGestureRecognizer.init()
            tap.rx.event.subscribe({[weak self] (_) in
                self?.select(uid: "-1", name: "所有人")
            }).disposed(by: disposeBag)
            v.addGestureRecognizer(tap)
            return v
        }
        set {}
    }
    
    var selectedBlock: ((FZMInputAtItem) -> ())?
    var cancelBlock: (() -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "选择成员"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(cancelClick))
        self.navigationItem.rightBarButtonItems?.remove(at: 0)
    }
    
    override func deal(with list: [IMGroupUserInfoModel]) {
        let list = list.filter({ return $0.userId != IMLoginUser.shared().userId})
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
        masterSection.memberArr = masterSection.memberArr.filter({ return $0.userId != IMLoginUser.shared().userId})
        if masterSection.memberArr.isEmpty {
            sectionArr.remove(at: masterSection)
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
    
    @objc private func cancelClick() {
        self.dismiss(animated: true, completion: nil)
        self.cancelBlock?()
    }
    
    private func select(uid: String, name: String) {
        guard !uid.isEmpty && !name.isEmpty else { return }
        let atItem = FZMInputAtItem.init(uid: uid, name: name)
        self.dismiss(animated: true, completion: nil)
        self.selectedBlock?(atItem)
    }
    
}

extension FZMAtPeopleVC {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let memberSection = memberList[indexPath.section]
        let member = memberSection.memberArr[indexPath.row]
        self.select(uid: member.userId, name: member.showName)
    }
}
