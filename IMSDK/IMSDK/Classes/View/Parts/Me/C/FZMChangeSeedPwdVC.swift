//
//  FZMSetQuestionVC.swift
//  IMSDK
//
//  Created by 吴文拼 on 2019/1/11.
//

import UIKit
import RxSwift

class FZMChangeSeedPwdVC: FZMBaseViewController {
    
    
    lazy var questionBlockView : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        let titleLab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: "旧密码")
        view.addSubview(titleLab)
        titleLab.snp.makeConstraints({ (m) in
            m.top.equalToSuperview()
            m.left.equalToSuperview().offset(14)
            m.height.equalTo(30)
        })
        view.addSubview(questionNumLab)
        questionNumLab.snp.makeConstraints({ (m) in
            m.top.equalToSuperview()
            m.right.equalToSuperview().offset(-16)
            m.height.equalTo(30)
        })
        view.addSubview(questionInput)
        questionInput.snp.makeConstraints({ (m) in
            m.left.equalTo(titleLab).offset(-4)
            m.right.equalToSuperview().offset(-14)
            m.bottom.equalToSuperview()
            m.height.equalTo(50)
        })
        return view
    }()
    
    lazy var questionNumLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .right, text: "0/20")
        lab.isHidden = true
        return lab
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
            m.top.equalToSuperview().offset(10)
            m.left.equalToSuperview().offset(4)
            m.size.equalTo(CGSize(width: 150, height: 23))
        })
