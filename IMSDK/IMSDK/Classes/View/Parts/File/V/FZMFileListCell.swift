//
//  FZMFileListCell.swift
//  IMSDK
//
//  Created by .. on 2019/2/21.
//

import UIKit
import RxSwift

class FZMFileListCell: UITableViewCell {
    let disposeBag = DisposeBag()
    var vm: FZMFileListVM?
    var senderLabBlock: ((FZMFileListVM)->())? {
        didSet {
            guard senderLabBlock != nil else {return}
            senderLab.textColor = FZM_TintColor
        }
    }
    lazy var selectBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(GetBundleImage("tool_disselect"), for: .normal)
        btn.setImage(GetBundleImage("tool_select"), for: .selected)
        btn.enlargeClickEdge(15, 15, 15, 15)
        btn.isHidden = true
        return btn
    }()
    var isShowSelect: Bool = false {
        didSet{
            selectBtn.isHidden = !isShowSelect
            if self.fileIconImageView.superview != nil {
                self.fileIconImageView.snp.updateConstraints { (m) in
                    m.left.equalToSuperview().offset(isShowSelect ? 45 : 15)
                }
            }
        }
    }
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
    
    let downloadProgressView = SectorProgress.init(frame: CGRect.init(x: 0, y: 0, width: 85, height: 85))
    
    let fileNameLab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .center, text: "")
    let fileSizeLab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: "")
    let senderLab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: "")
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = FZM_BackgroundColor
        self.clipsToBounds = true
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .download)
        self.initViews()
    }
    
    func initViews() {
        
        self.contentView.addSubview(selectBtn)
        selectBtn.snp.makeConstraints { (m) in
            m.left.equalToSuperview().offset(15)
            m.centerY.equalToSuperview()
            m.size.equalTo(CGSize(width: 15, height: 15))
        }
        self.contentView.addSubview(fileIconImageView)
        fileIconImageView.snp.makeConstraints { (m) in
            m.size.equalTo(CGSize.init(width: 60, height: 60))
            m.left.equalToSuperview().offset(15)
            m.centerY.equalToSuperview()
        }
        self.fileIconImageView.addSubview(downloadProgressView)
        downloadProgressView.isHidden = true
        downloadProgressView.alpha = 0.6
        downloadProgressView.snp.makeConstraints { (m) in
            m.center.equalToSuperview()
            m.size.equalTo(CGSize.init(width: 85, height: 85))
        }
        fileNameLab.textAlignment = .left
        self.contentView.addSubview(fileNameLab)
        fileNameLab.snp.makeConstraints { (m) in
            m.top.equalTo(self.fileIconImageView)
            m.left.equalTo(self.fileIconImageView.snp.right).offset(10)
            m.right.equalToSuperview().offset(-15)
        }
        fileSizeLab.textAlignment = .left
        self.contentView.addSubview(fileSizeLab)
        fileSizeLab.snp.makeConstraints { (m) in
            m.left.right.equalTo(self.fileNameLab)
            m.centerY.equalTo(self.fileIconImageView)
        }
        senderLab.textAlignment = .left
        self.contentView.addSubview(senderLab)
        senderLab.enlargeClickEdge(10, 0, 2, 10)
        senderLab.snp.makeConstraints { (m) in
            m.left.equalTo(self.fileNameLab)
            m.right.lessThanOrEqualTo(self.contentView)
            m.bottom.equalTo(self.fileIconImageView)
        }
        
        let tap = UITapGestureRecognizer.init()
        tap.rx.event.subscribe { [weak self] (_) in
            guard let strongSelf = self,let vm = self?.vm else {return}
            strongSelf.senderLabBlock?(vm)
            }.disposed(by: disposeBag)
        selectBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.selectBtn.isSelected = !strongSelf.selectBtn.isSelected
            strongSelf.vm?.selected = strongSelf.selectBtn.isSelected
            }.disposed(by: disposeBag)
        senderLab.addGestureRecognizer(tap)

    }
    
    func configure(with data: FZMFileListVM) {
        self.vm = data
        self.isShowSelect = data.isShowSelect
        self.selectBtn.isSelected = data.selected
        self.fileIconImageView.image = GetBundleImage(data.iconImageName)
        if data.isCiphertext {
            let attachment = NSTextAttachment.init()
            attachment.image = GetBundleImage("encrypt_file")
            attachment.bounds = CGRect.init(x: 3, y: -4, width: 20, height: 20)
            let attStr = NSMutableAttributedString.init(attachment: attachment)
            attStr.insert(NSAttributedString.init(string: "无法解密的文件", attributes: [NSAttributedString.Key.font: UIFont.regularFont(16), NSAttributedString.Key.foregroundColor: FZM_GrayWordColor]), at: 0)
            attStr.insert(NSAttributedString.init(string: " "), at: attStr.length)
            self.fileNameLab.attributedText = attStr
        } else {
            self.fileNameLab.text = data.fileName
        }
        if let haveFile = FZM_UserDefaults.value(forKey: data.fileUrl) as? String, !haveFile.isEmpty {
            downloadProgressView.isHidden = true
        } else {
            downloadProgressView.isHidden = false
        }
        self.downloadProgressView.progress = 0
        data.fileDownloadFailedSubject.subscribe { [weak self] (_) in
            self?.downloadProgressView.isHidden = false
            self?.downloadProgressView.progress = 0
            }.disposed(by: disposeBag)
        
        self.fileSizeLab.text = data.time + "   " + ((data.size / 1024) > 1024 ? "\(data.size / 1024 / 1024)M" : (data.size / 1024) > 0 ? "\(data.size / 1024 )K" : "\(data.size)B")
        data.infoSubject.subscribe {[weak self] (event) in
            guard case .next(let (name,_)) = event else { return }
            self?.senderLab.text = name
            }.disposed(by: disposeBag)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

extension FZMFileListCell: DownloadDelegate {
    func downloadProgress(_ sendMsgID: String, _ progress: Float) {
        guard let data = self.vm,sendMsgID == data.fileDownloadID  else {
            return
        }
        self.downloadProgressView.isHidden = false
        self.downloadProgressView.progress = CGFloat(progress)
        
        if progress == 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.downloadProgressView.isHidden = true
                self.downloadProgressView.progress = 0
            }
        }
    }
}

