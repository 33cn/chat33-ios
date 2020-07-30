//
//  FZMInputAlertView.swift
//  IMSDK
//
//  Created by .. on 2019/4/3.
//


import UIKit
import RxSwift
import RxCocoa

public class FZMInputAlertView: UIView {
    
    private let disposeBag = DisposeBag()
        
    private var block : ((String)->())?
    
    private let titleLab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_BlackWordColor, textAlignment: .center, text: "")
    
    private lazy var centerView : UIView = {
        let v = UIView()
        v.backgroundColor = FZM_BackgroundColor
        v.clipsToBounds = true
        v.layer.cornerRadius = 5
        v.addSubview(titleLab)
        titleLab.snp.makeConstraints({ (m) in
            m.top.equalToSuperview()
            m.centerX.equalToSuperview()
            m.height.equalTo(60)
        })
        
        v.addSubview(answerNumLab)
        answerNumLab.snp.makeConstraints({ (m) in
            m.top.equalTo(titleLab.snp.bottom)
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(20)
        })
        v.addSubview(answerInput)
        answerInput.snp.makeConstraints({ (m) in
            m.top.equalTo(answerNumLab.snp.bottom).offset(5)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(60)
        })
        v.addSubview(fixBugView)
        fixBugView.snp.makeConstraints({ (m) in
            m.edges.equalTo(self.answerInput)
        })
        
        v.addSubview(answerTextField)
        answerTextField.snp.makeConstraints({ (m) in
            m.top.equalTo(answerNumLab.snp.bottom).offset(5)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
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
    
    private lazy var answerNumLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .right, text: "0/20")
        return lab
    }()
    private lazy var answerInput : UITextView = {
        let input = UITextView()
        input.font = UIFont.regularFont(16)
        input.textColor = FZM_BlackWordColor
        input.tintColor = FZM_TintColor
        input.backgroundColor = FZM_LineColor
        input.layer.cornerRadius = 4
        input.clipsToBounds = true
        input.addSubview(answerPlaceLab2)
        answerPlaceLab2.snp.makeConstraints({ (m) in
            m.left.equalToSuperview().offset(4)
            m.top.equalToSuperview().offset(8)
            m.size.equalTo(CGSize(width: 150, height: 23))
        })
        return input
    }()
    
    private lazy var fixBugView: UIView = {
        let v = UIView.init()
        v.backgroundColor = .clear
        let tap = UITapGestureRecognizer.init()
        tap.rx.event.subscribe({[weak self] (_) in
            self?.answerInput.endEditing(true)
            self?.fixBugView.removeFromSuperview()
        }).disposed(by: disposeBag)
        v.addGestureRecognizer(tap)
        return v
    }()
    
    private lazy var answerTextField : UITextField = {
        let input = UITextField()
        input.font = UIFont.boldSystemFont(ofSize: 20)
        input.leftView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 10, height: 10))
        input.rightView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 10, height: 10))
        input.leftViewMode = .always
        input.rightViewMode = .always
        input.textColor = FZM_BlackWordColor
        input.tintColor = FZM_TintColor
        input.backgroundColor = FZM_LineColor
        input.layer.cornerRadius = 4
        input.clipsToBounds = true
        input.keyboardType = .asciiCapable
        input.isSecureTextEntry = true
        input.addSubview(answerPlaceLab)
        answerPlaceLab.snp.makeConstraints({ (m) in
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.centerY.equalToSuperview()
        })
        input.isHidden = true
        return input
    }()
    
    private lazy var answerPlaceLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .left, text: "")
        return lab
    }()
    private lazy var answerPlaceLab2 : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .left, text: "")
        return lab
    }()
    
    private lazy var cancelBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.setAttributedTitle(NSAttributedString(string: "取消", attributes: [.font:UIFont.mediumFont(16),.foregroundColor:FZM_TintColor]), for: .normal)
        btn.addTarget(self, action: #selector(cancelClick), for: .touchUpInside)
        return btn
    }()
    
    private lazy var confirmBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.setAttributedTitle(NSAttributedString(string: "确定", attributes: [.font:UIFont.mediumFont(16),.foregroundColor:FZM_TintColor]), for: .normal)
        btn.setAttributedTitle(NSAttributedString(string: "确定", attributes: [.font:UIFont.mediumFont(16),.foregroundColor:FZM_GrayWordColor]), for: .disabled)
        btn.addTarget(self, action: #selector(confirmClick), for: .touchUpInside)
        btn.isEnabled = false
        return btn
    }()
    
    var isSecureTextEntry = false
    
    var limitTextCount = 20
    
    public init(title: String, placehoder: String,isSecureTextEntry: Bool = false, defaultStr: String? = nil, limitTextCount: Int = 20, confirmBlock:((String)->())?) {
        block = confirmBlock
        super.init(frame: ScreenBounds)
        self.limitTextCount = limitTextCount
        titleLab.text = title
        answerPlaceLab.text = placehoder
        answerPlaceLab2.text = placehoder
        self.isSecureTextEntry = isSecureTextEntry
        self.backgroundColor = UIColor(white: 0, alpha: 0.5)
        self.addSubview(centerView)
        centerView.snp.makeConstraints { (m) in
            m.centerX.equalToSuperview()
            m.centerY.equalToSuperview().offset(-80)
            m.width.equalTo(290)
            m.height.equalTo(220)
        }
        if isSecureTextEntry {
            answerTextField.isHidden = false
            answerTextField.isEnabled = true
            
            answerInput.isHidden = true
            answerInput.isEditable = false
            
            self.answerNumLab.isHidden = true
            
            answerTextField.text = defaultStr
            answerTextField.becomeFirstResponder()
            
        } else {
            answerTextField.isHidden = true
            answerTextField.isEnabled = false
            
            answerInput.isHidden = false
            answerInput.isEditable = true
            
            answerInput.text = defaultStr
            answerInput.becomeFirstResponder()
        }
        answerNumLab.text = "\(defaultStr?.count ?? 0)/\(limitTextCount)"
        
        answerTextField.rx.text.subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            if let text = strongSelf.answerTextField.text, text.count > 0 {
                strongSelf.confirmBtn.isEnabled = true
                strongSelf.answerPlaceLab.isHidden = true
                strongSelf.answerPlaceLab2.isHidden = true
            }else {
                strongSelf.confirmBtn.isEnabled = false
                strongSelf.answerPlaceLab.isHidden = false
                strongSelf.answerPlaceLab2.isHidden = false
            }
            }.disposed(by: disposeBag)
        
        answerInput.rx.text.subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.answerInput.limitText(with: limitTextCount)
            if let text = strongSelf.answerInput.text, text.count > 0 {
                strongSelf.answerNumLab.text = "\(text.count)/\(limitTextCount)"
                strongSelf.confirmBtn.isEnabled = true
                strongSelf.answerPlaceLab.isHidden = true
                strongSelf.answerPlaceLab2.isHidden = true
            }else {
                strongSelf.answerNumLab.text = "0/\(limitTextCount)"
                strongSelf.confirmBtn.isEnabled = false
                strongSelf.answerPlaceLab.isHidden = false
                strongSelf.answerPlaceLab2.isHidden = false
            }
        }.disposed(by: disposeBag)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func show() {
        UIApplication.shared.keyWindow?.addSubview(self)
    }
    
    public func hide() {
        self.removeFromSuperview()
    }
    
    
    @objc private func cancelClick(){
        self.hide()
    }
    
    @objc private func confirmClick(){
        if isSecureTextEntry {
            self.block?(answerTextField.text ?? "")
        } else {
            self.block?(answerInput.text)
        }
        self.hide()
    }
    
}





