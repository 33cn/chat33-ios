//
//  FZMMeCenterVC.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/8.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import SwiftyJSON

let loginArr = [["title":"红包记录","image":"me_redpacket"],
                ["title":"实名认证","image":"me_Certification"],
                ["title":"分享邀请","image":"me_share_download"],
                ["title":"安全管理","image":"me_secure"],
                ["title":"设置中心","image":"tool_configure_center"],
                ["title":"检测更新","image":"me_version"]]


class FZMMeCenterVC: FZMBaseViewController {

    var dataArr = [[String:String]]()
    
    lazy var tableView : UITableView = {
        let view = UITableView(frame: CGRect.zero, style: .plain)
        view.backgroundColor = FZM_BackgroundColor
        view.showsVerticalScrollIndicator = false
        view.rowHeight = 75
//        view.bounces = false
        view.delegate = self
        view.dataSource = self
        view.separatorStyle = .none
        view.tableFooterView = footerView
        view.tableHeaderView = userInfoView
        view.register(FZMMeCenterCell.self, forCellReuseIdentifier: "FZMMeCenterCell")
        return view
    }()
    
    lazy var userInfoView : FZMMeInfoView = {
        let view = FZMMeInfoView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 170))
        view.editNameBlock = {[weak self] in
            let vc = FZMMeUserEditVC.init()
            vc.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        view.qrCodeBlock = {[weak self] in
            FZMUIMediator.shared().pushVC(.qrCodeShow(type: .me))
        }
        view.headImgBlock = {[weak self] in
            let vc = FZMEditHeadImageVC(with: .me)
            vc.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        view.sweepBlock = {[weak self] in
            self?.sweepItemClick()
        }
        return view
    }()
    
    lazy var loginView : FZMLoginView = {
        let view = FZMLoginView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 260))
        view.sendBlock = { (account,type) in
            FZMUIMediator.shared().goLoginView(type: type, account: account)
        }
        return view
    }()
    
    lazy var footerView : UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 55))
        let logoutBtn = UIButton(type: .custom)
        logoutBtn.makeOriginalShdowShow()
        logoutBtn.layer.cornerRadius = 20
        logoutBtn.setAttributedTitle(NSAttributedString(string: "退出账号", attributes: [.foregroundColor:FZM_GrayWordColor,.font:UIFont.regularFont(16)]), for: .normal)
        view.addSubview(logoutBtn)
        logoutBtn.snp.makeConstraints({ (m) in
            m.center.equalToSuperview()
            m.size.equalTo(CGSize(width: ScreenWidth-30, height: 40))
        })
        logoutBtn.rx.controlEvent(.touchUpInside).subscribe({[weak self] (_) in
            let alertController = UIAlertController.init(title: "提示", message: "确定退出登录", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            let okAction = UIAlertAction.init(title: "确定", style: .destructive, handler: { (_) in
                self?.showProgress()
                HttpConnect.shared().logout(completionBlock: { (_) in
                    self?.hideProgress()
                    IMLoginUser.shared().clearUserInfo()
                })
            })
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            self?.present(alertController, animated: true, completion: nil)
        }).disposed(by: disposeBag)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.createUI()
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .user)
        
    }
    var isCanAuth = false
    override func viewWillAppear(_ animated: Bool) {
        userInfoView.refreshIdentificationInfo()
        HttpConnect.shared().moduleState { (response) in
            if let array = response.data?["modules"].arrayValue {
                if app_id == "1001" {
                    array.forEach({ (json) in
                        if json["type"].intValue == 2 {
                            if json["enable"].boolValue, IMLoginUser.shared().currentUser?.workUser == nil {
                                IMLoginUser.shared().getWorkUser()
                            }
                            if !json["enable"].boolValue {
                                IMLoginUser.shared().currentUser?.workUser = nil
                                IMLoginUser.shared().refreshUserInfo()
                            }
                        }
                    })
                }
                if app_id == "1006" {
                    array.forEach({ (json) in
                        if json["type"].intValue == 1 && json["enable"].boolValue {
                            self.isCanAuth = true
                        }
                    })
                }
            }
        }
        self.setDataSource()
        tableView.reloadData()
    }
    
    private func createUI() {
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (m) in
            m.top.equalTo(self.view.snp.top).offset(StatusBarHeight)
            m.left.right.bottom.equalTo(self.view.safeArea)
        }
        let tap = UITapGestureRecognizer()
        tap.cancelsTouchesInView = false
        tap.rx.event.subscribe(onNext:{[weak self] (_) in
            self?.view.endEditing(true)
        }).disposed(by: disposeBag)
        tableView.addGestureRecognizer(tap)
        self.checkUserLogin()
    }
    
    @objc func sweepItemClick() {
        FZMUIMediator.shared().pushVC(.sweepQRCode)
    }
    
    private func checkUserLogin() {
        if IMLoginUser.shared().isLogin {
            tableView.tableFooterView = footerView
            tableView.tableHeaderView = userInfoView
            self.setDataSource()
        }else{
            IMLoginUser.shared().clearUserInfo()
        }
        tableView.reloadData()
    }
    
    private func setDataSource() {
        var array = loginArr
        if !IMSDK.shared().showRedBag {
            array.removeFirst()
            if IMSDK.shared().certificationDelegate == nil {
                array.removeFirst()
            }
        } else if IMSDK.shared().certificationDelegate == nil {
            array.remove(at: 1)
        }
        dataArr = array
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension FZMMeCenterVC: UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  dataArr.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FZMMeCenterCell", for: indexPath) as! FZMMeCenterCell
        let dic = dataArr[indexPath.row]
        cell.configure(with: dic)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dic = dataArr[indexPath.row]
        if dic["title"] == "分享邀请" {
            FZMUIMediator.shared().pushVC(.qrCodeShow(type: .me))
        }else if dic["title"] == "检测更新" {
            FZMUIMediator.shared().checkVersion(true)
        }else if dic["title"] == "设置中心" {
            FZMUIMediator.shared().pushVC(.configureCenter)
            
        }else if dic["title"] == "安全管理" {
            let vc = FZMSecurityManagementVC.init()
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension FZMMeCenterVC: UserInfoChangeDelegate {
    func userLogin() {
        self.checkUserLogin()
    }
    func userLogout() {
        self.checkUserLogin()
    }
    func userInfoChange() {
        
    }
}