//        input.addSubview(forgetPwdLab)
//        forgetPwdLab.snp.makeConstraints({ (m) in
//            m.centerY.equalTo(self.questionPlaceLab)
//            m.right.equalToSuperview().offset(-4)
//            m.size.equalTo(CGSize(width: 60, height: 23))
//        })
        return input
    }()
    lazy var questionPlaceLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .left, text: "请输入旧密码")
        return lab
    }()
    
    lazy var forgetPwdLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_TintColor, textAlignment: .left, text: "忘记密码")
        lab.isUserInteractionEnabled = true
        lab.enlargeClickEdge(10, 0, 10, 10)
        let tap = UITapGestureRecognizer.init()
        tap.rx.event.subscribe({[weak self](_) in
            let alertController = UIAlertController.init(title: "提示", message: "重设密聊密码后, 将无法解密以前的聊天记录", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            let okAction = UIAlertAction.init(title: "确定", style: .destructive, handler: { (_) in
                let vc = FZMSetSeedPwdVC.init(seed: nil)
                self?.navigationController?.pushViewController(vc, animated: true)
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
        let titleLab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: "新密码")
        view.addSubview(titleLab)
        titleLab.snp.makeConstraints({ (m) in
            m.top.equalToSuperview()
            m.left.equalToSuperview().offset(14)
            m.height.equalTo(30)
        })
        view.addSubview(answerInput)
        answerInput.snp.makeConstraints({ (m) in
            m.left.equalTo(titleLab).offset(-4)
            m.right.equalToSuperview().offset(-14)
            m.top.equalTo(titleLab.snp.bottom)
            m.height.equalTo(50)
        })
        view.addSubview(answerInputAgain)
        answerInputAgain.snp.makeConstraints({ (m) in
            m.left.equalTo(titleLab).offset(-4)
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
            m.size.equalTo(CGSize(width: 270, height: 23))
        })
        return input
    }()
    lazy var answerPlaceLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .left, text: "请设置8-16位数字、字母或符号组合")
        return lab
    }()
    
    lazy var answerInputAgain : UITextField = {
        let input = UITextField()
        input.font = UIFont.regularFont(16)
        input.textColor = FZM_BlackWordColor
        input.tintColor = FZM_TintColor
        input.backgroundColor = UIColor.clear
        input.addSubview(answerPlaceLabAgain)
        input.isSecureTextEntry = true
        answerPlaceLabAgain.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(4)
            m.size.equalTo(CGSize(width: 150, height: 23))
        })
        return input
    }()
    lazy var answerPlaceLabAgain : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .left, text: "请再次输入密码")
        return lab
    }()
    
    lazy var confirmBtn : UIButton = {
        let btn = UIButton.getNormalBtn(with: "确定")
        btn.layer.backgroundColor = UIColor(hex: 0xC8D3DE).cgColor
        return btn
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationItem.title = "修改密聊密码"
        let headLab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: "")
        self.view.addSubview(headLab)
        headLab.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(15)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(0)
        }
        
        self.view.addSubview(questionBlockView)
        questionBlockView.snp.makeConstraints { (m) in
            m.top.equalTo(headLab.snp.bottom)
            m.left.right.equalTo(headLab)
            m.height.equalTo(80)
        }
        self.view.addSubview(answerBlockView)
        answerBlockView.snp.makeConstraints { (m) in
            m.top.equalTo(questionBlockView.snp.bottom).offset(15)
            m.left.right.equalTo(headLab)
            m.height.equalTo(130)
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
        let answerAgainBtn = answerInputAgain.addToolBar(with: "确定", target: self, sel: #selector(commitInfo))
        
        Observable.combineLatest(questionInput.rx.text, answerInput.rx.text, answerInputAgain.rx.text).subscribe {[weak self, weak questionBtn, weak answerBtn, weak answerAgainBtn] (event) in
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
            strongSelf.answerInputAgain.limitText(with: 16)
            if let text = strongSelf.answerInputAgain.text, text.count > 0 {
                strongSelf.answerPlaceLabAgain.isHidden = true
            }else {
                strongSelf.answerPlaceLabAgain.isHidden = false
            }
            
            if strongSelf.answerPlaceLab.isHidden && strongSelf.answerPlaceLabAgain.isHidden && strongSelf.questionPlaceLab.isHidden {
                strongSelf.confirmBtn.isEnabled = true
                strongSelf.confirmBtn.layer.backgroundColor = FZM_TintColor.cgColor
                questionBtn?.isEnabled = true
                questionBtn?.layer.backgroundColor = FZM_TintColor.cgColor
                answerBtn?.isEnabled = true
                answerBtn?.layer.backgroundColor = FZM_TintColor.cgColor
                answerAgainBtn?.isEnabled = true
                answerAgainBtn?.layer.backgroundColor = FZM_TintColor.cgColor
            }else {
                strongSelf.confirmBtn.isEnabled = false
                strongSelf.confirmBtn.layer.backgroundColor = UIColor(hex: 0xC8D3DE).cgColor
                questionBtn?.isEnabled = false
                questionBtn?.layer.backgroundColor = UIColor(hex: 0xC8D3DE).cgColor
                answerBtn?.isEnabled = false
                answerBtn?.layer.backgroundColor = UIColor(hex: 0xC8D3DE).cgColor
                answerAgainBtn?.isEnabled = false
                answerAgainBtn?.layer.backgroundColor = UIColor(hex: 0xC8D3DE).cgColor
            }
            }.disposed(by: disposeBag)
        
        confirmBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            self?.commitInfo()
            }.disposed(by: disposeBag)
        
    }
    
    @objc func commitInfo() {
        guard let question = questionInput.text, let answer = answerInput.text, let answerAgain = answerInputAgain.text, answerAgain == answer else {
            self.showToast(with: "两次输入的密码不一致")
            return
        }
        guard (answer as NSString).isRightPassword() else {
            self.showToast(with: "密码需要8-16位数字、字母或符号组合")
            return
        }
        
        self.view.endEditing(true)
        self.showProgress()
        if let seed = IMLoginUser.shared().currentUser?.getSeed(pwd: question) {
            IMLoginUser.shared().currentUser?.setSeed(pwd: answer, seed: seed)
            self.showToast(with: "修改成功")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.popBack()
            }
        } else {
            self.showToast(with: "原密码错误")
        }
    }
}
