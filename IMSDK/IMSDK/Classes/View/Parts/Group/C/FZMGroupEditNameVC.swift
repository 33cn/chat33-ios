//
//  FZMGroupEditNameVC.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/30.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit

class FZMGroupEditNameVC: FZMBaseViewController {

    let editGroupId : String
    let oldName : String
    
    let editNickname : Bool // true:修改自己的群昵称 false:修改群名
    
    var completeBlock: NormalBlock?
    
    lazy var remarkBlockView : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        let titleLab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .left, text: editNickname ? "群昵称" : "群名")
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
            m.bottom.equalToSuperview()
            m.height.equalTo(40)
        })
        return view
    }()
    
    lazy var remarkNumLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .right, text: "0/20")
        return lab
    }()
    
    lazy var remarkInput : UITextField = {
        let input = UITextField()
        input.font = UIFont.regularFont(16)
        input.textColor = FZM_BlackWordColor
        input.tintColor = FZM_TintColor
        input.attributedPlaceholder = NSAttributedString(string: editNickname ? "请输入你在本群的昵称" : "请输入群名", attributes: [.foregroundColor:FZM_GrayWordColor])
        return input
    }()
    
    lazy var confirmBtn : UIButton = {
        let btn = UIButton.getNormalBtn(with: "确定")
        return btn
    }()
    
    init(with groupId: String, _ name: String, _ editUser: Bool = false) {
        editGroupId = groupId
        oldName = name
        editNickname = editUser
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = editNickname ? "我在本群的昵称" : "修改群名"
        self.createUI()
    }
    
    override func rt_customBackItem(withTarget target: Any!, action: Selector!) -> UIBarButtonItem! {
        return UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(popBack))
    }
    
    private func createUI() {
        self.view.addSubview(remarkBlockView)
        remarkBlockView.snp.makeConstraints { (m) in
            m.centerX.equalToSuperview()
            m.top.equalToSuperview()
            m.width.equalTo(ScreenWidth - 30.0)
            m.height.equalTo(80)
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
        remarkInput.text = oldName
        remarkNumLab.text = "\(oldName.count)/20"
        remarkInput.addToolBar(with: "确定", target: self, sel: #selector(FZMGroupEditNameVC.commitInfo))
    }
    
    @objc private func commitInfo() {
        guard let name = remarkInput.text, name.count > 0 else { return }
        self.showProgress(with: nil)
        if editNickname {
            IMConversationManager.shared().setMyGroupNickname(groupId: editGroupId, nickname: name) { (response) in
                self.hideProgress()
                guard response.success else {
                    self.showToast(with: response.message)
                    return
                }
                self.completeBlock?()
                self.popBack()
            }
        }else {
            if let gropuKey = IMLoginUser.shared().currentUser?.getLatestGroupKey(groupId: editGroupId),
            let key = gropuKey.plainTextKey,
            let plainText = name.data(using: .utf8),
            let ciphertext = FZMEncryptManager.encryptSymmetric(key: key, plaintext: plainText){
                IMConversationManager.shared().editGroupName(groupId: editGroupId, name: ciphertext.toHexString() + String.getEncryptStringPrefix() + gropuKey.keyId + String.getEncryptStringPrefix() + editGroupId) { (response) in
                    self.hideProgress()
                    guard response.success else {
                        self.showToast(with: response.message)
                        return
                    }
                    self.completeBlock?()
                    self.popBack()
                }
            }
        }
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
