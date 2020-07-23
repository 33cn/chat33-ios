//
//  FZMConversationCell.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/25.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa


class FZMConversationCell: UITableViewCell {

    private let disposeBag = DisposeBag()
    
    private var refreshDisposeBag : DisposeBag?
    
    private var conversation : SocketConversationModel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    var selectStyle : FZMContactSelectStyle = .disSelect {
        didSet{
            switch selectStyle {
            case .select:
                selectBtn.image = GetBundleImage("tool_select")
            case .disSelect:
                selectBtn.image = GetBundleImage("tool_disselect")
            case .cantSelect:
                selectBtn.image = GetBundleImage("tool_delete")
            }
        }
    }
    
    lazy var selectBtn : UIImageView = {
        let btn = UIImageView(image: GetBundleImage("tool_disselect"))
        btn.isHidden = true
        return btn
    }()
    
    lazy var identificationImageView: UIImageView = {
        let imgV = UIImageView.init()
        imgV.isUserInteractionEnabled = true
        imgV.contentMode = .scaleAspectFill
        imgV.isHidden = true
        return imgV
    }()
    
    lazy var headerImageView : UIImageView = {
        let imV = UIImageView(image: GetBundleImage("chat_normal_head"))
        imV.layer.cornerRadius = 5
        imV.clipsToBounds = true
        imV.contentMode = .scaleAspectFill
        imV.addSubview(identificationImageView)
        identificationImageView.snp.makeConstraints({ (m) in
            m.size.equalTo(CGSize.init(width: 10, height: 10))
            m.bottom.right.equalToSuperview()
        })
        return imV
    }()
    
