//
//  FZMSetSeedVC.swift
//  IMSDK
//
//  Created by .. on 2019/10/25.
//

import UIKit

class FZMSetSeedVC: FZMBaseViewController {
    
    lazy var topImageView: UIImageView = {
        let v = UIImageView.init()
        v.contentMode = .scaleAspectFit
        v.image = GetBundleImage("set_seed_bg")
        return v
    }()
    
    let lab1 = UILabel.getLab(font: UIFont.boldFont(20), textColor: FZM_TitleColor, textAlignment: .center, text: "加密聊天")
    let lab2 = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_BlackWordColor, textAlignment: .left, text: "加密聊天是指用户之间的聊天消息和聊天文件均为加密传输，只有参与者可解密查看，更换设备登录时需输入密聊密码才可解密历史加密消息，若忘记密码则无法解密历史加密消息，需设置新的密聊密码加密未来的消息。")
    
    lazy var confirmBtn : UIButton = {
        let btn = UIButton.getNormalBtn(with: "设置密聊密码")
        btn.layer.backgroundColor = FZM_TintColor.cgColor
        return btn
    }()
    lazy var forgetBtn : UIButton = {
        let btn = UIButton.init()
        btn.titleLabel?.font = UIFont.boldFont(14)
        btn.setTitle("忘记密码", for: .normal)
        btn.setTitleColor(FZM_TintColor, for: .normal)
        btn.addTarget(self, action: #selector(forgetPwd), for: .touchUpInside)
        return btn
    }()
    
    init(isShowForget: Bool) {
        super.init()
        if isShowForget {
            self.confirmBtn.setAttributedTitle(nil, for: .normal)
            self.confirmBtn.setTitle("找回历史加密消息", for: .normal)
            self.confirmBtn.addTarget(self, action: #selector(findHistoryMsg), for: .touchUpInside)
        } else {
            self.forgetBtn.isHidden = true
            self.confirmBtn.addTarget(self, action: #selector(setSeedPwd), for: .touchUpInside)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationController?.navigationBar.isHidden = true
        self.initView()
    }
    
    func initView() {
        self.view.addSubview(topImageView)
        topImageView.snp.makeConstraints { (m) in
            m.top.left.right.equalToSuperview()
            m.height.equalTo(ScreenHeight * 0.41)
        }
        self.view.addSubview(lab1)
        lab1.snp.makeConstraints { (m) in
            m.top.equalTo(topImageView.snp.bottom).offset(30)
            m.centerX.equalToSuperview()
            m.height.equalTo(30)
        }
        lab2.numberOfLines = 0
        self.view.addSubview(lab2)
        lab2.snp.makeConstraints { (m) in
            m.left.equalToSuperview().offset(30)
            m.right.equalToSuperview().offset(-30)
            m.top.equalTo(lab1.snp.bottom).offset(15)
            m.height.equalTo(100)
        }
        
        self.view.addSubview(confirmBtn)
        confirmBtn.snp.makeConstraints { (m) in
            m.top.equalTo(lab2.snp.bottom).offset(50)
            m.left.right.equalTo(lab2)
            m.height.equalTo(40)
        }
        
        self.view.addSubview(forgetBtn)
        forgetBtn.snp.makeConstraints { (m) in
            m.centerX.equalToSuperview()
            m.top.equalTo(confirmBtn.snp.bottom).offset(25)
            m.size.equalTo(CGSize.init(width: 80, height: 20))
        }
        
    }
    
    @objc func setSeedPwd() {
        guard let currentUser = IMLoginUser.shared().currentUser, currentUser.seedInServer.isEmpty else { return }
        //服务端没有助记词 本地也没有
        let vc = FZMSetSeedPwdVC.init(seed: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func findHistoryMsg() {
        guard let seedInServer = IMLoginUser.shared().currentUser?.seedInServer, seedInServer.count > 0 else { return }
        let alert = FZMInputAlertView.init(title: "请输入密聊密码", placehoder: "请输入密码", isSecureTextEntry: true) { (pwd) in
            self.showProgress()
            if let seed = ChatapiByteTostring(ChatapiSeedDecKey(ChatapiEncPasswd(pwd), ChatapiHexTobyte(seedInServer), nil)), !seed.isEmpty {
                IMLoginUser.shared().currentUser?.setSeed(pwd: pwd, seed: seed)
                self.navigationController?.dismiss(animated: true, completion: nil)
            } else {
               self.showToast(with: "密码错误")
            }
        }
        alert.show()
    }
    
    @objc func forgetPwd() {
        let vc = FZMSetSeedPwdVC.init(seed: nil)
        self.navigationController?.pushViewController(vc, animated: true)
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
