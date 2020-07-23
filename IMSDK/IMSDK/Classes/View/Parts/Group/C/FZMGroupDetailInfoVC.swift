//
//  FZMGroupDetailInfoVC.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/29.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit

class FZMGroupDetailInfoVC: FZMBaseViewController {
    
    private let groupId : String
    
    private var groupDetailInfo : IMGroupDetailInfoModel?{
        didSet{
            self.refreshView()
        }
    }
    
    private lazy var scrollView : UIScrollView = {
        let view = UIScrollView(frame: CGRect.zero)
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.contentSize = CGSize(width: ScreenWidth, height: ScreenHeight)
        view.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 40, right: 0)
        view.addSubview(contentView)
        contentView.frame = CGRect(x: 0, y: 0, width: ScreenWidth, height: ScreenHeight)
        return view
    }()
    
    private lazy var contentView : UIView = {
        let view = UIView()
        view.addSubview(headerImageView)
        headerImageView.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(10)
            m.left.equalToSuperview().offset(15)
            m.size.equalTo(CGSize(width: 50, height: 50))
        }
        view.addSubview(nameLab)
        nameLab.snp.makeConstraints { (m) in
            m.top.equalTo(headerImageView)
            m.left.equalTo(headerImageView.snp.right).offset(15)
            m.right.lessThanOrEqualToSuperview().offset(-20)
        }
        view.addSubview(desLab)
        desLab.snp.makeConstraints { (m) in
            m.top.equalTo(nameLab.snp.bottom).offset(5)
            m.left.equalTo(nameLab)
        }
        
        view.addSubview(identificationInfoLab)
        identificationInfoLab.snp.makeConstraints { (m) in
            m.top.equalTo(desLab.snp.bottom).offset(5)
            m.left.equalTo(nameLab)
            m.right.equalToSuperview().offset(-16)
        }
        
        
        view.addSubview(memberBlockView)
        memberBlockView.snp.makeConstraints({ (m) in
            m.top.equalTo(identificationInfoLab.snp.bottom).offset(20)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(210)
        })
        
        view.addSubview(infoBlockView)
        infoBlockView.snp.makeConstraints({ (m) in
            m.top.equalTo(memberBlockView.snp.bottom).offset(15)
            m.left.right.equalTo(memberBlockView)
            m.height.equalTo(100)
        })
        
        view.addSubview(ctrlBlockView)
        ctrlBlockView.snp.makeConstraints({ (m) in
            m.top.equalTo(infoBlockView.snp.bottom).offset(15)
            m.left.right.equalTo(memberBlockView)
            m.height.equalTo(250)
        })
        
        view.addSubview(configureView)
        configureView.snp.makeConstraints({ (m) in
            m.top.equalTo(ctrlBlockView.snp.bottom).offset(15)
            m.left.right.equalTo(memberBlockView)
            m.height.equalTo(200)
        })
        
        view.addSubview(bottomBtn)
        bottomBtn.snp.makeConstraints({ (m) in
            m.top.equalTo(configureView.snp.bottom).offset(15)
            m.left.right.equalTo(memberBlockView)
            m.height.equalTo(40)
        })
        return view
    }()
    
    lazy var identificationImageView: UIImageView = {
        let imgV = UIImageView(image: GetBundleImage("group_identification"))
        imgV.isUserInteractionEnabled = true
        imgV.contentMode = .scaleAspectFill
        imgV.isHidden = true
        return imgV
    }()
    
    private lazy var headerImageView : UIImageView = {
        let imV = UIImageView(image: GetBundleImage("chat_group_head"))
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
    
    private lazy var nameLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(17), textColor: FZM_BlackWordColor, textAlignment: .left, text: nil)
        lab.numberOfLines = 0
        lab.isUserInteractionEnabled = true
        return lab
    }()
    
    private lazy var desLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: nil)
    }()
    
    private lazy var identificationInfoLab : UILabel = {
        let lab = UILabel.init()
        lab.textAlignment = .left
        lab.numberOfLines = 0
        lab.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer.init()
        lab.addGestureRecognizer(tap)
        tap.rx.event.subscribe { (_) in
            FZMUIMediator.shared().pushVC(.goIdentification(type: 2, roomId: self.groupId))
            }.disposed(by: disposeBag)
        return lab
    }()
    
    private lazy var memberBlockView : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        let titleView = self.getOnlineView(title: "群成员", rightView: memberNumberLab, true, false)
        view.addSubview(titleView)
        titleView.snp.makeConstraints({ (m) in
            m.top.left.right.equalToSuperview()
            m.height.equalTo(50)
        })
        view.addSubview(memberView)
        memberView.snp.makeConstraints({ (m) in
            m.top.equalTo(titleView.snp.bottom).offset(10)
            m.left.right.equalToSuperview()
            m.bottom.equalToSuperview().offset(-17)
        })
        return view
    }()
    private lazy var memberNumberLab : UILabel = {
        return self.getNormalLab()
    }()
    private lazy var memberView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets.init(top: 0, left: 15, bottom: 0, right: 15)
        layout.minimumLineSpacing = 15
        layout.minimumInteritemSpacing = (ScreenWidth - 300) / 4
        layout.itemSize = CGSize(width: 48, height: 64)
        let view = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        view.backgroundColor = UIColor.clear
        view.isScrollEnabled = false
        view.register(FZMGroupUserCell.self, forCellWithReuseIdentifier: "FZMGroupUserCell")
        view.dataSource = self
        view.delegate = self
        return view
    }()
    private var memberList = [FZMGroupDetailUserViewModel]()
    
    private lazy var infoBlockView : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        let titleView = self.getOnlineView(title: "群公告", rightView: notifyNumLab, true, true)
        view.addSubview(titleView)
        titleView.snp.makeConstraints({ (m) in
            m.top.left.right.equalToSuperview()
            m.height.equalTo(50)
        })
        view.addSubview(notifyInfoLab)
        notifyInfoLab.snp.makeConstraints({ (m) in
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.top.equalToSuperview().offset(55)
        })
        let nameView = self.getOnlineView(title: "我在本群的昵称", rightView: nickNameLab, true, false)
        view.addSubview(nameView)
        nameView.snp.makeConstraints({ (m) in
            m.bottom.left.right.equalToSuperview()
            m.height.equalTo(50)
        })
        let lineV = UIView.getNormalLineView()
        view.addSubview(lineV)
        lineV.snp.makeConstraints { (m) in
            m.left.right.equalToSuperview()
            m.bottom.equalTo(nameView.snp.top)
            m.height.equalTo(0.5)
        }
        return view
    }()
    
    private lazy var notifyNumLab : UILabel = {
        return self.getNormalLab()
    }()
    
    private lazy var notifyInfoLab : UILabel = {
        let lab = self.getNormalLab()
        lab.textAlignment = .left
        lab.numberOfLines = 0
        return lab
    }()
    
    private lazy var nickNameLab : UILabel = {
        return self.getNormalLab()
    }()
    
    private lazy var ctrlBlockView : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        
        view.addSubview(chatRecordView)
        chatRecordView.snp.makeConstraints({ (m) in
            m.top.left.right.equalToSuperview()
            m.height.equalTo(50)
        })
        view.addSubview(fileView)
        fileView.snp.makeConstraints({ (m) in
            m.left.right.equalToSuperview()
            m.top.equalTo(chatRecordView.snp.bottom)
            m.height.equalTo(50)
        })
        let disView = self.getOnlineView(title: "消息免打扰", rightView: disturbSwitch, false, true)
        view.addSubview(disView)
        disView.snp.makeConstraints({ (m) in
            m.left.right.equalToSuperview()
            m.top.equalTo(fileView.snp.bottom)
            m.height.equalTo(50)
        })
        let stickView = self.getOnlineView(title: "置顶聊天", rightView: stickSwitch, false, false)
        view.addSubview(stickView)
        stickView.snp.makeConstraints({ (m) in
            m.left.right.equalToSuperview()
            m.top.equalTo(disView.snp.bottom)
            m.height.equalTo(50)
        })
        view.addSubview(feedbackView)
        feedbackView.snp.makeConstraints({ (m) in
            m.bottom.left.right.equalToSuperview()
            m.height.equalTo(50)
        })
        return view
    }()
    
    private lazy var chatRecordView: UIView = {
        self.getOnlineView(title: "查找聊天记录", rightView: UIView.init(), true, true)
    }()
    
    private lazy var fileView: UIView = {
        self.getOnlineView(title: "群文件", rightView: UIView.init(), true, true)
    }()
    
    private lazy var feedbackView: UIView = {
        self.getOnlineView(title: "举报该群聊", rightView: UIView.init(), true, true)
    }()
    
    private lazy var disturbSwitch : UISwitch = {
        let v = UISwitch()
        v.onTintColor = FZM_TintColor
        return v
    }()
    private lazy var stickSwitch : UISwitch = {
        let v = UISwitch()
        v.onTintColor = FZM_TintColor
        return v
    }()
    
    
    private lazy var configureView : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        
        view.addSubview(managerView)
        managerView.snp.makeConstraints({ (m) in
            m.top.left.right.equalToSuperview()
            m.height.equalTo(50)
        })
        
        view.addSubview(transferView)
        transferView.snp.makeConstraints({ (m) in
            m.left.right.equalToSuperview()
            m.top.equalTo(managerView.snp.bottom)
            m.height.equalTo(50)
        })
        
        view.addSubview(addGroupView)
        addGroupView.snp.makeConstraints({ (m) in
            m.left.right.equalToSuperview()
            m.top.equalTo(transferView.snp.bottom)
            m.height.equalTo(50)
        })
        
        view.addSubview(addFriendView)
        addFriendView.snp.makeConstraints({ (m) in
            m.left.right.equalToSuperview()
            m.top.equalTo(addGroupView.snp.bottom)
            m.height.equalTo(50)
        })
        
        view.addSubview(chatLimitView)
        chatLimitView.snp.makeConstraints({ (m) in
            m.left.right.equalToSuperview()
            m.top.equalTo(addFriendView.snp.bottom)
            m.height.equalTo(50)
        })
        
        view.addSubview(listLimitView)
        listLimitView.snp.makeConstraints({ (m) in
            m.left.right.equalToSuperview()
            m.top.equalTo(chatLimitView.snp.bottom)
            m.height.equalTo(50)
        })
        return view
    }()
    private lazy var managerView : UIView = {
        return self.getOnlineView(title: "管理员设置", rightView: managerSetLab, true, true)
    }()
    private lazy var transferView : UIView = {
        return self.getOnlineView(title: "转让群主", rightView: transferLab, true, true)
    }()
    private lazy var addGroupView : UIView = {
        return self.getOnlineView(title: "加群限制", rightView: addGroupLab, true, true)
    }()
    private lazy var addFriendView : UIView = {
        return self.getOnlineView(title: "加好友限制", rightView: addFriendLab, true, true)
    }()
    private lazy var chatLimitView : UIView = {
        return self.getOnlineView(title: "禁言设置", rightView: chatLimitLab, true, false)
    }()
    private lazy var listLimitView : UIView = {
        return self.getOnlineView(title: "新成员可查看历史记录", rightView: listLimitSwitch, false, false)
    }()
    private lazy var managerSetLab : UILabel = {
        return self.getNormalLab()
    }()
    private lazy var transferLab : UILabel = {
        return self.getNormalLab()
    }()
    private lazy var addGroupLab : UILabel = {
        return self.getNormalLab()
    }()
    private lazy var addFriendLab : UILabel = {
        return self.getNormalLab()
    }()
    private lazy var chatLimitLab : UILabel = {
        return self.getNormalLab()
    }()
    private lazy var listLimitSwitch : UISwitch = {
        let v = UISwitch()
        v.onTintColor = FZM_TintColor
        return v
    }()
    
    private lazy var bottomBtn : UIButton = {
        let btn = UIButton.getNormalBtn(with: "退出群聊", backgroundColor: FZM_BackgroundColor)
        return btn
    }()
    
    init(with groupId: String) {
        self.groupId = groupId
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "群聊详情"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: GetBundleImage("me_qrcode")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(qrCodeClick))
        self.navigationItem.rightBarButtonItem?.tintColor = FZM_TintColor
        self.createUI()
        self.makeActions()
        self.refreshInfo()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.refreshView()
    }
    
    @objc func qrCodeClick() {
        guard let info = self.groupDetailInfo else { return }
        FZMUIMediator.shared().pushVC(.qrCodeShow(type: .group(info)))
    }
    
    private func createUI() {
        self.view.addSubview(scrollView)
        scrollView.snp.makeConstraints { (m) in
            m.edges.equalToSuperview()
        }
        bottomBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            guard let strongSelf = self, let info = strongSelf.groupDetailInfo else { return }
            if info.isMaster {
                let alert = FZMAlertView(dissolveGroup: info.showName, confirmBlock: {
                    IMConversationManager.shared().deleteGroup(groupId: strongSelf.groupId, completionBlock: { (response) in
                        guard response.success else {
                            strongSelf.showToast(with: response.message)
                            return
                        }
                        strongSelf.navigationController?.popToRootViewController(animated: true)
                    })
                })
                alert.show()
            }else {
                let alert = FZMAlertView(quitGroup: info.showName, confirmBlock: {
                    IMConversationManager.shared().quitGroup(groupId: strongSelf.groupId, completionBlock: { (response) in
                        guard response.success else {
                            strongSelf.showToast(with: response.message)
                            return
                        }
                        strongSelf.navigationController?.popToRootViewController(animated: true)
                    })
                })
                alert.show()
            }
            
        }.disposed(by: disposeBag)
    }
    
    
    private func getOnlineView(title: String,rightView: UIView, _ showMore: Bool = true, _ showBottomLine: Bool = true) -> UIView {
        let view = UIView()
        view.clipsToBounds = true
        let titleLab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: title)
        view.addSubview(titleLab)
        titleLab.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(15)
        }
        titleLab.setContentHuggingPriority(.defaultHigh, for: .horizontal)
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
    private func getNormalLab() -> UILabel {
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .right, text: nil)
        lab.isUserInteractionEnabled = true
        lab.enlargeClickEdge(5, 30, 5, 30)
        return lab
    }
    
    private func refreshInfo() {
        self.showProgress(with: nil)
        
        IMConversationManager.shared().getServerGroupMemberList(groupId: groupId, completionBlock: nil)
        
        IMConversationManager.shared().getGroupDetailInfo(groupId: groupId) { (model, response) in
            self.hideProgress()
            guard response.success else {
                self.showToast(with: response.message)
                return
            }
            self.groupDetailInfo = model
        }
    }
    
    private func refreshView() {
        guard let info = groupDetailInfo else { return }
        nameLab.text = info.showName
        desLab.text = "群号 \(info.showId)"
        if info.identification == true {
            identificationImageView.isHidden = false
            var att: NSMutableAttributedString
            if info.isMaster || info.isManager {
                att = NSMutableAttributedString.init(string: "\(IMSDK.shared().shareTitle ?? "")认证： \(info.identificationInfo) \(FZMIconFont.identificationArrow.rawValue)", attributes: [NSAttributedString.Key.font : UIFont.iconfont(ofSize: 14),NSAttributedString.Key.foregroundColor : FZM_GrayWordColor])
            } else {
                identificationInfoLab.isUserInteractionEnabled = false
                att = NSMutableAttributedString.init(string: "\(IMSDK.shared().shareTitle ?? "")认证： \(info.identificationInfo)", attributes: [NSAttributedString.Key.font : UIFont.regularFont(14),NSAttributedString.Key.foregroundColor : FZM_GrayWordColor])
            }
            att.yy_lineSpacing = 4
            identificationInfoLab.attributedText = att
            
        } else {
            if (info.isMaster || info.isManager) && IMSDK.shared().showIdentification {
                identificationImageView.isHidden = true
                let att = NSMutableAttributedString.init(string: "去认证 \(FZMIconFont.identificationArrow.rawValue)", attributes: [NSAttributedString.Key.font : UIFont.iconfont(ofSize: 14),NSAttributedString.Key.foregroundColor :FZM_TintColor])
                att.insert(NSAttributedString.init(string: "\(IMSDK.shared().shareTitle ?? "")认证：", attributes: [NSAttributedString.Key.font : UIFont.regularFont(14),NSAttributedString.Key.foregroundColor : FZM_GrayWordColor]), at: 0)
                identificationInfoLab.attributedText = att
            } else {
                identificationInfoLab.isHidden = true
                identificationInfoLab.snp.remakeConstraints { (m) in
                    m.top.equalTo(desLab.snp.bottom)
                    m.left.equalTo(nameLab)
                    m.right.equalToSuperview().offset(-16)
                    m.height.equalTo(0)
                }
            }
        }
        headerImageView.loadNetworkImage(with: info.avatar.getDownloadUrlString(width: 50), placeImage: GetBundleImage("chat_group_head"))
        memberNumberLab.text = "共\(info.memberNumber)人"
        
        managerSetLab.text = "共\(info.managerNumber)人"
        
        nickNameLab.text = info.groupNickname
        notifyNumLab.text = "共\(info.notifyNum)条"
        var contentHeight : CGFloat = 0
        if let notify = info.notifyList.first {
            notifyInfoLab.text = notify.content
            contentHeight = notify.content.getContentHeight(width: ScreenWidth - 60, font: UIFont.regularFont(14))
        }else {
            notifyInfoLab.text = ""
        }
        let infoHeight = contentHeight > 0 ? contentHeight + 120 : 100
        infoBlockView.snp.updateConstraints { (m) in
            m.height.equalTo(infoHeight)
        }
        
        if let master = info.master {
            transferLab.text = master.showName
        }
        disturbSwitch.isOn = info.noDisturbing == .open
        stickSwitch.isOn = info.onTop
        addFriendLab.text = info.canAddFriend ? "可加好友" : "禁止加好友"
        listLimitSwitch.isOn = info.recordPermission
        addGroupLab.text = info.joinPermission.getDescriptionStr()
        chatLimitLab.text = info.bannedDescription
        if info.isMaster {
            bottomBtn.setAttributedTitle(NSAttributedString(string: "解散群聊", attributes: [.foregroundColor: FZM_GrayWordColor,.font:UIFont.regularFont(16)]), for: .normal)
        }
        if info.joinPermission == .forbid {
            if info.isMaster || info.isManager {
                var arr : [FZMGroupDetailUserViewModel] = info.users.compactMap { (user) -> FZMGroupDetailUserViewModel in
                    return FZMGroupDetailUserViewModel(with: user)
                }
                memberList = arr.count > 8 ? Array(arr[0...7]) : arr
                memberList.append(FZMGroupDetailUserViewModel(with: .invite))
                memberList.append(FZMGroupDetailUserViewModel(with: .remove))
            }else {
                var arr : [FZMGroupDetailUserViewModel] = info.users.compactMap { (user) -> FZMGroupDetailUserViewModel in
                    return FZMGroupDetailUserViewModel(with: user)
                }
                memberList = arr.count > 10 ? Array(arr[0...9]) : arr
            }
        }else {
            if info.isMaster || info.isManager {
                var arr : [FZMGroupDetailUserViewModel] = info.users.compactMap { (user) -> FZMGroupDetailUserViewModel in
                    return FZMGroupDetailUserViewModel(with: user)
                }
                memberList = arr.count > 8 ? Array(arr[0...7]) : arr
                memberList.append(FZMGroupDetailUserViewModel(with: .invite))
                memberList.append(FZMGroupDetailUserViewModel(with: .remove))
            }else {
                var arr : [FZMGroupDetailUserViewModel] = info.users.compactMap { (user) -> FZMGroupDetailUserViewModel in
                    return FZMGroupDetailUserViewModel(with: user)
                }
                memberList = arr.count > 9 ? Array(arr[0...8]) : arr
                memberList.append(FZMGroupDetailUserViewModel(with: .invite))
            }
        }
        memberView.reloadData()
        let memberHeight : CGFloat = memberList.count > 5 ? 220 : 143
        memberBlockView.snp.updateConstraints { (m) in
            m.height.equalTo(memberHeight)
        }
        var configureHeight : CGFloat = 0
        configureView.isHidden = true
        
        if info.isMaster {
            configureView.isHidden = false
            let attStr = NSMutableAttributedString(string: info.showName)
            attStr.append(NSAttributedString(string: " \(FZMIconFont.editPencil.rawValue)", attributes: [.foregroundColor: FZM_GrayWordColor, .font: UIFont.iconfont(ofSize: 12)]))
            nameLab.attributedText = attStr
            configureHeight = 300
            managerView.snp.updateConstraints { (m) in
                m.height.equalTo(50)
            }
            transferView.snp.updateConstraints { (m) in
                m.height.equalTo(50)
            }
        }else if info.isManager {
            configureView.isHidden = false
            let attStr = NSMutableAttributedString(string: info.showName)
            attStr.append(NSAttributedString(string: "\(FZMIconFont.editPencil.rawValue)", attributes: [.foregroundColor: FZM_GrayWordColor, .font: UIFont.iconfont(ofSize: 12)]))
            nameLab.attributedText = attStr
            configureHeight = 200
            managerView.snp.updateConstraints { (m) in
                m.height.equalTo(0)
            }
            transferView.snp.updateConstraints { (m) in
                m.height.equalTo(0)
            }
        }
        configureView.snp.updateConstraints { (m) in
            m.height.equalTo(configureHeight)
        }
        contentView.frame = CGRect(x: 0, y: 0, width: ScreenWidth, height: 470 + infoHeight + configureHeight + memberHeight)
        scrollView.contentSize = CGSize(width: ScreenWidth, height: 470 + infoHeight + configureHeight + memberHeight)
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

extension FZMGroupDetailInfoVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return memberList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FZMGroupUserCell", for: indexPath) as! FZMGroupUserCell
        cell.setImageSize(48)
        let vm = memberList[indexPath.row]
        cell.configure(with: vm)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let addBlock = {
            guard let group = self.groupDetailInfo else { return }
            FZMUIMediator.shared().pushVC(.selectFriend(type: .exclude(group.groupId, group.isEncryptGroup), completeBlock: {[weak self] in
                self?.refreshInfo()
            }))
        }
        let deleteBlock = {
            guard let group = self.groupDetailInfo else { return }
            let vc = FZMGroupCtrlMemberVC(with: group, ctrlType: .delete)
            vc.reloadBlock = {[weak self] in
                self?.refreshInfo()
            }
            self.navigationController?.pushViewController(vc, animated: true)
        }
        let vm = memberList[indexPath.row]
        switch vm.type {
        case .person:
            FZMUIMediator.shared().pushVC(.friendInfo(friendId: vm.userId, groupId: self.groupId, source: .group(groupId: self.groupId)))
        case .invite:
            addBlock()
        case .remove:
            deleteBlock()
        }
    }
    
}


