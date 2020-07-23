//
//  FZMFriendInfoVC.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/9.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import SwiftyJSON
import IDMPhotoBrowser
import YYWebImage

enum FZMApplyEntrance {
    case normal //从好友信息
    case sweep //扫二维码
    case search //搜索
    case invite(inviterId: String)
    case group(groupId: String) //群
    case share(userId: String) //分享
}

class FZMFriendInfoVC: FZMBaseViewController {

    let userId : String
    var userModel : IMUserModel?
    var groupId : String?
    
    lazy var identificationImageView: UIImageView = {
        let imgV = UIImageView(image: GetBundleImage("user_identification"))
        imgV.isUserInteractionEnabled = true
        imgV.contentMode = .scaleAspectFill
        imgV.isHidden = true
        return imgV
    }()
    
    lazy var headerImageView : UIImageView = {
        let imV = UIImageView(image: GetBundleImage("chat_normal_head"))
        imV.layer.cornerRadius = 5
        imV.clipsToBounds = true
        imV.isUserInteractionEnabled = true
        imV.contentMode = .scaleAspectFill
        imV.addSubview(identificationImageView)
        identificationImageView.snp.makeConstraints({ (m) in
            m.size.equalTo(CGSize.init(width: 15, height: 15))
            m.bottom.right.equalToSuperview()
        })
        return imV
    }()
    
    lazy var nameLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(17), textColor: FZM_BlackWordColor, textAlignment: .left, text: nil)
        lab.numberOfLines = 0
        lab.isUserInteractionEnabled = true
        return lab
    }()
    
    lazy var desLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: nil)
    }()
    
    lazy var nickNameLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: nil)
    }()
    
    private lazy var identificationInfoLab : UILabel = {
        let lab = UILabel.init()
        lab.textAlignment = .left
        lab.numberOfLines = 0
        lab.isUserInteractionEnabled = true
        return lab
    }()
    
    lazy var ctrlView : UIView = {
        let view = UIView()
        
        let bgView = UIView()
        bgView.makeOriginalShdowShow()
        view.addSubview(bgView)
        bgView.snp.makeConstraints({ (m) in
            m.height.equalTo(200)
            m.top.left.right.equalToSuperview()
        })
        
        let view0 = self.getOnlineView(title: "查找聊天记录", rightView: UIView.init(), true, true)
        let tap0 = UITapGestureRecognizer.init()
        tap0.addTarget(self, action: #selector(toSearchChatRecordVC))
        view0.addGestureRecognizer(tap0)
        bgView.addSubview(view0)
        view0.snp.makeConstraints({ (m) in
            m.height.equalTo(50)
            m.top.left.right.equalToSuperview()
        })
        let view1 = self.getOnlineView(title: "聊天文件", rightView: UIView.init(), true, true)
        let tap = UITapGestureRecognizer.init()
        tap.addTarget(self, action: #selector(toFileVC))
        view1.addGestureRecognizer(tap)
        bgView.addSubview(view1)
        view1.snp.makeConstraints({ (m) in
            m.left.right.height.equalTo(view0)
            m.top.equalTo(view0.snp.bottom)
        })
        let view2 = self.getOnlineView(title: "消息免打扰", rightView: disturbSwitch, false, true)
        bgView.addSubview(view2)
        view2.snp.makeConstraints({ (m) in
            m.left.right.height.equalTo(view1)
            m.top.equalTo(view1.snp.bottom)
        })
        let view3 = self.getOnlineView(title: "置顶聊天", rightView: stickSwitch, false, false)
        bgView.addSubview(view3)
        view3.snp.makeConstraints({ (m) in
            m.left.right.height.equalTo(view2)
            m.top.equalTo(view2.snp.bottom)
        })
        
        let view4 = self.getOnlineView(title: "来源      ", rightView: self.sourceLab, false, true)
        view4.makeOriginalShdowShow()
        view.addSubview(view4)
        view4.snp.makeConstraints({ (m) in
            m.top.equalTo(view3.snp.bottom).offset(15)
            m.height.equalTo(50)
            m.left.right.equalToSuperview()
        })
        
        return view
    }()
    
    lazy var ctrlView2 : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        
        let view4 = self.getOnlineView(title: "举报该联系人", rightView: UIView.init(), true, true)
        view.addSubview(view4)
        let feedbackTap = UITapGestureRecognizer.init()
        feedbackTap.addTarget(self, action: #selector(toFeedback))
        view4.addGestureRecognizer(feedbackTap)
        view4.snp.makeConstraints({ (m) in
            m.top.left.right.equalToSuperview()
            m.height.equalTo(50)
        })
        
        let view5 = self.blacklistView
        view.addSubview(view5)
        let blacklistTap = UITapGestureRecognizer.init()
        blacklistTap.addTarget(self, action: #selector(blacklistTapHandle))
        view5.addGestureRecognizer(blacklistTap)
        view5.snp.makeConstraints({ (m) in
            m.left.right.height.equalTo(view4)
            m.top.equalTo(view4.snp.bottom)
        })
        
        return view
    }()
    
    
    lazy var disturbSwitch : UISwitch = {
        let v = UISwitch()
        v.onTintColor = FZM_TintColor
        return v
    }()
    
    lazy var stickSwitch : UISwitch = {
        let v = UISwitch()
        v.onTintColor = FZM_TintColor
        return v
    }()
    
    lazy var blacklistView : UIView = {
        let view = UIView()
        view.addSubview(blacklistLab)
        blacklistLab.snp.makeConstraints({ (m) in
            m.top.equalToSuperview().offset(14)
            m.left.equalToSuperview().offset(15)
            m.size.equalTo(CGSize(width: 100, height: 23))
        })
        let imV = UIImageView(image: GetBundleImage("me_more"))
        view.addSubview(imV)
        imV.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.right.equalToSuperview().offset(-15)
            m.size.equalTo(CGSize(width: 3, height: 15))
        }
        view.addSubview(blacklistInfoLab)
        blacklistInfoLab.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.right.equalTo(imV.snp.left).offset(-5)
            m.height.equalTo(20)
        })
        return view
    }()
    
    lazy var blacklistLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: "")
        return lab
    }()
    
    lazy var blacklistInfoLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .right, text: nil)
        return lab
    }()
    
