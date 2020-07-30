//
//  FZMContactApplyListVC.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/16.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import MJRefresh

class FZMContactApplyListVC: FZMBaseViewController {

    private var listArr = [IMContactApplyModel]()
    private var modelArr = [[IMContactApplyModel]]()
    
    lazy var applyListView : UITableView = {
        let view = UITableView(frame: CGRect.zero, style: .grouped)
        view.backgroundColor = FZM_BackgroundColor
        view.delegate = self
        view.dataSource = self
        view.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        view.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: CGFloat(BottomOffset)))
        if #available(iOS 11.0, *) {
            view.contentInsetAdjustmentBehavior = .never
        }
        view.sectionHeaderHeight = 24.5
        view.sectionFooterHeight = 0.01
        view.separatorStyle = .none
        view.register(FZMContactApplyCell.self, forCellReuseIdentifier: "FZMContactApplyCell")
        view.mj_footer = MJRefreshBackNormalFooter(refreshingTarget: self, refreshingAction: #selector(loadMore))
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "新朋友"
        let addBtn = UIBarButtonItem(image: GetBundleImage("contact_add")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(addBtnClick))
        self.navigationItem.rightBarButtonItems = [addBtn]
        self.createUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IMContactManager.shared().refreshApplyNumber()
    }
    
    @objc func addBtnClick() {
        FZMUIMediator.shared().pushVC(.search(type: .addFriendOrGroup))
    }
    
    private func createUI() {
        self.view.addSubview(applyListView)
        applyListView.snp.makeConstraints { (m) in
            m.edges.equalToSuperview()
        }
        self.loadMore()
    }
    
    @objc private func loadMore() {
        self.showProgress(with: nil)
        let lastId = listArr.last?.applyId
        HttpConnect.shared().getContactApplyList(lastId: lastId) { (list, response) in
            self.hideProgress()
            self.applyListView.mj_footer.endRefreshing()
            guard response.success else {
                self.showToast(with: response.message)
                return
            }
            var list = list
            if let _ = lastId {
                list = list.filter({ (apply) -> Bool in
                    return apply !== list.first
                })
            }
            self.listArr += list
            
            
            let dicGroupByTime = Dictionary(grouping: self.listArr, by: {(model) in
                return model.dateTimeOnlyYM
            })
            self.modelArr = [[IMContactApplyModel]]()
            for section in Array(dicGroupByTime.keys).sorted(by: {$0 > $1}) {
                if let arr = dicGroupByTime[section] {
                    self.modelArr.append(arr.sorted(by: { $0.dateTime > $1.dateTime }))
                }
            }
            
            self.applyListView.mj_footer.isHidden = list.count == 0
            self.applyListView.reloadData()
        }
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


extension FZMContactApplyListVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return modelArr.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modelArr[section].count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let model = modelArr[indexPath.section][indexPath.row]
        let vm = FZMContactApplyVM(with: model)
        return vm.contentHeight
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return FZMContactApplySectionHeaderView(with: modelArr[section].first?.dateTimeOnlyYM)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FZMContactApplyCell", for: indexPath) as! FZMContactApplyCell
        let model = modelArr[indexPath.section][indexPath.row]
        let vm = FZMContactApplyVM(with: model)
        cell.configure(with: vm)
        cell.dealBlock = {[weak model,weak self] (result) in
            guard let strongModel = model else { return }
            if strongModel.type == .friend {
                self?.showProgress()
                IMContactManager.shared().dealFriendApply(userId: strongModel.senderInfo.userId, agree: result, completionBlock: { (response) in
                    self?.hideProgress()
                    guard response.success else {
                        self?.showToast(with: response.message)
                        return
                    }
                    strongModel.status = result ? .agree : .reject
                    self?.applyListView.reloadRows(at: [indexPath], with: .fade)
                })
            }else {
                self?.showProgress()
                IMContactManager.shared().dealGroupApply(groupId: strongModel.receiveInfo.userId, userId: strongModel.senderInfo.userId, agree: result, completionBlock: { (response) in
                    self?.hideProgress()
                    guard response.success else {
                        self?.showToast(with: response.message)
                        return
                    }
                    strongModel.status = result ? .agree : .reject
                    self?.applyListView.reloadRows(at: [indexPath], with: .fade)
                    if result {
                        FZNEncryptKeyManager.shared().updataGroupKey(groupId: strongModel.receiveInfo.userId)
                    }
                })
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = modelArr[indexPath.section][indexPath.row]
        if model.type == .friend {
            if !model.isSender && model.status == .waiting {
                return
            }
            let userId = model.isSender ? model.receiveInfo.userId : model.senderInfo.userId
            self.showProgress()
            HttpConnect.shared().isFriend(userId: userId) { (isFriend, response) in
                self.hideProgress()
                guard let isFriend = isFriend, response.success else {
                    self.showToast(with: response.message)
                    return
                }
                if isFriend {
                    FZMUIMediator.shared().pushVC(.goChat(chatId: userId, type: .person))
                }else {
                    FZMUIMediator.shared().pushVC(.friendInfo(friendId: userId, groupId: nil, source: .search))
                }
            }
        }else {
            if !model.isSender  {
                if model.status != .waiting {
                    self.showProgress()
                    let userId = model.senderInfo.userId
                    HttpConnect.shared().isFriend(userId: userId) { (isFriend, response) in
                        self.hideProgress()
                        guard let isFriend = isFriend, response.success else {
                            self.showToast(with: response.message)
                            return
                        }
                        if isFriend {
                            FZMUIMediator.shared().pushVC(.goChat(chatId: userId, type: .person))
                        }else {
                            FZMUIMediator.shared().pushVC(.friendInfo(friendId: userId, groupId: nil, source: .search))
                        }
                    }
                }
                return
            }
            let groupId = model.receiveInfo.userId
            self.showProgress()
            HttpConnect.shared().isInGroup(groupId: groupId) { (isInGroup, response) in
                self.hideProgress()
                guard let isInGroup = isInGroup, response.success else {
                    self.showToast(with: response.message)
                    return
                }
                if isInGroup {
                    FZMUIMediator.shared().pushVC(.goChat(chatId: groupId, type: .group))
                }else {
                    FZMUIMediator.shared().openInfoVC(with: model.receiveInfo.markId, shareId: nil, isSweep: false)
                }
            }
        }
    }
}
