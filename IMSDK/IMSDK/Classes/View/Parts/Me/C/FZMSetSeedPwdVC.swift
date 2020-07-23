//
//  FZMSetSeedPwdVC.swift
//  IMSDK
//
//  Created by .. on 2019/10/25.
//

import UIKit
import RxSwift

class FZMSetSeedPwdVC: FZMBaseViewController {
    
    lazy var questionBlockView : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        view.addSubview(questionInput)
        questionInput.snp.makeConstraints({ (m) in
            m.left.equalTo(view).offset(15)
            m.right.equalToSuperview().offset(-14)
            m.bottom.equalToSuperview()
            m.height.equalTo(50)
        })
        return view
    }()
    
    lazy var questionInput : UITextField = {
        let input = UITextField()
        input.font = UIFont.regularFont(16)
        input.textColor = FZM_BlackWordColor
        input.tintColor = FZM_TintColor
        input.backgroundColor = UIColor.clear
        input.isSecureTextEntry = true
        input.addSubview(questionPlaceLab)
        questionPlaceLab.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(4)
            m.size.equalTo(CGSize(width: 150, height: 23))
        })
        return input
    }()
    lazy var questionPlaceLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .left, text: "请设置密码")
        return lab
    }()
    
    lazy var forgetPwdLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_TintColor, textAlignment: .left, text: "忘记密码")
        lab.isUserInteractionEnabled = true
        lab.enlargeClickEdge(10, 0, 10, 10)
        let tap = UITapGestureRecognizer.init()
        tap.rx.event.subscribe({[weak self](_) in
            let alertController = UIAlertController.init(title: "提示", message: "重新导入助记词可以重设密码", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            let okAction = UIAlertAction.init(title: "确定", style: .destructive, handler: { (_) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                    self?.popBack()
                })
                FZMUIMediator.shared().pushVC(.goImportSeed(isHideBackBtn: false))
            })
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            self?.present(alertController, animated: true, completion: nil)
            
        }).disposed(by: disposeBag)
        lab.addGestureRecognizer(tap)
        return lab
    }()
    
    lazy var answerBlockView : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        view.addSubview(answerInput)
        answerInput.snp.makeConstraints({ (m) in
            m.left.equalTo(view).offset(15)
            m.right.equalToSuperview().offset(-14)
            m.bottom.equalToSuperview()
            m.height.equalTo(50)
        })
        return view
    }()
    
    lazy var answerInput : UITextField = {
        let input = UITextField()
        input.font = UIFont.regularFont(16)
        input.textColor = FZM_BlackWordColor
        input.tintColor = FZM_TintColor
        input.backgroundColor = UIColor.clear
        input.addSubview(answerPlaceLab)
        input.isSecureTextEntry = true
        answerPlaceLab.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(4)
            m.size.equalTo(CGSize(width: 150, height: 23))
        })
        return input
    }()
    lazy var answerPlaceLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .left, text: "请再次输入新密码")
        return lab
    }()
    
    lazy var confirmBtn : UIButton = {
        let btn = UIButton.getNormalBtn(with: "确定")
        btn.layer.backgroundColor = UIColor(hex: 0xC8D3DE).cgColor
        return btn
    }()
    let seed: String? //兼容老版本 没有设置过密码的助记词
    init(seed: String?) {
        self.seed = seed
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationItem.title = "设置密聊密码"
        let headLab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: "8-16位数字、字母或符号组合")
        self.view.addSubview(headLab)
        headLab.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(15)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(20)
        }
        
        self.view.addSubview(questionBlockView)
        questionBlockView.snp.makeConstraints { (m) in
            m.top.equalTo(headLab.snp.bottom).offset(5)
            m.left.right.equalTo(headLab)
            m.height.equalTo(50)
        }
        self.view.addSubview(answerBlockView)
        answerBlockView.snp.makeConstraints { (m) in
            m.top.equalTo(questionBlockView.snp.bottom).offset(15)
            m.left.right.equalTo(headLab)
            m.height.equalTo(50)
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
        
        let questionBtn = questionInput.addToolBar(with: "确定", target: self, sel: #selector(commitInfo))
        let answerBtn = answerInput.addToolBar(with: "确定", target: self, sel: #selector(commitInfo))
        
        Observable.combineLatest(questionInput.rx.text, answerInput.rx.text).subscribe {[weak self, weak questionBtn, weak answerBtn] (event) in
            guard let strongSelf = self else { return }
            strongSelf.questionInput.limitText(with: 16)
            if let text = strongSelf.questionInput.text, text.count > 0 {
                strongSelf.questionPlaceLab.isHidden = true
            }else {
                strongSelf.questionPlaceLab.isHidden = false
            }
            strongSelf.answerInput.limitText(with: 16)
            if let text = strongSelf.answerInput.text, text.count > 0 {
                strongSelf.answerPlaceLab.isHidden = true
            }else {
                strongSelf.answerPlaceLab.isHidden = false
            }
            if strongSelf.answerPlaceLab.isHidden && strongSelf.questionPlaceLab.isHidden {
                strongSelf.confirmBtn.isEnabled = true
                strongSelf.confirmBtn.layer.backgroundColor = FZM_TintColor.cgColor
                questionBtn?.isEnabled = true
                questionBtn?.layer.backgroundColor = FZM_TintColor.cgColor
                answerBtn?.isEnabled = true
                answerBtn?.layer.backgroundColor = FZM_TintColor.cgColor
            }else {
                strongSelf.confirmBtn.isEnabled = false
                strongSelf.confirmBtn.layer.backgroundColor = UIColor(hex: 0xC8D3DE).cgColor
                questionBtn?.isEnabled = false
                questionBtn?.layer.backgroundColor = UIColor(hex: 0xC8D3DE).cgColor
                answerBtn?.isEnabled = false
                answerBtn?.layer.backgroundColor = UIColor(hex: 0xC8D3DE).cgColor
            }
        }.disposed(by: disposeBag)
        
        confirmBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            self?.commitInfo()
        }.disposed(by: disposeBag)
        
    }
    
    @objc func commitInfo() {
        guard let question = questionInput.text, let answer = answerInput.text, question == answer else {
            self.showToast(with: "两次输入的密码不一致")
            return
        }
        guard (answer as NSString).isRightPassword() else {
            self.showToast(with: "密码需要8-16位数字、字母或符号组合")
            return
        }
        self.view.endEditing(true)
        var isCreateSucess: Bool
        if let seed = self.seed {
            IMLoginUser.shared().currentUser?.setSeed(pwd: answer, seed: seed)
            isCreateSucess = true
        } else {
            isCreateSucess = IMLoginUser.shared().currentUser?.createSeed(isChinses: true, pwd: answer) ?? false
        }
        if isCreateSucess {
            if self.presentingViewController != nil {
                self.navigationController?.dismiss(animated: true, completion: nil)
            }else {
                self.navigationController?.popViewController(animated: true)
            }
            UIApplication.shared.keyWindow?.showToast(with: "密聊密码设置成功")
        } else {
            self.showToast(with: "设置失败")
        }
    }
}
