//
//  FZMCtrlUserAlertView.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/17.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit

enum IMCtrlUserAlertType {
    case banned//禁言
    case kickOut//踢出
}

class FZMCtrlUserAlertView: UIView {

    private let groupId : String
    private var userInfo : IMGroupUserInfoModel?
    
    private var userList : [String]?

    var showType : IMCtrlUserAlertType

    var selectIndex = 0

    var completeBlock : (()->())?

    lazy var centerView : UIView = {
        let v = UIView()
        v.backgroundColor = FZM_BackgroundColor
        v.clipsToBounds = true
        v.layer.cornerRadius = 5
        let cancelBtn = UIButton(type: .custom)
        cancelBtn.setAttributedTitle(NSAttributedString(string: "取消", attributes: [.font:UIFont.mediumFont(16),.foregroundColor:FZM_TintColor]), for: .normal)
        cancelBtn.addTarget(self, action: #selector(cancelClick), for: .touchUpInside)
        v.addSubview(cancelBtn)
        cancelBtn.snp.makeConstraints({ (m) in
            m.bottom.left.equalToSuperview()
            m.right.equalTo(v.snp.centerX)
            m.height.equalTo(50)
        })
        let confirmBtn = UIButton(type: .custom)
        confirmBtn.setAttributedTitle(NSAttributedString(string: "确定", attributes: [.font:UIFont.mediumFont(16),.foregroundColor:FZM_TintColor]), for: .normal)
        confirmBtn.addTarget(self, action: #selector(confirmClick), for: .touchUpInside)
        v.addSubview(confirmBtn)
        confirmBtn.snp.makeConstraints({ (m) in
            m.bottom.right.equalToSuperview()
            m.left.equalTo(v.snp.centerX)
            m.height.equalTo(50)
        })
        let bottomLine = UIView.getNormalLineView()
        v.addSubview(bottomLine)
        bottomLine.snp.makeConstraints({ (m) in
            m.top.equalTo(confirmBtn)
            m.left.right.equalToSuperview()
            m.height.equalTo(1)
        })
        let centerLine = UIView.getNormalLineView()
        v.addSubview(centerLine)
        centerLine.snp.makeConstraints({ (m) in
            m.top.bottom.equalTo(confirmBtn)
            m.centerX.equalToSuperview()
            m.width.equalTo(1)
        })
        v.addSubview(timeView)
        timeView.snp.makeConstraints({ (m) in
            m.centerX.equalToSuperview()
            m.bottom.equalTo(bottomLine.snp.top).offset(-30)
            m.size.equalTo(CGSize(width: 260, height: 110))
        })
        v.addSubview(timeTitleView)
        timeTitleView.snp.makeConstraints({ (m) in
            m.bottom.equalTo(timeView.snp.top).offset(-15)
            m.left.right.equalToSuperview()
        })
        v.addSubview(titleView)
        titleView.snp.makeConstraints({ (m) in
            m.top.equalToSuperview().offset(30)
            m.left.equalToSuperview().offset(24)
            m.right.equalToSuperview().offset(-24)
        })
        v.addSubview(cancelCtrlBtn)
        cancelCtrlBtn.snp.makeConstraints({ (m) in
            m.top.equalToSuperview().offset(81)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(50)
        })
        cancelCtrlBtn.isHidden = true
        return v
    }()

    lazy var timeView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.itemSize = CGSize(width: 80, height: 50)
        let view = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        view.isScrollEnabled = false
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = UIColor.clear
        view.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "TimeViewCell")
        return view
    }()

