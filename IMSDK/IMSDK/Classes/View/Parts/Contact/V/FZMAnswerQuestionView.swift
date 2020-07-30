//
//  FZMAnswerQuestionView.swift
//  AFNetworking
//
//  Created by 吴文拼 on 2019/1/12.
//

import UIKit
import RxSwift
import RxCocoa

class FZMAnswerQuestionView: UIView {
    
    private let disposeBag = DisposeBag()
    
    private let addFriendId : String
    
    var block : StringBlock?
    
    lazy var centerView : UIView = {
        let v = UIView()
        v.backgroundColor = FZM_BackgroundColor
        v.clipsToBounds = true
        v.layer.cornerRadius = 5
        
        let titleLab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .center, text: "需回答问题")
        v.addSubview(titleLab)
        titleLab.snp.makeConstraints({ (m) in
            m.top.equalToSuperview()
            m.centerX.equalToSuperview()
            m.height.equalTo(60)
        })
        
        v.addSubview(questionLab)
        questionLab.snp.makeConstraints({ (m) in
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.top.equalTo(titleLab.snp.bottom)
            m.height.equalTo(45)
        })
        v.addSubview(answerNumLab)
        answerNumLab.snp.makeConstraints({ (m) in
            m.top.equalTo(questionLab.snp.bottom)
            m.right.equalTo(questionLab)
            m.height.equalTo(20)
        })
        v.addSubview(answerInput)
        answerInput.snp.makeConstraints({ (m) in
            m.top.equalTo(answerNumLab.snp.bottom).offset(5)
            m.left.right.equalTo(questionLab)
            m.height.equalTo(60)
        })
        
        
        v.addSubview(cancelBtn)
        cancelBtn.snp.makeConstraints({ (m) in
            m.bottom.left.equalToSuperview()
            m.right.equalTo(v.snp.centerX)
            m.height.equalTo(50)
        })
        
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
        return v
    }()
    
    lazy var questionLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: nil)
        lab.numberOfLines = 2
        return lab
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
        input.backgroundColor = FZM_LineColor
        input.layer.cornerRadius = 4
        input.clipsToBounds = true
        input.addSubview(answerPlaceLab)
        answerPlaceLab.snp.makeConstraints({ (m) in
            m.left.top.equalToSuperview().offset(4)
            m.size.equalTo(CGSize(width: 150, height: 23))
        })
        return input
    }()
    lazy var answerPlaceLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .left, text: "请输入答案")
        return lab
    }()

    lazy var cancelBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.setAttributedTitle(NSAttributedString(string: "取消", attributes: [.font:UIFont.mediumFont(16),.foregroundColor:FZM_TintColor]), for: .normal)
        btn.addTarget(self, action: #selector(cancelClick), for: .touchUpInside)
        return btn
    }()
    
    lazy var confirmBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.setAttributedTitle(NSAttributedString(string: "确定", attributes: [.font:UIFont.mediumFont(16),.foregroundColor:FZM_TintColor]), for: .normal)
        btn.setAttributedTitle(NSAttributedString(string: "确定", attributes: [.font:UIFont.mediumFont(16),.foregroundColor:FZM_GrayWordColor]), for: .disabled)
        btn.addTarget(self, action: #selector(confirmClick), for: .touchUpInside)
        btn.isEnabled = false
        return btn
    }()
    
    init(userId: String, question: String, confirmBlock:StringBlock?) {
        block = confirmBlock
        addFriendId = userId
        super.init(frame: ScreenBounds)
        self.backgroundColor = UIColor(white: 0, alpha: 0.5)
        self.addSubview(centerView)
        centerView.snp.makeConstraints { (m) in
            m.centerX.equalToSuperview()
            m.centerY.equalToSuperview().offset(-80)
            m.width.equalTo(290)
            m.height.equalTo(270)
        }
        questionLab.text = question
        answerInput.rx.text.subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.answerInput.limitText(with: 20)
            if let text = strongSelf.answerInput.text, text.count > 0 {
                strongSelf.answerNumLab.text = "\(text.count)/20"
                strongSelf.confirmBtn.isEnabled = true
                strongSelf.answerPlaceLab.isHidden = true
            }else {
                strongSelf.answerNumLab.text = "0/20"
                strongSelf.confirmBtn.isEnabled = false
                strongSelf.answerPlaceLab.isHidden = false
            }
        }.disposed(by: disposeBag)
        
        answerInput.becomeFirstResponder()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        UIApplication.shared.keyWindow?.addSubview(self)
    }
    
    func hide() {
        self.removeFromSuperview()
    }
    
    
    @objc func cancelClick(){
        self.hide()
    }
    
    @objc func confirmClick(){
        self.showProgress()
        HttpConnect.shared().checkAnswer(userId: addFriendId, answer: answerInput.text) { (success, response) in
            self.hideProgress()
            guard let success = success, success else {
                self.showToast(with: "回答错误")
                return
            }
            self.hide()
            self.block?(self.answerInput.text)
        }
    }

}
