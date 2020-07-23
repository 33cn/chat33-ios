//
//  FZMMeInfoView.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/8.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class FZMMeInfoView: UIView {

    let disposeBag = DisposeBag()
    
    var editNameBlock : NormalBlock?
    var qrCodeBlock : NormalBlock?
    var sweepBlock: NormalBlock?
    var headImgBlock : NormalBlock?
    
    lazy var identificationImageView: UIImageView = {
        let imgV = UIImageView(image: GetBundleImage("user_identification"))
        imgV.isUserInteractionEnabled = true
        imgV.contentMode = .scaleAspectFill
        imgV.isHidden = true
        return imgV
    }()
    
    lazy var headImageView : UIImageView = {
        let imV = UIImageView(image: GetBundleImage("chat_normal_head"))
        imV.isUserInteractionEnabled = true
        imV.layer.cornerRadius = 5
        imV.clipsToBounds = true
        imV.contentMode = .scaleAspectFill
        imV.addSubview(identificationImageView)
        identificationImageView.snp.makeConstraints({ (m) in
            m.size.equalTo(CGSize.init(width: 25, height: 25))
            m.bottom.right.equalToSuperview()
        })
        return imV
    }()
    
    lazy var nameLab : UILabel = {
        return UILabel.getLab(font: UIFont.mediumFont(17), textColor: FZM_TitleColor, textAlignment: .center, text: nil)
    }()
    
    lazy var uidLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: nil)
    }()
    
    lazy var accountLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .center, text: nil)
    }()
    
    private lazy var identificationInfoLab : UILabel = {
        let lab = UILabel.init()
        lab.textAlignment = .left
        lab.numberOfLines = 0
        lab.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer.init()
        lab.addGestureRecognizer(tap)
        tap.rx.event.subscribe { (_) in
            FZMUIMediator.shared().pushVC(.goIdentification(type: 1, roomId: ""))
        }.disposed(by: disposeBag)
        return lab
    }()
    
    lazy var positionBackView : UIView = {
        let view = UIView()
        view.layer.backgroundColor = FZM_LineColor.cgColor
        view.layer.cornerRadius = 15
        return view
    }()
    
    lazy var positionLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_BlackWordColor, textAlignment: .center, text: nil)
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let qrBtn = UIButton(type: .custom)
        qrBtn.setImage(GetBundleImage("me_qrcode")?.withRenderingMode(.alwaysTemplate), for: .normal)
        qrBtn.tintColor = FZM_TintColor
        qrBtn.enlargeClickEdge(20, 20, 20, 20)
        self.addSubview(qrBtn)
        qrBtn.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.size.equalTo(CGSize(width: 20, height: 20))
        }
        
        let sweepBtn = UIButton(type: .custom)
        sweepBtn.setImage(GetBundleImage("tool_sweep_icon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        sweepBtn.enlargeClickEdge(20, 20, 20, 20)
        sweepBtn.tintColor = FZM_TintColor
        self.addSubview(sweepBtn)
        sweepBtn.snp.makeConstraints { (m) in
            m.centerY.equalTo(qrBtn)
            m.size.equalTo(qrBtn)
            m.left.equalToSuperview().offset(15)
        }
        
        self.addSubview(headImageView)
        headImageView.snp.makeConstraints { (m) in
            m.top.equalTo(sweepBtn.snp.bottom).offset(12)
            m.left.equalTo(sweepBtn).offset(3)
            m.size.equalTo(CGSize(width: 100, height: 100))
        }
        self.addSubview(nameLab)
        nameLab.snp.makeConstraints { (m) in
            m.top.equalTo(headImageView).offset(IMSDK.shared().showIdentification ? 0 : 14)
            m.left.equalTo(headImageView.snp.right).offset(10)
            m.width.lessThanOrEqualTo(200)
        }
        self.addSubview(uidLab)
        uidLab.snp.makeConstraints { (m) in
            m.left.equalTo(nameLab)
            m.right.equalToSuperview()
            m.top.equalTo(nameLab.snp.bottom).offset(5)
            m.height.equalTo(20)
        }
        self.addSubview(accountLab)
        accountLab.snp.makeConstraints { (m) in
            m.top.equalTo(uidLab.snp.bottom).offset(5)
            m.left.equalTo(uidLab)
            m.height.equalTo(20)
        }
        self.addSubview(identificationInfoLab)
        identificationInfoLab.snp.makeConstraints { (m) in
            m.top.equalTo(accountLab.snp.bottom).offset(5)
            m.left.equalTo(accountLab)
            m.right.equalToSuperview().offset(-16)
        }
        
        let btn = UIButton(type: .custom)
        btn.setImage(GetBundleImage("me_edit"), for: .normal)
        btn.enlargeClickEdge(20, 20, 20, 20)
        self.addSubview(btn)
        btn.snp.makeConstraints { (m) in
            m.centerY.equalTo(nameLab)
            m.left.equalTo(nameLab.snp.right).offset(5)
            m.size.equalTo(CGSize(width: 10, height: 10))
        }
        
        btn.isHidden = true
        
        if !IMSDK.shared().showIdentification {
            self.identificationImageView.isHidden = true
            self.identificationInfoLab.isHidden = true
            self.identificationInfoLab.snp.remakeConstraints { (m) in
                m.top.equalTo(accountLab.snp.bottom).offset(5)
                m.left.equalTo(accountLab)
                m.right.equalToSuperview().offset(-16)
                m.height.equalTo(0)
            }
        }
        
        self.refreshView()
        btn.rx.controlEvent(.touchUpInside).subscribe(onNext:{[weak self] (_) in
            self?.editNameBlock?()
        }).disposed(by: disposeBag)
        qrBtn.rx.controlEvent(.touchUpInside).subscribe(onNext:{[weak self] (_) in
            self?.qrCodeBlock?()
        }).disposed(by: disposeBag)
        sweepBtn.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self] (_) in
            self?.sweepBlock?()
        }).disposed(by: disposeBag)
        
        let headImgTap = UITapGestureRecognizer()
        headImgTap.rx.event.subscribe {[weak self] (_) in
            self?.headImgBlock?()
        }.disposed(by: disposeBag)
        headImageView.addGestureRecognizer(headImgTap)
        
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .user)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func refreshIdentificationInfo() {
        guard let user = IMLoginUser.shared().currentUser else { return }
        if user.identification == false {
            IMContactManager.shared().requestUserDetailInfo(with: user.userId) { (userModel, success, _) in
                guard success, let user = userModel,user.identification == true else {  return }
                self.identificationImageView.isHidden = false
                let att = NSMutableAttributedString.init(string: "\(IMSDK.shared().shareTitle ?? "")认证： \(user.identificationInfo) \(FZMIconFont.identificationArrow.rawValue)", attributes: [NSAttributedString.Key.font : UIFont.iconfont(ofSize: 14),NSAttributedString.Key.foregroundColor : FZM_GrayWordColor])
                att.yy_lineSpacing = 4
                self.identificationInfoLab.attributedText = att
            }
        }
    }
    
    private func refreshView() {
        guard let user = IMLoginUser.shared().currentUser else { return }
        accountLab.text = "账号 " + user.securityAccount
        nameLab.text = user.userName
        uidLab.text = "UID " + user.showId
        headImageView.loadNetworkImage(with: user.avatar, placeImage: GetBundleImage("chat_normal_head"))
        if IMSDK.shared().showIdentification  {
            if user.identification == true {
                self.identificationImageView.isHidden = false
                let att = NSMutableAttributedString.init(string: "\(IMSDK.shared().shareTitle ?? "")认证： \(user.identificationInfo) \(FZMIconFont.identificationArrow.rawValue)", attributes: [NSAttributedString.Key.font : UIFont.iconfont(ofSize: 14),NSAttributedString.Key.foregroundColor : FZM_GrayWordColor])
                att.yy_lineSpacing = 4
                self.identificationInfoLab.attributedText = att
            } else {
                self.identificationImageView.isHidden = true
                let att = NSMutableAttributedString.init(string: "去认证 \(FZMIconFont.identificationArrow.rawValue)", attributes: [NSAttributedString.Key.font : UIFont.iconfont(ofSize: 14),NSAttributedString.Key.foregroundColor :FZM_TintColor])
                att.insert(NSAttributedString.init(string: "\(IMSDK.shared().shareTitle ?? "")认证：", attributes: [NSAttributedString.Key.font : UIFont.regularFont(14),NSAttributedString.Key.foregroundColor : FZM_GrayWordColor]), at: 0)
                self.identificationInfoLab.attributedText = att
            }
        }
        
    }
}

extension FZMMeInfoView: UserInfoChangeDelegate {
    func userLogin() {
        self.refreshView()
    }
    func userLogout() {
        
    }
    func userInfoChange() {
        self.refreshView()
    }
}
