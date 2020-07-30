//
//  FZMEditHeadImageVC.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/14.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import MobileCoreServices

enum FZMEditHeadImageType {
    case me
    case group(groupId:String)
}

class FZMEditHeadImageVC: FZMBaseViewController {
    
    init(with type: FZMEditHeadImageType, oldAvatar: String = "") {
        self.type = type
        self.oldAvatar = oldAvatar
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let type : FZMEditHeadImageType
    private var oldAvatar : String
    
    lazy var headImageView : UIImageView = {
        let imV = UIImageView(image: GetBundleImage("me_head_image"))
        return imV
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "头像"
        self.navBarColor = UIColor.black
        self.navTintColor = FZM_OldTintColor
        self.navTitleColor = FZM_OldTintColor
        self.view.backgroundColor = UIColor.black
        let moreItem = UIBarButtonItem(image: GetBundleImage("me_more"), style: .plain, target: self, action: #selector(moreItemClick))
        self.navigationItem.rightBarButtonItem = moreItem
        
        self.createUI()
    }
    
    @objc func moreItemClick() {
        let block : (Bool)->() = { isAlbum in
            if isAlbum {
                FZMUIMediator.shared().pushVC(.photoLibrary(selectOne: true, maxSelectCount: 1, allowEditing: true, showVideo: false, selectBlock: { (list, _) in
                    guard let image = list.first else { return }
                    self.changeImage(image)
                }))
            }else {
                FZMUIMediator.shared().pushVC(.camera(allowEditing: true, selectBlock: { (list, _) in
                    guard let image = list.first else { return }
                    self.changeImage(image)
                }))
            }
        }
        FZMBottomSelectView.show(with: [
            FZMBottomOption(title: "保存图片", block: {
                guard let img = self.headImageView.image else { return }
                UIImageWriteToSavedPhotosAlbum(img, self, #selector(FZMEditHeadImageVC.image(image:didFinishSavingWithError:contextInfo:)), nil)
            }),FZMBottomOption(title: "从相册选择", block: {
                block(true)
            }),FZMBottomOption(title: "拍照", block: {
                block(false)
            })])
    }
    
    private func createUI() {
        self.view.addSubview(headImageView)
        headImageView.snp.makeConstraints { (m) in
            m.center.equalToSuperview()
            m.size.equalTo(CGSize(width: ScreenWidth, height: ScreenWidth))
        }
        
        let tap = UILongPressGestureRecognizer()
        tap.rx.event.subscribe {[weak self] (event) in
            guard case .next(let ges) = event else { return }
            if ges.state == .began {
                self?.moreItemClick()
            }
        }.disposed(by: disposeBag)
        self.view.addGestureRecognizer(tap)
        
        self.requestImage()
    }
    
    private func requestImage() {
        switch type {
        case .me:
            guard let user = IMLoginUser.shared().currentUser else { return }
            headImageView.loadNetworkImage(with: user.avatar, placeImage: GetBundleImage("me_head_image"))
        case .group:
            headImageView.loadNetworkImage(with: oldAvatar, placeImage: GetBundleImage("chat_group_head"))
        }
    }
    
    private func changeImage(_ image : UIImage){
        self.showProgress(with: nil)
        IMOSSClient.shared().uploadImage(file: image.jpegData(compressionQuality: 0.6)!, uploadProgressBlock: { (progress) in

        }) { (url, success) in
            if success, let url = url {
                self.sendImageUrl(with: url)
            }else{
                self.hideProgress()
                self.showToast(with: "上传图片出错，请重新操作")
            }
        }
    }
    
    func sendImageUrl(with url: String) {
        switch type {
        case .me:
            HttpConnect.shared().editUserHeadImage(headImageUrl: url, completionBlock: { (response) in
                self.hideProgress()
                if response.success {
                    self.requestImage()
                }else {
                    self.showToast(with: response.message)
                }
            })
        case .group(let groupId):
            IMConversationManager.shared().editGroupAvatar(groupId: groupId, avatar: url) { (response) in
                self.hideProgress()
                if response.success {
                    self.oldAvatar = url
                    self.requestImage()
                }else {
                    self.showToast(with: response.message)
                }
            }
        }
        
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
