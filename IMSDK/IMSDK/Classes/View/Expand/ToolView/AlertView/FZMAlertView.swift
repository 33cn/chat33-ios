//
//  FZMAlertView.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/17.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift

public class FZMAlertView: UIView {

    var block : (()->())?
    
    lazy var centerView : UIView = {
        let v = UIView()
        v.backgroundColor = FZM_BackgroundColor
        v.clipsToBounds = true
        v.layer.cornerRadius = 5
        v.addSubview(titleLab)
        titleLab.snp.makeConstraints({ (m) in
            m.top.equalToSuperview().offset(20)
            m.centerX.equalToSuperview()
            m.height.equalTo(20)
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
        v.addSubview(centerLine)
        centerLine.snp.makeConstraints({ (m) in
            m.top.bottom.equalTo(confirmBtn)
            m.centerX.equalToSuperview()
            m.width.equalTo(1)
        })
        v.addSubview(desLab)
        desLab.snp.makeConstraints({ (m) in
            m.edges.equalToSuperview().inset(UIEdgeInsets.init(top: 85, left: 20, bottom: 95, right: 20))
        })
        v.transform = CGAffineTransform.init(scaleX: 0, y: 0)
        return v
    }()
    
    lazy var titleLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .center, text: "提示")
    }()
    
    lazy var desLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_TintColor, textAlignment: .center, text: nil)
        lab.numberOfLines = 0
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
        btn.addTarget(self, action: #selector(confirmClick), for: .touchUpInside)
        return btn
    }()
    
    lazy var centerLine : UIView = {
        return UIView.getNormalLineView()
    }()
    
     init(with desText : String?, confirmBlock:(()->())?) {
        block = confirmBlock
        super.init(frame: ScreenBounds)
        self.backgroundColor = UIColor(white: 0, alpha: 0.5)
        desLab.text = desText
        self.addSubview(centerView)
        centerView.snp.makeConstraints { (m) in
            m.center.equalToSuperview()
            m.width.equalTo(290)
        }
    }
    
    @objc public init(with attributedText : NSAttributedString?, confirmBlock:(()->())?) {
        block = confirmBlock
        super.init(frame: ScreenBounds)
        self.backgroundColor = UIColor(white: 0, alpha: 0.5)
        desLab.attributedText = attributedText
        self.addSubview(centerView)
        centerView.snp.makeConstraints { (m) in
            m.center.equalToSuperview()
            m.width.equalTo(290)
        }
    }
    
    @objc public init(attributedTitle : NSAttributedString?, attributedText : NSAttributedString?,btnTitle: String = "确定", confirmBlock:(()->())?) {
        block = confirmBlock
        super.init(frame: ScreenBounds)
        self.backgroundColor = UIColor(white: 0, alpha: 0.5)
        desLab.attributedText = attributedText
        titleLab.attributedText = attributedTitle
        self.addSubview(centerView)
        centerView.snp.makeConstraints { (m) in
            m.center.equalToSuperview()
            m.width.equalTo(290)
        }
        confirmBtn.setAttributedTitle(NSAttributedString(string: btnTitle, attributes: [.font:UIFont.mediumFont(16),.foregroundColor:FZM_TintColor]), for: .normal)
    }
    
    
    @objc public init(onlyAlert text: String?, btnTitle: String = "确定", confirmBlock:(()->())?) {
        block = confirmBlock
        super.init(frame: ScreenBounds)
        self.backgroundColor = UIColor(white: 0, alpha: 0.5)
        desLab.text = text
        desLab.textColor = FZM_BlackWordColor
        self.addSubview(centerView)
        centerView.snp.makeConstraints { (m) in
            m.center.equalToSuperview()
            m.width.equalTo(290)
        }
        cancelBtn.isHidden = true
        centerLine.isHidden = true
        titleLab.isHidden = true
        desLab.snp.updateConstraints { (m) in
            m.edges.equalToSuperview().inset(UIEdgeInsets.init(top: 40, left: 20, bottom: 90, right: 20))
        }
        confirmBtn.snp.remakeConstraints({ (m) in
            m.bottom.left.right.equalToSuperview()
            m.height.equalTo(50)
        })
        confirmBtn.setAttributedTitle(NSAttributedString(string: btnTitle, attributes: [.font:UIFont.regularFont(16),.foregroundColor:FZM_TintColor]), for: .normal)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc public func show() {
        UIApplication.shared.keyWindow?.addSubview(self)
        UIView.animate(withDuration: 0.3) {
            self.centerView.transform = CGAffineTransform.init(scaleX: 1, y: 1)
        }
    }
    
    func hide() {
        self.removeFromSuperview()
    }
    
    
    @objc func cancelClick(){
        self.hide()
    }
    
    @objc func confirmClick(){
        self.hide()
        block?()
    }

}


extension FZMAlertView {
    convenience init(deleteConversation: String, confirmBlock: NormalBlock?) {
        let attStr = NSMutableAttributedString(string: "删除后，将清空该聊天的消息记录， 确定删除 ", attributes: [.foregroundColor:FZM_BlackWordColor])
        attStr.append(NSAttributedString(string: deleteConversation, attributes: [.foregroundColor:FZM_TintColor]))
        attStr.append(NSAttributedString(string: " 的聊天吗？", attributes: [.foregroundColor:FZM_BlackWordColor]))
        self.init(with: attStr, confirmBlock: confirmBlock)
    }
    