//    lazy var sourceView : UIView = {
//        let view = UIView()
//        view.makeOriginalShdowShow()
//        let lab1 = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: "来源")
//        view.addSubview(lab1)
//        lab1.snp.makeConstraints({ (m) in
//            m.centerY.equalToSuperview()
//            m.left.equalToSuperview().offset(15)
//            m.size.equalTo(CGSize(width: 100, height: 23))
//        })
//        view.addSubview(sourceLab)
//        sourceLab.snp.makeConstraints({ (m) in
//            m.centerY.equalToSuperview()
//            m.right.equalToSuperview().offset(-15)
//            m.width.equalTo(236)
//        })
//        return view
//    }()
    
    lazy var sourceLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .right, text: nil)
        lab.numberOfLines = 2
        return lab
    }()
    
    lazy var bannedView : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        let lab1 = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: "禁言")
        view.addSubview(lab1)
        lab1.snp.makeConstraints({ (m) in
            m.top.equalToSuperview().offset(14)
            m.left.equalToSuperview().offset(15)
            m.size.equalTo(CGSize(width: 100, height: 23))
        })
        let imV = UIImageView(image: GetBundleImage("me_more"))
        view.addSubview(imV)
        imV.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.right.equalToSuperview().offset(-15)
            m.size.equalTo(CGSize(width: 3, height: 15))
        }
        view.addSubview(bannedLab)
        bannedLab.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.right.equalTo(imV.snp.left).offset(-5)
            m.height.equalTo(20)
        })
        view.isHidden = true
        return view
    }()
    
    lazy var bannedLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .right, text: nil)
        return lab
    }()
    
    lazy var sendMsgBtn : UIButton = {
        let btn = UIButton.getNormalBtn(with: "发消息")
//        btn.addTarget(self, action: #selector(sendMsgBtnPress), for: .touchUpInside)
        return btn
    }()
    
    lazy var deleteBtn : UIButton = {
        let btn = UIButton.getNormalBtn(with: "删除好友", backgroundColor: FZM_BackgroundColor)
        return btn
    }()
    
    lazy var addBtn : UIButton = {
        let btn = UIButton.getNormalBtn(with: "添加好友")
        btn.setAttributedTitle(NSAttributedString(string: "该群禁止互加好友", attributes: [.foregroundColor: UIColor.white,.font:UIFont.regularFont(16)]), for: .disabled)
        btn.isHidden = true
        return btn
    }()
    
    private var source : FZMApplyEntrance = .normal
    
    init(with userId: String, groupId: String? = nil, source: FZMApplyEntrance? = nil) {
        self.userId = userId
        self.groupId = groupId
        if source != nil {
            self.source = source!
        }
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let scrollView = UIScrollView.init(frame: CGRect.init(x: 0, y: 0, width: ScreenWidth, height: ScreenHeight - StatusNavigationBarHeight))
    private let contentView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: ScreenWidth, height: ScreenHeight - StatusNavigationBarHeight))
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.contentSize = CGSize.init(width: ScreenWidth, height: deleteBtn.frame.origin.y + StatusNavigationBarHeight + 30)
        contentView.frame.size = scrollView.contentSize
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.refreshUserInfo()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "详细资料"
        let addBtn = UIBarButtonItem(image: GetBundleImage("friend_addGroup")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(addBtnClick))
        self.navigationItem.rightBarButtonItems = [addBtn]
        self.navigationItem.rightBarButtonItem?.tintColor = UIColor(hex: 0x8192F0)
        self.createUI()
        self.setupActions()
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .contact)
    }
    
    private func createUI() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delaysContentTouches = false
        self.view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        self.contentView.addSubview(headerImageView)
        headerImageView.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(10)
            m.left.equalToSuperview().offset(15)
            m.size.equalTo(CGSize(width: 50, height: 50))
        }
        self.contentView.addSubview(nameLab)
        nameLab.snp.makeConstraints { (m) in
            m.top.equalTo(headerImageView)
            m.left.equalTo(headerImageView.snp.right).offset(15)
            m.right.lessThanOrEqualToSuperview().offset(-20)
        }
        self.contentView.addSubview(desLab)
        desLab.snp.makeConstraints { (m) in
            m.top.equalTo(nameLab.snp.bottom).offset(5)
            m.left.equalTo(nameLab)
            m.right.equalToSuperview().offset(-20)
            m.height.equalTo(20)
        }
        self.contentView.addSubview(nickNameLab)
        nickNameLab.snp.makeConstraints { (m) in
            m.top.equalTo(desLab.snp.bottom).offset(5)
            m.left.equalTo(desLab)
            m.height.equalTo(20)
        }
        
        self.contentView.addSubview(identificationInfoLab)
        identificationInfoLab.snp.makeConstraints { (m) in
            m.top.equalTo(nickNameLab.snp.bottom).offset(5)
            m.left.equalTo(nickNameLab)
            m.right.equalToSuperview().offset(-16)
        }
        self.contentView.addSubview(ctrlView)
        ctrlView.snp.makeConstraints { (m) in
            m.top.equalTo(identificationInfoLab.snp.bottom).offset(21)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(265)
        }
        self.contentView.addSubview(bannedView)
        bannedView.snp.makeConstraints { (m) in
            m.top.equalTo(ctrlView.snp.bottom)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(0)
        }
        
        self.contentView.addSubview(ctrlView2)
        ctrlView2.snp.makeConstraints { (m) in
            m.top.equalTo(bannedView.snp.bottom).offset(15)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(100)
        }
        
        self.contentView.addSubview(sendMsgBtn)
        sendMsgBtn.snp.makeConstraints { (m) in
            m.top.equalTo(ctrlView2.snp.bottom).offset(15)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(40)
        }
        self.contentView.addSubview(deleteBtn)
        deleteBtn.snp.makeConstraints { (m) in
            m.top.equalTo(sendMsgBtn.snp.bottom).offset(15)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(40)
        }
        self.contentView.addSubview(addBtn)
        addBtn.snp.makeConstraints { (m) in
            m.top.equalTo(ctrlView2.snp.bottom).offset(15)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(40)
        }
        
    }
    
    @objc func addBtnClick() {
        let vc = FZMSelectFriendToGroupVC.init(with: .all)
        vc.defaultSelectId = self.userId
        let nav = FZMNavigationController.init(rootViewController: vc)
        vc.reloadBlock = {}
        self.navigationController?.present(nav, animated: true, completion: {
            
        })
    }

    private func setupActions() {
        let nameTap = UITapGestureRecognizer()
        nameTap.rx.event.subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.toEditUserInfo()
        }.disposed(by: disposeBag)
        nameLab.addGestureRecognizer(nameTap)
        sendMsgBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            guard let user = strongSelf.userModel else { return }
            FZMUIMediator.shared().pushVC(.goChat(chatId: user.userId, type: .person))
        }.disposed(by: disposeBag)
        
        deleteBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            guard let user = strongSelf.userModel else { return }
            let alert = FZMAlertView(deleteFriend: user.showName, confirmBlock: {
                strongSelf.showProgress(with: nil)
                IMContactManager.shared().deleteFriend(with: user.userId, completeBlock: { (response) in
                    strongSelf.hideProgress()
                    guard response.success else {
                        strongSelf.showToast(with: response.message)
                        return
                    }
                    strongSelf.navigationController?.popToRootViewController(animated: true)
                })
            })
            alert.show()
        }.disposed(by: disposeBag)
        
        addBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            self?.addFriend()
        }.disposed(by: disposeBag)
        
        disturbSwitch.rx.controlEvent(.valueChanged).subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            IMContactManager.shared().friendSetNoDisturbing(userId: strongSelf.userId, on: strongSelf.disturbSwitch.isOn, completionBlock: { (response) in
                if !response.success {
                    strongSelf.disturbSwitch.isOn = !strongSelf.disturbSwitch.isOn
                    strongSelf.showToast(with: response.message)
                }
            })
        }.disposed(by: disposeBag)
        
        stickSwitch.rx.controlEvent(.valueChanged).subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            IMContactManager.shared().friendSetOnTop(userId: strongSelf.userId, on: strongSelf.stickSwitch.isOn, completionBlock: { (response) in
                if !response.success {
                    strongSelf.stickSwitch.isOn = !strongSelf.stickSwitch.isOn
                    strongSelf.showToast(with: response.message)
                }
            })
        }.disposed(by: disposeBag)
        
        let headTap = UITapGestureRecognizer()
        headTap.rx.event.subscribe {[weak self] (_) in
            guard let strongSelf = self, let user = strongSelf.userModel else { return }
            FZMUIMediator.shared().showImage(view: strongSelf.headerImageView, url: user.avatar)
        }.disposed(by: disposeBag)
        headerImageView.addGestureRecognizer(headTap)
        
        let bannedTap = UITapGestureRecognizer()
        bannedTap.rx.event.subscribe {[weak self] (_) in
            guard let strongSelf = self, let groupId = strongSelf.groupId else { return }
            let view = FZMCtrlUserAlertView(with: strongSelf.userId, groupId: groupId)
            view.completeBlock = {
                strongSelf.refreshView()
            }
            view.show()
        }.disposed(by: disposeBag)
        bannedView.addGestureRecognizer(bannedTap)
        
    }
    
    private func refreshUserInfo() {
        self.showProgress(with: nil)
        IMContactManager.shared().requestUserDetailInfo(with: self.userId) { (userModel, success, message) in
            self.hideProgress()
            guard success else {
                self.showToast(with: message)
                return
            }
            self.userModel = userModel
            self.refreshView()
        }
    }
    var extView: UIView?
    private func refreshView() {
        DispatchQueue.main.async {
            guard let user = self.userModel else {
                return
            }
            if user.isBlocked {
                self.blacklistLab.text = "移出黑名单"
                self.blacklistInfoLab.text = "已不再接收对方消息"
            } else {
                self.blacklistLab.text = "加入黑名单"
                self.blacklistInfoLab.text = nil
            }
            self.nameLab.text = user.showName
            
            if user.remark.count > 0 {
                self.nickNameLab.text = "昵称：" + user.name
            }
            
            if let groupId = self.groupId, groupId.count > 0 {
                IMConversationManager.shared().getGroupDetailInfo(groupId: groupId) { (group,_) in
                    guard let group = group else { return }
                    if group.canAddFriend || user.isFriend {
                        self.desLab.text = "UID：" + user.showId
                    }else {
                        self.addBtn.isEnabled = false
                        self.addBtn.layer.backgroundColor = UIColor(hex: 0xC8D3DE).cgColor
                    }
                    IMContactManager.shared().getUserGroupInfo(userId: self.userId, groupId: groupId, completionBlock: { (groupInfo, _, _) in
                        guard let groupInfo = groupInfo else { return }
                        if groupInfo.groupNickname.count > 0 {
                            self.nickNameLab.text = "群昵称：" + groupInfo.groupNickname
                        }
                        if (group.isMaster || group.isManager) && groupInfo.memberLevel == .normal {
                            self.bannedView.isHidden = false
                            self.bannedView.snp.updateConstraints { (m) in
                                m.top.equalTo(self.ctrlView.snp.bottom).offset(15)
                                m.height.equalTo(50)
                            }
                        }
                        self.clearBannedInfo()
                        let (banned, distance) = IMConversationManager.shared().handleBannedInfo(user: groupInfo, group: group)
                        guard banned else { return }
                        self.showPopAnimatiom(time: distance)
                    })
                }
            }else {
                self.desLab.text = "UID：" + user.showId
            }
            if user.identification == true {
                self.identificationImageView.isHidden = false
                let att = NSMutableAttributedString.init(string: "\(IMSDK.shared().shareTitle ?? "")认证： \(user.identificationInfo)", attributes: [NSAttributedString.Key.font : UIFont.regularFont(14),NSAttributedString.Key.foregroundColor : FZM_GrayWordColor])
                self.identificationInfoLab.attributedText = att
                att.yy_lineSpacing = 4
            } else {
                self.identificationImageView.isHidden = true
                self.identificationInfoLab.isHidden = true
                self.identificationInfoLab.snp.remakeConstraints { (m) in
                    m.top.equalTo(self.nickNameLab.snp.bottom).offset(0)
                    m.left.equalTo(self.nickNameLab)
                    m.right.equalToSuperview().offset(-16)
                    m.height.equalTo(0)
                }
            }
            if self.nickNameLab.text == nil {
                self.nickNameLab.snp.updateConstraints { (m) in
                    m.top.equalTo(self.desLab.snp.bottom).offset(0)
                    m.height.equalTo(0)
                }
            }
            self.headerImageView.loadNetworkImage(with: user.avatar.getDownloadUrlString(width: 50), placeImage: GetBundleImage("chat_normal_head"))
            self.ctrlView.isHidden = !user.isFriend
            self.sendMsgBtn.isHidden = !user.isFriend
            self.deleteBtn.isHidden = !user.isFriend
            self.addBtn.isHidden = user.isFriend

            if user.isFriend {
                let attStr = NSMutableAttributedString(string: user.showName)
                attStr.append(NSAttributedString(string: " \(FZMIconFont.editPencil.rawValue)", attributes: [.foregroundColor: FZM_GrayWordColor, .font: UIFont.iconfont(ofSize: 12)]))
                self.nameLab.attributedText = attStr
            }
            
            self.extView?.removeFromSuperview()
            let eView = self.getExtView(with: user)
            self.contentView.addSubview(eView)
            self.extView = eView
            
            eView.snp.makeConstraints { (m) in
                m.top.equalTo(self.nickNameLab.snp.bottom).offset(21)
                m.left.equalToSuperview().offset(15)
                m.right.equalToSuperview().offset(-15)
            }
            self.ctrlView.snp.remakeConstraints { (m) in
                if user.extRemark.des.isEmpty && user.extRemark.pictureUrls.isEmpty && user.extRemark.telephones.isEmpty {
                    m.top.equalTo(self.identificationInfoLab.snp.bottom).offset(21)
                } else {
                    m.top.equalTo(eView.snp.bottom).offset(15)
                }
                m.left.equalToSuperview().offset(15)
                m.right.equalToSuperview().offset(-15)
                m.height.equalTo(user.isFriend ? 265 : 0)
            }
            if !user.isFriend  {
                self.ctrlView2.isHidden = !user.isBlocked
                self.ctrlView2.snp.remakeConstraints { (m) in
                    m.top.equalTo(self.bannedView.snp.bottom).offset(user.isBlocked ? 15 : 0)
                    m.left.equalToSuperview().offset(15)
                    m.right.equalToSuperview().offset(-15)
                    m.height.equalTo(user.isBlocked ? 100 : 0)
                }
            }
            self.navigationItem.rightBarButtonItem?.isEnabled = user.isFriend
            self.navigationItem.rightBarButtonItem?.image = user.isFriend ? GetBundleImage("friend_addGroup") : nil
            self.sourceLab.text = user.source
            self.stickSwitch.isOn = user.onTop
            self.disturbSwitch.isOn = user.noDisturbing == .open
            if user.userId == IMLoginUser.shared().userId {
                self.addBtn.isHidden = true
            }
        }
    }
    
    private func showPopAnimatiom(time: Double) {
        if time < OnedaySeconds {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            FZMAnimationTool.countdown(with: bannedLab, fromValue: time, toValue: 0, block: { [weak self] (useTime) in
                let time = useTime - 8 * 3600
                let date = Date.init(timeIntervalSince1970: TimeInterval(time))
                self?.bannedLab.text = "禁言 " + formatter.string(from: date)
            },finishBlock: {[weak self] in
                self?.clearBannedInfo()
            })
        }else{
            self.bannedLab.text = "永远禁言"
        }
    }
    
    private func clearBannedInfo() {
        FZMAnimationTool.removeCountdown(with: bannedLab)
        self.bannedLab.text = "        "
    }
    
    
    private func addFriend() {
        guard let user = self.userModel else { return }
        IMContactManager.shared().addFriend(user: user)
        self.showToast(with: "添加成功")
        self.addBtn.isHidden = true
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

extension FZMFriendInfoVC: ContactInfoChangeDelegate {
    func contactUserInfoChange(with userId: String) {
//        self.refreshView()
    }
    
    @objc func toSearchChatRecordVC() {
        let vc = FZMFullTextSearchVC.init(searchType: .chatRecord(specificId: self.userId), limitCount: NSInteger.max, isHideHistory: true)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func toFileVC() {
        let vc = FZMFileViewController.init(conversationType: .person, conversationID: self.userId )
        vc.title = "聊天文件"
        vc.senderNameCanTouch = false
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func toFeedback() {
        let vc = FZMWebViewController.init()
        vc.url = FeedbackUrl
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func toEditUserInfo() {
        guard let user = self.userModel, user.isFriend else { return }
        let vc = FZMUserEditNameVC(with: self.userId)
        vc.userModel = user
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func toCall(gesture: UITapGestureRecognizer) {
        if let text = (gesture.view as? UILabel)?.text,let url = URL.init(string: "tel:" + text) {
            UIApplication.shared.openURL(url)
        }
    }
    @objc private func blacklistTapHandle() {
           guard let user = self.userModel else { return }
           if user.isBlocked {
            IMContactManager.shared().deleteBlockList(address: [user.showId]) { (response) in
                guard response.success else {
                    self.showToast(with: response.message)
                    return
                }
                IMContactManager.shared().blockList.remove(at: user.showId)
                self.refreshUserInfo()
            }
           } else {
               let str = "加入黑名单后，你将不再接收到对方的消息，确定将 \(user.showName) 移至黑名单吗?"
               let attStr = NSMutableAttributedString.init(string: str, attributes: [NSAttributedString.Key.foregroundColor: FZM_BlackWordColor, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)])
               attStr.addAttributes([NSAttributedString.Key.foregroundColor: FZM_TintColor], range:(str as NSString).range(of: user.showName))
            let alert = FZMAlertView.init(with: attStr) {
                IMContactManager.shared().addBlockList(address: [user.showId]) { (response) in
                    guard response.success else {
                        self.showToast(with: response.message)
                        return
                    }
                    IMConversationManager.shared().deleteConversation(with: user.userId, type: .person)
                    self.refreshUserInfo()
                }
            }
               alert.show()
           }
       }
}


extension FZMFriendInfoVC {
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
            m.left.equalTo(titleLab.snp.right).offset(10)
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
    
    func getPhoneCellView(title1: String?,image: UIImage?,title2: String,title3: String, showMore: Bool = true, showBottomLine: Bool = true) -> UIView {
        let view = UIView()
        view.clipsToBounds = true
        
        if let title1 = title1 {
            let titleLab1 = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .left, text: title1)
            view.addSubview(titleLab1)
            titleLab1.snp.makeConstraints { (m) in
                m.centerY.equalToSuperview()
                m.left.equalToSuperview().offset(15)
            }
        }
        
        let imageView = UIImageView.init(image: image)
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        imageView.snp.makeConstraints { (m) in
            m.size.equalTo(CGSize.init(width: 20, height: 20))
            m.left.equalToSuperview().offset(65)
            m.centerY.equalToSuperview()
        }
        
        let titleLab2 = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: title2)
        titleLab2.isUserInteractionEnabled = true
        view.addSubview(titleLab2)
        titleLab2.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.left.equalTo(imageView.snp.right).offset(5)
        }
        let tap = UITapGestureRecognizer.init()
        tap.addTarget(self, action: #selector(toCall(gesture:)))
        titleLab2.addGestureRecognizer(tap)
        
        let titleLab3 = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .left, text: title3)
        view.addSubview(titleLab3)
        titleLab3.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.right.equalToSuperview().offset(showMore ? -24 : -15)
        }
        
        if showMore {
            let imV = UIImageView(image: GetBundleImage("me_more"))
            imV.isUserInteractionEnabled = true
            imV.enlargeClickEdge(10, 20, 10, 10)
            view.addSubview(imV)
            imV.snp.makeConstraints { (m) in
                m.centerY.equalToSuperview()
                m.right.equalToSuperview().offset(-15)
                m.size.equalTo(CGSize(width: 3, height: 15))
            }
            let tap = UITapGestureRecognizer.init()
            tap.addTarget(self, action: #selector(toEditUserInfo))
            view.addGestureRecognizer(tap)
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
    
    func getDesCellView(title: String,infor: String?, showMore: Bool = true, showBottomLine: Bool = true) -> UIView {
        let view = UIView()
        view.clipsToBounds = true
        let titleLab1 = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .left, text: title)
        view.addSubview(titleLab1)
        titleLab1.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(15)
        }
        
        if let infor = infor {
            let inforLab2 = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: infor)
            inforLab2.numberOfLines = 0
            view.addSubview(inforLab2)
            inforLab2.snp.makeConstraints { (m) in
                m.top.equalToSuperview().offset(10)
                m.bottom.equalToSuperview().offset(-10)
                m.left.equalTo(titleLab1.snp.right).offset(18)
                m.right.equalToSuperview().offset(showMore ? -19 : 0)
            }
        }
        
        if showMore {
            let imV = UIImageView(image: GetBundleImage("me_more"))
            view.addSubview(imV)
            imV.isUserInteractionEnabled = true
            imV.enlargeClickEdge(10, 20, 10, 10)
            imV.snp.makeConstraints { (m) in
                m.centerY.equalToSuperview()
                m.right.equalToSuperview().offset(-15)
                m.size.equalTo(CGSize(width: 3, height: 15))
            }
            let tap = UITapGestureRecognizer.init()
            tap.addTarget(self, action: #selector(toEditUserInfo))
            view.addGestureRecognizer(tap)
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
    
    func getExtView(with user: IMUserModel) -> UIView {
        let view = UIView.init()
        view.makeOriginalShdowShow()
        let des = user.extRemark.des
        let pictureUrls = user.extRemark.pictureUrls
        let telephones = user.extRemark.telephones
        
        let phoneView = UIView.init()
        view.addSubview(phoneView)
        phoneView.snp.makeConstraints { (m) in
            m.top.left.right.equalToSuperview()
        }
        for i in 0..<telephones.count {
            var cell: UIView
            if i == 0 {
                cell = self.getPhoneCellView(title1: "电话", image: GetBundleImage("user_phone"), title2: telephones[i]["phone"] ?? "", title3: telephones[i]["remark"] ?? "手机", showMore: true, showBottomLine: true)
                
            } else {
                cell = self.getPhoneCellView(title1: nil, image: GetBundleImage("user_phone"), title2: telephones[i]["phone"] ?? "", title3: telephones[i]["remark"] ?? "手机", showMore: true, showBottomLine: true)
            }
            phoneView.addSubview(cell)
            cell.snp.makeConstraints { (m) in
                m.height.equalTo(50)
                m.left.right.equalToSuperview()
                m.top.equalToSuperview().offset(50 * i)
                if i == telephones.count - 1 {
                    m.bottom.equalToSuperview()
                }
            }
        }
        
        let desView = UIView.init()
        view.addSubview(desView)
        desView.snp.makeConstraints { (m) in
            m.top.equalTo(phoneView.snp.bottom)
            m.left.right.equalTo(phoneView)
        }
        if !des.isEmpty {
            let desLab = self.getDesCellView(title: "描述", infor: des, showMore: true, showBottomLine: true)
            desView.addSubview(desLab)
            desLab.snp.makeConstraints { (m) in
                m.top.bottom.left.right.equalToSuperview()
                m.height.equalTo(des.count < 18 ? 50 : 70)
            }
        }
        
        let picView = UIView.init()
        view.addSubview(picView)
        picView.snp.makeConstraints { (m) in
            m.top.equalTo(desView.snp.bottom)
            m.left.right.bottom.equalToSuperview()
        }
        if !pictureUrls.isEmpty {
            let picLab = self.getDesCellView(title: "图片", infor: nil, showMore: true, showBottomLine: false)
            picView.addSubview(picLab)
            picLab.snp.makeConstraints { (m) in
                m.top.bottom.left.right.equalToSuperview()
                m.height.equalTo(70)
            }
            for i in 0..<pictureUrls.count {
                let imageView = UIImageView.init()
                imageView.contentMode = .scaleAspectFill
                imageView.layer.cornerRadius = 5
                imageView.layer.masksToBounds = true
                imageView.layer.borderWidth = 0.5
                imageView.layer.borderColor = FZM_GrayWordColor.cgColor
                let urlStr = pictureUrls[i]
                if urlStr.isEncryptMedia() {
                    if let image = YYImageCache.shared().getImageForKey(urlStr) {
                        imageView.image = image
                    }else if let url = URL.init(string: urlStr) {
                        IMOSSClient.shared().download(with: url, downloadProgressBlock: nil) { (imageData, result) in
                            if result, let imageData = imageData,
                                let privateKey = IMLoginUser.shared().currentUser?.privateKey,
                                let publicKey = IMLoginUser.shared().currentUser?.publicKey,
                                let plaintextImageData = FZMEncryptManager.decryptSymmetric(privateKey: privateKey, publicKey: publicKey, ciphertext: imageData),
                                let image = UIImage(data: plaintextImageData) {
                                YYImageCache.shared().setImage(image, forKey: urlStr)
                                imageView.image = image
                            }
                        }
                    }
                } else {
                    imageView.sd_setImage(with: URL.init(string: urlStr))
                }
                picLab.addSubview(imageView)
                imageView.snp.makeConstraints { (m) in
                    m.centerY.equalToSuperview()
                    m.width.height.equalTo(50)
                    m.left.equalToSuperview().offset(65 + i * (50 + 10) )
                }
                imageView.isUserInteractionEnabled = true
                
                let tap = UITapGestureRecognizer.init()
                tap.rx.event.subscribe {(_) in
                    var photos = [Any]()
                    for urlString in pictureUrls {
                        if urlString.isEncryptMedia() {
                            if let image = YYImageCache.shared().getImageForKey(urlString),
                                let photo = IDMPhoto.init(image: image) {
                                photos.append(photo)
                            }
                        } else if let url = URL.init(string: urlString),
                            let photo = IDMPhoto.init(url: url) {
                            photos.append(photo)
                        }
                    }
                    if !photos.isEmpty,
                        let vc = FZMPhotoBrowser.init(photos: photos, animatedFrom: imageView) {
                        if i < photos.count {
                            vc.setInitialPageIndex(UInt(i))
                        }
                        UIViewController.current()?.present(vc, animated: true, completion: nil)
                    }
                }.disposed(by: disposeBag)
                imageView.addGestureRecognizer(tap)
            }
        }
        return view
    }
}
