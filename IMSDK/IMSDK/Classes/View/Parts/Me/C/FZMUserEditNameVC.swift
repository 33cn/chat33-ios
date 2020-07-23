//
//  FZMUserEditNameVC.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/15.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit

class FZMUserEditNameVC: FZMBaseViewController {
    
    let editUserId : String
    var userModel : IMUserModel?
    
    
    lazy var remarkBlockView : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        let titleLab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: "备注名")
        view.addSubview(titleLab)
        titleLab.snp.makeConstraints({ (m) in
            m.left.equalToSuperview().offset(15)
            m.top.equalToSuperview().offset(7)
            m.height.equalTo(23)
        })
        view.addSubview(remarkNumLab)
        remarkNumLab.snp.makeConstraints({ (m) in
            m.top.equalToSuperview().offset(7)
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(17)
        })
        view.addSubview(remarkInput)
        remarkInput.snp.makeConstraints({ (m) in
            m.left.equalTo(titleLab)
            m.right.equalToSuperview()
            m.height.equalTo(40)
            m.centerY.equalToSuperview()
        })
        return view
    }()
    
    lazy var remarkNumLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .right, text: "0/20")
        return lab
    }()
    
    lazy var remarkInput : UITextField = {
        let input = UITextField()
        input.font = UIFont.regularFont(16)
        input.textColor = FZM_BlackWordColor
        input.tintColor = FZM_TintColor
        input.attributedPlaceholder = NSAttributedString(string: "请输入备注名", attributes: [.foregroundColor:FZM_GrayWordColor])
        return input
    }()
    
    
    lazy var desBlockView : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        let titleLab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: "描述")
        view.addSubview(titleLab)
        titleLab.snp.makeConstraints({ (m) in
            m.left.equalToSuperview().offset(14)
            m.top.equalToSuperview()
            m.height.equalTo(30)
        })
        view.addSubview(desNumLab)
        desNumLab.snp.makeConstraints({ (m) in
            m.top.equalTo(titleLab)
            m.height.equalTo(titleLab)
            m.right.equalToSuperview().offset(-16)
        })
        view.addSubview(desInput)
        desInput.snp.makeConstraints({ (m) in
            m.left.equalTo(titleLab)
            m.right.equalToSuperview().offset(-14)
            m.top.equalTo(desNumLab.snp.bottom).offset(9)
            m.bottom.equalToSuperview().offset(-16)
        })
        return view
    }()
    
    lazy var desNumLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .right, text: "0/400")
        return lab
    }()
    
    lazy var desInput : UITextView = {
        let input = UITextView()
        input.font = UIFont.regularFont(16)
        input.textColor = FZM_BlackWordColor
        input.tintColor = FZM_TintColor
        input.backgroundColor = UIColor.clear
        input.addSubview(desPlaceLab)
        input.isScrollEnabled = false
        input.textContainerInset = .zero
        input.textContainer.lineFragmentPadding = 0
        desPlaceLab.snp.makeConstraints({ (m) in
            m.left.equalToSuperview().offset(4)
            m.centerY.equalToSuperview()
            m.size.equalTo(CGSize(width: 150, height: 23))
        })
        return input
    }()
    
    lazy var desPlaceLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .left, text: "添加更多备注信息")
        return lab
    }()
    
    lazy var confirmBtn : UIButton = {
        let btn = UIButton.getNormalBtn(with: "确定")
        btn.layer.cornerRadius = 20
        return btn
    }()
    
    private let scrollView = UIScrollView.init()
    lazy private var phoneView = FZMUserEditPhoneView.init()
    lazy private var photoView = FZMUserEditPhotoView.init()
    
    init(with userId: String) {
        editUserId = userId
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "备注信息"
        self.createUI()
        self.setValues()
    }
    override func rt_customBackItem(withTarget target: Any!, action: Selector!) -> UIBarButtonItem! {
        return UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(popBack))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.contentSize = CGSize.init(width: 0, height: remarkBlockView.size.height + phoneView.size.height + desBlockView.size.height + photoView.size.height + 70 + 60)
    }
    private let imageDownloadTool = UIImageView.init()
    private func setValues() {
        if let userModel = userModel {
            if !userModel.extRemark.des.isEmpty {
                desInput.text = userModel.extRemark.des
                self.view.layoutIfNeeded()
                desPlaceLab.isHidden = true
                desNumLab.text = "\(userModel.extRemark.des.count)/400"
            }
            let size = desInput.sizeThatFits(CGSize.init(width: desInput.size.width, height: CGFloat(MAXFLOAT)))
            desBlockView.snp.makeConstraints { (m) in
                 m.height.equalTo(size.height + 30 + 16 + 9)
            }
            if !userModel.extRemark.telephones.isEmpty {
                phoneView.rowArrUseOutside = userModel.extRemark.telephones.compactMap({ (phone) -> FZMUserEditPhoneRowView in
                    let row = FZMUserEditPhoneRowView.init()
                    row.leftValue = phone["remark"] ?? ""
                    row.rigthValue = phone["phone"] ?? ""
                    return row
                })
            }
            if !userModel.extRemark.pictureUrls.isEmpty {
                self.photoView.photos = userModel.extRemark.pictureUrls
            }
        }
    }
    
    private func createUI() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .onDrag
        self.view.addSubview(scrollView)
        scrollView.snp.makeConstraints { (m) in
            m.top.left.right.equalToSuperview()
            m.bottom.equalTo(self.safeArea).offset(-70)
        }
        
       scrollView.addSubview(remarkBlockView)
        remarkBlockView.snp.makeConstraints { (m) in
            m.centerX.equalToSuperview()
            m.top.equalToSuperview().offset(10)
            m.width.equalTo(ScreenWidth - 30.0)
            m.height.equalTo(110)
        }
        
        scrollView.addSubview(phoneView)
        phoneView.snp.makeConstraints { (m) in
            m.centerX.equalToSuperview()
            m.top.equalTo(remarkBlockView.snp.bottom).offset(15)
            m.width.equalTo(remarkBlockView)
        }
        
        
        scrollView.addSubview(desBlockView)
        desBlockView.snp.makeConstraints { (m) in
            m.top.equalTo(phoneView.snp.bottom).offset(15)
            m.left.right.equalTo(remarkBlockView)
        }
        
        scrollView.addSubview(photoView)
        photoView.makeOriginalShdowShow()
        photoView.snp.makeConstraints { (m) in
            m.top.equalTo(desBlockView.snp.bottom).offset(15)
            m.centerX.equalToSuperview()
            m.width.equalTo(desBlockView)
            m.bottom.equalToSuperview()
        }
        
        
        let view = UIView()
        view.makeOriginalShdowShow()
        self.view.addSubview(view)
        view.snp.makeConstraints { (m) in
            m.bottom.left.right.equalTo(self.safeArea)
            m.height.equalTo(70)
        }
        view.addSubview(confirmBtn)
        confirmBtn.snp.makeConstraints { (m) in
            m.center.equalToSuperview()
            m.size.equalTo(CGSize(width: ScreenWidth - 30 , height: 40))
        }
        
        confirmBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            self?.commitInfo()
        }.disposed(by: disposeBag)
        
        remarkInput.rx.text.subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.remarkInput.limitText(with: 20)
            if let text = strongSelf.remarkInput.text, text.count > 0 {
                strongSelf.remarkNumLab.text = "\(text.count)/20"
            }else {
                strongSelf.remarkNumLab.text = "0/20"
            }
        }.disposed(by: disposeBag)
        
        desInput.rx.didChange.subscribe(onNext:{[weak self] in
            guard let strongSelf = self else{ return }
            let size = strongSelf.desInput.sizeThatFits(CGSize.init(width: strongSelf.desInput.size.width, height: CGFloat(MAXFLOAT)))
            strongSelf.desBlockView.snp.updateConstraints({ (m) in
                m.height.equalTo(size.height + 30 + 16 + 9)
            })
            strongSelf.desInput.limitText(with: 400)
            if let text = strongSelf.desInput.text, text.count > 0 {
                strongSelf.desNumLab.text = "\(text.count)/400"
                strongSelf.desPlaceLab.isHidden = true
            }else {
                strongSelf.desNumLab.text = "0/400"
                strongSelf.desPlaceLab.isHidden = false
            }
        }).disposed(by: disposeBag)
        
        remarkInput.addToolBar(with: "确定", target: self, sel: #selector(FZMUserEditNameVC.commitInfo))
        desInput.addToolBar(with: "确定", target: self, sel: #selector(FZMUserEditNameVC.commitInfo))
        phoneView.addToolBar(with: "确定", target: self, sel: #selector(FZMUserEditNameVC.commitInfo))
        
        IMContactManager.shared().requestUserModel(with: editUserId) { (user, _, _) in
            if let user = user {
                self.remarkInput.text = user.showName
                self.remarkNumLab.text = "\(user.showName.count)/20"
            }
        }
        
        let endTap = UITapGestureRecognizer.init()
        endTap.rx.event.subscribe {[weak self](_) in
            self?.view.endEditing(true)
            }.disposed(by: disposeBag)
        scrollView.addGestureRecognizer(endTap)
        
    }
    
    @objc private func commitInfo() {
        guard let name = remarkInput.text else { return }
        self.showProgress(with: nil)
        var tels = [[String:String]]()
        for phoneRow in self.phoneView.phoneRowArr {
            let remark = phoneRow.leftValue
            let phone = phoneRow.rigthValue
            if !phone.isEmpty {
                let tel = ["remark":remark,"phone":phone]
                tels.append(tel)
            }
        }
        let des = desInput.text ?? ""
        var photosData = [Data]()
        var photosUrlArray = [String]()
        for item in self.photoView.photos {
            if let url = item as? String {
                photosUrlArray.append(url)
            } else if let image = item as? UIImage, let data = image.jpegData(compressionQuality: 0.6) {
                photosData.append(data)
            }
        }
        let uploadGroup = DispatchGroup.init()
        for data in photosData {
            uploadGroup.enter()
            var data = data
            var uploadPath = IMOSSClient.shared().getUploadPath(uploadType: .image, ofType: "jpg", isEncryptFile: false)
            if let privateKey = IMLoginUser.shared().currentUser?.privateKey,
                let publicKey = IMLoginUser.shared().currentUser?.publicKey,
                let ciphertext = FZMEncryptManager.encryptSymmetric(privateKey: privateKey, publicKey: publicKey, plaintext: data) {
                data = ciphertext
                uploadPath = IMOSSClient.shared().getUploadPath(uploadType: .image, ofType: "jpg", isEncryptFile: true)
            }
            IMOSSClient.shared().uploadImage(file: data, toServerPath: uploadPath, uploadProgressBlock: nil) { (url, success) in
                if success, let url = url {
                    photosUrlArray.append(url)
                }
                uploadGroup.leave()
            }
        }
        uploadGroup.notify(queue: DispatchQueue.main) {
            let dic = ["telephones": tels, "description": des, "pictures": photosUrlArray] as [String : Any]
            if let privateKey = IMLoginUser.shared().currentUser?.privateKey,
                let publicKey = IMLoginUser.shared().currentUser?.publicKey,
                let plainTextExt = try? JSONSerialization.data(withJSONObject: dic, options: []),
                let ciphertextExt = FZMEncryptManager.encryptSymmetric(privateKey: privateKey, publicKey: publicKey, plaintext: plainTextExt)?.toHexString(),
                let plainTextName = name.data(using: .utf8),
                let ciphertextName = FZMEncryptManager.encryptSymmetric(privateKey: privateKey, publicKey: publicKey, plaintext: plainTextName)?.toHexString() {
                IMContactManager.shared().editFriendEncryptExtRemark(with: self.editUserId, encryptRemark: ciphertextName, encryptExt: ciphertextExt) { (response) in
                     self.hideProgress()
                    if response.success {
                        IMContactManager.shared().getContact(userId: self.editUserId)?.name = name
                        self.popBack()
                    }else {
                        self.showToast(with: response.message)
                    }
                }
            }
//            IMContactManager.shared().editFriendExtRemark(with: self.editUserId, remark: name, tels: tels, des: des, pics: photosUrlArray, completionBlock: { (response) in
//                 self.hideProgress()
//                if response.success {
//                    self.popBack()
//                }else {
//                    self.showToast(with: response.message)
//                }
//            })
        }
    }

}







