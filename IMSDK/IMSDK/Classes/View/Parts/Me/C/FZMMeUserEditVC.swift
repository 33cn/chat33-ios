//
//  FZMMeUserEditVC.swift
//  IMSDK
//
//  Created by .. on 2019/2/26.
//

import UIKit

class FZMMeUserEditVC: FZMBaseViewController {

    let editUserId : String
    
    lazy var remarkBlockView : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        let titleLab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .left, text:"昵称")
        view.addSubview(titleLab)
        titleLab.snp.makeConstraints({ (m) in
            m.left.equalToSuperview().offset(15)
            m.top.equalToSuperview().offset(7)
            m.height.equalTo(23)
        })
        view.addSubview(remarkNumLab)
        remarkNumLab.snp.makeConstraints({ (m) in
            m.top.equalToSuperview().offset(7)
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(17)
        })
        view.addSubview(remarkInput)
        remarkInput.snp.makeConstraints({ (m) in
            m.left.equalTo(titleLab)
            m.right.equalToSuperview()
            m.bottom.equalToSuperview()
            m.height.equalTo(40)
        })
        return view
    }()
    
    lazy var remarkNumLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .right, text: "0/20")
        return lab
    }()
    
    lazy var remarkInput : UITextField = {
        let input = UITextField()
        input.font = UIFont.regularFont(16)
        input.textColor = FZM_BlackWordColor
        input.tintColor = FZM_TintColor
        input.attributedPlaceholder = NSAttributedString(string: "请输入昵称", attributes: [.foregroundColor:FZM_GrayWordColor])
        return input
    }()
    
    

    
    lazy var confirmBtn : UIButton = {
        let btn = UIButton.getNormalBtn(with: "确定")
        btn.layer.cornerRadius = 20
        return btn
    }()
    
    
    override init() {
        editUserId = IMLoginUser.shared().userId
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationItem.title = "修改昵称"
        self.createUI()
    }
    
    override func rt_customBackItem(withTarget target: Any!, action: Selector!) -> UIBarButtonItem! {
        return UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(popBack))
    }
    
    private func createUI() {
        self.view.addSubview(remarkBlockView)
        remarkBlockView.snp.makeConstraints { (m) in
            m.centerX.equalToSuperview()
            m.top.equalToSuperview()
            m.width.equalTo(ScreenWidth - 30.0)
            m.height.equalTo(80)
        }
        let view = UIView()
        view.makeOriginalShdowShow()
        self.view.addSubview(view)
        view.snp.makeConstraints { (m) in
            m.bottom.left.right.equalTo(self.safeArea)
            m.height.equalTo(70)
        }
        view.addSubview(confirmBtn)
        confirmBtn.snp.makeConstraints { (m) in
            m.center.equalToSuperview()
            m.size.equalTo(CGSize(width: ScreenWidth - 30 , height: 40))
        }
        
        confirmBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            self?.commitInfo()
            }.disposed(by: disposeBag)
        
        remarkInput.rx.text.subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.remarkInput.limitText(with: 20)
            if let text = strongSelf.remarkInput.text, text.count > 0 {
                strongSelf.remarkNumLab.text = "\(text.count)/20"
            }else {
                strongSelf.remarkNumLab.text = "0/20"
            }
            }.disposed(by: disposeBag)
        
        remarkInput.addToolBar(with: "确定", target: self, sel: #selector(commitInfo))
        
        if let user = IMLoginUser.shared().currentUser {
            remarkInput.text = user.userName
            remarkNumLab.text = "\(user.userName.count)/20"
        }
    }
    
    @objc func commitInfo() {
        guard let name = remarkInput.text, name.count > 0 else { return }
        self.showProgress(with: nil)
        HttpConnect.shared().editUserName(name: name) { (response) in
            self.hideProgress()
            if response.success {
                self.popBack()
            }else {
                self.showToast(with: response.message)
            }
        }
    }

}