//MARK: 响应事件
extension FZMGroupDetailInfoVC {
    
    private func makeActions() {
        
        let nameTap = UITapGestureRecognizer()
        nameTap.rx.event.subscribe {[weak self] (_) in
            guard let strongSelf = self, let info = strongSelf.groupDetailInfo else { return }
            guard info.isMaster || info.isManager else { return }
            let vc = FZMGroupEditNameVC(with: strongSelf.groupId, info.name)
            vc.completeBlock = {
                strongSelf.refreshInfo()
            }
            strongSelf.navigationController?.pushViewController(vc, animated: true)
        }.disposed(by: disposeBag)
        nameLab.addGestureRecognizer(nameTap)
        
        let headTap = UITapGestureRecognizer()
        headTap.rx.event.subscribe {[weak self] (_) in
            guard let strongSelf = self, let info = strongSelf.groupDetailInfo else { return }
            if info.isMaster || info.isManager {
                let vc = FZMEditHeadImageVC(with: .group(groupId:strongSelf.groupId), oldAvatar: info.avatar)
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }else {
                FZMUIMediator.shared().showImage(view: strongSelf.headerImageView, url: info.avatar)
            }
        }.disposed(by: disposeBag)
        headerImageView.addGestureRecognizer(headTap)
        
        let managerTap = UITapGestureRecognizer()
        managerTap.rx.event.subscribe {[weak self] (_) in
            guard let info = self?.groupDetailInfo else { return }
            let vc = FZMGroupManagerSetVC(with: info)
            self?.navigationController?.pushViewController(vc, animated: true)
        }.disposed(by: disposeBag)
        managerSetLab.addGestureRecognizer(managerTap)
        
        let transferTap = UITapGestureRecognizer()
        transferTap.rx.event.subscribe {[weak self] (_) in
            guard let info = self?.groupDetailInfo else { return }
            let vc = FZMGroupAddManagerVC(with: info, type: .owner)
            vc.reloadBlock = {
                self?.refreshInfo()
            }
            self?.navigationController?.pushViewController(vc, animated: true)
        }.disposed(by: disposeBag)
        transferLab.addGestureRecognizer(transferTap)
        
        let groupTap = UITapGestureRecognizer()
        groupTap.rx.event.subscribe {[weak self] (_) in
            guard let _ = self else { return }
            FZMBottomSelectView.show(with: [
                FZMBottomOption(title: "禁止加群", titleColor: FZM_BlackWordColor, content: "除群主/管理员邀请不允许加群", contentColor: FZM_GrayWordColor, block: {
                    self?.setPermission(canAddFriend: nil, joinPermission: 3, recordPermission: nil)
                }),FZMBottomOption(title: "需要审批", titleColor: FZM_BlackWordColor, content: "加群需要群主或管理员同意", contentColor: FZM_GrayWordColor, block: {
                    self?.setPermission(canAddFriend: nil, joinPermission: 1, recordPermission: nil)
                }),FZMBottomOption(title: "无需审批", titleColor: FZM_BlackWordColor, content: "加群无需群主或管理员同意", contentColor: FZM_GrayWordColor, block: {
                    self?.setPermission(canAddFriend: nil, joinPermission: 2, recordPermission: nil)
                })])
        }.disposed(by: disposeBag)
        addGroupLab.addGestureRecognizer(groupTap)
        
        let friendTap = UITapGestureRecognizer()
        friendTap.rx.event.subscribe {[weak self] (_) in
            guard let _ = self else { return }
            FZMBottomSelectView.show(with: [
                FZMBottomOption(title: "禁止加好友", block: {
                    self?.setPermission(canAddFriend: 2, joinPermission: nil, recordPermission: nil)
                }),FZMBottomOption(title: "可加好友", block: {
                    self?.setPermission(canAddFriend: 1, joinPermission: nil, recordPermission: nil)
                })])
        }.disposed(by: disposeBag)
        addFriendLab.addGestureRecognizer(friendTap)
        
        let chatLimitTap = UITapGestureRecognizer()
        chatLimitTap.rx.event.subscribe {[weak self] (_) in
            guard let strongSelf = self, let group = strongSelf.groupDetailInfo else { return }
            FZMBottomSelectView.show(with: [
                FZMBottomOption(title: "设置禁言名单（新成员默认发言）", block: {
                    let vc = FZMGroupCtrlMemberVC(with: group, ctrlType: .blackMap)
                    vc.reloadBlock = {
                        strongSelf.refreshInfo()
                    }
                    strongSelf.navigationController?.pushViewController(vc, animated: true)
                }),FZMBottomOption(title: "设置发言名单（新成员默认禁言）", block: {
                    let vc = FZMGroupCtrlMemberVC(with: group, ctrlType: .whiteMap)
                    vc.reloadBlock = {
                        strongSelf.refreshInfo()
                    }
                    strongSelf.navigationController?.pushViewController(vc, animated: true)
                }),FZMBottomOption(title: "全员禁言（除群主和群管理员）", block: {
                    strongSelf.setBannedType(4)
                }),FZMBottomOption(title: "全员可发言", block: {
                    strongSelf.setBannedType(1)
                })])
        }.disposed(by: disposeBag)
        chatLimitLab.addGestureRecognizer(chatLimitTap)
        
        let nicknameTap = UITapGestureRecognizer()
        nicknameTap.rx.event.subscribe {[weak self] (_) in
            guard let strongSelf = self, let info = strongSelf.groupDetailInfo else { return }
            let vc = FZMGroupEditNameVC(with: strongSelf.groupId, info.groupNickname, true)
            vc.completeBlock = {
                strongSelf.refreshInfo()
            }
            strongSelf.navigationController?.pushViewController(vc, animated: true)
        }.disposed(by: disposeBag)
        nickNameLab.addGestureRecognizer(nicknameTap)
        
        let notifyTap = UITapGestureRecognizer()
        notifyTap.rx.event.subscribe {[weak self] (_) in
            guard let strongSelf = self, let info = strongSelf.groupDetailInfo else { return }
            let vc = FZMGroupNotifyListVC(with: info)
            strongSelf.navigationController?.pushViewController(vc, animated: true)
        }.disposed(by: disposeBag)
        notifyNumLab.addGestureRecognizer(notifyTap)
        
        let memberListTap = UITapGestureRecognizer()
        memberListTap.rx.event.subscribe {[weak self] (_) in
            guard let info = self?.groupDetailInfo else { return }
            let vc = FZMGroupMemberListVC(with: info)
            self?.navigationController?.pushViewController(vc, animated: true)
        }.disposed(by: disposeBag)
        memberNumberLab.addGestureRecognizer(memberListTap)
        
        let fileTap = UITapGestureRecognizer.init()
        fileTap.rx.event.subscribe { [weak self] (_) in
            guard let strongSelf = self else {return}
            let vc = FZMFileViewController.init(conversationType: .group, conversationID: strongSelf.groupId )
            vc.title = "群文件"
            strongSelf.navigationController?.pushViewController(vc, animated: true)
        }.disposed(by: disposeBag)
        fileView.addGestureRecognizer(fileTap)
        
        let chatRecordTap = UITapGestureRecognizer.init()
        chatRecordTap.rx.event.subscribe { [weak self] (_) in
            guard let strongSelf = self else { return }
            let vc = FZMFullTextSearchVC.init(searchType: .chatRecord(specificId: strongSelf.groupId), limitCount: NSInteger.max, isHideHistory: true)
            strongSelf.navigationController?.pushViewController(vc, animated: true)
        }.disposed(by: disposeBag)
        chatRecordView.addGestureRecognizer(chatRecordTap)
        
        let feedbackTap = UITapGestureRecognizer.init()
        feedbackTap.rx.event.subscribe { [weak self] (_) in
            guard let strongSelf = self else {return}
            let vc = FZMWebViewController.init()
            vc.url = FeedbackUrl
            strongSelf.navigationController?.pushViewController(vc, animated: true)
            }.disposed(by: disposeBag)
        feedbackView.addGestureRecognizer(feedbackTap)
        
        disturbSwitch.rx.controlEvent(.valueChanged).subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            IMConversationManager.shared().groupSetNoDisturbing(groupId: strongSelf.groupId, on: strongSelf.disturbSwitch.isOn, completionBlock: { (response) in
                if !response.success {
                    strongSelf.disturbSwitch.isOn = !strongSelf.disturbSwitch.isOn
                    strongSelf.showToast(with: response.message)
                }
            })
        }.disposed(by: disposeBag)
        
