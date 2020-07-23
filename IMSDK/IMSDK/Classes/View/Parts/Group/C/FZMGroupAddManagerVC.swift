//
//  FZMGroupAddManagerVC.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/30.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit

enum FZMGroupSetType {
    case manager //设置为管理员
    case owner //设置为群主
}

class FZMGroupAddManagerVC: FZMGroupMemberListVC {

    private let showType : FZMGroupSetType
    var addBlock : ((IMGroupUserInfoModel)->())?
    
    init(with gid: IMGroupDetailInfoModel, type: FZMGroupSetType = .manager) {
        showType = type
        super.init(with: gid)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItems?.remove(at: 0)
        if showType == .owner {
            self.navigationItem.title = "转让群主"
        }else {
            self.navigationItem.title = "添加管理员"
        }
    }
    
    override func deal(with list: [IMGroupUserInfoModel]) {
        var list = list
        if showType == .owner {
            list = list.filter { $0.memberLevel != .owner }
        }else {
            list = list.filter { $0.memberLevel == .normal }
        }
        var sectionArr = [FZMGroupMemberListSection]()
        var sectionMap = [String:FZMGroupMemberListSection]()
        list.forEach { (member) in
            if member.memberLevel == .normal {
                let titleKey = member.showName.findFirstLetterFromString()
                if let section = sectionMap[titleKey] {
                    section.memberArr.append(member)
                    section.memberArr.sort(by: <)
                }else {
                    let section = FZMGroupMemberListSection(titleKey: titleKey, user: member)
                    sectionMap[titleKey] = section
                    sectionArr.append(section)
                }
            }
            if showType == .owner {
                if member.memberLevel == .manager {
                    let titleKey = "管理员"
                    if let section = sectionMap[titleKey] {
                        section.memberArr.append(member)
                    }else {
                        let section = FZMGroupMemberListSection(titleKey: titleKey, user: member)
                        sectionMap[titleKey] = section
                        sectionArr.append(section)
                    }
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
}

extension FZMGroupAddManagerVC {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let memberSection = memberList[indexPath.section]
        let member = memberSection.memberArr[indexPath.row]
        let block = {
            self.showProgress(with: nil)
            IMConversationManager.shared().setGroupUserLevel(groupId: self.group.groupId, userId: member.userId, level: self.showType == .manager ? .manager : .owner) { (response) in
                self.hideProgress()
                guard response.success else {
                    self.showToast(with: response.message)
                    return
                }
                if self.showType == .manager {
                    member.memberLevel = .manager
                    self.group.managerNumber += 1
                    self.addBlock?(member)
                    self.popBack()
                }else {
                    self.reloadBlock?()
                    self.popBack()
                }
            }
        }
        if showType == .manager {
            block()
        }else if showType == .owner {
            IMContactManager.shared().getUsernameAndAvatar(with: member.userId) { (_, useName, _) in
                let str = NSMutableAttributedString(string: "确定将群主转让给", attributes: [.foregroundColor:FZM_GrayWordColor])
                str.append(NSAttributedString(string: " \(useName.count > 0 ? useName : member.showName) ", attributes: [.foregroundColor:FZM_TintColor]))
                str.append(NSAttributedString(string: "吗?", attributes: [.foregroundColor:FZM_GrayWordColor]))
                let alert = FZMAlertView(with: str) {
                    block()
                }
                alert.show()
            }
        }
    }
}
