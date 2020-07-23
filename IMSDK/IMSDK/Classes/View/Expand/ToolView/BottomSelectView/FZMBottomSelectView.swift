//
//  FZMBottomSelectView.swift
//  IM_SocketIO_Demo
//
//  Created by 吴文拼 on 2018/9/12.
//  Copyright © 2018年 Wang. All rights reserved.
//

import UIKit
import RxSwift

class FZMBottomSelectView: UIView {

    let disposeBag = DisposeBag()
    
    private let cancelBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = FZM_BackgroundColor
        btn.layer.cornerRadius = 20
        btn.clipsToBounds = true
        btn.setAttributedTitle(NSAttributedString(string: "取消", attributes: [.foregroundColor:FZM_BlackWordColor,.font:UIFont.regularFont(16)]), for: .normal)
        return btn
    }()
    init(with titleArr:[FZMBottomOption]) {
        super.init(frame: ScreenBounds)
        self.backgroundColor = UIColor(white: 0, alpha: 0.5)
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe(onNext:{[weak self] (_) in
            self?.hide()
        }).disposed(by: disposeBag)
        self.addGestureRecognizer(tap)
        
        cancelBtn.rx.controlEvent(.touchUpInside).subscribe(onNext:{[weak self] (_) in
            self?.hide()
        }).disposed(by: disposeBag)
        self.addSubview(cancelBtn)
        cancelBtn.snp.makeConstraints { (m) in
            m.left.equalToSuperview().offset(30)
            m.right.equalToSuperview().offset(-30)
            m.bottom.equalToSuperview().offset(300)
            m.height.equalTo(40)
        }
        var lastBtn = cancelBtn
        titleArr.forEach { (option) in
            let btn = UIButton(type: .custom)
            btn.backgroundColor = FZM_BackgroundColor
            btn.layer.cornerRadius = 20
            btn.clipsToBounds = true
            var height = 40
            let attStr = NSMutableAttributedString(string: option.title, attributes: [.foregroundColor:option.textColor,.font:UIFont.regularFont(16)])
            if let content = option.content, content.count > 0 {
                height = 60
                btn.titleLabel?.numberOfLines = 0
                btn.titleLabel?.textAlignment = .center
                attStr.append(NSAttributedString(string: "\n"))
                attStr.append(NSAttributedString(string: content, attributes: [.foregroundColor:option.contentColor,.font:UIFont.regularFont(14)]))
            }
            btn.setAttributedTitle(attStr, for: .normal)
            btn.rx.controlEvent(.touchUpInside).subscribe(onNext:{[weak self] (_) in
                option.clickBlock?()
                self?.hide()
            }).disposed(by: disposeBag)
            self.addSubview(btn)
            btn.snp.makeConstraints { (m) in
                m.left.equalToSuperview().offset(30)
                m.right.equalToSuperview().offset(-30)
                m.bottom.equalTo(lastBtn.snp.top).offset(-10)
                m.height.equalTo(height)
            }
            lastBtn = btn
        }
    }
    
    func show(){
        UIApplication.shared.keyWindow?.addSubview(self)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateConstraints(with: 0.3) {
                self.cancelBtn.snp.updateConstraints({ (m) in
                    m.bottom.equalToSuperview().offset(-30)
                })
            }
        }
    }
    
    func hide(){
        self.updateConstraints(with: 0.3, updateBlock: {
            self.cancelBtn.snp.updateConstraints({ (m) in
                m.bottom.equalToSuperview().offset(300)
            })
        }) {
            self.removeFromSuperview()
        }
    }
    
    class func show(with arr:[FZMBottomOption]){
        let view = FZMBottomSelectView(with: arr)
        view.show()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class FZMBottomOption: NSObject {
    var title = ""
    var content : String?
    var textColor : UIColor
    var contentColor : UIColor
    var clickBlock : (()->())?
    init(title : String , titleColor : UIColor = FZM_BlackWordColor, content: String? = nil, contentColor: UIColor = FZM_GrayWordColor, block:(()->())?) {
        self.title = title
        self.content = content
        self.textColor = titleColor
        self.contentColor = contentColor
        self.clickBlock = block
        super.init()
    }
    
    
}
