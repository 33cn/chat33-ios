//
//  FZMImagePickerController.swift
//  IMSDK
//
//  Created by .. on 2019/2/13.
//

import UIKit
import TZImagePickerController

class FZMImagePickerController: TZImagePickerController {

    override init!(maxImagesCount: Int, columnNumber: Int, delegate: TZImagePickerControllerDelegate!, pushPhotoPickerVc: Bool) {
        super.init(maxImagesCount: maxImagesCount, columnNumber: columnNumber, delegate: delegate, pushPhotoPickerVc: pushPhotoPickerVc)
        self.modalPresentationStyle = .fullScreen
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    init(withSelectOne selectOne: Bool,maxSelectCount:Int = 9, allowEditing: Bool,showVideo:Bool) {
        super.init(maxImagesCount: maxSelectCount, delegate: nil)
        self.naviBgColor = .white
        self.naviTitleColor = FZM_TitleColor
        self.naviTitleFont = UIFont.boldFont(17)
        self.barItemTextFont = UIFont.boldFont(16)
        self.barItemTextColor = FZM_TintColor
        self.iconThemeColor = FZM_TintColor
        self.photoDefImage = GetBundleImage("photo_select_normal")
        self.allowTakePicture = false
        self.allowTakeVideo = false
        self.showSelectedIndex = true
        self.allowPickingOriginalPhoto = false
        self.allowPickingGif = true
        self.allowPickingMultipleVideo = true
        self.allowPickingVideo = showVideo
        self.navigationBar.tintColor = FZM_TintColor
        if !selectOne {
            self.minImagesCount = 1
            self.photoPickerPageDidLayoutSubviewsBlock = {[weak self] (a,b,c,d,e,f,g,h,i) in
                if let self = self, let collectionView = a, let bottomBgView = b,let previewBtn = c, let doneBtn = f, let countLab = h, let popView = g, let lineView = i {
                    collectionView.frame = CGRect(x: collectionView.frame.origin.x, y: collectionView.frame.origin.y, width: collectionView.frame.width, height: collectionView.frame.height - 20)
                    bottomBgView.backgroundColor = .white
                    bottomBgView.frame = CGRect(x: 0, y: ScreenHeight - 70, width: ScreenWidth, height: 70)
                    previewBtn.setTitleColor(FZM_TintColor, for: .normal)
                    previewBtn.frame = CGRect(x: 20, y: 0, width: 40, height: 70)
                    previewBtn.titleLabel?.font = UIFont.boldFont(16)
                    
                    doneBtn.frame = CGRect(x: ScreenWidth - 100 - 15, y: 15, width: 100, height: 40)
                    doneBtn.layer.cornerRadius = 20
                    doneBtn.layer.masksToBounds = true
                    doneBtn.backgroundColor = FZM_TintColor
                    doneBtn.setTitleColor(.white, for: .normal)
                    doneBtn.setTitleColor(.white, for: .disabled)
                    doneBtn.setTitle("确定(  /" + "\(self.maxImagesCount)" + ")", for: .normal)
                    doneBtn.setTitle("确定(0/" + "\(self.maxImagesCount)" + ")", for: .disabled)
                    doneBtn.titleLabel?.font = UIFont.boldFont(16)
                    
                    countLab.frame = CGRect(x: countLab.frame.origin.x + 5, y: countLab.frame.origin.y + 10, width: countLab.frame.width, height: countLab.frame.height)
                    countLab.font = doneBtn.titleLabel?.font
                    countLab.backgroundColor = .clear
                    
                    popView.alpha = 0
                    lineView.alpha = 0
                }
            }
            self.photoPreviewPageDidLayoutSubviewsBlock = {[weak self] (_,b,_,_,_,f,_,_,i,j,k) in
                if let self = self, let naviBar = b, let toolbar = f,let doneBtn = i, let popView = j, let countLab = k {
                    naviBar.backgroundColor = UIColor(hex: 0x142E4D, alpha: 0.8)
                    toolbar.backgroundColor = naviBar.backgroundColor
                    toolbar.frame = CGRect(x: 0, y: ScreenHeight - 70, width: ScreenWidth, height: 70)
                    
                    doneBtn.frame = CGRect(x: ScreenWidth - 100 - 15, y: 17, width: 100, height: 40)
                    doneBtn.layer.cornerRadius = 20
                    doneBtn.layer.masksToBounds = true
                    doneBtn.backgroundColor = FZM_TintColor
                    doneBtn.setTitleColor(.white, for: .normal)
                    doneBtn.setTitleColor(.white, for: .disabled)
                    doneBtn.setTitle("确定(0/" + "\(self.maxImagesCount)" + ")", for: .normal)
                    doneBtn.titleLabel?.font = UIFont.boldFont(16)
                    
                    countLab.frame = CGRect(x: countLab.frame.origin.x + 11, y: countLab.frame.origin.y + 15, width: countLab.frame.width - 15, height: countLab.frame.height)
                    countLab.font = doneBtn.titleLabel?.font
                    countLab.backgroundColor = doneBtn.backgroundColor
                    popView.alpha = 0
                }
            }
        }
        
        if selectOne {
            self.allowPickingVideo = false
            self.allowPickingGif = false
            self.maxImagesCount = 1
            self.showSelectBtn = false
            self.allowCrop = allowEditing
            self.allowPreview = allowEditing
            if allowEditing {
                self.cropRect = CGRect(x: 0, y: (ScreenHeight - ScreenWidth) * 0.5, width: ScreenWidth, height: ScreenWidth)
                self.photoPreviewPageDidLayoutSubviewsBlock = {[weak self] (_,_,_,d,_,_,_,_,i,_,_) in
                    if let checkBtn = d, let okBtn = i {
                        okBtn.setTitle("确定", for: .normal)
                        okBtn.setTitleColor(.white, for: .normal)
                        okBtn.superview?.backgroundColor = .clear
                        okBtn.frame = CGRect(x: okBtn.frame.origin.x - 20, y: okBtn.frame.origin.y + 10, width: okBtn.frame.width + 20, height: okBtn.frame.height)
                        checkBtn.superview?.addSubview(okBtn)
                    }
                }
            }
        }
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    deinit {
        IMLog("FZMImagePickerController销毁")
    }
}
