//
//  FZMMeQRCodeVC.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/8.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift

enum FZMQRCodeVCShowType {
    case me
    case group(IMGroupDetailInfoModel)
}

class FZMQRCodeShowVC: FZMBaseViewController {
    
    lazy var borderView : UIView = {
        let view = UIView()
        view.backgroundColor = FZM_TintColor
        return view
    }()
    
    lazy var centerView : UIImageView = {
        let view = UIImageView(image: GetBundleImage("me_qrcode_back"))
        view.backgroundColor = FZM_TintColor
        view.isUserInteractionEnabled = true
        var isGroup = false
        if case .group(_) = self.type {
            isGroup = true
        }
        
        view.addSubview(headImageView)
        headImageView.snp.makeConstraints({ (m) in
            m.centerX.equalToSuperview()
            m.top.equalToSuperview().offset(isGroup ? 68 : 56)
            m.size.equalTo(CGSize(width: 50, height: 50))
        })
        view.addSubview(nameLab)
        nameLab.snp.makeConstraints { (m) in
            m.top.equalTo(headImageView.snp.bottom).offset(5)
            m.left.equalToSuperview().offset(20)
            m.right.equalToSuperview().offset(-20)
        }
        
        view.addSubview(idLab)
        idLab.snp.makeConstraints({ (m) in
            m.top.equalTo(nameLab.snp.bottom).offset(5)
            if case .group(_) = self.type {
                m.centerX.equalToSuperview()
            } else {
                m.left.equalToSuperview().offset(32)
                m.right.equalToSuperview().offset(-49)
            }
            m.height.equalTo(20)
        })
        
        view.addSubview(idCopyImageView)
        idCopyImageView.snp.makeConstraints { (m) in
            m.size.equalTo(CGSize.init(width: 12, height: 14))
            m.left.equalTo(idLab.snp.right).offset(5)
            m.centerY.equalTo(idLab)
        }
        
        view.addSubview(inviteCodeLab)
        inviteCodeLab.snp.makeConstraints({ (m) in
            m.top.equalTo(idLab.snp.bottom).offset(isGroup ? 0 : 5)
            m.centerX.equalToSuperview()
            m.size.equalTo(isGroup ? CGSize(width: 0, height: 0) : CGSize(width: 180, height: 32))
        })
        
        view.addSubview(qrImageView)
        qrImageView.snp.makeConstraints({ (m) in
            m.top.equalTo(inviteCodeLab.snp.bottom).offset(10)
            m.centerX.equalToSuperview()
            m.size.equalTo(CGSize(width: 140, height: 140))
        })
        
        view.addSubview(alertLab)
        alertLab.snp.makeConstraints({ (m) in
            m.top.equalTo(qrImageView.snp.bottom).offset(10)
            m.centerX.equalToSuperview()
            m.size.equalTo(CGSize(width: 200, height: 20))
        })
        
        return view
    }()
    
