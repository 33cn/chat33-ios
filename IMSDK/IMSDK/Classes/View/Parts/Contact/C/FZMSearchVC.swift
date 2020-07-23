//
//  FZMSearchVC.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/15.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit

enum FZMSearchVCShowType {
    case addFriendOrGroup
    case localInfo
}

class FZMSearchVC: FZMBaseViewController {
    
    private var showType : FZMSearchVCShowType
    
    var listArr = [IMSearchInfoModel]()
    
    lazy var listView : UITableView = {
        let view = UITableView(frame: CGRect.zero, style: .plain)
        view.backgroundColor = FZM_BackgroundColor
        view.dataSource = self
        view.delegate = self
        view.tableHeaderView = UIView(frame: CGRect.zero)
        view.tableFooterView = UIView(frame: CGRect.zero)
        view.rowHeight = 50
        view.register(FZMSearchCell.self, forCellReuseIdentifier: "FZMSearchCell")
        view.separatorColor = FZM_LineColor
        return view
    }()
    
    lazy var headerView : UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 50))
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_BlackWordColor, textAlignment: .center, text: nil)
        view.addSubview(lab)
        lab.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.centerX.equalToSuperview().offset(-20)
            m.height.equalTo(20)
        })
        let imageView = UIImageView(image: GetBundleImage("me_qrcode")?.withRenderingMode(.alwaysTemplate))
        imageView.tintColor = FZM_TintColor
        view.addSubview(imageView)
        imageView.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.left.equalTo(lab.snp.right).offset(10)
            m.width.height.equalTo(20)
        })
        if let user = IMLoginUser.shared().currentUser {
            lab.text = "我的账号：\(user.securityAccount)"
        }
        imageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe({[weak self] (_) in
            guard let _ = self else { return }
            FZMUIMediator.shared().pushVC(.qrCodeShow(type: .me))
        }).disposed(by: disposeBag)
        imageView.addGestureRecognizer(tap)
        return view
    }()
    
    lazy var hotGroupBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.layer.cornerRadius = 17.5
        btn.layer.borderWidth = 1
        btn.layer.borderColor = FZM_TintColor.cgColor
        btn.clipsToBounds = true
        btn.titleLabel?.font = UIFont.regularFont(16)
        btn.setImage(GetBundleImage("chat_hot_group"), for: .normal)
        btn.setImage(GetBundleImage("chat_hot_group"), for: .highlighted)
        btn.setTitle("  热门群聊", for: .normal)
        btn.setTitleColor(FZM_TintColor, for: .normal)
        return btn
    }()
    
    lazy var footerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 246))
        var noDataView = FZMNoDataView(image: GetBundleImage("nodata_search"), imageSize: CGSize(width: 250, height: 200), desText: "没有匹配的对象", btnTitle: nil, clickBlock: nil)
        view.addSubview(noDataView)
        noDataView.snp.makeConstraints({ (m) in
            m.top.equalToSuperview().offset(65)
            m.left.right.equalToSuperview()
            m.height.equalTo(181)
        })
        return view
    }()
    
    lazy var cancelBtn : UIButton = {
        let btn = UIButton()
        btn.setAttributedTitle(NSAttributedString(string: "取消", attributes: [.foregroundColor:FZM_TintColor,.font:UIFont.regularFont(16)]), for: .normal)
        return btn
    }()
    
    lazy var searchBlockView : UIView = {
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
    
    lazy var searchInput : UITextField = {
        let input = UITextField()
        input.tintColor = FZM_TintColor
        input.textAlignment = .left
        input.font = UIFont.regularFont(16)
        input.textColor = FZM_BlackWordColor
        input.attributedPlaceholder = NSAttributedString(string: "搜索联系人、群、聊天室、聊天记录等", attributes: [.foregroundColor:FZM_GrayWordColor,.font:UIFont.regularFont(16)])
        input.returnKeyType = .search
        input.delegate = self
        return input
    }()

    init(with showType: FZMSearchVCShowType) {
        self.showType = showType
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.createUI()
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
        self.view.addSubview(listView)
        listView.snp.makeConstraints { (m) in
            m.left.right.bottom.equalToSuperview()
            m.top.equalTo(searchBlockView.snp.bottom).offset(5)
        }
        
        listView.addSubview(hotGroupBtn)
        hotGroupBtn.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(90)
            m.centerX.equalToSuperview()
            if IMSDK.shared().showPromoteHotGroup {
                m.size.equalTo(CGSize(width: 150, height: 35))
            } else {
                m.size.equalTo(CGSize(width: 0, height: 0))
            }
        }
        
        hotGroupBtn.rx.controlEvent(.touchUpInside).subscribe(onNext: { (_) in
            FZMUIMediator.shared().pushVC(.goPromoteHotGroup)
        }).disposed(by: disposeBag)
        
        if showType == .addFriendOrGroup {
            searchInput.attributedPlaceholder = NSAttributedString(string: "输入手机号、UID或群号", attributes: [.foregroundColor:FZM_GrayWordColor,.font:UIFont.regularFont(16)])
            self.listView.tableHeaderView = self.headerView
        }
        
        cancelBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            self?.popBack()
        }.disposed(by: disposeBag)
        
        searchInput.rx.text.subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            if (strongSelf.searchInput.text?.isEmpty ?? false) && strongSelf.listArr.isEmpty {
                strongSelf.hotGroupBtn.isHidden = false
                strongSelf.listView.tableFooterView = UIView(frame: CGRect.zero)
            } else {
                strongSelf.hotGroupBtn.isHidden = true
            }
        }.disposed(by: disposeBag)
        
        searchInput.becomeFirstResponder()
    }
    
    private func search(_ text: String) {
        listArr.removeAll()
        if showType == .addFriendOrGroup {
            self.showProgress(with: nil)
            HttpConnect.shared().searchContact(searchId: text) { (list, response) in
                self.hideProgress()
                guard response.success else {
                    self.showToast(with: response.message)
                    return
                }
                self.listArr = list
                self.listView.tableFooterView = list.count == 0 ? self.footerView : UIView(frame: CGRect.zero)
                self.listView.reloadData()
            }
        }else {
            
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

extension FZMSearchVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n", let text = self.searchInput.text, text.count > 0 {
            var isEmpty = true
            text.forEach { (c) in
                if c != " " && c != "\n" {
                    isEmpty = false
                }
            }
            if !isEmpty {
                self.search(self.searchInput.text!)
            }
            self.searchInput.endEditing(true)
            return false
        }
        return true
    }
}

extension FZMSearchVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FZMSearchCell", for: indexPath) as! FZMSearchCell
        let model = listArr[indexPath.row]
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = listArr[indexPath.row]
        if model.type == .person {
            FZMUIMediator.shared().pushVC(.friendInfo(friendId: model.uid, groupId: nil, source: .search))
        }else {
            FZMUIMediator.shared().pushVC(.groupInfo(data: model, type: .search))
        }
    }
}