    lazy var timeTitleView : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_BlackWordColor, textAlignment: .center, text: nil)
        return lab
    }()

    lazy var titleView : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .center, text: nil)
        lab.numberOfLines = 0
        return lab
    }()

    lazy var cancelCtrlBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.layer.cornerRadius = 5
        btn.layer.borderWidth = 1
        btn.layer.borderColor = FZM_BlackWordColor.cgColor
        btn.setTitleColor(FZM_BlackWordColor, for: .normal)
        btn.titleLabel?.font = UIFont.regularFont(16)
        btn.addTarget(self, action: #selector(cancelCtrlUser), for: .touchUpInside)
        return btn
    }()

    let timeArr : [[String:Any]] = [["title":"永远","number": Int(OnedaySeconds) * 30],["title":"24小时","number":Int(OnedaySeconds)],["title":"2小时","number":7200],["title":"1小时","number":3600],["title":"30分钟","number":1800],["title":"10分钟","number":600],]

    init(with userId: String, groupId: String) {
        showType = .banned
        self.groupId = groupId
        super.init(frame: ScreenBounds)
        self.backgroundColor = UIColor.init(white: 0, alpha: 0.5)
        self.addSubview(centerView)
        centerView.snp.makeConstraints { (m) in
            m.center.equalToSuperview()
            m.width.equalTo(300)
            m.height.equalTo(310)
        }
        switch showType {
        case .banned:
            timeTitleView.text = "选择禁言时间"
        case .kickOut:
            timeTitleView.text = "选择移出时间"
        }
        self.getUserInfo(with: userId, groupId: groupId)
    }
    
    init(with memberList: [String], title: String, groupId: String) {
        showType = .banned
        self.groupId = groupId
        self.userList = memberList
        super.init(frame: ScreenBounds)
        self.backgroundColor = UIColor.init(white: 0, alpha: 0.5)
        self.addSubview(centerView)
        centerView.snp.makeConstraints { (m) in
            m.center.equalToSuperview()
            m.width.equalTo(300)
            m.height.equalTo(310)
        }
        timeTitleView.text = "选择禁言时间"
        let attrStr = NSMutableAttributedString(string: "确定将 ")
        attrStr.append(NSAttributedString(string: title, attributes: [.foregroundColor:UIColor.init(hex: 0x00AAEE)]))
        attrStr.append(NSAttributedString(string:"禁言吗？"))
        titleView.attributedText = attrStr
    }

    private func getUserInfo(with userId : String, groupId: String) {
        IMContactManager.shared().getUserGroupInfo(userId: userId, groupId: groupId) { (model, _, _) in
            self.userInfo = model
            self.reloadView()
        }
    }

    func reloadView() {
        guard let userInfo = self.userInfo else { return }
        if showType == .banned {
            if userInfo.deadline > Date.timestamp {
                centerView.snp.updateConstraints { (m) in
                    m.height.equalTo(370)
                }
                let distance = userInfo.deadline - Date.timestamp
                self.popAnimation(time: distance/1000,name: userInfo.showName)
                timeTitleView.text = "更改禁言时间"
                cancelCtrlBtn.isHidden = false
                cancelCtrlBtn.setTitle("取消禁言", for: .normal)
            }else{
                let attrStr = NSMutableAttributedString(string: "确定将 ")
                attrStr.append(NSAttributedString(string: userInfo.showName, attributes: [.foregroundColor:UIColor.init(hex: 0x00AAEE)]))
                attrStr.append(NSAttributedString(string:"禁言吗？"))
                titleView.attributedText = attrStr
            }
        } else {
            if userInfo.deadline > Date.timestamp {
                centerView.snp.updateConstraints { (m) in
                    m.height.equalTo(370)
                }
                let distance = userInfo.deadline - Date.timestamp
                self.popAnimation(time: distance/1000,name: userInfo.showName)
                timeTitleView.text = "更改移出时间"
                cancelCtrlBtn.isHidden = false
                cancelCtrlBtn.setTitle("取消移出", for: .normal)
            }else{
                let attrStr = NSMutableAttributedString(string: "确定将 ")
                attrStr.append(NSAttributedString(string: userInfo.showName, attributes: [.foregroundColor:UIColor.init(hex: 0x00AAEE)]))
                attrStr.append(NSAttributedString(string:" 移出聊天室吗？"))
                titleView.attributedText = attrStr
            }
        }
    }

    private func popAnimation(time:Double,name:String){
        if time < OnedaySeconds {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            let attrStr = NSMutableAttributedString(string: name, attributes: [.foregroundColor:UIColor.init(hex: 0x00AAEE)])
            attrStr.append(NSAttributedString(string: showType == .banned ? "禁言" : "移出"))
            FZMAnimationTool.countdown(with: titleView, fromValue: time, toValue: 0, block: { [weak self] (useTime) in
                let time = useTime - 8 * 3600
                let date = Date.init(timeIntervalSince1970: TimeInterval(time))
                let mutAttStr = attrStr.mutableCopy() as! NSMutableAttributedString
                mutAttStr.append(NSAttributedString(string: formatter.string(from: date)))
                self?.titleView.attributedText = mutAttStr
                },finishBlock: {[weak self] in
                    self?.hide()
            })
        }else{
            let attrStr = NSMutableAttributedString(string: name, attributes: [.foregroundColor:UIColor.init(hex: 0x00AAEE)])
            attrStr.append(NSAttributedString(string: showType == .banned ? "永远禁言" : "永远移出"))
            self.titleView.attributedText = attrStr
        }
    }

    func show() {
        UIApplication.shared.keyWindow?.addSubview(self)
    }

    func hide() {
        self.removeFromSuperview()
    }

    @objc func cancelCtrlUser(){
        guard let userInfo = self.userInfo else { return }
        self.showProgress(with: nil)
        if showType == .banned {
            IMConversationManager.shared().bannedGroupUser(groupId: self.groupId, userId: userInfo.userId, deadline: 0) { (response) in
                self.hideProgress()
                guard response.success else {
                    self.showToast(with: response.message)
                    return
                }
                self.completeBlock?()
                self.hide()
            }
        }else{
            
        }
    }

    @objc func cancelClick(){
        self.hide()
    }

    @objc func confirmClick(){
        let dic = timeArr[selectIndex]
        var num = Double(dic["number"] as! Int) * 1000 + Date.timestamp
        if selectIndex == 0 {
            num = forverBannedTime * 1000
        }
        self.showProgress(with: nil)
        if showType == .banned {
            if let users = userList {
                IMConversationManager.shared().groupBannedSet(groupId: self.groupId, type: 2, users: users, deadline: num) { (response) in
                    self.hideProgress()
                    guard response.success else {
                        self.showToast(with: response.message)
                        return
                    }
                    self.completeBlock?()
                    self.hide()
                }
            }else {
                guard let userInfo = self.userInfo else { return }
                IMConversationManager.shared().bannedGroupUser(groupId: userInfo.groupId, userId: userInfo.userId, deadline: num) { (response) in
                    self.hideProgress()
                    guard response.success else {
                        self.showToast(with: response.message)
                        return
                    }
                    self.completeBlock?()
                    self.hide()
                }
            }
        }else{
            
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension FZMCtrlUserAlertView:UICollectionViewDelegate,UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return timeArr.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TimeViewCell", for: indexPath)
        cell.contentView.layer.cornerRadius = 5
        cell.contentView.layer.borderColor = FZM_BlackWordColor.cgColor
        cell.contentView.layer.borderWidth = 1
        cell.contentView.backgroundColor = UIColor.clear
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        let dic = timeArr[indexPath.item]
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .center, text: dic["title"] as? String)
        cell.contentView.addSubview(lab)
        lab.snp.makeConstraints { (m) in
            m.edges.equalToSuperview()
        }
        if selectIndex == indexPath.item {
            lab.textColor = UIColor.white
            cell.contentView.backgroundColor = FZM_TintColor
            cell.contentView.layer.borderColor = FZM_TintColor.cgColor
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectIndex = indexPath.item
        collectionView.reloadData()
    }
}

