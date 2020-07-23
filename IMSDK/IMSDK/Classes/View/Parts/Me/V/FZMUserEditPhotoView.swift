//
//  FZMUserEditPhotoView.swift
//  IMSDK
//
//  Created by .. on 2019/2/27.
//

import UIKit
import RxSwift
import FSPagerView
import YYWebImage

class FZMUserEditPhotoView: UIView {
    private let disposeBag = DisposeBag()
    var photos = [Any]() {
        didSet {
            self.reloadPagerView()
            desNumLab.text = "\(self.photos.count)/3"
        }
    }
    lazy private var pagerView: FSPagerView = {
        let view = FSPagerView.init(frame: CGRect.zero)
        view.dataSource = self
        view.delegate = self
        view.register(FSPagerViewCell.self, forCellWithReuseIdentifier: "FSPagerViewCell")
        view.addSubview(delBtn)
        delBtn.snp.makeConstraints({ (m) in
            m.top.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
        })
        return view
    }()
    
    lazy private var delBtn: UIImageView = {
        let view = UIImageView.init(image: GetBundleImage("user_photo_del"))
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer.init()
        tap.rx.event.subscribe({ [weak self] (_) in
            if let strongSelf = self, let index = strongSelf.currentIndex, index < strongSelf.photos.count {
                strongSelf.photos.remove(at: index)
                if strongSelf.photos.isEmpty {
                    strongSelf.currentIndex = nil
                }
                strongSelf.reloadPagerView()
            }
        })
        view.addGestureRecognizer(tap)
        return view
    }()
    
    
    private var currentIndex: Int?
    
