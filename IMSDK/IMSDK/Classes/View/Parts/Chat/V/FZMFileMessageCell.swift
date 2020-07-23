//
//  FZMFileMessageCell.swift
//  IMSDK
//
//  Created by .. on 2019/2/19.
//

import UIKit

class FZMFileMessageCell: FZMBaseMessageCell {
    lazy var contentImageView : UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        v.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        v.isUserInteractionEnabled = true
        v.image = GetBundleImage("chat_fileBg")
        return v
    }()
    
    lazy var fileIconImageView : UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        v.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        v.isUserInteractionEnabled = true
        v.layer.cornerRadius = 5
        v.layer.masksToBounds = true
        return v
    }()
    
    let downloadOrUploadProgressView = SectorProgress.init(frame: CGRect.init(x: 0, y: 0, width: 71, height: 71))
    
    let fileNameLab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .center, text: "")
    let fileSizeLab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .left, text: "")
    
    override func initView() {
        super.initView()
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .download)
        self.contentView.addSubview(contentImageView)
        contentImageView.snp.makeConstraints { (m) in
            m.top.equalTo(userNameLbl.snp.bottom).offset(2)
            m.left.equalTo(headerImageView.snp.right)
            m.size.equalTo(CGSize.init(width: 260, height: 120))
            m.bottom.equalToSuperview().offset(-15)
        }
        self.contentView.addSubview(sourceLab)
        sourceLab.snp.makeConstraints { (m) in
            m.right.equalTo(headerImageView.snp.left).offset(-15)
            m.left.greaterThanOrEqualToSuperview().offset(80)
            m.bottom.equalToSuperview().offset(-5)
            m.height.lessThanOrEqualTo(35)
            m.top.equalTo(contentImageView.snp.bottom).offset(-5)
        }
        self.contentImageView.addSubview(fileIconImageView)
        fileIconImageView.snp.makeConstraints { (m) in
            m.size.equalTo(CGSize.init(width: 50, height: 50))
            m.left.equalToSuperview().offset(23)
            m.top.equalToSuperview().offset(19)
        }
        fileNameLab.numberOfLines = 0
        fileNameLab.textAlignment = .left
        self.contentImageView.addSubview(fileNameLab)
        fileNameLab.snp.makeConstraints { (m) in
            m.top.equalTo(self.fileIconImageView)
            m.left.equalTo(self.fileIconImageView.snp.right).offset(10)
            m.right.equalToSuperview().offset(-20)
            m.height.equalTo(45)
        }
        let line = UIView.getNormalLineView()
        self.contentImageView.addSubview(line)
        line.snp.makeConstraints { (m) in
            m.height.equalTo(0.5)
            m.left.equalToSuperview()
            m.right.equalToSuperview()
            m.top.equalTo(self.fileIconImageView.snp.bottom).offset(10)
        }
        self.contentImageView.addSubview(fileSizeLab)
        fileSizeLab.snp.makeConstraints { (m) in
            m.left.equalTo(self.fileIconImageView)
            m.bottom.equalToSuperview().offset(-18)
        }
        
        self.fileIconImageView.addSubview(downloadOrUploadProgressView)
        downloadOrUploadProgressView.isHidden = true
        downloadOrUploadProgressView.alpha = 0.6
        downloadOrUploadProgressView.snp.makeConstraints { (m) in
            m.center.equalToSuperview()
            m.size.equalTo(CGSize.init(width: 71, height: 71))
        }
        
        self.admireView.snp.makeConstraints { (m) in
            m.bottom.equalTo(contentImageView.snp.bottom).offset(-15)
            m.left.equalTo(contentImageView.snp.right).offset(-5)
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
            strongSelf.contentImageViewTap(msgId: strongSelf.vm.msgId)
            }.disposed(by: disposeBag)
        contentImageView.addGestureRecognizer(tap)
        
    }
    
    override func configure(with data: FZMMessageBaseVM) {
        super.configure(with: data)
        guard let data = data as? FZMFileMessageVM  else { return }
        self.sourceLab.text = nil
        self.fileIconImageView.image = GetBundleImage(data.iconImageName)
        self.fileNameLab.text = data.fileName
        self.fileSizeLab.text = (data.size / 1024) > 1024 ? "\(data.size / 1024 / 1024)M" : (data.size / 1024) > 0 ? "\(data.size / 1024 )K" : "\(data.size)B"
        downloadOrUploadProgressView.isHidden = !data.message.body.localFilePath.isEmpty
        self.downloadOrUploadProgressView.progress = 0
        data.fileDownloadFailedSubject.subscribe { [weak self] (_) in
            self?.downloadOrUploadProgressView.isHidden = false
            self?.downloadOrUploadProgressView.progress = 0
        }.disposed(by: disposeBag)
        
    }
    
    func contentImageViewTap(msgId: String) {
        guard let vm = self.vm as? FZMFileMessageVM else { return }
        if vm.message.body.localFilePath.count == 0 {
            vm.downloadFile()
        } else {
            self.actionDelegate?.openFile(msgId: msgId, filePath:vm.message.body.localFilePath, fileName: vm.fileName)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

extension FZMFileMessageCell: DownloadDelegate {
    func downloadProgress(_ sendMsgID: String, _ progress: Float) {
        guard let data = self.vm as? FZMFileMessageVM,sendMsgID == data.fileDownloadID  else {
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


class FZMMineFileMessageCell: FZMFileMessageCell {
    
    override func initView() {
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .upload)
        super.initView()
        self.changeMineConstraints()
        contentImageView.snp.remakeConstraints { (m) in
            m.top.equalTo(userNameLbl.snp.bottom).offset(2)
            m.right.equalTo(headerImageView.snp.left)
            m.size.equalTo(CGSize.init(width: 260, height: 120))
            m.bottom.equalToSuperview().offset(-15)
        }
        sendingView.snp.remakeConstraints { (m) in
            m.centerY.equalTo(contentImageView)
            m.right.equalTo(contentImageView.snp.left).offset(-5)
            m.size.equalTo(CGSize(width: 15, height: 15))
        }
        self.admireView.snp.remakeConstraints { (m) in
            m.bottom.equalTo(contentImageView.snp.bottom).offset(-15)
            m.right.equalTo(contentImageView.snp.left).offset(5)
        }
  
    }
    
    override func configure(with data: FZMMessageBaseVM) {
        super.configure(with: data)
        self.sendingView.transform = CGAffineTransform.init(scaleX: 0, y: 0)
        guard let data = data as? FZMFileMessageVM else { return }
        sourceLab.text = data.forwardType == .detail ? data.forwardDescriptionText : nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}

extension FZMMineFileMessageCell: UploadDelegate {
    func uploadProgress(_ sendMsgID: String, _ progress: Float) {
        guard sendMsgID == self.vm.sendMsgId  else {
            return
        }
        
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