        stickSwitch.rx.controlEvent(.valueChanged).subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            IMConversationManager.shared().groupSetOnTop(groupId: strongSelf.groupId, on: strongSelf.stickSwitch.isOn, completionBlock: { (response) in
                if !response.success {
                    strongSelf.stickSwitch.isOn = !strongSelf.stickSwitch.isOn
                    strongSelf.showToast(with: response.message)
                }
            })
        }.disposed(by: disposeBag)
        
        listLimitSwitch.rx.controlEvent(.valueChanged).subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.setPermission(canAddFriend: nil, joinPermission: nil, recordPermission: strongSelf.listLimitSwitch.isOn ? 1 : 2)
        }.disposed(by: disposeBag)
    }
    
    private func setPermission(canAddFriend: Int?, joinPermission: Int?, recordPermission: Int?) {
        self.showProgress(with: nil)
        IMConversationManager.shared().groupSetPermission(groupId: groupId, canAddFriend: canAddFriend, joinPermission: joinPermission, recordPermission: recordPermission) { (response) in
            self.hideProgress()
            guard response.success else {
                self.showToast(with: response.message)
                return
            }
            guard let info = self.groupDetailInfo else { return }
            if let can = canAddFriend {
                info.canAddFriend = can == 1
            }
            if let join = joinPermission {
                if let permission = IMGroupJoinPermission(rawValue: join) {
                    info.joinPermission = permission
                }
            }
            if let record = recordPermission {
                info.recordPermission = record == 1
            }
            self.refreshView()
        }
    }
    
    private func setBannedType(_ type: Int) {
        self.showProgress()
        IMConversationManager.shared().groupBannedSet(groupId: groupId, type: type) { (response) in
            self.hideProgress()
            guard response.success else {
                self.showToast(with: response.message)
                return
            }
            guard let info = self.groupDetailInfo else { return }
            if type == 1 {
                info.bannedType = .all
            }else if type == 4 {
                info.bannedType = .bannedAll
            }
            self.refreshView()
        }
    }
}

enum FZMGroupDetailUserViewModelType {
    case person//用户
    case invite//邀请
    case remove//移除
}

class FZMGroupDetailUserViewModel : NSObject {
    var name = ""
    var avatar = ""
    var userId = ""
    var groupId = ""
    var identification = false
    let type : FZMGroupDetailUserViewModelType
    
    init(with user: IMGroupUserInfoModel) {
        type = .person
        name = user.showName
        avatar = user.avatar
        userId = user.userId
        groupId = user.groupId
        identification = user.identification
        super.init()
    }
    
    init(with type: FZMGroupDetailUserViewModelType) {
        self.type = type
        super.init()
    }
    
}