    lazy private var desBlockView : UIView = {
        let view = UIView()
        let titleLab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: "图片")
        view.addSubview(titleLab)
        titleLab.snp.makeConstraints({ (m) in
            m.left.equalToSuperview()
            m.centerY.equalToSuperview()
        })
        view.addSubview(desNumLab)
        desNumLab.snp.makeConstraints({ (m) in
            m.right.equalToSuperview()
            m.centerY.equalTo(titleLab)
        })
        return view
    }()
    
    lazy private var desNumLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .right, text: "0/3")
        return lab
    }()
    
    lazy private var addImageBtn: UIView = {
        let view = UIView.init()
        view.layer.borderColor = UIColor(hex: 0xC8D3DE).cgColor
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .right, text: "添加名片或相关图片")
        view.addSubview(lab)
        lab.snp.makeConstraints({ (m) in
            m.center.equalToSuperview()
        })
        let tap = UITapGestureRecognizer.init()
        tap.rx.event.subscribe({ [weak self](_) in
            self?.showImagePicker()
        })
        view.addGestureRecognizer(tap)
        return view
    }()
    
    
    private func showImagePicker() {
        guard self.photos.count < 3 else {return}
        let block : (Bool)->() = { isAlbum in
            if isAlbum {
                FZMUIMediator.shared().pushVC(.photoLibrary(selectOne: (3 - self.photos.count == 1), maxSelectCount: 3 - self.photos.count, allowEditing: (3 - self.photos.count != 1), showVideo: false, selectBlock: { (list, _) in
                    for image in list {
                        self.photos.append(image)
                    }
                }))
            }else {
                FZMUIMediator.shared().pushVC(.camera(allowEditing: false, selectBlock: { (list, _) in
                    guard let image = list.first else { return }
                    self.photos.append(image)
                }))
            }
        }
        FZMBottomSelectView.show(with: [
            FZMBottomOption(title: "从相册选择", block: {
                block(true)
            }),FZMBottomOption(title: "拍照", block: {
                block(false)
            })])
    }
    
    private func reloadPagerView() {
        if self.photos.isEmpty {
            self.pagerView.snp.updateConstraints { (m) in
                m.height.equalTo(0)
            }
        } else {
            self.pagerView.snp.updateConstraints { (m) in
                m.height.equalTo(ScreenWidth - 60).multipliedBy(1.05)
            }
        }
        self.pagerView.reloadData()
        self.superview?.layoutIfNeeded()
        
    }
    
    init() {
        super.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0))
        self.addSubview(desBlockView)
        desBlockView.snp.makeConstraints { (m) in
            m.height.equalTo(30)
            m.width.equalToSuperview().offset(-30)
            m.top.equalToSuperview()
            m.centerX.equalToSuperview()
        }
        self.addSubview(pagerView)
        pagerView.layer.cornerRadius = 5
        pagerView.layer.masksToBounds = true
        pagerView.snp.makeConstraints { (m) in
            m.top.equalTo(self.desBlockView.snp.bottom).offset(15)
            m.width.equalToSuperview().offset(-30)
            m.height.equalTo(0)
            m.centerX.equalToSuperview()
        }
        
        self.addSubview(addImageBtn)
        addImageBtn.snp.makeConstraints { (m) in
            m.height.equalTo(80)
            m.width.equalToSuperview().offset(-30)
            m.centerX.equalToSuperview()
            m.top.equalTo(self.pagerView.snp.bottom).offset(15)
            m.bottom.equalToSuperview().offset(-25)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

import IDMPhotoBrowser
extension FZMUserEditPhotoView: FSPagerViewDelegate,FSPagerViewDataSource {
    
    func showImage(imageView: UIImageView?) {
        var phs = [Any]()
        for item in self.photos {
            if let urlStr = item as? String {
                if urlStr.isEncryptMedia() {
                    if let image = YYImageCache.shared().getImageForKey(urlStr) {
                        phs.append(IDMPhoto.init(image: image))
                    }
                } else if let url = URL.init(string: urlStr) {
                    phs.append(IDMPhoto.init(url: url))
                }
            } else if let image = item as? UIImage {
                phs.append(IDMPhoto.init(image: image))
            }
        }
        guard !phs.isEmpty else {return}
        if let imageView = imageView,
            let vc = FZMPhotoBrowser.init(photos: phs, animatedFrom: imageView),
            let index = currentIndex {
            if index < phs.count {
                vc.setInitialPageIndex(UInt(index))
            }
            UIViewController.current()?.present(vc, animated: true, completion: nil)
        }
    }
    
    func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
        pagerView.cellForItem(at: index)?.imageView?.subviews.first?.alpha = 0
    }
    
    func numberOfItems(in pagerView: FSPagerView) -> Int {
        return self.photos.count
    }
    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "FSPagerViewCell", at: index)
        if let urlStr = self.photos[index] as? String {
            if urlStr.isEncryptMedia() {
                if let image = YYImageCache.shared().getImageForKey(urlStr) {
                    cell.imageView?.image = image
                }else if let url = URL.init(string: urlStr) {
                    IMOSSClient.shared().download(with: url, downloadProgressBlock: nil) { (imageData, result) in
                        if result, let imageData = imageData,
                            let privateKey = IMLoginUser.shared().currentUser?.privateKey,
                            let publicKey = IMLoginUser.shared().currentUser?.publicKey,
                            let plaintextImageData = FZMEncryptManager.decryptSymmetric(privateKey: privateKey, publicKey: publicKey, ciphertext: imageData),
                            let image = UIImage(data: plaintextImageData) {
                            YYImageCache.shared().setImage(image, forKey: urlStr)
                            cell.imageView?.image = image
                        }
                    }
                }
            } else {
                cell.imageView?.loadNetworkImage(with: urlStr, placeImage: nil)
            }
        } else if let image = self.photos[index] as? UIImage {
            cell.imageView?.image = image
        }
        cell.imageView?.contentMode = .scaleAspectFill
        cell.layer.masksToBounds = true
        cell.imageView?.subviews.first?.alpha = 0
        cell.imageView?.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer.init()
        tap.rx.event.subscribe({ [weak self](_) in
            self?.showImage(imageView: cell.imageView)
        })
        cell.imageView?.addGestureRecognizer(tap)
        return cell
    }
    
    func pagerView(_ pagerView: FSPagerView, willDisplay cell: FSPagerViewCell, forItemAt index: Int) {
        self.currentIndex = index
    }
}

