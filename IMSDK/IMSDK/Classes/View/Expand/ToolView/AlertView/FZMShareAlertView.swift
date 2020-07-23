//
//  FZMShareAlertView.swift
//  IMSDK
//
//  Created by .. on 2019/3/21.
//

import UIKit

class FZMShareAlertView: UIView {

    var shareBlock: ((IMSharePlatment) -> ())?
    
    private let shareViewHeight = 190 + TabbarHeight - 49
    lazy private var shareView: UIView = {
       let v = UIView.init()
        v.backgroundColor = FZM_BackgroundColor
        self.addSubview(v)
        v.snp.makeConstraints({ (m) in
            m.height.equalTo(shareViewHeight)
            m.bottom.equalToSuperview().offset(shareViewHeight)
            m.left.right.equalToSuperview()
        })
        
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .center, text: "选择分享方式")
        v.addSubview(lab)
        lab.snp.makeConstraints({ (m) in
            m.height.equalTo(20)
            m.top.equalToSuperview().offset(18)
            m.centerX.equalToSuperview()
        })
        
        let timeLineBtn = FZMImageTitleView(headImage: GetBundleImage("red_share_timeline"), imageSize: CGSize(width: 35, height: 35), title: "朋友圈",titleColor:FZM_BlackWordColor) {[weak self] in
            self?.share(with: .wxTimeline)
        }
        v.addSubview(timeLineBtn)
        timeLineBtn.snp.makeConstraints { (m) in
            m.top.equalTo(lab.snp.bottom).offset(25)
            m.right.equalTo(v.snp.centerX).offset(-20)
            m.size.equalTo(CGSize(width: 35, height: 55))
        }
        
        let wxBtn = FZMImageTitleView(headImage: GetBundleImage("red_share_wx"), imageSize: CGSize(width: 35, height: 35), title: "微信",titleColor:FZM_BlackWordColor) {[weak self] in
            self?.share(with: .wxFriend)
        }
        v.addSubview(wxBtn)
        wxBtn.snp.makeConstraints { (m) in
            m.top.equalTo(timeLineBtn)
            m.left.equalTo(v.snp.centerX).offset(20)
            m.size.equalTo(timeLineBtn)
        }
        
        let line = UIView.getNormalLineView()
        v.addSubview(line)
        line.snp.makeConstraints({ (m) in
            m.top.equalTo(wxBtn.snp.bottom).offset(17)
            m.left.right.equalToSuperview()
            m.height.equalTo(0.5)
        })
        
        let btn = UIButton.init()
        btn.setTitle("取消", for: .normal)
        btn.setTitleColor(FZM_TintColor, for: .normal)
        btn.titleLabel?.font = UIFont.mediumFont(16)
        v.addSubview(btn)
        btn.snp.makeConstraints({ (m) in
            m.top.equalTo(line).offset(17)
            m.height.equalTo(23)
            m.width.equalTo(80)
            m.centerX.equalToSuperview()
        })
        btn.addTarget(self, action: #selector(hide), for: .touchUpInside)
        return v
    }()
    
    init() {
        super.init(frame: ScreenBounds)
        self.backgroundColor = UIColor.init(white: 0, alpha: 0.5)
        let backCtrl = UIControl.init(frame: ScreenBounds)
        backCtrl.addTarget(self, action: #selector(hide), for: .touchUpInside)
        self.addSubview(backCtrl)
        self.addSubview(shareView)
        self.layoutIfNeeded()
    }
    
    func show() {
        shareView.snp.updateConstraints { (m) in
            m.bottom.equalToSuperview().offset(0)
        }
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
    
    @objc func hide() {
        shareView.snp.updateConstraints { (m) in
            m.bottom.equalToSuperview().offset(shareViewHeight)
        }
        UIView.animate(withDuration: 0.3, animations: {
            self.layoutIfNeeded()
        }) { (_) in
            self.removeFromSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func share(with platment: IMSharePlatment) {
        self.shareBlock?(platment)
//        guard let code = inviteCode else { return }
//        var url = ""
//        
//        if case .group(let model) = self.type {
//            url = qrCodeShareUrl + "code=\(code)&" + "uid=\(IMLoginUser.shared().showId)&" + "gid=\(model.showId)"
//        }else{
//            url = qrCodeShareUrl + "code=\(code)&" + "uid=\(IMLoginUser.shared().showId)"
//        }
//        let image = UIImage.getImageFromView(view: self.borderView)
//        IMSDK.shared().shareDelegate?.shareQRCode(url: url, image: image, platment: platment)
    }
    
}
