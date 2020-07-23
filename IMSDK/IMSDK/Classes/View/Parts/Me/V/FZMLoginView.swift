//
//  FZMLoginView.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/8.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift

class FZMLoginView: UIView {
    
    var inputType : AccountInputType = .mobile {
        didSet{
            self.configureView()
        }
    }
    
    let disposeBag = DisposeBag()
    
    var sendBlock : ((String,AccountInputType)->())?
    
    lazy var backView : UIView = {
        let view = UIView()
        view.layer.backgroundColor = UIColor.white.cgColor
        view.makeNormalShadow()
        view.layer.cornerRadius = 5
        
        let lineV = UIView()
        lineV.backgroundColor = FZM_TintColor
        view.addSubview(lineV)
        lineV.snp.makeConstraints({ (m) in
            m.bottom.equalToSuperview().offset(-50)
            m.left.equalToSuperview().offset(25)
            m.right.equalToSuperview().offset(-25)
            m.height.equalTo(1)
        })
        view.addSubview(accountInput)
        accountInput.snp.makeConstraints({ (m) in
            m.bottom.equalTo(lineV.snp.top)
            m.height.equalTo(45)
            m.left.right.equalTo(lineV)
        })
        view.addSubview(sendBtn)
        sendBtn.snp.makeConstraints({ (m) in
            m.centerY.equalTo(accountInput)
            m.right.equalTo(lineV).offset(-15)
            m.size.equalTo(CGSize(width: 20, height: 17))
        })
        
        view.addSubview(typeSwitchView)
        typeSwitchView.snp.makeConstraints({ (m) in
            m.centerX.equalToSuperview()
            m.top.equalToSuperview().offset(40)
            m.size.equalTo(CGSize(width: 140, height: 25))
        })
        return view
    }()
    
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
    
    lazy var typeSwitchView : FZMTypeSwitchView = {
        let view = FZMTypeSwitchView(with: ["手机","邮箱"], width: 70)
        view.selectBlock = {[weak self] index in
            self?.inputType = index == 0 ? .mobile : .email
        }
        return view
    }()
    
    lazy var sendBtn : UIButton = {
        let btn = UIButton(type: .custom)
        let img = GetBundleImage("me_send_info")?.withRenderingMode(.alwaysTemplate)
        btn.setImage(img, for: .normal)
        btn.tintColor = FZM_GrayWordColor
        btn.isEnabled = true
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let titleLab = UILabel.getLab(font: UIFont.mediumFont(30), textColor: FZM_TintColor, textAlignment: .left, text: "登录/注册")
        self.addSubview(titleLab)
        titleLab.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(20)
            m.left.equalToSuperview().offset(28)
            m.size.equalTo(CGSize(width: 200, height: 42))
        }
        
        self.addSubview(backView)
        backView.snp.makeConstraints { (m) in
            m.top.equalTo(titleLab.snp.bottom).offset(10)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(180)
        }
        
        self.setupActions()
    }
    
    private func setupActions() {
        sendBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.sendBlock?(strongSelf.accountInput.text!,strongSelf.inputType)
        }.disposed(by: disposeBag)
        
        accountInput.rx.text.subscribe {[weak self] (_) in
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
            strongSelf.sendBtn.tintColor = isSuccess ? FZM_TintColor : FZM_GrayWordColor
            strongSelf.sendBtn.isEnabled = isSuccess
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


class FZMTypeSwitchView: UIView {
    
    let disposeBag = DisposeBag()
    var subViewArr = [UILabel]()
    
    var selectBlock : IntBlock?
    
    var selectIndex : Int = 0 {
        didSet{
            self.setSelectIndex()
        }
    }
    
    init(with titleArr: [String], width: CGFloat) {
        super.init(frame: CGRect.zero)
        self.layer.borderWidth = 1
        self.layer.cornerRadius = 12.5
        self.layer.borderColor = FZM_TintColor.cgColor
        self.clipsToBounds = true
        for (index,str) in titleArr.enumerated() {
            let lab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_TintColor, textAlignment: .center, text: str)
            lab.backgroundColor = UIColor.white
            lab.layer.cornerRadius = 12.5
            lab.clipsToBounds = true
            self.addSubview(lab)
            lab.snp.makeConstraints({ (m) in
                m.left.equalToSuperview().offset(width*CGFloat(index))
                m.top.bottom.equalToSuperview()
                m.width.equalTo(width)
            })
            subViewArr.append(lab)
            lab.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer()
            tap.rx.event.subscribe {[weak self] (_) in
                self?.selectIndex = index
                self?.selectBlock?(index)
            }.disposed(by: disposeBag)
            lab.addGestureRecognizer(tap)
        }
        self.setSelectIndex()
    }
    
    private func setSelectIndex() {
        for (index,item) in subViewArr.enumerated() {
            if index == selectIndex {
                item.textColor = UIColor.white
                item.backgroundColor = FZM_TintColor
            }else{
                item.textColor = FZM_TintColor
                item.backgroundColor = UIColor.white
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
