//
//  FZMImageMessageCell.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/27.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import YYWebImage

class FZMImageMessageCell: FZMBaseMessageCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    lazy var contentImageView : UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        v.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        v.isUserInteractionEnabled = true
        return v
    }()
    
    override func initView() {
        super.initView()
        self.contentView.addSubview(contentImageView)
        contentImageView.snp.makeConstraints { (m) in
            m.top.equalTo(userNameLbl.snp.bottom).offset(2)
            m.left.equalTo(headerImageView.snp.right).offset(15)
            m.size.equalTo(CGSize.zero)
            m.bottom.equalToSuperview().offset(-15)
        }
        
        self.contentView.addSubview(self.lockView)
        self.lockView.snp.makeConstraints { (m) in
            m.top.equalTo(self.userNameLbl.snp.bottom).offset(-5)
            m.left.equalToSuperview().offset(55)
            m.size.equalTo(CGSize(width: 120, height: 65))
        }
        self.contentView.addSubview(self.countDownTimeView)
        self.countDownTimeView.snp.makeConstraints { (m) in
            m.top.equalTo(self.contentImageView)
            m.centerX.equalTo(self.contentImageView.snp.right)
            m.size.equalTo(CGSize(width: 0, height: 0))
        }
        
        sendingView.snp.makeConstraints { (m) in
            m.centerY.equalTo(contentImageView)
            m.left.equalTo(contentImageView.snp.right).offset(15)
            m.size.equalTo(CGSize(width: 15, height: 15))
        }
        
        self.admireView.snp.makeConstraints { (m) in
            m.bottom.equalTo(contentImageView.snp.bottom).offset(-5)
            m.left.equalTo(contentImageView.snp.right).offset(5)
        }

        
        let longPress = UILongPressGestureRecognizer()
        longPress.rx.event.subscribe {[weak self] (event) in
            guard case .next(let press) = event else { return }
            if press.state == .began {
                guard let view = press.view else { return }
                self?.showMenu(in: view)
            }
        }.disposed(by: disposeBag)
        contentImageView.addGestureRecognizer(longPress)
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe {[weak self] (event) in
            guard let strongSelf = self else { return }
            strongSelf.contentImageViewTap(from: strongSelf.contentImageView, msgId: strongSelf.vm.msgId)
        }.disposed(by: disposeBag)
        contentImageView.addGestureRecognizer(tap)
    }
    
    override func configure(with data: FZMMessageBaseVM) {
        super.configure(with: data)
        guard let data = data as? FZMImageMessageVM , data.direction == .receive else { return }
        if data.snap == .burn {
            self.contentImageView.isHidden = true
            self.lockView.isHidden = false
            self.countDownTimeView.setTime(0)
            self.contentImageView.snp.updateConstraints { (m) in
                m.size.equalTo(CGSize(width: 50, height: 50))
            }
            return
        }
        self.contentImageView.isHidden = false
        self.lockView.isHidden = true
        self.countDownTimeView.setTime(0)
        var maxValue = max(data.width, data.height)
        var minValue = min(data.width, data.height)
        if maxValue > 150.0 {
            minValue = minValue / maxValue * 150.0
            maxValue = 150.0
        }
        let size = data.width > data.height ? CGSize(width: maxValue, height: minValue) : CGSize(width: minValue, height: maxValue)
        self.contentImageView.snp.updateConstraints { (m) in
            m.size.equalTo(size)
        }
        self.contentImageView.image = UIImage.imageWithColor(with: .black, size: size)
        if data.imageUrl.count > 0 {
            if data.message.body.isEncryptMedia {
                if let image = YYImageCache.shared().getImageForKey(data.imageUrl) {
                    self.contentImageView.image = image
                    self.actionDelegate?.shouldBurnData(msgId: data.msgId)
                } else if let url = URL.init(string: data.imageUrl) {
                    IMOSSClient.shared().download(with: url, downloadProgressBlock: nil) { (imageData, result) in
                        if result, var imageData = imageData {
                            imageData = data.message.decryptMedia(ciphertext: imageData)
                            if let image = UIImage(data: imageData) {
                                YYImageCache.shared().setImage(image, forKey: data.imageUrl)
                                self.contentImageView.image = image
                                self.actionDelegate?.shouldBurnData(msgId: data.msgId)
                            }
                        }
                    }
                }
            } else {
                self.contentImageView.loadNetworkImage(with: data.imageUrl.getDownloadUrlString(width: 150), placeImage: nil) { (image) in
                    guard let _ = image else { return }
                    self.actionDelegate?.shouldBurnData(msgId: data.msgId)
                }
            }
        }else {
            self.contentImageView.image = UIImage(data: data.imgData)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func contentImageViewTap(from imageView: UIImageView, msgId: String) {
        self.actionDelegate?.browserImage(from: imageView, msgId: msgId)
    }

}

class FZMMineImageMessageCell: FZMImageMessageCell {
    override func initView() {
        super.initView()
        self.changeMineConstraints()
        contentImageView.snp.remakeConstraints { (m) in
            m.top.equalTo(userNameLbl.snp.bottom).offset(2)
            m.right.equalTo(headerImageView.snp.left).offset(-15)
            m.size.equalTo(CGSize.zero)
        }
        self.contentView.addSubview(sourceLab)
        sourceLab.snp.makeConstraints { (m) in
            m.right.equalTo(headerImageView.snp.left).offset(-15)
            m.left.greaterThanOrEqualToSuperview().offset(80)
            m.bottom.equalToSuperview().offset(-5)
            m.height.lessThanOrEqualTo(35)
            m.top.equalTo(contentImageView.snp.bottom).offset(5)
        }
        
        lockView.removeFromSuperview()
        countDownTimeView.removeFromSuperview()
        self.contentView.addSubview(lockImg)
        lockImg.snp.makeConstraints { (m) in
            m.top.equalTo(self.contentImageView)
            m.centerX.equalTo(self.contentImageView.snp.left)
            m.size.equalTo(CGSize(width: 20, height: 20))
        }
        
        sendingView.snp.remakeConstraints { (m) in
            m.centerY.equalTo(contentImageView)
            m.right.equalTo(contentImageView.snp.left).offset(-15)
            m.size.equalTo(CGSize(width: 15, height: 15))
        }
        
        self.admireView.snp.remakeConstraints { (m) in
            m.bottom.equalTo(contentImageView.snp.bottom).offset(-5)
            m.right.equalTo(contentImageView.snp.left).offset(-5)
        }

    }
    
    override func configure(with data: FZMMessageBaseVM) {
        super.configure(with: data)
        guard let data = data as? FZMImageMessageVM , data.direction == .send else { return }
        lockImg.isHidden = data.snap == .none
        var maxValue = max(data.width, data.height)
        var minValue = min(data.width, data.height)
        if maxValue > 150.0 {
            minValue = minValue / maxValue * 150.0
            maxValue = 150.0
        }
        let size = data.width > data.height ? CGSize(width: maxValue, height: minValue) : CGSize(width: minValue, height: maxValue)
        self.contentImageView.snp.updateConstraints { (m) in
            m.size.equalTo(size)
        }
        if data.imageUrl.count > 0 {
            if data.message.body.isEncryptMedia {
                if let image = YYImageCache.shared().getImageForKey(data.imageUrl) {
                    self.contentImageView.image = image
                } else if let url = URL.init(string: data.imageUrl) {
                    IMOSSClient.shared().download(with: url, downloadProgressBlock: nil) { (imageData, result) in
                        if result, var imageData = imageData {
                            imageData = data.message.decryptMedia(ciphertext: imageData)
                            if let image = UIImage(data: imageData) {
                                YYImageCache.shared().setImage(image, forKey: data.imageUrl)
                                self.contentImageView.image = image
                            }
                        }
                    }
                }
            } else {
                self.contentImageView.loadNetworkImage(with: data.imageUrl.getDownloadUrlString(width: 150), placeImage: nil) { (image) in
                    guard let _ = image else { return }
                    self.actionDelegate?.shouldBurnData(msgId: data.msgId)
                }
            }
        }else {
            self.contentImageView.image = UIImage(data: data.imgData)
        }
        
        sourceLab.text = data.forwardType == .detail ? data.forwardDescriptionText : nil
    }
}
