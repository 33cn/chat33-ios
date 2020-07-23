//
//  FZMBurnImageView.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/12/17.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit

class FZMBurnImageView: UIView {

    var loadCompleteBlock : NormalBlock?
    
    lazy var photoView: PhotoBrowserView = {
        let pbv = PhotoBrowserView(frame: CGRect(x: 0, y: StatusBarHeight + 5, width: ScreenWidth, height: ScreenHeight - StatusBarHeight - 5))
        return pbv
    }()
    
    fileprivate lazy var lineView : UIView = {
        let view = UIView(frame: CGRect(x: 0, y: StatusBarHeight, width: ScreenWidth, height: 5))
        view.layer.cornerRadius = 3
        view.clipsToBounds = true
        view.backgroundColor = UIColor(hex: 0xF9EEE7)
        view.addSubview(self.progressLine)
        return view
    }()
    fileprivate lazy var progressLine : UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 5))
        view.layer.cornerRadius = 3
        view.clipsToBounds = true
        view.backgroundColor = FZM_OrangeColor
        return view
    }()
    
    fileprivate lazy var countDownTimeView : FZMCountdownLab = {
        let view = FZMCountdownLab()
        return view
    }()
    
    init(imageUrl: String, placeImg: UIImage?, endTime: Double) {
        super.init(frame: ScreenBounds)
        self.backgroundColor = UIColor.black
        self.addSubview(photoView)
        self.addSubview(lineView)
        self.addSubview(countDownTimeView)
        countDownTimeView.snp.makeConstraints { (m) in
            m.top.equalTo(lineView.snp.bottom).offset(11)
            m.left.equalToSuperview().offset(15)
            m.size.equalTo(CGSize.zero)
        }
        
        self.countDown(endTime: endTime)
        photoView.imageView.loadNetworkImage(with: imageUrl, placeImage: placeImg) { (img) in
            guard let _ = img else { return }
            
        }
        
        photoView.pb_setImageWithUrl(imageUrl, placeHolder: placeImg) { (img) in
            guard let _ = img else { return }
            if placeImg == nil {
                self.countDown(endTime: 30)
                self.loadCompleteBlock?()
            }
        }
        
        photoView.dismissSelf = {[weak self] (imageView) in
            self?.hide()
        }
        
        if let arr = photoView.gestureRecognizers {
            photoView.gestureRecognizers = arr.filter({ (ges) -> Bool in
                return !ges.isKind(of: UILongPressGestureRecognizer.self)
            })
        }
    }
    
    private func countDown(endTime: Double) {
        guard endTime > 0 else { return }
        FZMAnimationTool.countdown(with: countDownTimeView, fromValue: endTime, toValue: 0, block: { (time) in
            self.countDownTimeView.setTime(Int(time))
            self.progressLine.frame = CGRect(x: 0, y: 0, width: ScreenWidth * (30 - time) / 30, height: 5)
        }) {
            self.hide()
        }
    }
    
    deinit {
        IMLog("FZMBurnImageView销毁")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        self.alpha = 0
        UIApplication.shared.keyWindow?.addSubview(self)
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { (finish) in
            if finish {
                self.removeFromSuperview()
            }
        }
    }
}
