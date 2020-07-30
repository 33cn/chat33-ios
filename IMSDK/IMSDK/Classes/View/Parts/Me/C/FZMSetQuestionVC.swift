//
//  FZMSetQuestionVC.swift
//  IMSDK
//
//  Created by 吴文拼 on 2019/1/11.
//

import UIKit
import RxSwift

class FZMSetQuestionVC: FZMBaseViewController {
    
    var configure: IMUserConfigureModel?
    
    lazy var questionBlockView : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        let titleLab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: "问题")
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
            m.bottom.equalToSuperview().offset(-20)
            m.height.equalTo(45)
        })
        return view
    }()
    
    lazy var questionNumLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .right, text: "0/20")
        return lab
    }()
    lazy var questionInput : UITextView = {
        let input = UITextView()
        input.font = UIFont.regularFont(16)
        input.textColor = FZM_BlackWordColor
        input.tintColor = FZM_TintColor
        input.backgroundColor = UIColor.clear
        input.addSubview(questionPlaceLab)
        questionPlaceLab.snp.makeConstraints({ (m) in
            m.left.top.equalToSuperview().offset(4)
            m.size.equalTo(CGSize(width: 150, height: 23))
        })
        return input
    }()
    lazy var questionPlaceLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .left, text: "请设置问题")
        return lab
    }()
    
    lazy var answerBlockView : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        let titleLab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: "答案")
        view.addSubview(titleLab)
        titleLab.snp.makeConstraints({ (m) in
            m.top.equalToSuperview()
            m.left.equalToSuperview().offset(14)
            m.height.equalTo(30)
        })
        view.addSubview(answerNumLab)
        answerNumLab.snp.makeConstraints({ (m) in
            m.top.equalToSuperview()
            m.right.equalToSuperview().offset(-16)
            m.height.equalTo(30)
        })
        view.addSubview(answerInput)
        answerInput.snp.makeConstraints({ (m) in
            m.left.equalTo(titleLab).offset(-4)
            m.right.equalToSuperview().offset(-14)
            m.bottom.equalToSuperview().offset(-20)
            m.height.equalTo(45)
        })
        return view
    }()
    
    lazy var answerNumLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .right, text: "0/20")
        return lab
    }()
    lazy var answerInput : UITextView = {
        let input = UITextView()
        input.font = UIFont.regularFont(16)
        input.textColor = FZM_BlackWordColor
        input.tintColor = FZM_TintColor
        input.backgroundColor = UIColor.clear
        input.addSubview(answerPlaceLab)
        answerPlaceLab.snp.makeConstraints({ (m) in
            m.left.top.equalToSuperview().offset(4)
            m.size.equalTo(CGSize(width: 150, height: 23))
        })
        return input
    }()
    lazy var answerPlaceLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .left, text: "请设置答案")
        return lab
    }()
    
    lazy var confirmBtn : UIButton = {
        let btn = UIButton.getNormalBtn(with: "确定")
        btn.layer.backgroundColor = UIColor(hex: 0xC8D3DE).cgColor
        return btn
    }()
    
    init(with configure: IMUserConfigureModel?) {
        self.configure = configure
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "设置问题"
        let headLab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: "设置问题后，对方加我为好友时需先正确回答以下问题的答案")
        self.view.addSubview(headLab)
        headLab.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(15)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
        }
        
        self.view.addSubview(questionBlockView)
        questionBlockView.snp.makeConstraints { (m) in
            m.top.equalTo(headLab.snp.bottom).offset(15)
            m.left.right.equalTo(headLab)
            m.height.equalTo(110)
        }
        self.view.addSubview(answerBlockView)
        answerBlockView.snp.makeConstraints { (m) in
            m.top.equalTo(questionBlockView.snp.bottom).offset(15)
            m.left.right.equalTo(headLab)
            m.height.equalTo(110)
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
        
        let questionBtn = questionInput.addToolBar(with: "确定", target: self, sel: #selector(FZMSetQuestionVC.commitInfo))
        let answerBtn = answerInput.addToolBar(with: "确定", target: self, sel: #selector(FZMSetQuestionVC.commitInfo))
        
        Observable.combineLatest(questionInput.rx.text, answerInput.rx.text).subscribe {[weak self, weak questionBtn, weak answerBtn] (event) in
            guard let strongSelf = self else { return }
            strongSelf.questionInput.limitText(with: 20)
            if let text = strongSelf.questionInput.text, text.count > 0 {
                strongSelf.questionNumLab.text = "\(text.count)/20"
                strongSelf.questionPlaceLab.isHidden = true
            }else {
                strongSelf.questionNumLab.text = "0/20"
                strongSelf.questionPlaceLab.isHidden = false
            }
            strongSelf.answerInput.limitText(with: 20)
            if let text = strongSelf.answerInput.text, text.count > 0 {
                strongSelf.answerNumLab.text = "\(text.count)/20"
                strongSelf.answerPlaceLab.isHidden = true
            }else {
                strongSelf.answerNumLab.text = "0/20"
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
        
        questionInput.text = self.configure?.question ?? ""
        answerInput.text = self.configure?.answer ?? ""
    }
    
    override func rt_customBackItem(withTarget target: Any!, action: Selector!) -> UIBarButtonItem! {
        return UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(popBack))
    }
    
    @objc func commitInfo() {
        guard let question = questionInput.text, let answer = answerInput.text else {
            return
        }
        self.showProgress()
        HttpConnect.shared().setAuthQuestion(tp: 1, question: question, answer: answer) { (response) in
            self.hideProgress()
            guard response.success else {
                self.showToast(with: response.message)
                return
            }
            self.popBack()
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
