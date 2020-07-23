//
//  FZMBaseMessageCell.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/25.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift

class FZMBaseMessageCell: UITableViewCell {

    weak var actionDelegate: CellActionProtocol?
    
    var vm : FZMMessageBaseVM = FZMMessageBaseVM()
    
    let disposeBag = DisposeBag()
    
    var refreshDisposeBag : DisposeBag?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    lazy var topTimeView : UIView = {
        let view = UIView.init()
        view.clipsToBounds = true
        return view
    }()
    
    lazy var timeLab : UILabel = {
        let lbl = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .center, text: nil)
        return lbl
    }()
    
    lazy var userNameLbl: UILabel = {
        let lbl = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .center, text: nil)
        lbl.numberOfLines = 1
        return lbl
    }()
    
    private lazy var typeLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(10), textColor: UIColor.white, textAlignment: .center, text: nil)
        lab.layer.cornerRadius = 4
        lab.clipsToBounds = true
        lab.isHidden = true
        return lab
    }()
    
    var memberLevel : IMGroupMemberLevel = .normal {
        didSet {
            switch memberLevel  {
            case .none:
                self.typeLab.isHidden = true
            case .owner:
                    self.typeLab.isHidden = false
                    self.typeLab.backgroundColor = FZM_TintColor
                    self.typeLab.text = "群主"
                    self.typeLab.snp.updateConstraints { (m) in
                        m.size.equalTo(CGSize(width: 30, height: 14))
                    }
            case .manager:
                    self.typeLab.isHidden = false
                    self.typeLab.backgroundColor = UIColor(hex: 0xECD13C)
                    self.typeLab.text = "管理员"
                    self.typeLab.snp.updateConstraints { (m) in
                        m.size.equalTo(CGSize(width: 35, height: 14))
                }
            default:
                self.typeLab.isHidden = true
            }
        }
    }
    
    lazy var identificationImageView: UIImageView = {
        let imgV = UIImageView(image: GetBundleImage("chat_identification"))
        imgV.isUserInteractionEnabled = true
        imgV.contentMode = .scaleAspectFill
        imgV.isHidden = true
        return imgV
    }()
    
    lazy var headerImageView: UIImageView = {
        let imgV = UIImageView(image: GetBundleImage("chat_normal_head"))
        imgV.layer.cornerRadius = 5
        imgV.clipsToBounds = true
        imgV.isUserInteractionEnabled = true
        imgV.contentMode = .scaleAspectFill
        imgV.addSubview(identificationImageView)
        identificationImageView.snp.makeConstraints({ (m) in
            m.size.equalTo(CGSize.init(width: 10, height: 10))
            m.bottom.right.equalToSuperview()
        })
        return imgV
    }()
    
    lazy var sourceLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .left, text: nil)
        lab.numberOfLines = 2
        return lab
    }()
    
    lazy var sendingView : UIImageView = {
        let imV = UIImageView(image: GetBundleImage("chat_sending"))
        imV.isHidden = true
        return imV
    }()
    
    lazy var failBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(GetBundleImage("chat_sendfail"), for: .normal)
        btn.enlargeClickEdge(10, 10, 10, 10)
        btn.isHidden = true
        return btn
    }()
    
    lazy var lockView: UIView = {
        let view = UIView()
        let backImgV = UIImageView()
        backImgV.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        backImgV.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let inset = UIEdgeInsets.init(top: 30, left: 30, bottom: 30, right: 30)
        var image = GetBundleImage("message_text")
        image = image?.resizableImage(withCapInsets: inset, resizingMode: .stretch)
        backImgV.image = image
        view.addSubview(backImgV)
        backImgV.snp.makeConstraints { (m) in
            m.edges.equalToSuperview()
        }
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_GrayWordColor, textAlignment: .center, text: "点击查看")
        backImgV.addSubview(lab)
        lab.snp.makeConstraints { (m) in
            m.edges.equalToSuperview()
        }
        let lockImV = UIImageView(image: GetBundleImage("message_lock"))
        backImgV.addSubview(lockImV)
        lockImV.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(10)
            m.right.equalToSuperview()
            m.size.equalTo(CGSize(width: 20, height: 20))
        }
        return view
    }()
    
    lazy var lockImg: UIImageView = {
        let view = UIImageView(image: GetBundleImage("message_lock"))
        return view
    }()
    
    lazy var countDownTimeView: FZMCountdownLab = {
        return FZMCountdownLab()
    }()
    
    lazy var selectBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(GetBundleImage("tool_disselect"), for: .normal)
        btn.enlargeClickEdge(15, 15, 15, 15)
        btn.isHidden = true
        return btn
    }()
    
    var showSelect : Bool = false {
        didSet{
            guard self.vm.msgType != .notify, self.vm.snap == .none, self.vm.msgType != .receipt, self.vm.msgType != .transfer else { return }
            selectBtn.isHidden = !showSelect
            if self.vm.direction == .receive, headerImageView.superview != nil {
                headerImageView.snp.updateConstraints { (m) in
                    m.left.equalToSuperview().offset(showSelect ? 45 : 15)
                }
            }
        }
    }
    
     let admireView = FZMAdmireView.init()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.initView()
    }
    
    func initView() {
        self.selectionStyle = .none
        self.backgroundColor = UIColor.clear
        self.contentView.addSubview(self.topTimeView)
        topTimeView.snp.makeConstraints { (m) in
            m.top.left.right.equalToSuperview()
            m.height.equalTo(0)
        }
        let backView = UIView()
        backView.layer.cornerRadius = 4.0
        backView.backgroundColor = FZM_LineColor
        backView.clipsToBounds = true
        topTimeView.addSubview(backView)
        topTimeView.addSubview(self.timeLab)
        timeLab.snp.makeConstraints { (m) in
            m.centerX.equalToSuperview()
            m.centerY.equalToSuperview().offset(-5)
            m.height.equalTo(25)
        }
        backView.snp.makeConstraints { (m) in
            m.center.height.equalTo(timeLab)
            m.width.equalTo(timeLab).offset(10)
        }
        
        self.contentView.addSubview(self.headerImageView)
        headerImageView.snp.makeConstraints { (m) in
            m.top.equalTo(topTimeView.snp.bottom)
            m.left.equalToSuperview().offset(15)
            m.size.equalTo(CGSize(width: 35, height: 35))
        }
        self.contentView.addSubview(self.userNameLbl)
        userNameLbl.snp.makeConstraints { (m) in
            m.top.equalTo(headerImageView)
            m.left.equalTo(headerImageView.snp.right).offset(15)
            m.height.equalTo(17)
        }
        
        self.contentView.addSubview(self.typeLab)
        typeLab.snp.makeConstraints { (m) in
            m.bottom.equalTo(userNameLbl).offset(-3)
            m.left.equalTo(userNameLbl.snp.right).offset(5)
            m.size.equalTo(CGSize(width: 45, height: 20))
        }
        
        self.contentView.addSubview(self.selectBtn)
        selectBtn.snp.makeConstraints { (m) in
            m.centerY.equalTo(headerImageView)
            m.left.equalToSuperview().offset(15)
            m.size.equalTo(CGSize(width: 15, height: 15))
        }
        
        self.contentView.addSubview(sendingView)
        self.contentView.addSubview(failBtn)
        failBtn.snp.makeConstraints { (m) in
            m.edges.equalTo(sendingView)
        }
        
        self.contentView.addSubview(admireView)

        failBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.actionDelegate?.reSendMessage(msgId: strongSelf.vm.msgId)
        }.disposed(by: disposeBag)
        
        let headTap = UITapGestureRecognizer()
        headTap.rx.event.subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.actionDelegate?.clickUserHeadImage(userId: strongSelf.vm.senderUid)
        }.disposed(by: disposeBag)
        headerImageView.addGestureRecognizer(headTap)
        

        let longPress = UILongPressGestureRecognizer()
        longPress.rx.event.subscribe {[weak self] (event) in
            guard case .next(let press) = event else { return }
            guard let strongSelf = self else { return }
            if press.state == .began {
                strongSelf.actionDelegate?.longTapOnHeaderImageView(msgId: strongSelf.vm.msgId)
            }
        }.disposed(by: disposeBag)
        headerImageView.addGestureRecognizer(longPress)
        
        let burnTap = UITapGestureRecognizer()
        burnTap.rx.event.subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.openBurnMessage()
        }.disposed(by: disposeBag)
        lockView.addGestureRecognizer(burnTap)

        selectBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            if let selected = strongSelf.actionDelegate?.forwardSelectMessage(msgId: strongSelf.vm.msgId) {
                strongSelf.selectBtn.setImage(GetBundleImage(selected ? "tool_select" : "tool_disselect"), for: .normal)
            }
        }.disposed(by: disposeBag)
        
        self.admireView.tapBlock = {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.actionDelegate?.admireInfoTap(msgId: strongSelf.vm.msgId)
        }
    }
    
    func changeMineConstraints() {
        headerImageView.snp.remakeConstraints { (m) in
            m.top.equalTo(topTimeView.snp.bottom)
            m.right.equalToSuperview().offset(-15)
            m.size.equalTo(CGSize(width: 35, height: 35))
        }
        userNameLbl.snp.remakeConstraints { (m) in
            m.top.equalTo(headerImageView)
            m.right.equalTo(headerImageView.snp.left).offset(-15)
            m.height.equalTo(17)
        }
        typeLab.snp.remakeConstraints { (m) in
            m.centerY.equalTo(userNameLbl)
            m.right.equalTo(userNameLbl.snp.left).offset(-5)
            m.size.equalTo(CGSize(width: 45, height: 20))
        }
        
        self.admireView.changeImageTrailing()
    }
    
    func hideUserNameLab() {
        userNameLbl.snp.updateConstraints { (m) in
            m.top.equalTo(headerImageView).offset(-19)
        }
        userNameLbl.isHidden = true
    }
    
    func configure(with data: FZMMessageBaseVM) {
        self.vm = data
        topTimeView.snp.updateConstraints { (m) in
            m.height.equalTo(data.isShowTime ? 40 : 0)
        }
        timeLab.text = data.timeStr
        userNameLbl.snp.updateConstraints { (m) in
            m.height.equalTo(data.showName ? 17 : 0)
        }
        refreshDisposeBag = nil
        refreshDisposeBag = DisposeBag()
        reloadNormalInfo()
        if vm.showForward {
            self.userNameLbl.text = data.senderName
            self.headerImageView.loadNetworkImage(with: data.senderAvatar.getDownloadUrlString(width: 35), placeImage: GetBundleImage("chat_normal_head"))
        }else {
            data.statusSubject.subscribe {[weak self] (_) in
                self?.reloadNormalInfo()
                }.disposed(by: refreshDisposeBag!)
            data.infoSubject.subscribe {[weak self] (event) in
                guard case .next(let (name,avatar)) = event else { return }
                if !name.isEmpty && name != self?.userNameLbl.text {
                    self?.userNameLbl.text = name
                }
                self?.headerImageView.loadNetworkImage(with: avatar.getDownloadUrlString(width: 35), placeImage: GetBundleImage("chat_normal_head"))
                }.disposed(by: refreshDisposeBag!)
        }
        
        selectBtn.setImage(GetBundleImage(vm.selected ? "tool_select" : "tool_disselect"), for: .normal)
        
        if data.snap == .open {
            let distance = (data.snapTime - Date.timestamp)/1000
            if distance > 0 {
                FZMAnimationTool.countdown(with: countDownTimeView, fromValue: distance, toValue: 0, block: { (time) in
                    self.countDownTimeView.setTime(Int(time))
                }) {
                    
                }
            }else {
                FZMAnimationTool.removeCountdown(with: countDownTimeView)
                self.countDownTimeView.setTime(0)
            }
        }else {
            FZMAnimationTool.removeCountdown(with: countDownTimeView)
            self.countDownTimeView.setTime(0)
        }
        self.identificationImageView.isHidden = true
        IMContactManager.shared().requestUserModel(with: data.senderUid) { (userModel, result, _) in
            if result == true, let userModel = userModel, userModel.identification == true {
                self.identificationImageView.isHidden = false
            }
        }
        self.admireView.isHidden = true
        self.admireView.setAdmire(info: "", state: .none)
        if data.snap == .none
            && (data.msgType == .text
            || data.msgType == .image
            || data.msgType == .audio
            || data.msgType == .video
            || data.msgType == .file
            || data.forwardType == .detail
            || data.forwardType == .merge
            || data.msgType == .redBag
            || data.msgType == .receipt
            || data.msgType == .transfer)
            && data.message.body.ciphertext.isEmpty {
            data.upvote.upvoteSubject.subscribe(onNext: {[weak self] (upvote) in
                guard let strongSelf = self, let upvote = upvote else { return }
                strongSelf.admireView.isHidden = (upvote.admire == 0 && upvote.reward == 0)
                let state = strongSelf.vm.direction == .send ? (upvote.reward > 0 ? .reward : .admire) : upvote.stateForMe
                let animation = data.isShowUpvoteAnimation ? upvote.stateForMe == .admire : false
                strongSelf.admireView.setAdmire(info: "\(upvote.admire + upvote.reward)", state: state, animation: animation)
                data.isShowUpvoteAnimation = false
            }).disposed(by: refreshDisposeBag!)
        }
        
        guard data.channelType == .group && data.msgType != .notify && data.msgType != .system else { return }
        self.typeLab.isHidden = true
        IMContactManager.shared().requestUserGroupInfo(userId: data.senderUid, groupId: data.conversationId) { (groupUserInfoModel, result, _) in
            if result == true  {
                self.memberLevel = groupUserInfoModel?.memberLevel ?? .none
            }
        }
    }
    
    func reloadNormalInfo() {
        DispatchQueue.main.async {
            self.sendingView.isHidden = true
            self.failBtn.isHidden = true
            if self.vm.status == .sending {
                self.sendingView.isHidden = false
                self.makeSendingAnimation()
            }else if self.vm.status == .failed {
                self.failBtn.isHidden = false
            }
        }
    }
    
    func makeSendingAnimation(){
        if !sendingView.isHidden {
            if sendingView.layer.animation(forKey: "rotation") != nil {
                sendingView.layer.removeAnimation(forKey: "rotation")
            }
            // 1.创建动画
            let rotationAnim = CABasicAnimation(keyPath: "transform.rotation.z")
            // 2.设置动画的属性
            rotationAnim.fromValue = 0
            rotationAnim.toValue = Double.pi * 2
            rotationAnim.repeatCount = MAXFLOAT
            rotationAnim.duration = 1.0
            // 这个属性很重要 如果不设置当页面运行到后台再次进入该页面的时候 动画会停止
            rotationAnim.isRemovedOnCompletion = false
            // 3.将动画添加到layer中
            sendingView.layer.add(rotationAnim, forKey: "rotation")
        }
    }
    
    //重定选择按钮位置，暂废弃
    func remakeSelectBtnConstraints(with view: UIView) {
//        selectBtn.snp.remakeConstraints { (m) in
//            m.centerY.equalTo(view)
//            m.left.equalToSuperview().offset(15)
//            m.size.equalTo(CGSize(width: 15, height: 15))
//        }
    }
    
    func showMenu(in targetView: UIView) {
        actionDelegate?.showMenu(in: targetView, msgId: self.vm.msgId)
    }
    
    func openBurnMessage() {
        let data = self.vm
        guard data.msgType == .text || data.msgType == .audio || data.msgType == .image, data.snap == .burn, data.snapTime == 0 else { return }
        self.actionDelegate?.burnAfterMessage(msgId: data.msgId)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

protocol CellActionProtocol: class {
    func showMenu(in targetView: UIView, msgId: String)
    func browserImage(from imageView: UIImageView, msgId: String)
    func clickLuckyPacket(msgId: String)
    func reSendMessage(msgId: String)
    func clickUserHeadImage(userId: String)
    func playVoice(msgId: String)
    func burnAfterMessage(msgId: String)
    func shouldBurnData(msgId: String)
    func forwardMessageDetail(msgId: String)
    func forwardSelectMessage(msgId: String) -> Bool
    func playVideo(msgId:String,videlPath:String)
    func openFile(msgId: String, filePath: String,fileName:String)
    func openTransfer(msgId: String)
    func openReceipt(msgId: String)
    func clickReceipyNotifyCell(msgId: String, logId: String, recordId: String)
    func clickReceiveRedBagNotifyCell(owner: String,operator: String, packetId: String)
    func decryptFailedCellClick(msgId: String)
    func inviteGroupCellClick(msgId: String, inviterId: String, inviteGroupId: String, inviteMarkId: String)
    func longTapOnHeaderImageView(msgId: String)
    func admireInfoTap(msgId: String) //点击大拇指
    func textTapAdmire(msgId: String) //文字消息 点击点赞
    func textTapReward(msgId: String) //文字消息 双击打赏
}

extension CellActionProtocol {
    func showMenu(in targetView: UIView, msgId: String) {}
    func browserImage(from imageView: UIImageView, msgId: String) {}
    func clickLuckyPacket(msgId: String) {}
    func reSendMessage(msgId: String) {}
    func clickUserHeadImage(userId: String) {}
    func playVoice(msgId: String) {}
    func burnAfterMessage(msgId: String) {}
    func shouldBurnData(msgId: String) {}
    func forwardMessageDetail(msgId: String) {}
    func forwardSelectMessage(msgId: String) -> Bool { return false }
    func playVideo(msgId:String,videlPath:String) {}
    func openFile(msgId: String, filePath: String,fileName:String){}
    func openTransfer(msgId: String) {}
    func openReceipt(msgId: String) {}
    func clickReceipyNotifyCell(msgId: String, logId: String, recordId: String) {}
    func clickReceiveRedBagNotifyCell(owner: String,operator: String, packetId: String) {}
    func decryptFailedCellClick(msgId: String) {}
    func inviteGroupCellClick(msgId: String, inviterId: String, inviteGroupId: String, inviteMarkId: String) {}
    func longTapOnHeaderImageView(msgId: String) {}
    func admireInfoTap(msgId: String) {}
    func textTapAdmire(msgId: String) {}
    func textTapReward(msgId: String) {}
}

protocol MessageCellBurnAfterReadProtocol: AnyObject {
    var lockView: UIView {get set}
    var lockImg: UIImageView {get set}
    var countDownTimeView: FZMCountdownLab {get set}
    func openLock()
}
