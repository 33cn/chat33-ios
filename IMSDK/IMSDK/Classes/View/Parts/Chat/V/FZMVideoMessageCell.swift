//
//  FZMVideoMessageCell.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/27.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift

class FZMVideoMessageCell: FZMImageMessageCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    lazy var playOrDownloadImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    lazy var videoTimeLab: UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_EA6Color, textAlignment: .right, text: "")
        return lab
    }()
    
    var downloadOrUploadProgressView = SectorProgress.init(frame: CGRect.init(x: 0, y: 0, width: 50, height: 50))
    
    override func initView() {
        super.initView()
        
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .download)
        self.playOrDownloadImageView.image = GetBundleImage("chat_video_play")

        self.contentImageView.addSubview(playOrDownloadImageView)
        playOrDownloadImageView.snp.makeConstraints { (m) in
            m.center.equalToSuperview()
            m.size.equalTo(CGSize.init(width: 50, height: 50))
        }
        self.contentImageView.addSubview(videoTimeLab)
        self.contentImageView.backgroundColor = .black
        videoTimeLab.snp.makeConstraints { (m) in
            m.right.equalToSuperview().offset(-5)
            m.bottom.equalToSuperview().offset(-5)
        }
        
        self.contentImageView.addSubview(downloadOrUploadProgressView)
        downloadOrUploadProgressView.isHidden = true
        downloadOrUploadProgressView.alpha = 0.6
        downloadOrUploadProgressView.snp.makeConstraints { (m) in
            m.center.equalToSuperview()
            m.size.equalTo(CGSize.init(width: 50, height: 50))
        }
        
        
    }
    
    override func configure(with data: FZMMessageBaseVM) {
        super.configure(with: data)
        guard let data = data as? FZMVideoMessageVM , data.direction == .receive else { return }
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
        downloadOrUploadProgressView.isHidden = true
        self.downloadOrUploadProgressView.progress = 0
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
        
        data.videoDownloadFailedSubject.subscribe { [weak self] (_) in
            self?.playOrDownloadImageView.image = GetBundleImage("chat_video_download")
            self?.downloadOrUploadProgressView.isHidden = true
            self?.downloadOrUploadProgressView.progress = 0
        }.disposed(by: disposeBag)
        
        if !data.firstFrameImgData.isEmpty {
            self.reloadImageView(with: data)
        } else {
            data.widthAndHeightRefreshSubject.subscribe {[weak self] (_) in
                self?.reloadImageView(with: data)
                }.disposed(by: disposeBag)
        }
        self.videoTimeLab.text = String.transToHourMinSec(time: data.duration)
        
    }
    
    func reloadImageView(with data:FZMVideoMessageVM) {
        if !data.firstFrameImgData.isEmpty {
            self.contentImageView.image = UIImage(data: data.firstFrameImgData)
        }
    }
    
    override func contentImageViewTap(from imageView: UIImageView, msgId: String) {
        guard let vm = self.vm as? FZMVideoMessageVM else { return }
        if vm.message.body.localVideoPath.count == 0 {
            vm.downloadVideo()
            self.playOrDownloadImageView.image = GetBundleImage("chat_video_play")
        } else {
            self.actionDelegate?.playVideo(msgId: msgId, videlPath:vm.message.body.localVideoPath )
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}

extension FZMVideoMessageCell: DownloadDelegate {
    func downloadProgress(_ sendMsgID: String, _ progress: Float) {
         guard let data = self.vm as? FZMVideoMessageVM,sendMsgID == data.videoDownloadID  else {
            return
        }
        self.downloadOrUploadProgressView.isHidden = false
        self.downloadOrUploadProgressView.progress = CGFloat(progress)
        
        if progress == 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.downloadOrUploadProgressView.isHidden = true
                self.downloadOrUploadProgressView.progress = 0
            }
        }
    }
}



class FZMMineVideoMessageCell: FZMVideoMessageCell {
    
    override func initView() {
        super.initView()
        self.changeMineConstraints()
        
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .upload)
        self.playOrDownloadImageView.image = GetBundleImage("chat_video_play")

        self.sendingView.transform = CGAffineTransform.init(scaleX: 0, y: 0)

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
        guard let data = data as? FZMVideoMessageVM , data.direction == .send else { return }
        self.reloadImageView(with: data)
        lockImg.isHidden = data.snap == .none
        sourceLab.text = data.forwardType == .detail ? data.forwardDescriptionText : nil
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
        if data.videoUrl.isEmpty {
            self.contentImageView.sd_addActivityIndicator()
        }
        self.videoTimeLab.text = String.transToHourMinSec(time: data.duration)
    }
    
    override func reloadNormalInfo() {
        super.reloadNormalInfo()
        DispatchQueue.main.async {
            if self.failBtn.isHidden == false {
                self.contentImageView.sd_removeActivityIndicator()
            }
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
}

extension FZMMineVideoMessageCell: UploadDelegate {
    func uploadProgress(_ sendMsgID: String, _ progress: Float) {
        guard sendMsgID == self.vm.sendMsgId  else {
            return
        }
        
        self.contentImageView.sd_removeActivityIndicator()
        self.downloadOrUploadProgressView.isHidden = false
        self.downloadOrUploadProgressView.progress = CGFloat(progress)
        
        if progress == 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.downloadOrUploadProgressView.isHidden = true
                self.downloadOrUploadProgressView.progress = 0
                self.sendingView.transform = CGAffineTransform.identity
            }
        }
    }
}