    lazy var nameLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: nil)
    }()
    
    lazy var messageLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: nil)
    }()
    let atString = "[有人@我]"
    var upvote: (admire: Int, reward: Int, stateForMe: SocketMessageUpvoteState)?
    lazy var isAtMeLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_RedColor, textAlignment: .left, text: "")
    }()
    
    lazy var timeLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .right, text: nil)
    }()
    
    lazy var unreadLab : FZMUnreadLab = {
        return FZMUnreadLab(frame: CGRect.zero)
    }()
    
    lazy var noDisturbView : UIImageView = {
        return UIImageView(image: GetBundleImage("tool_no_disturb"))
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = FZM_BackgroundColor
        self.contentView.addSubview(selectBtn)
        self.contentView.addSubview(headerImageView)
        selectBtn.snp.makeConstraints { (m) in
            m.left.equalToSuperview().offset(15)
            m.centerY.equalToSuperview()
            m.size.equalTo(CGSize(width: 15, height: 15))
        }
        headerImageView.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(15)
            m.size.equalTo(CGSize(width: 35, height: 35))
        }
        self.contentView.addSubview(nameLab)
        nameLab.snp.makeConstraints { (m) in
            m.left.equalTo(headerImageView.snp.right).offset(10)
            m.right.equalToSuperview().offset(-80)
            m.top.equalToSuperview().offset(14)
            m.height.equalTo(23)
        }
        self.contentView.addSubview(isAtMeLab)
        isAtMeLab.snp.makeConstraints { (m) in
            m.left.equalTo(nameLab)
            m.top.equalTo(nameLab.snp.bottom)
            m.height.equalTo(20)
        }
        self.contentView.addSubview(messageLab)
        messageLab.snp.makeConstraints { (m) in
            m.left.equalTo(isAtMeLab.snp.right)
            m.top.equalTo(nameLab.snp.bottom)
            m.height.equalTo(20)
            m.right.equalToSuperview().offset(-60)
        }
        self.contentView.addSubview(timeLab)
        timeLab.snp.makeConstraints { (m) in
            m.right.equalToSuperview().offset(-14)
            m.top.equalToSuperview().offset(18)
            m.height.equalTo(17)
        }
        self.contentView.addSubview(noDisturbView)
        noDisturbView.snp.makeConstraints { (m) in
            m.right.equalToSuperview().offset(-15)
            m.bottom.equalToSuperview().offset(-13)
            m.width.height.equalTo(17)
        }
        self.contentView.addSubview(unreadLab)
        unreadLab.snp.makeConstraints { (m) in
            m.centerX.equalTo(headerImageView.snp.right)
            m.centerY.equalTo(headerImageView.snp.top)
            m.size.equalTo(CGSize.zero)
        }
        let longPress = UILongPressGestureRecognizer()
        longPress.rx.event.subscribe {[weak self] (event) in
            guard case .next(let ges) = event else { return }
            guard let strongSelf = self,self?.selectBtn.isHidden == true else { return }
            if ges.state == .began {
                let point = ges.location(in: UIApplication.shared.keyWindow!)
                VoiceMessagePlayerManager.shared().vibrateAction()
                strongSelf.showConversationMenu(with: point)
            }
        }.disposed(by: disposeBag)
        self.contentView.addGestureRecognizer(longPress)
    }
    
    private func showConversationMenu(with point: CGPoint) {
        guard let model = conversation else { return }
        var itemArr = [FZMMenuItem]()
        let onTopItem = FZMMenuItem(title: "置顶聊天", block: {
            model.onTop = true
            IMConversationManager.shared().conversationChangeOntop(conversation: model, onTop: true)
        })
        let cancelOnTopItem = FZMMenuItem(title: "取消置顶", block: {
            model.onTop = false
            IMConversationManager.shared().conversationChangeOntop(conversation: model, onTop: false)
        })
        let noDisturbItem = FZMMenuItem(title: "免打扰", block: {
            IMConversationManager.shared().conversationChangeNoDisturb(conversation: model, noDisturb: true)
        })
        let cancelNoDisturbItem = FZMMenuItem(title: "取消免打扰", block: {
            IMConversationManager.shared().conversationChangeNoDisturb(conversation: model, noDisturb: false)
        })
        model.onTop ? itemArr.append(cancelOnTopItem) : itemArr.append(onTopItem)
        model.noDisturbing == .open ? itemArr.append(cancelNoDisturbItem) : itemArr.append(noDisturbItem)
        itemArr.append(FZMMenuItem(title: "删除聊天", block: {
            let alert = FZMAlertView(deleteConversation: model.name, confirmBlock: {
                IMConversationManager.shared().deleteConversation(with: model.conversationId, type: model.type)
            })
            alert.show()
        }))
        self.backgroundColor = UIColor(hex: 0xF1F4F6)
        let view = FZMMenuView(with: itemArr)
        view.hideBlock = {
            self.backgroundColor = model.onTop ? UIColor(hex: 0xF1F4F6) : FZM_BackgroundColor
        }
        view.show(in: point)
    }
    
    func showSelect() {
        selectBtn.isHidden = false
        unreadLab.isHidden = true;
        headerImageView.snp.updateConstraints { (m) in
            m.left.equalToSuperview().offset(45)
        }
    }
    
    func configure(with conversation: SocketConversationModel) {
        self.conversation = conversation
        self.messageLab.text = nil
        self.timeLab.text = nil
        self.isAtMeLab.text = ""
        if let lastMessage = conversation.lastMsg {
            self.setMessageAndTime(msg: lastMessage)
        }
        if selectBtn.isHidden == false {
            selectStyle = conversation.isSelected ? .select : .disSelect
        }
        let placeImg = GetBundleImage(conversation.type == .person ? "chat_normal_head" : "chat_group_head")
        refreshDisposeBag = nil
        refreshDisposeBag = DisposeBag()
        self.unreadLab.setUnreadCount(conversation.unreadCount)
        self.backgroundColor = conversation.onTop ? UIColor(hex: 0xF1F4F6) : FZM_BackgroundColor
        self.unreadLab.layer.backgroundColor = conversation.noDisturbing == .open ? UIColor(hex: 0xD3DFE6).cgColor : FZM_RedColor.cgColor
        self.noDisturbView.isHidden = conversation.noDisturbing == .close
        conversation.noDisturbingSubject.subscribe {[weak self] (event) in
            if case .next(let noDisturbing) = event {
                self?.noDisturbView.isHidden = noDisturbing == .close
                self?.unreadLab.layer.backgroundColor = conversation.noDisturbing == .open ? UIColor(hex: 0xD3DFE6).cgColor : FZM_RedColor.cgColor
            }
        }.disposed(by: refreshDisposeBag!)
        
        self.identificationImageView.isHidden = true
        let identificationImage = GetBundleImage(conversation.type == .person ? "chat_identification" : "group_identification")
        self.identificationImageView.image = identificationImage
        conversation.identificationSubject.subscribe {[weak self] (event) in
            if case .next(let identification) = event {
                self?.identificationImageView.isHidden = !identification
            }
        }.disposed(by: refreshDisposeBag!)
        
        conversation.lastMsgRefreshSubject.subscribe {[weak self] (event) in
            guard case .next(let msg) = event, let showMsg = msg else { return }
            self?.setMessageAndTime(msg: showMsg)
        }.disposed(by: refreshDisposeBag!)
        
        conversation.infoSubject.subscribe {[weak self] (event) in
            guard case .next(let (count,name,avatar)) = event else { return }
            self?.unreadLab.setUnreadCount(count)
            self?.nameLab.text = name
            self?.headerImageView.loadNetworkImage(with: avatar.getDownloadUrlString(width: 35), placeImage: placeImg)
        }.disposed(by: refreshDisposeBag!)
        conversation.isAtMeSubject.subscribe {[weak self] (event) in
            guard case .next(let e) = event, let isAtMe = e, let strongSelf = self else { return }
            strongSelf.isAtMeLab.textColor = FZM_RedColor
            if isAtMe {
                strongSelf.isAtMeLab.text = strongSelf.atString
            } else {
                strongSelf.isAtMeLab.text = ""
                strongSelf.setUpvoteString()
            }
        }.disposed(by: refreshDisposeBag!)
        conversation.allUpvote.upvoteSubject.subscribe(onNext: {[weak self] (upvote) in
            guard let strongSelf = self,
                let upvote = upvote
            else { return }
            strongSelf.upvote = upvote
            strongSelf.setUpvoteString()
          
        }).disposed(by: refreshDisposeBag!)
    }
    
    private func setUpvoteString() {
        guard let upvote = self.upvote,
            (self.isAtMeLab.text?.count == 0 || self.isAtMeLab.text != self.atString)
        else { return }
        
        if upvote.admire == 0 && upvote.reward == 0 {
            self.isAtMeLab.text = ""
        } else {
            self.isAtMeLab.text = "[\(upvote.admire + upvote.reward)" + "赞赏]"
            self.isAtMeLab.textColor = upvote.reward != 0 ? FZM_EFA019Color : FZM_TintColor
        }
    }
    
    private func setMessageAndTime(msg:SocketMessage) {
        if msg.msgType == .notify, let event = msg.body.notifyEvent, case .receiveRedBag(_, _, _, _) = event  {
            msg.getProcessedBodyContent(completeBlock: { (content) in
                self.messageLab.text = content
            })
        } else {
            msg.getBodyDescription(completeBlock: { (userId, conversationId, text) in
                self.messageLab.text = text
            })
        }
        self.timeLab.text = String.dateString(with: msg.datetime)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
