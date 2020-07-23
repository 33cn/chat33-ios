//
//  FZMPromoteHotGroupVC.swift
//  IMSDK
//
//  Created by .. on 2019/7/3.
//

import UIKit

class FZMPromoteHotGroupVC: FZMBaseViewController {
    
    lazy var headerView: UIView = {
       let v = UIView.init(frame: CGRect.init(x: 0, y: 0, width: ScreenWidth, height: 50))
        v.backgroundColor = FZM_BackgroundColor
        
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = UIFont.regularFont(14)
        btn.setImage(GetBundleImage("chat_hot_group"), for: .normal)
        btn.setImage(GetBundleImage("chat_hot_group"), for: .highlighted)
        btn.setTitle("  热门群聊", for: .normal)
        btn.setTitleColor(FZM_TintColor, for: .normal)
        
        v.addSubview(btn)
        btn.snp.makeConstraints({ (m) in
            m.left.equalToSuperview().offset(20)
            m.centerY.equalToSuperview()
            m.size.equalTo(CGSize.init(width: 80, height: 20))
        })
        
        let changeBtn = UIButton(type: .custom)
        changeBtn.titleLabel?.font = UIFont.regularFont(14)
        changeBtn.setTitle("换一批", for: .normal)
        changeBtn.setTitleColor(FZM_TintColor, for: .normal)
        changeBtn.addTarget(self, action: #selector(changeBtnPress), for: .touchUpInside)
        v.addSubview(changeBtn)
        changeBtn.snp.makeConstraints({ (m) in
            m.top.equalTo(btn)
            m.right.equalToSuperview().offset(-15)
            m.size.equalTo(CGSize.init(width: 43, height: 20))
        })
        return v
    }()
    
    lazy var listView : UITableView = {
        let view = UITableView(frame: CGRect.zero, style: .plain)
        view.backgroundColor = FZM_BackgroundColor
        view.dataSource = self
        view.delegate = self
        view.tableHeaderView = headerView
        view.tableFooterView = UIView(frame: CGRect.zero)
        view.rowHeight = 65
        view.register(FZMPromoteHotGroupCell.self, forCellReuseIdentifier: "FZMPromoteHotGroupCell")
        view.separatorStyle = .none
        return view
    }()
    
  
    
    lazy var bottomView: UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        view.backgroundColor = FZM_WhiteColor
        let btn = UIButton.getNormalBtn(with: "马上加入")
        view.addSubview(btn)
        btn.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(15)
            m.size.equalTo(CGSize(width: (ScreenWidth - 30) , height: 40))
            m.left.equalToSuperview().offset(15)
        }
        btn.addTarget(self, action: #selector(joinRooms), for: .touchUpInside)
        return view
    }()
    
    var listArr: [FZMPromoteHotGroup] = Array.init()
    var times = 1
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "猜你喜欢"
        
        self.createViews()
        
        self.loadData()
        
    }
    
    func loadData() {
        self.showProgress()
        IMConversationManager.shared().getRecommendRoom(number: 6, times: self.times) { (response) in
            self.hideProgress()
            guard response.success else {
                self.showToast(with: response.message)
                return
            }
            self.listArr = response.data?["roomList"].arrayValue.compactMap({ (json) -> FZMPromoteHotGroup? in
                return FZMPromoteHotGroup.init(json: json)
            }) ?? []
            self.listView.reloadData()
        }
    }
    
    @objc func changeBtnPress() {
        self.times = self.times + 1
        self.loadData()
    }
    
    @objc func joinRooms() {
        let rooms = self.listArr.compactMap { (hotGroup) -> String? in
            return hotGroup.isSelected ? hotGroup.id : nil
        }
        guard !rooms.isEmpty else {
            self.showToast(with: "请选择群聊")
            return
        }
        self.showProgress()
        IMConversationManager.shared().batchJoinRoomApply(rooms: rooms) { (response) in
            self.hideProgress()
            guard response.success else {
                self.showToast(with: response.message)
                return
            }
            self.showToast(with: "申请加入群聊成功")
            if let joinedRooms = response.data?["rooms"].arrayValue {
                joinedRooms.forEach({ (json) in
                    FZNEncryptKeyManager.shared().updataGroupKey(groupId: json.stringValue)
                })
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self.popBack()
            })
        }
    }

    func createViews() {
        
        self.view.addSubview(self.bottomView)
        self.bottomView.snp.makeConstraints { (m) in
            m.bottom.left.right.equalToSuperview()
            m.height.equalTo(70 + BottomOffset)
        }
        
        self.view.addSubview(self.listView)
        self.listView.snp.makeConstraints { (m) in
            m.top.left.right.equalToSuperview()
            m.bottom.equalTo(bottomView.snp.top)
        }
    }

}

extension FZMPromoteHotGroupVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FZMPromoteHotGroupCell", for: indexPath) as! FZMPromoteHotGroupCell
        guard indexPath.row >= 0 && indexPath.row < listArr.count else { return cell }
        let model = listArr[indexPath.row]
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row >= 0 && indexPath.row < listArr.count else { return }
        let model = listArr[indexPath.row]
        model.isSelected = !model.isSelected
        self.listView.reloadData()
    }
}