    lazy var alertLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .center, text: "扫描二维码加我\(IMSDK.shared().shareTitle ?? "")好友")
    }()
    
    lazy var qrImageView : UIImageView = {
        let imV = UIImageView()
        imV.isUserInteractionEnabled = true
        return imV
    }()
    
    lazy var identificationImageView: UIImageView = {
        let imgV = UIImageView(image: GetBundleImage("user_identification"))
        imgV.isUserInteractionEnabled = true
        imgV.contentMode = .scaleAspectFill
        imgV.isHidden = true
        return imgV
    }()
    
    lazy var headImageView : UIImageView = {
        let imV = UIImageView(image: GetBundleImage("chat_normal_head"))
        imV.layer.cornerRadius = 5
        imV.clipsToBounds = true
        imV.contentMode = .scaleAspectFill
        imV.addSubview(identificationImageView)
        identificationImageView.snp.makeConstraints({ (m) in
            m.size.equalTo(CGSize.init(width: 15, height: 15))
            m.bottom.right.equalToSuperview()
        })
        return imV
    }()
    
    lazy var nameLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.mediumFont(17), textColor: FZM_TitleColor, textAlignment: .center, text: nil)
        lab.numberOfLines = 0
        return lab
    }()
    
    lazy var idLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_BlackWordColor, textAlignment: .center, text: nil)
        lab.lineBreakMode = .byTruncatingMiddle
        return lab
    }()
    
    lazy var idCopyImageView: UIImageView = {
        let v = UIImageView.init(image: GetBundleImage("text_copy"))
        v.isUserInteractionEnabled = true
        v.enlargeClickEdge(10, 10, 10, 10)
        let tap = UITapGestureRecognizer.init()
        tap.rx.event.subscribe {[weak self] (_) in
            if case .group(let model) = self?.type {
                UIPasteboard.general.string =  model.showId
            }else{
                UIPasteboard.general.string = IMLoginUser.shared().currentUser?.showId
            }
            self?.showToast(with: "已复制")
        }.disposed(by: disposeBag)
        v.addGestureRecognizer(tap)
        return v
    }()
    
    lazy var inviteCodeLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .center, text: nil)
        lab.layer.cornerRadius = 16
        lab.layer.borderColor = FZM_TintColor.cgColor
        lab.layer.borderWidth = 1
        return lab
    }()
    
    lazy var rightBtn: UIButton = {
        let btn = UIButton.init()
        btn.addTarget(self, action: #selector(promoteDetail), for: .touchUpInside)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        btn.setTitle("推广详情", for: .normal)
        btn.setTitleColor(self.navTintColor, for: .normal)
        btn.setTitleColor(self.navTintColor, for: .highlighted)
        return btn
    }()
    
    let type : FZMQRCodeVCShowType
    init(with type: FZMQRCodeVCShowType) {
        self.type = type
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.navBarColor = FZM_TintColor
        self.navTintColor = UIColor.white
        self.navTitleColor = UIColor.white
        self.view.backgroundColor = FZM_TintColor
        self.createUI()
    }
    
    private func createUI() {
        self.view.addSubview(borderView)
        borderView.snp.makeConstraints { (m) in
            m.centerX.equalToSuperview()
            m.centerY.equalTo(self.safeCenterY).offset(-40)
            m.size.equalTo(CGSize(width: ScreenWidth, height: ScreenWidth * 1.32))
        }
        borderView.addSubview(centerView)
        centerView.snp.makeConstraints { (m) in
            m.center.equalToSuperview()
            m.size.equalTo(CGSize(width: 300, height: 455))
        }
        
        if IMSDK.shared().showShare {
            let timeLineBtn = FZMImageTitleView(headImage: GetBundleImage("qrcodeshare_timeline"), imageSize: CGSize(width: 35, height: 35), title: "朋友圈") {[weak self] in
                self?.share(with: .wxTimeline)
            }
            self.view.addSubview(timeLineBtn)
            timeLineBtn.snp.makeConstraints { (m) in
                m.top.equalTo(borderView.snp.bottom).offset(10)
                m.right.equalTo(self.view.snp.centerX).offset(-20)
                m.size.equalTo(CGSize(width: 35, height: 55))
            }
            
            let iconBtn = FZMImageTitleView(headImage: IMSDK.shared().shareIcon ?? GetBundleImage("qrcode_share_chat"), imageSize: CGSize(width: 35, height: 35), title: IMSDK.shared().shareTitle ?? "分享") {[weak self] in
                guard let strongSelf = self else { return }
                let image = UIImage.getImageFromView(view: strongSelf.borderView)
                FZMUIMediator.shared().pushVC(.multipleSendMsg(type: .image(image: image)))
            }
            self.view.addSubview(iconBtn)
            iconBtn.snp.makeConstraints { (m) in
                m.top.equalTo(borderView.snp.bottom).offset(10)
                m.right.equalTo(timeLineBtn.snp.left).offset(-40)
                m.size.equalTo(CGSize(width: 35, height: 55))
            }
            
            let wxBtn = FZMImageTitleView(headImage: GetBundleImage("qrcodeshare_wx"), imageSize: CGSize(width: 35, height: 35), title: "微信") {[weak self] in
                self?.share(with: .wxFriend)
            }
            self.view.addSubview(wxBtn)
            wxBtn.snp.makeConstraints { (m) in
                m.top.equalTo(borderView.snp.bottom).offset(10)
                m.left.equalTo(self.view.snp.centerX).offset(20)
                m.size.equalTo(CGSize(width: 35, height: 55))
            }
            
            let saveBtn = FZMImageTitleView(headImage: GetBundleImage("qrcode_share_save"), imageSize: CGSize(width: 35, height: 35), title: "保存") {[weak self] in
                guard let strongSelf = self else { return }
                let image = UIImage.getImageFromView(view: strongSelf.borderView)
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(FZMQRCodeShowVC.image(image:didFinishSavingWithError:contextInfo:)), nil)
            }
            self.view.addSubview(saveBtn)
            saveBtn.snp.makeConstraints { (m) in
                m.top.equalTo(borderView.snp.bottom).offset(10)
                m.left.equalTo(wxBtn.snp.right).offset(40)
                m.size.equalTo(CGSize(width: 35, height: 55))
            }
        }else {
            let iconBtn = FZMImageTitleView(headImage: IMSDK.shared().shareIcon ?? GetBundleImage("qrcode_share_chat"), imageSize: CGSize(width: 35, height: 35), title: IMSDK.shared().shareTitle ?? "分享") {[weak self] in
                guard let strongSelf = self else { return }
                let image = UIImage.getImageFromView(view: strongSelf.borderView)
                FZMUIMediator.shared().pushVC(.multipleSendMsg(type: .image(image: image)))
            }
            self.view.addSubview(iconBtn)
            iconBtn.snp.makeConstraints { (m) in
                m.top.equalTo(borderView.snp.bottom).offset(10)
                m.right.equalTo(self.view.snp.centerX).offset(-20)
                m.size.equalTo(CGSize(width: 35, height: 55))
            }
            
            let saveBtn = FZMImageTitleView(headImage: GetBundleImage("qrcode_share_save"), imageSize: CGSize(width: 35, height: 35), title: "保存") {[weak self] in
                guard let strongSelf = self else { return }
                let image = UIImage.getImageFromView(view: strongSelf.borderView)
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(FZMQRCodeShowVC.image(image:didFinishSavingWithError:contextInfo:)), nil)
            }
            self.view.addSubview(saveBtn)
            saveBtn.snp.makeConstraints { (m) in
                m.top.equalTo(borderView.snp.bottom).offset(10)
                m.left.equalTo(self.view.snp.centerX).offset(20)
                m.size.equalTo(CGSize(width: 35, height: 55))
            }
        }
        
        let code = IMLoginUser.shared().currentUser?.code ?? ""
        if case .group(let model) = self.type {
            self.navigationItem.title = "群二维码"
            self.identificationImageView.image = GetBundleImage("group_identification")
            self.identificationImageView.isHidden = !model.identification
            alertLab.text = "扫描二维码加\(IMSDK.shared().shareTitle ?? "")群"
            let image = FZMQRCodeGenerator.setupQRCodeImage(qrCodeShareUrl + "code=\(code)&" + "uid=\(IMLoginUser.shared().showId)&" + "gid=\(model.showId)", image: nil)
            qrImageView.image = FZMQRCodeGenerator.syntheticImage(image, iconImage: IMSDK.shared().qrCodeCenterIcon, width: 40, height: 40)
            nameLab.text = model.showName
            headImageView.loadNetworkImage(with: model.avatar.getDownloadUrlString(width: 50), placeImage: GetBundleImage("chat_normal_head"))
            idLab.text = "群号：" + model.showId
        }else{
            self.navigationItem.title = "我的二维码"
            if IMSDK.shared().certificationDelegate != nil {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: rightBtn)
            }
            let image = FZMQRCodeGenerator.setupQRCodeImage(qrCodeShareUrl + "code=\(code)&" + "uid=\(IMLoginUser.shared().showId)", image: nil)
            qrImageView.image = FZMQRCodeGenerator.syntheticImage(image, iconImage: IMSDK.shared().qrCodeCenterIcon, width: 40, height: 40)
            guard let user = IMLoginUser.shared().currentUser else { return }
            self.identificationImageView.image = GetBundleImage("user_identification")
            self.identificationImageView.isHidden = !user.identification
            nameLab.text = user.userName
            headImageView.loadNetworkImage(with: user.avatar.getDownloadUrlString(width: 50), placeImage: GetBundleImage("chat_normal_head"))
            idLab.text = "UID：" + user.showId
            if !code.isEmpty {
                let attStr = NSMutableAttributedString(string: "邀请码 ")
                attStr.append(NSAttributedString(string: code, attributes: [.foregroundColor:FZM_TintColor]))
                inviteCodeLab.attributedText = attStr
            } else {
                inviteCodeLab.isHidden = true
                qrImageView.snp.updateConstraints { (m) in
                    m.size.equalTo(CGSize(width: 165, height: 165))
                }
                inviteCodeLab.snp.updateConstraints({ (m) in
                    m.top.equalTo(self.idLab.snp.bottom).offset(0)
                    m.size.equalTo(CGSize(width: 0, height: 0))
                })
            }
        }
    }
    
    @objc private func promoteDetail() {
        let vc = FZMPromoteDetailVC.init()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
        var showMessage = ""
        if error != nil{
            showMessage = "图片保存失败"
        }else{
            showMessage = "图片已保存"
        }
        UIApplication.shared.keyWindow?.showToast(with: showMessage)
    }
    
    private func share(with platment: IMSharePlatment) {
        let code = IMLoginUser.shared().currentUser?.code ?? ""
        var url = ""

        if case .group(let model) = self.type {
            url = qrCodeShareUrl + "code=\(code)&" + "uid=\(IMLoginUser.shared().showId)&" + "gid=\(model.showId)"
        }else{
            url = qrCodeShareUrl + "code=\(code)&" + "uid=\(IMLoginUser.shared().showId)"
        }
        let image = UIImage.getImageFromView(view: self.borderView)
        IMSDK.shared().shareDelegate?.shareQRCode(url: url, image: image, platment: platment)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
