//
//  FZMSecurityManagementVC.swift
//  IMSDK
//
//  Created by .. on 2019/5/29.
//

import UIKit
import RxSwift

class FZMSecurityManagementVC: FZMBaseViewController {

    lazy var desLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .left, text: nil)
    }()
    
    lazy var payPasswordView: UIView = {
        let v = UIView.init()
        v.makeOriginalShdowShow()
        let v1 = UIView.getOnlineView(title: "支付密码", rightView: desLab, showMore: true, showBottomLine: false)
        v.addSubview(v1)
        v1.snp.makeConstraints({ (m) in
            m.height.equalToSuperview()
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.centerY.equalToSuperview()
        })
        return v
    }()
    
    lazy var seedPwdLab: UILabel =  {
        let lab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .right, text: "修改密码")
        return lab
    }()
    
    lazy var chatEncryptPasswordView: UIView = {
        let v = UIView.init()
        v.makeOriginalShdowShow()
        let rightView = seedPwdLab
        let v1 = UIView.getOnlineView(title: "密聊密码", rightView: rightView, showMore: true, showBottomLine: false)
        v.addSubview(v1)
        v1.snp.makeConstraints({ (m) in
            m.height.equalToSuperview()
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.centerY.equalToSuperview()
        })
        return v
    }()
    
    lazy var promptLab1: UILabel = {
      let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: "密聊密码用于加密聊天消息和聊天文件，更换设备登录时需输入密聊密码才可解密历史加密消息，若忘记密码则无法解密历史加密消息，需设置新的密聊密码加密未来的消息，请自行保管好，防止遗失或泄露导致无法找回历史加密聊天消息！")
        lab.numberOfLines = 0
        return lab
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "安全管理"
        self.createUI()
        self.makeActions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard IMSDK.shared().showRedBag else { return }
        IMLoginUserManager.shared().isSetPayPwd { arr in
            guard let isSetPayPwd = arr[0] as? Bool, let response = arr[1] as? HttpResponse else { return }
            if response.success == true {
                self.desLab.text = isSetPayPwd ? "修改密码" : "设置密码"
            }
        }
    }
    
    func createUI() {
        self.view.addSubview(self.payPasswordView)
        self.payPasswordView.snp.makeConstraints { (m) in
            m.height.equalTo(IMSDK.shared().showRedBag ? 50 : 0)
            m.left.equalTo(self.view).offset(16)
            m.right.equalTo(self.view).offset(-16)
            m.top.equalTo(self.safeTop).offset(IMSDK.shared().showRedBag ? 10 : 0)
        }
        
        if  IMSDK.shared().isEncyptChat {
            self.view.addSubview(self.chatEncryptPasswordView)
            self.view.addSubview(self.promptLab1)
            self.chatEncryptPasswordView.snp.makeConstraints { (m) in
                m.height.equalTo(50)
                m.left.right.equalTo(self.payPasswordView)
                m.top.equalTo(self.payPasswordView.snp.bottom).offset(15)
            }
            
            self.promptLab1.snp.makeConstraints { (m) in
                m.left.right.equalTo(self.chatEncryptPasswordView)
                m.top.equalTo(self.chatEncryptPasswordView.snp.bottom).offset(10)
                m.height.greaterThanOrEqualTo(60)
            }
        }
    }
    
    func makeActions() {
        let tap1 = UITapGestureRecognizer.init()
        tap1.rx.event.subscribe {[weak self] (_) in
            self?.payPasswordViewClick()
        }.disposed(by: disposeBag)
        self.payPasswordView.addGestureRecognizer(tap1)
        
        let tap2 = UITapGestureRecognizer.init()
        tap2.rx.event.subscribe {[weak self] (_) in
            self?.chatEncryptPasswordViewClick()
            }.disposed(by: disposeBag)
        self.chatEncryptPasswordView.addGestureRecognizer(tap2)
        
    }
    
    
    func payPasswordViewClick() {
        IMLoginUserManager.shared().isSetPayPwd { arr in
            guard let isSetPayPwd = arr[0] as? Bool, let response = arr[1] as? HttpResponse else { return }
            if response.success == true {
                
            }
        }
    }

    func chatEncryptPasswordViewClick() {
        let vc = FZMChangeSeedPwdVC.init()
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
