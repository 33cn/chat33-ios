//
//  FZMLoginHomeVC.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/11/2.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift

enum AccountInputType {
    case mobile
    case email
}

class FZMLoginHomeVC: FZMBaseViewController {

    private var inputType : AccountInputType = .mobile {
        didSet{
            self.configureView()
        }
    }
    
    lazy var accountInput : UITextField = {
        let input = UITextField()
        input.tintColor = FZM_TintColor
        input.textColor = FZM_BlackWordColor
        input.textAlignment = .center
        input.font = UIFont.mediumFont(17)
        input.attributedPlaceholder = NSAttributedString(string: "请输入手机号", attributes: [.foregroundColor:FZM_GrayWordColor,.font:UIFont.regularFont(15)])
        input.keyboardType = .phonePad
        return input
    }()
    
    lazy var pwdInput : UITextField = {
        let input = UITextField()
        input.tintColor = FZM_TintColor
        input.textColor = FZM_BlackWordColor
        input.textAlignment = .center
        input.font = UIFont.mediumFont(17)
        input.isSecureTextEntry = true
        input.attributedPlaceholder = NSAttributedString(string: "请输入密码", attributes: [.foregroundColor:FZM_GrayWordColor,.font:UIFont.regularFont(15)])
        return input
    }()
    
    lazy var sendBtn : UIButton = {
        let btn = UIButton.getNormalBtn(with: "登录")
        return btn
    }()
    
    lazy var typeSwitchView : FZMTypeSwitchView = {
        let view = FZMTypeSwitchView(with: ["手机","邮箱"], width: 100)
        view.selectBlock = {[weak self] index in
            self?.inputType = index == 0 ? .mobile : .email
        }
        view.snp.makeConstraints({ (m) in
            m.size.equalTo(CGSize(width: 200, height: 32))
        })
        return view
    }()
    
    init(with type: AccountInputType, account: String?) {
        super.init()
        self.inputType = type
        self.accountInput.text = account
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.titleView = self.typeSwitchView
        self.createUI()
    }
    
    @objc func dismissVC() {
        self.navigationController?.dismiss(animated: true, completion: {
            
        })
    }
    
    private func createUI() {
        let lineV = UIView()
        lineV.backgroundColor = FZM_TintColor
        self.view.addSubview(lineV)
        lineV.snp.makeConstraints({ (m) in
            m.top.equalToSuperview().offset(100)
            m.left.equalToSuperview().offset(25)
            m.right.equalToSuperview().offset(-25)
            m.height.equalTo(1)
        })
        self.view.addSubview(accountInput)
        accountInput.snp.makeConstraints({ (m) in
            m.bottom.equalTo(lineV.snp.top)
            m.height.equalTo(45)
            m.left.right.equalTo(lineV)
        })
        
        let lineV2 = UIView()
        lineV2.backgroundColor = FZM_TintColor
        self.view.addSubview(lineV2)
        lineV2.snp.makeConstraints({ (m) in
            m.top.equalTo(lineV.snp.bottom).offset(100)
            m.left.equalToSuperview().offset(25)
            m.right.equalToSuperview().offset(-25)
            m.height.equalTo(1)
        })
        self.view.addSubview(pwdInput)
        pwdInput.snp.makeConstraints({ (m) in
            m.bottom.equalTo(lineV2.snp.top)
            m.height.equalTo(45)
            m.left.right.equalTo(lineV)
        })
        
        self.view.addSubview(sendBtn)
        sendBtn.snp.makeConstraints { (m) in
            m.top.equalTo(lineV2.snp.bottom).offset(30)
            m.height.equalTo(40)
            m.left.right.equalTo(lineV)
        }
        self.makeActions()
    }
    
    private func makeActions() {
        
        Observable.combineLatest([accountInput.rx.text,pwdInput.rx.text]).subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            var isSuccess = false
            if strongSelf.inputType == .mobile {
                strongSelf.accountInput.limitText(with: 11)
                if let text = strongSelf.accountInput.text, text.count == 11 {
                    isSuccess = true
                }
            }else {
                if let text = strongSelf.accountInput.text, text.contains("@") {
                    isSuccess = true
                }
            }
            if let text = strongSelf.pwdInput.text, text.count > 0 {
                
            }else {
                isSuccess = false
            }
            strongSelf.sendBtn.tintColor = isSuccess ? FZM_TintColor : FZM_GrayWordColor
            strongSelf.sendBtn.isEnabled = isSuccess
        }.disposed(by: disposeBag)
        
        sendBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            guard let strongSelf = self, let account = strongSelf.accountInput.text, let pwd = strongSelf.pwdInput.text else { return }
            strongSelf.showProgress(with: "登录中")
            HttpConnect.shared().userLogin(account: account, pwd: pwd, completionBlock: { (user, response) in
                strongSelf.hideProgress()
                strongSelf.dismissVC()
            })
        }.disposed(by: disposeBag)
    }
    
    private func configureView() {
        if inputType == .mobile {
            self.accountInput.attributedPlaceholder = NSAttributedString(string: "请输入手机号", attributes: [.foregroundColor:FZM_GrayWordColor,.font:UIFont.regularFont(15)])
            self.accountInput.keyboardType = .phonePad
        }else {
            self.accountInput.attributedPlaceholder = NSAttributedString(string: "请输入邮箱", attributes: [.foregroundColor:FZM_GrayWordColor,.font:UIFont.regularFont(15)])
            self.accountInput.keyboardType = .emailAddress
        }
        self.accountInput.text = ""
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
