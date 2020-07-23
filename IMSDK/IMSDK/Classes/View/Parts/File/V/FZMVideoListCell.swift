//
//  FZMVideoListCell.swift
//  IMSDK
//
//  Created by .. on 2019/2/21.
//

import UIKit
import RxSwift
import YYWebImage


class FZMVideoListCell: UICollectionViewCell {
    let disposeBag = DisposeBag()
    var vm: FZMVideoListVM?
    var selectBlock: ((FZMVideoListVM,UIImageView)->())?
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var contentImageView : UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        v.isUserInteractionEnabled = true
        v.clipsToBounds = true
        return v
    }()
    
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
    
    lazy var selectBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(GetBundleImage("tool2_disselect"), for: .normal)
        btn.setImage(GetBundleImage("tool2_select"), for: .selected)
        btn.enlargeClickEdge(15, 15, 15, 15)
        btn.isHidden = true
        return btn
    }()
    var isShowSelect: Bool = false {
        didSet{
            selectBtn.isHidden = !isShowSelect
        }
    }
    
    var downloadProgressView = SectorProgress.init(frame: CGRect.init(x: 0, y: 0, width: 35, height: 35))
    
     func initView() {
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .download)
        
        self.contentView.addSubview(self.contentImageView)
        self.contentImageView.snp.makeConstraints { (m) in
            m.edges.equalToSuperview()
        }
        
        self.contentView.addSubview(playOrDownloadImageView)
        playOrDownloadImageView.snp.makeConstraints { (m) in
            m.center.equalToSuperview()
            m.size.equalTo(CGSize.init(width: 35, height: 35))
        }
        self.contentView.addSubview(videoTimeLab)
        videoTimeLab.snp.makeConstraints { (m) in
            m.right.equalToSuperview().offset(-4)
            m.bottom.equalToSuperview().offset(-2)
        }
        
        self.contentView.addSubview(downloadProgressView)
        downloadProgressView.isHidden = true
        downloadProgressView.snp.makeConstraints { (m) in
            m.center.equalToSuperview()
            m.size.equalTo(CGSize.init(width: 35, height: 35))
        }
        self.contentView.addSubview(selectBtn)
        selectBtn.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(8)
            m.right.equalToSuperview().offset(-8)
            m.size.equalTo(CGSize(width: 25, height: 25))
        }
        
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe {[weak self] (event) in
            guard let strongSelf = self,let vm = self?.vm else { return }
            strongSelf.contentImageViewTap(from: strongSelf.contentImageView, msgId: vm.msgId)
            }.disposed(by: disposeBag)
        self.contentView.addGestureRecognizer(tap)
        
        selectBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.selectBtn.isSelected = !strongSelf.selectBtn.isSelected
            strongSelf.vm?.selected = strongSelf.selectBtn.isSelected
            }.disposed(by: disposeBag)
    }
    
     func configure(with data: FZMVideoListVM) {
        self.vm = data
        self.contentImageView.image = nil
        self.isShowSelect = data.isShowSelect
        self.selectBtn.isSelected = self.vm?.selected ?? false
        playOrDownloadImageView.isHidden = true
        self.downloadProgressView.progress = 0
        if data.isCiphertext {
            self.contentImageView.image = GetBundleImage("encrypt_video")
        } else {
            switch data.msgType {
            case .video:
                playOrDownloadImageView.isHidden = false
                videoTimeLab.isHidden = false
                if let haveVideo = FZM_UserDefaults.value(forKey: data.videoUrl) as? String, !haveVideo.isEmpty {
                    self.playOrDownloadImageView.image = GetBundleImage("chat_video_play")
                    if let videoPath = FZM_UserDefaults.object(forKey: data.videoUrl) as? String, !videoPath.isEmpty {
                        let filePath = FZMLocalFileClient.shared().getFilePath(with: .video(fileName: (videoPath as NSString).lastPathComponent))
                        UIImage.getFirstFrame(URL.init(fileURLWithPath: filePath), compeletion: { (image) in
                            DispatchQueue.main.async {
                                self.contentImageView.image = image
                            }
                        })
                    }
                } else {
                    self.playOrDownloadImageView.image = GetBundleImage("chat_video_download")
                }
                data.videoDownloadFailedSubject.subscribe { [weak self] (_) in
                    self?.playOrDownloadImageView.image = GetBundleImage("chat_video_download")
                    self?.downloadProgressView.isHidden = true
                    self?.downloadProgressView.progress = 0
                    }.disposed(by: disposeBag)
                
                if !data.firstFrameImgData.isEmpty {
                    self.reloadImageView(with: data)
                } else {
                    data.widthAndHeightRefreshSubject.subscribe {[weak self] (_) in
                        self?.reloadImageView(with: data)
                        }.disposed(by: disposeBag)
                }
                self.videoTimeLab.text = String.transToHourMinSec(time: data.duration)
            case .image:
                playOrDownloadImageView.isHidden = true
                downloadProgressView.isHidden = true
                videoTimeLab.isHidden = true
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
                        }
                    }
                }else {
                    self.contentImageView.image = UIImage(data: data.imgData)
                }
            default:
                break
            }
        }
        
    }
    
    func reloadImageView(with data:FZMVideoMessageVM) {
        if !data.firstFrameImgData.isEmpty {
            self.contentImageView.image = UIImage(data: data.firstFrameImgData)
        }
    }
    
    func contentImageViewTap(from imageView: UIImageView, msgId: String) {
        guard let vm = self.vm else { return }
        if vm.isCiphertext {
            let alert = FZMAlertView.init(onlyAlert: "无法解密的图片/视频，可前往安全管理导入以前的助记词查看！", confirmBlock: nil)
            alert.show()
            return
        }
        switch vm.msgType {
        case .video:
            if let haveVideo = FZM_UserDefaults.value(forKey: vm.videoUrl) as? String, !haveVideo.isEmpty {
                self.selectBlock?(vm,self.contentImageView)
            } else {
                vm.downloadVideo()
                self.playOrDownloadImageView.image = GetBundleImage("chat_video_play")
            }
        case .image:
            self.selectBlock?(vm,self.contentImageView)
        default:
            break
        }
    }
}

extension FZMVideoListCell: DownloadDelegate {
    func downloadProgress(_ sendMsgID: String, _ progress: Float) {
        guard self.vm?.msgType == .video, sendMsgID == self.vm?.videoDownloadID  else {
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
