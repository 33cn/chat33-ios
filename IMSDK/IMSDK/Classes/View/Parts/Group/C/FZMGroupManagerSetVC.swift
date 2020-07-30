//
//  FZMGroupManagerSetVC.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/30.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit

class FZMGroupManagerSetVC: FZMBaseViewController {

    private let group : IMGroupDetailInfoModel
    
    var changeBlock : NormalBlock?
    lazy var memberListView : UITableView = {
        let view = UITableView(frame: CGRect.zero, style: .plain)
        view.backgroundColor = FZM_BackgroundColor
        view.dataSource = self
        view.delegate = self
        view.tableHeaderView = UIView(frame: CGRect.zero)
        view.tableFooterView = bottomView
        view.rowHeight = 50
        view.register(FZMGroupMemberCell.self, forCellReuseIdentifier: "FZMGroupMemberCell")
        view.separatorColor = FZM_LineColor
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        return view
    }()
    
    lazy var bottomView : UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 50))
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_TintColor, textAlignment: .center, text: "添加管理员")
        view.addSubview(lab)
        lab.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.centerX.equalToSuperview().offset(10)
            m.size.equalTo(CGSize(width: 86, height: 23))
        })
        lab.isUserInteractionEnabled = true
        let imageView = UIImageView(image: GetBundleImage("tool_more")?.withRenderingMode(.alwaysTemplate))
        imageView.tintColor = FZM_TintColor
        view.addSubview(imageView)
        imageView.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.right.equalTo(lab.snp.left).offset(-10)
            m.size.equalTo(CGSize(width: 17, height: 17))
        })
        imageView.isUserInteractionEnabled = true
        return view
    }()
    
    var managerList = [IMGroupUserInfoModel]() {
        didSet{
            bottomView.isHidden = managerList.count >= 10
            memberListView.reloadData()
        }
    }
    
    init(with groupModel: IMGroupDetailInfoModel) {
        group = groupModel
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "管理员设置"
        self.createUI()
        self.refreshData()
    }
    
    private func createUI() {
        self.view.addSubview(memberListView)
        memberListView.snp.makeConstraints { (m) in
            m.edges.equalToSuperview()
        }
        
        let addTap = UITapGestureRecognizer()
        addTap.rx.event.subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            let vc = FZMGroupAddManagerVC(with: strongSelf.group)
            vc.addBlock = { model in
                strongSelf.managerList.append(model)
                strongSelf.changeBlock?()
            }
            strongSelf.navigationController?.pushViewController(vc, animated: true)
        }.disposed(by: disposeBag)
        bottomView.addGestureRecognizer(addTap)
    }
    
    private func refreshData() {
        self.showProgress(with: nil)
        IMConversationManager.shared().getGroupMemberList(groupId: group.groupId) { (list, response) in
            self.hideProgress()
            guard response.success else {
                self.showToast(with: response.message)
                return
            }
            self.managerList.removeAll()
            self.managerList = list.filter({ (model) -> Bool in
                return model.memberLevel == .manager
            })
            self.memberListView.reloadData()
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

extension FZMGroupManagerSetVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = FZM_BackgroundColor
        let lab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .left, text:"管理员(\(managerList.count)/10)")
        if section == 0 {
            lab.text = "群主"
        }
        view.addSubview(lab)
        lab.snp.makeConstraints { (m) in
            m.top.bottom.right.equalToSuperview()
            m.left.equalToSuperview().offset(20)
        }
        return view
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return managerList.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FZMGroupMemberCell", for: indexPath) as! FZMGroupMemberCell
        cell.showType = false
        if indexPath.section == 0 {
            cell.configure(with: group.master!)
            cell.showRightDelete = false
        }else {
            cell.configure(with: managerList[indexPath.row])
            cell.showRightDelete = true
            cell.deleteBlock = {[weak self] in
                self?.deleteManager(with: indexPath.row)
            }
        }
        
        return cell
    }
    
    private func deleteManager(with index: Int) {
        self.showProgress(with: nil)
        let member = managerList[index]
        IMConversationManager.shared().setGroupUserLevel(groupId: group.groupId, userId: member.userId, level: .normal) { (response) in
            self.hideProgress()
            guard response.success else {
                self.showToast(with: response.message)
                return
            }
            self.managerList.remove(at: index)
            self.group.managerNumber -= 1
            self.changeBlock?()
        }
    }
}
