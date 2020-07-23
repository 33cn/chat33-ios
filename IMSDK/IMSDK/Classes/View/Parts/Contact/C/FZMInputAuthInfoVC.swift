//
//  FZMInputAuthInfoVC.swift
//  AFNetworking
//
//  Created by 吴文拼 on 2019/1/12.
//

import UIKit

enum FZMInputAuthInfoVCType {
    case user(userId: String, answer: String?, source: [String : Any])
    case group(groupId: String, source: [String : Any])
}

class FZMInputAuthInfoVC: FZMBaseViewController {
    
    let type : FZMInputAuthInfoVCType
    
    let block : NormalBlock?
    
    init(with type: FZMInputAuthInfoVCType, completeBlock: NormalBlock?) {
        self.type = type
        self.block = completeBlock
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var inputBlockView : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        let titleLab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: "验证申请")
        view.addSubview(titleLab)
        titleLab.snp.makeConstraints({ (m) in
            m.top.equalToSuperview()
            m.left.equalToSuperview().offset(14)
            m.height.equalTo(30)
        })
        view.addSubview(answerNumLab)
        answerNumLab.snp.makeConstraints({ (m) in
            m.top.equalToSuperview()
            m.right.equalToSuperview().offset(-16)
            m.height.equalTo(30)
        })
        view.addSubview(answerInput)
        answerInput.snp.makeConstraints({ (m) in
            m.left.equalTo(titleLab).offset(-4)
            m.right.equalToSuperview().offset(-14)
            m.bottom.equalToSuperview().offset(-15)
            m.height.equalTo(65)
        })
        return view
    }()
    
    lazy var answerNumLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .right, text: "0/50")
        return lab
    }()
    lazy var answerInput : UITextView = {
        let input = UITextView()
        input.font = UIFont.regularFont(16)
        input.textColor = FZM_BlackWordColor
        input.tintColor = FZM_TintColor
        input.backgroundColor = UIColor.clear
        input.addSubview(answerPlaceLab)
        answerPlaceLab.snp.makeConstraints({ (m) in
            m.left.top.equalToSuperview().offset(4)
            m.size.equalTo(CGSize(width: 150, height: 23))
        })
        return input
    }()
    lazy var answerPlaceLab : UILabel = {
        let name = "我是 \(IMLoginUser.shared().currentUser!.userName)"
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .left, text: name)
        return lab
    }()
    
    lazy var confirmBtn : UIButton = {
        let btn = UIButton.getNormalBtn(with: "确定")
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        switch type {
        case .user:
            self.navigationItem.title = "好友验证"
        case .group:
            self.navigationItem.title = "入群验证"
        }
        self.createUI()
    }
    override func rt_customBackItem(withTarget target: Any!, action: Selector!) -> UIBarButtonItem! {
        return UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(popBack))
    }
    
    private func createUI() {
        let titleLab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: "你需要发送验证申请，等待对方通过")
        self.view.addSubview(titleLab)
        titleLab.snp.makeConstraints { (m) in
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.top.equalToSuperview()
            m.height.equalTo(50)
        }
        self.view.addSubview(inputBlockView)
        inputBlockView.snp.makeConstraints { (m) in
            m.top.equalTo(titleLab.snp.bottom)
            m.left.right.equalTo(titleLab)
            m.height.equalTo(125)
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
        
        answerInput.addToolBar(with: "确定", target: self, sel: #selector(FZMInputAuthInfoVC.commitInfo))
        
        answerInput.rx.text.subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.answerInput.limitText(with: 50)
            if let text = strongSelf.answerInput.text, text.count > 0 {
                strongSelf.answerNumLab.text = "\(text.count)/50"
                strongSelf.answerPlaceLab.isHidden = true
            }else {
                strongSelf.answerNumLab.text = "0/50"
                strongSelf.answerPlaceLab.isHidden = false
            }
        }.disposed(by: disposeBag)
        confirmBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            self?.commitInfo()
        }.disposed(by: disposeBag)
    }
    
    @objc private func commitInfo() {
        switch type {
        case .user(let userId, let answer, let source):
            self.showProgress(with: "正在申请")
            HttpConnect.shared().addFriendApply(userId: userId, remark: "", reason: answerInput.text, source: source, answer: answer, completionBlock: { (response) in
                self.hideProgress()
                guard response.success else {
                    self.showToast(with: response.message)
                    return
                }
                self.popBack()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                    self.block?()
                })
            })
        case .group(let groupId, let source):
            self.showProgress(with: "正在申请")
            IMConversationManager.shared().applyJoinGroup(groupId: groupId, reason: answerInput.text, source: source) { (response) in
                self.hideProgress()
                guard response.success else {
                    self.showToast(with: response.message)
                    return
                }
                self.popBack()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                    self.block?()
                })
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
