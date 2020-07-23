//
//  PhotoBrowserCell.swift
//  IM_SocketIO_Demo
//
//  Created by Wang on 2018/6/1.
//  Copyright © 2018年 Wang. All rights reserved.
//

import UIKit
import RxSwift
class PhotoBrowserCell: UICollectionViewCell, BrowserVCHandler {
    
    let disposeBag = DisposeBag()
    
    var dismissSelf: ((UIImageView) -> Void)? {
        didSet {
            photoView.dismissSelf = dismissSelf
        }
    }
    var dataModel: BrowserViewable = BrowserViewable() {
        didSet {
            photoView.dataModel = dataModel
        }
    }
    lazy var photoView: PhotoBrowserView = {
        let pbv = PhotoBrowserView(frame: ScreenBounds)
        return pbv
    }()
    
    lazy var saveBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = FZM_TintColor
        btn.layer.cornerRadius = 4
        btn.setAttributedTitle(NSAttributedString(string: "保存图片", attributes: [.foregroundColor:UIColor.white,.font:UIFont.regularFont(16)]), for: .normal)
        btn.addTarget(self, action: #selector(saveBtnClick), for: .touchUpInside)
        return btn
    }()
    
    @objc func saveBtnClick() {
        guard let img = photoView.imageView.image else { return }
        UIImageWriteToSavedPhotosAlbum(img, self, #selector(PhotoBrowserCell.image(image:didFinishSavingWithError:contextInfo:)), nil)
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    fileprivate func initView() {
        self.contentView.addSubview(photoView)
//        self.contentView.addSubview(saveBtn)
//        saveBtn.snp.makeConstraints { (m) in
//            m.bottom.equalToSuperview().offset(-30)
//            m.left.equalToSuperview().offset(30)
//            m.right.equalToSuperview().offset(-30)
//            m.height.equalTo(40)
//        }
    }
    func resetPhotoScroll() {
        photoView.resetScroll()
    }
    func pb_imageWithUrl(_ url: String, placeHolder: UIImage?) {
        photoView.pb_setImageWithUrl(url, placeHolder: placeHolder)
    }
    
}