    convenience init(deleteFriend: String, confirmBlock: NormalBlock?) {
        let attStr = NSMutableAttributedString(string: "删除后，将同时删除与该联系人的聊 天记录，确定删除联系人 ", attributes: [.foregroundColor:FZM_BlackWordColor])
        attStr.append(NSAttributedString(string: deleteFriend, attributes: [.foregroundColor:FZM_TintColor]))
        attStr.append(NSAttributedString(string: " 吗？", attributes: [.foregroundColor:FZM_BlackWordColor]))
        self.init(with: attStr, confirmBlock: confirmBlock)
    }
    
    convenience init(dissolveGroup: String, confirmBlock: NormalBlock?) {
        let attStr = NSMutableAttributedString(string: "确定解散 ", attributes: [.foregroundColor:FZM_BlackWordColor])
        attStr.append(NSAttributedString(string: dissolveGroup, attributes: [.foregroundColor:FZM_TintColor]))
        attStr.append(NSAttributedString(string: " 群吗？", attributes: [.foregroundColor:FZM_BlackWordColor]))
        self.init(with: attStr, confirmBlock: confirmBlock)
    }
    
    convenience init(quitGroup: String, confirmBlock: NormalBlock?) {
        let attStr = NSMutableAttributedString(string: "退群通知仅群主和管理员可见，确定 退出 ", attributes: [.foregroundColor:FZM_BlackWordColor])
        attStr.append(NSAttributedString(string: quitGroup, attributes: [.foregroundColor:FZM_TintColor]))
        attStr.append(NSAttributedString(string: " 群吗？", attributes: [.foregroundColor:FZM_BlackWordColor]))
        self.init(with: attStr, confirmBlock: confirmBlock)
    }
}



class FZMEditNameAlertView : UIView {
    
    let disposeBag = DisposeBag()
    lazy var centerView : UIView = {
        let v = UIView()
        v.backgroundColor = FZM_BackgroundColor
        v.clipsToBounds = true
        v.layer.cornerRadius = 5
        v.addSubview(titleLab)
        titleLab.snp.makeConstraints({ (m) in
            m.top.equalToSuperview()
            m.left.right.equalToSuperview()
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
        v.addSubview(centerLine)
        centerLine.snp.makeConstraints({ (m) in
            m.top.bottom.equalTo(confirmBtn)
            m.centerX.equalToSuperview()
            m.width.equalTo(1)
        })
        v.addSubview(inputNumLab)
        inputNumLab.snp.makeConstraints({ (m) in
            m.top.equalTo(titleLab.snp.bottom)
            m.right.equalToSuperview().offset(-16)
            m.height.equalTo(20)
        })
        v.addSubview(inputBackView)
        inputBackView.snp.makeConstraints({ (m) in
            m.top.equalTo(inputNumLab.snp.bottom).offset(5)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(65)
        })
        v.transform = CGAffineTransform.init(scaleX: 0, y: 0)
        return v
    }()
    
    lazy var titleLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .center, text: "设置昵称")
    }()
    
    lazy var inputNumLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .right, text: "0/20")
    }()
    
    lazy var inputBackView : UIView = {
        let view = UIView()
        view.layer.cornerRadius = 5
        view.backgroundColor = FZM_LineColor
        view.clipsToBounds = true
        view.addSubview(nameInput)
        nameInput.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(10)
            m.right.equalToSuperview().offset(-10)
            m.height.equalTo(30)
        })
        view.addSubview(placeLab)
        placeLab.snp.makeConstraints({ (m) in
            m.center.equalToSuperview()
            m.size.equalTo(CGSize(width: 160, height: 30))
        })
        return view
    }()
    
    lazy var nameInput : UITextView = {
        let input = UITextView()
        input.tintColor = FZM_TintColor
        input.backgroundColor = UIColor.clear
        input.textAlignment = .center
        input.font = UIFont.regularFont(16)
        input.textColor = FZM_BlackWordColor
        return input
    }()
    
    lazy var placeLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .center, text: "取个名字吧！20字内")
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
        btn.addTarget(self, action: #selector(confirmClick), for: .touchUpInside)
        return btn
    }()
    
    lazy var centerLine : UIView = {
        return UIView.getNormalLineView()
    }()
    
    override init(frame: CGRect) {
        super.init(frame: ScreenBounds)
        self.backgroundColor = UIColor(white: 0, alpha: 0.5)
        self.addSubview(centerView)
        centerView.snp.makeConstraints { (m) in
            m.centerX.equalToSuperview()
            m.centerY.equalToSuperview().offset(-50)
            m.width.equalTo(290)
            m.height.equalTo(220)
        }
        
        nameInput.rx.text.subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.nameInput.limitText(with: 20)
            if let text = strongSelf.nameInput.text, text.count > 0 {
                strongSelf.inputNumLab.text = "\(text.count)/20"
                strongSelf.confirmBtn.isEnabled = true
                strongSelf.placeLab.isHidden = true
            }else {
                strongSelf.inputNumLab.text = "0/20"
                strongSelf.confirmBtn.isEnabled = false
                strongSelf.placeLab.isHidden = false
            }
            let height = strongSelf.nameInput.sizeThatFits(CGSize(width: strongSelf.nameInput.frame.width, height: CGFloat.greatestFiniteMagnitude)).height + 3
            strongSelf.nameInput.snp.updateConstraints({ (m) in
                m.height.equalTo(height)
            })
        }.disposed(by: disposeBag)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func cancelClick(){
        self.hide()
    }
    
    @objc func confirmClick(){
        guard let name = nameInput.text else { return }
        self.showProgress()
        HttpConnect.shared().editUserName(name: name) { (response) in
            self.hideProgress()
            if response.success {
                self.hide()
            }else {
                self.showToast(with: response.message)
            }
        }
    }
    
    func show() {
        UIApplication.shared.keyWindow?.addSubview(self)
        UIView.animate(withDuration: 0.3) {
            self.centerView.transform = CGAffineTransform.init(scaleX: 1, y: 1)
        }
        self.nameInput.becomeFirstResponder()
    }
    
    func hide() {
        self.removeFromSuperview()
    }
}


