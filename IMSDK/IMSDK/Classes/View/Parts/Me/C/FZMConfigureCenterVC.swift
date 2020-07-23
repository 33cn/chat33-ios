//
//  FZMConfigureCenterVC.swift
//  IMSDK
//
//  Created by 吴文拼 on 2019/1/11.
//

import UIKit

class FZMConfigureCenterVC: FZMBaseViewController {
    
    var useConfigure : IMUserConfigureModel?
    
    lazy var addFriendView : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        view.addSubview(addAuthView)
        addAuthView.snp.makeConstraints({ (m) in
            m.top.left.right.equalToSuperview()
            m.height.equalTo(50)
        })
        view.addSubview(questionAuthView)
        questionAuthView.snp.makeConstraints({ (m) in
            m.left.right.equalToSuperview()
            m.top.equalTo(addAuthView.snp.bottom)
            m.height.equalTo(50)
        })
        view.addSubview(questionBlockView)
        questionBlockView.snp.makeConstraints({ (m) in
            m.left.right.equalToSuperview()
            m.top.equalTo(questionAuthView.snp.bottom)
            m.height.equalTo(140)
        })
        
        return view
    }()
    
    lazy var inviteMeView : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        view.addSubview(inviteLineView)
        inviteLineView.snp.makeConstraints({ (m) in
            m.top.left.right.equalToSuperview()
            m.height.equalTo(50)
        })
        return view
    }()
    
    lazy var inviteLineView : UIView = {
        let view = self.getOnlineView(title: "邀请我入群需要确认", rightView: inviteLineSwitch, false, false)
        return view
    }()
    private lazy var inviteLineSwitch : UISwitch = {
        let v = UISwitch()
        v.onTintColor = FZM_TintColor
        return v
    }()
    
    lazy var protocalViwe: UIView = {
        let v = UIView.init()
        return v
    }()
    
    lazy var addAuthView : UIView = {
        let view = self.getOnlineView(title: "加我为好友时需要验证", rightView: addAuthSwitch, false, true)
        return view
    }()
    private lazy var addAuthSwitch : UISwitch = {
        let v = UISwitch()
        v.onTintColor = FZM_TintColor
        return v
    }()
    
    lazy var questionAuthView : UIView = {
        let view = self.getOnlineView(title: "加我为好友时需回答问题", rightView: questionAuthSwitch, false, false)
        return view
    }()
    private lazy var questionAuthSwitch : UISwitch = {
        let v = UISwitch()
        v.onTintColor = FZM_TintColor
        return v
    }()
    
    lazy var questionBlockView : UIView = {
        let view = UIView()
        let titleLab1 = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: "问题")
        view.addSubview(titleLab1)
        titleLab1.snp.makeConstraints({ (m) in
            m.top.equalToSuperview()
            m.left.equalToSuperview().offset(15)
            m.height.equalTo(30)
        })
        view.addSubview(questionLab)
        questionLab.snp.makeConstraints({ (m) in
            m.top.equalTo(titleLab1.snp.bottom)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(40)
        })
        let titleLab2 = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: "答案")
        view.addSubview(titleLab2)
        titleLab2.snp.makeConstraints({ (m) in
            m.top.equalTo(questionLab.snp.bottom)
            m.left.equalToSuperview().offset(15)
            m.height.equalTo(30)
        })
        view.addSubview(answerLab)
        answerLab.snp.makeConstraints({ (m) in
            m.top.equalTo(titleLab2.snp.bottom)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(40)
        })
        return view
    }()
    
    lazy var questionLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .left, text: nil)
        lab.numberOfLines = 2
        return lab
    }()
    lazy var answerLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .left, text: nil)
        lab.numberOfLines = 2
        return lab
    }()
    
    private func getOnlineView(title: String,rightView: UIView, _ showMore: Bool = true, _ showBottomLine: Bool = true) -> UIView {
        let view = UIView()
        view.clipsToBounds = true
        let titleLab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: title)
        view.addSubview(titleLab)
        titleLab.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(15)
        }
        view.addSubview(rightView)
        rightView.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.right.equalToSuperview().offset(showMore ? -24 : -15)
        }
        if showMore {
            let imV = UIImageView(image: GetBundleImage("me_more"))
            view.addSubview(imV)
            imV.snp.makeConstraints { (m) in
                m.centerY.equalToSuperview()
                m.right.equalToSuperview().offset(-15)
                m.size.equalTo(CGSize(width: 3, height: 15))
            }
        }
        if showBottomLine {
            let lineV = UIView.getNormalLineView()
            view.addSubview(lineV)
            lineV.snp.makeConstraints { (m) in
                m.bottom.left.right.equalToSuperview()
                m.height.equalTo(0.5)
            }
        }
        return view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "设置中心"
        
        self.view.addSubview(addFriendView)
        addFriendView.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(15)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(100)
        }
        
        self.view.addSubview(inviteMeView)
        inviteMeView.snp.makeConstraints { (m) in
            m.top.equalTo(addFriendView.snp.bottom).offset(15)
            m.left.right.equalTo(addFriendView)
            m.height.equalTo(50)
        }
        
        if IMSDK.shared().showWallet {
            self.view.addSubview(protocalViwe)
            protocalViwe.snp.makeConstraints { (m) in
                m.top.equalTo(inviteMeView.snp.bottom).offset(15)
                m.left.right.equalTo(addFriendView)
                m.height.equalTo(50)
            }
        }
        
        self.makeActions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.refreshView()
    }
    
    private func refreshView() {
        self.showProgress()
        HttpConnect.shared().getMyConfigure { (configure, response) in
            self.hideProgress()
            guard let configure = configure else {
                self.showToast(with: response.message)
                return
            }
            self.useConfigure = configure
            self.addAuthSwitch.isOn = configure.needConfirm
            self.questionAuthSwitch.isOn = configure.needAnswer
            self.inviteLineSwitch.isOn = configure.needConfirmInvite
            if configure.needAnswer {
                self.addFriendView.snp.updateConstraints({ (m) in
                    m.height.equalTo(240)
                })
                self.questionBlockView.isHidden = false
                self.questionLab.text = configure.question
                self.answerLab.text = configure.answer
            }else {
                self.addFriendView.snp.updateConstraints({ (m) in
                    m.height.equalTo(100)
                })
                self.questionBlockView.isHidden = true
            }
        }
    }
    
    private func goProtocal() {
        
    }
    
    private func makeActions() {
        addAuthSwitch.rx.controlEvent(.valueChanged).subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.showProgress()
            HttpConnect.shared().setNeedAuth(need: strongSelf.addAuthSwitch.isOn, completionBlock: { (response) in
                strongSelf.hideProgress()
                if !response.success {
                    strongSelf.addAuthSwitch.isOn = !strongSelf.addAuthSwitch.isOn
                    strongSelf.showToast(with: response.message)
                }
            })
        }.disposed(by: disposeBag)
        questionAuthSwitch.rx.controlEvent(.valueChanged).subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            if strongSelf.questionAuthSwitch.isOn {
                let vc = FZMSetQuestionVC(with: strongSelf.useConfigure)
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }else {
                strongSelf.showProgress()
                HttpConnect.shared().setAuthQuestion(tp: 2, question: "", answer: "", completionBlock: { (response) in
                    strongSelf.hideProgress()
                    if !response.success {
                        strongSelf.addAuthSwitch.isOn = !strongSelf.addAuthSwitch.isOn
                        strongSelf.showToast(with: response.message)
                    }
                    strongSelf.refreshView()
                })
            }
        }.disposed(by: disposeBag)
        
        inviteLineSwitch.rx.controlEvent(.valueChanged).subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.showProgress()
            HttpConnect.shared().setNeedConfirmInvite(need: strongSelf.inviteLineSwitch.isOn, completionBlock: { (response) in
                strongSelf.hideProgress()
                if !response.success {
                    strongSelf.inviteLineSwitch.isOn = !strongSelf.inviteLineSwitch.isOn
                    strongSelf.showToast(with: response.message)
                }
            })
            }.disposed(by: disposeBag)
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
