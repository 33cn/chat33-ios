//
//  FZMInputPawAlertView.swift
//  IMSDK
//
//  Created by .. on 2019/3/19.
//

import UIKit
import RxSwift

class FZMInputPawAlertView: UIView {
    
    private let disposeBag = DisposeBag.init()
    
    private lazy var pawCodeField: CRBoxInputView_CustomBox = {
        
        let cellProperty = CRBoxInputCellProperty()
        cellProperty.cellBgColorNormal = UIColor.white
        cellProperty.cellBgColorSelected = UIColor.white
        cellProperty.cellCursorColor = UIColor.black
        cellProperty.cellCursorWidth = 1
        cellProperty.cellCursorHeight = 20
        cellProperty.cornerRadius = 5
        cellProperty.borderWidth = 0
        cellProperty.cellFont = UIFont.boldFont(18)
        cellProperty.cellTextColor = UIColor.black
        cellProperty.securityType = .customViewType
        
        let codeField = CRBoxInputView_CustomBox()
        codeField.frame = CGRect(x: 18, y: 161, width: 265, height: 40)
        codeField.boxFlowLayout.itemSize = CGSize(width: 40, height: 40)
        codeField.customCellProperty = cellProperty
        codeField.codeLength = 6
        codeField.loadAndPrepare()
        codeField.ifNeedSecurity = true

        codeField.textDidChangeblock = {[weak self] (text,isFinish) in
            if isFinish {
                if let pwd = text, pwd.count == 6 {
                    self?.hide()
                    self?.okBlock?(pwd)
                }
            }
        }
        return codeField
    }()
    
    private lazy var pawCodeView: UIView = {
 
        let centerView = UIView.init()
        centerView.backgroundColor = UIColor.white
        centerView.layer.cornerRadius = 5
        centerView.layer.masksToBounds = true
        centerView.backgroundColor = FZM_BackgroundColor
        
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_BlackWordColor, textAlignment: .center, text: "请输入支付密码")
        centerView.addSubview(lab)
        lab.snp.makeConstraints({ (m) in
            m.top.equalToSuperview().offset(21)
            m.centerX.equalToSuperview()
        })
        
        let cancelBtn = UIButton.init()
        cancelBtn.setBackgroundImage(GetBundleImage("ver_cancel"), for: .normal)
        cancelBtn.enlargeClickEdge(10, 10, 10, 10)
        centerView.addSubview(cancelBtn)
        cancelBtn.snp.makeConstraints({ (m) in
            m.centerY.equalTo(lab)
            m.right.equalToSuperview().offset(-18)
            m.height.width.equalTo(14)
        })
        cancelBtn.rx.controlEvent(.touchUpInside).subscribe(onNext: {[weak self] (_) in
            self?.hide()
        }).disposed(by: disposeBag)
        
        let lab2 = UILabel.getLab(font: UIFont.boldFont(40), textColor: FZM_BlackWordColor, textAlignment: .center, text: self.title)
        centerView.addSubview(lab2)
        lab2.snp.makeConstraints({ (m) in
            m.top.equalTo(lab.snp.bottom).offset(20)
            m.centerX.equalToSuperview()
            m.height.equalTo(47)
        })
        
        let lab3 = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .center, text: "需支付")
        centerView.addSubview(lab3)
        lab3.snp.makeConstraints({ (m) in
            m.top.equalTo(lab2.snp.bottom).offset(5)
            m.centerX.equalToSuperview()
        })
        
        centerView.addSubview(pawCodeField)
        
        let btn = UIButton.init()
        btn.setTitle("忘记密码", for: .normal)
        btn.titleLabel?.font = UIFont.mediumFont(14)
        btn.setTitleColor(FZM_TintColor, for: .normal)
        btn.setTitleColor(FZM_TintColor, for: .disabled)
        centerView.addSubview(btn)
        btn.snp.makeConstraints({ (m) in
            m.centerX.equalToSuperview()
            m.top.equalTo(pawCodeField.snp.bottom).offset(20)
            m.height.equalTo(20)
            m.width.equalTo(80)
        })
        
        btn.rx.controlEvent(.touchUpInside).subscribe(onNext: {[weak self] (_) in
            self?.hide()
            self?.forgetBlock?()
        }).disposed(by: disposeBag)
        
        return centerView
    }()
    
    let title: String?
    var okBlock : ((String)->())?
    var forgetBlock : (()->())?
    
    init(title: String?) {
        self.title = title
        super.init(frame: ScreenBounds)
        self.backgroundColor = UIColor.init(white: 0, alpha: 0.7)

        self.addSubview(pawCodeView)
        pawCodeView.snp.makeConstraints({ (m) in
            m.width.equalTo(300)
            m.height.equalTo(261)
            m.centerX.equalToSuperview()
            m.centerY.equalToSuperview().offset(-100)
        })
        pawCodeView.transform = CGAffineTransform.init(scaleX: 0, y: 0)

    }
    
    func show() {
        UIApplication.shared.keyWindow?.addSubview(self)
        UIView.animate(withDuration: 0.3) {
            self.pawCodeView.transform = CGAffineTransform.init(scaleX: 1, y: 1)
        }
    }
    
    func hide() {
        self.removeFromSuperview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