class FZMDetailInputAlertView: UIView {

    private let disposeBag = DisposeBag()
        
    private var block : ((String)->())?
    
    private let titleLab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .center, text: "")
    
    private lazy var centerView : UIView = {
        let v = UIView()
        v.backgroundColor = FZM_BackgroundColor
        v.clipsToBounds = true
        v.layer.cornerRadius = 5
        
        v.addSubview(titleLab)
        titleLab.snp.makeConstraints({ (m) in
            m.top.equalToSuperview()
            m.centerX.equalToSuperview()
            m.height.equalTo(60)
        })
        
        v.addSubview(answerNumLab)
        answerNumLab.snp.makeConstraints({ (m) in
            m.top.equalTo(titleLab.snp.bottom)
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(20)
        })
        v.addSubview(answerInput)
        answerInput.snp.makeConstraints({ (m) in
            m.top.equalTo(answerNumLab.snp.bottom).offset(5)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(225)
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
    
    private lazy var answerNumLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .right, text: "0/20")
        return lab
    }()
    private lazy var answerInput : UITextView = {
        let input = UITextView()
        input.font = UIFont.regularFont(16)
        input.textColor = FZM_BlackWordColor
        input.tintColor = FZM_TintColor
        input.backgroundColor = FZM_LineColor
        input.layer.cornerRadius = 4
        input.clipsToBounds = true
        input.addSubview(answerPlaceLab)
        answerPlaceLab.snp.makeConstraints({ (m) in
            m.left.equalToSuperview().offset(10)
            m.right.equalToSuperview().offset(-10)
            m.top.equalToSuperview().offset(10)
            m.bottom.equalToSuperview().offset(-10)
        })
        return input
    }()
    
    private lazy var answerPlaceLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .left, text: "")
        lab.numberOfLines = 0
        return lab
    }()
    
    private lazy var confirmBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.setAttributedTitle(NSAttributedString(string: "确定", attributes: [.font:UIFont.mediumFont(16),.foregroundColor:FZM_TintColor]), for: .normal)
        btn.setAttributedTitle(NSAttributedString(string: "确定", attributes: [.font:UIFont.mediumFont(16),.foregroundColor:FZM_GrayWordColor]), for: .disabled)
        btn.addTarget(self, action: #selector(confirmClick), for: .touchUpInside)
        btn.isEnabled = false
        return btn
    }()
    
    private lazy var cancelBtn : UIButton = {
           let btn = UIButton(type: .custom)
           btn.setAttributedTitle(NSAttributedString(string: "取消", attributes: [.font:UIFont.mediumFont(16),.foregroundColor:FZM_TintColor]), for: .normal)
           btn.addTarget(self, action: #selector(cancelClick), for: .touchUpInside)
           return btn
       }()
        
    var limitTextCount = 20
    var requireTextCount = 1
    
    public init(title: String, placehoder: String, defaultStr: String? = nil, requireTextCount: Int = 1 ,limitTextCount: Int = 20, confirmBlock:((String)->())?) {
        block = confirmBlock
        super.init(frame: ScreenBounds)
        self.requireTextCount = requireTextCount
        self.limitTextCount = limitTextCount
        titleLab.text = title
        answerPlaceLab.text = placehoder
        self.backgroundColor = UIColor(white: 0, alpha: 0.5)
        self.addSubview(centerView)
        centerView.snp.makeConstraints { (m) in
            m.centerX.equalToSuperview()
            m.centerY.equalToSuperview().offset(-130)
            m.width.equalTo(290)
            m.height.equalTo(370)
        }
        if defaultStr == nil {
            self.answerInput.becomeFirstResponder()
        } else {
            self.answerPlaceLab.isHidden = true
            self.answerInput.isHidden = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.answerInput.text = defaultStr
                self.answerInput.isHidden = false
            }
        }
        let answerNumInfo = requireTextCount == 1 ? "\(limitTextCount)" : "\(requireTextCount)-\(limitTextCount)"
        answerNumLab.text = "\(defaultStr?.count ?? 0)/" + answerNumInfo
        
        answerInput.rx.text.subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.answerInput.limitText(with: limitTextCount)
            if let text = strongSelf.answerInput.text, text.count > 0 {
                strongSelf.answerNumLab.text = "\(text.count)/" + answerNumInfo
                strongSelf.answerPlaceLab.isHidden = true
            }else {
                strongSelf.answerNumLab.text = "0/" + answerNumInfo
                strongSelf.answerPlaceLab.isHidden = false
            }
            strongSelf.confirmBtn.isEnabled = strongSelf.answerInput.text.count >= strongSelf.requireTextCount
        }.disposed(by: disposeBag)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func show() {
        UIApplication.shared.keyWindow?.addSubview(self)
    }
    
    public func hide() {
        self.removeFromSuperview()
    }
    
    
    @objc private func cancelClick(){
        self.hide()
    }
    
    @objc private func confirmClick(){
        self.block?(answerInput.text)
        self.hide()
    }

}