class FZMImageAlertView: UIView {
    let disposeBag = DisposeBag.init()
    var block : (()->())?
    
    lazy var centerView : UIView = {
        let v = UIView()
        v.backgroundColor = FZM_WhiteColor
        v.clipsToBounds = true
        v.layer.cornerRadius = 10
        
        v.addSubview(topImageView)
        topImageView.snp.makeConstraints({ (m) in
             m.top.left.right.equalToSuperview()
        })
        
        v.addSubview(titleLab)
        titleLab.snp.makeConstraints({ (m) in
            m.top.equalTo(topImageView.snp.bottom).offset(15)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
        })
        
        v.addSubview(desLab1)
        desLab1.snp.makeConstraints({ (m) in
            m.top.equalTo(titleLab.snp.bottom).offset(15)
            m.left.equalTo(titleLab)
            m.right.equalTo(titleLab)
        })
        
        v.addSubview(desLab2)
        desLab2.snp.makeConstraints({ (m) in
            m.top.equalTo(desLab1.snp.bottom).offset(15)
            m.left.equalTo(desLab1)
            m.right.equalTo(desLab1)
        })
    
        v.addSubview(confirmBtn)
        confirmBtn.snp.makeConstraints({ (m) in
            m.bottom.equalToSuperview().offset(-30)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(40)
        })
        v.transform = CGAffineTransform.init(scaleX: 0, y: 0)
        return v
    }()
    
    lazy var topImageView : UIImageView = {
        return UIImageView.init()
    }()
    
    lazy var titleLab : UILabel = {
        let lab =  UILabel.getLab(font: UIFont.boldFont(20), textColor: FZM_BlackWordColor, textAlignment: .center, text: nil)
        lab.numberOfLines = 0
        return lab
    }()
    
    lazy var desLab1 : UILabel = {
        let lab = UILabel.getLab(font: UIFont.boldFont(16), textColor: FZM_TintColor, textAlignment: .center, text: nil)
        lab.numberOfLines = 0
        return lab
    }()
    
    lazy var desLab2 : UILabel = {
        let lab = UILabel.getLab(font: UIFont.mediumFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: nil)
        lab.numberOfLines = 0
        return lab
    }()
    
    lazy var confirmBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.addTarget(self, action: #selector(confirmClick), for: .touchUpInside)
        btn.setBackgroundColor(color: FZM_TintColor, state: .normal)
        btn.layer.cornerRadius = 5
        btn.layer.masksToBounds = true
        return btn
    }()
    
   
    init(image: UIImage?, title: String?, des1: String?, des2: String?, confirmTitle: String, dismissOnTouchBg:Bool = false, confirmBlock:(()->())?) {
        block = confirmBlock
        super.init(frame: ScreenBounds)
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe {[weak self] (_) in
            if dismissOnTouchBg {
               self?.hide()
            }
        }.disposed(by: disposeBag)
        self.addGestureRecognizer(tap)
        self.backgroundColor = UIColor(white: 0, alpha: 0.5)
        topImageView.image = image
        titleLab.text = title
        desLab1.text = des1
        desLab2.text = des2
        confirmBtn.setAttributedTitle(NSAttributedString(string: confirmTitle, attributes: [.font:UIFont.mediumFont(16),.foregroundColor:FZM_WhiteColor]), for: .normal)
        
        self.addSubview(centerView)
        centerView.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(30)
            m.right.equalToSuperview().offset(-30)
            m.height.equalTo(408)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        UIApplication.shared.keyWindow?.addSubview(self)
        UIView.animate(withDuration: 0.3) {
            self.centerView.transform = CGAffineTransform.init(scaleX: 1, y: 1)
        }
    }
    
    func hide() {
        self.removeFromSuperview()
    }
    
    @objc func confirmClick(){
        self.hide()
        block?()
    }
}
