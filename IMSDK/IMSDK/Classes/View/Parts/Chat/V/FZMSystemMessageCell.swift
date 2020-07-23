//
//  FZMSystemMessageCell.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/27.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit

//公告消息
class FZMSystemMessageCell: FZMBaseMessageCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    lazy var messageLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .center, text: nil)
        lab.numberOfLines = 0
        return lab
    }()
    
    override func initView() {
        super.initView()
        failBtn.isHidden = true
        sendingView.isHidden = true
        headerImageView.removeFromSuperview()
        userNameLbl.removeFromSuperview()
        let backView = UIView()
        backView.backgroundColor = FZM_LineColor
        backView.layer.cornerRadius = 4
        backView.clipsToBounds = true
        self.contentView.addSubview(backView)
        self.contentView.addSubview(messageLab)
        messageLab.snp.makeConstraints { (m) in
            m.centerX.equalToSuperview()
            m.top.equalTo(topTimeView.snp.bottom).offset(49)
            m.bottom.equalToSuperview().offset(-24)
            m.width.lessThanOrEqualToSuperview().offset(-84)
            m.width.greaterThanOrEqualTo(100)
        }
        let imageView = UIImageView(image: GetBundleImage("message_system_icon")?.withRenderingMode(.alwaysTemplate))
        imageView.tintColor = FZM_TintColor
        imageView.isUserInteractionEnabled = true
        let titleLab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .center, text: "公告")
        titleLab.isUserInteractionEnabled = true
        backView.addSubview(titleLab)
        titleLab.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(9)
            m.centerX.equalToSuperview().offset(15)
            m.height.equalTo(23)
        }
        backView.addSubview(imageView)
        imageView.snp.makeConstraints { (m) in
            m.centerY.equalTo(titleLab)
            m.right.equalTo(titleLab.snp.left).offset(-10)
            m.size.equalTo(CGSize(width: 20, height: 20))
        }
        backView.snp.makeConstraints { (m) in
            m.centerX.equalTo(messageLab)
            m.centerY.equalTo(messageLab).offset(-20)
            m.width.equalTo(messageLab).offset(24)
            m.height.equalTo(messageLab).offset(58)
        }
        selectBtn.snp.remakeConstraints { (m) in
            m.top.equalTo(backView).offset(10)
            m.left.equalToSuperview().offset(15)
            m.size.equalTo(CGSize(width: 15, height: 15))
        }
        
        let longPress = UILongPressGestureRecognizer()
        longPress.rx.event.subscribe {[weak self] (event) in
            guard case .next(let press) = event else { return }
            guard let strongSelf = self else { return }
            if press.state == .began {
                self?.showMenu(in: strongSelf.messageLab)
            }
        }.disposed(by: disposeBag)
        backView.addGestureRecognizer(longPress)
    }
    
    
    override func configure(with data: FZMMessageBaseVM) {
        super.configure(with: data)
        guard let data = data as? FZMSystemMessageVM else { return }
        messageLab.text = data.content
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

//通知消息
class FZMNotifyMessageCell: FZMBaseMessageCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    lazy var messageLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .center, text: nil)
        lab.numberOfLines = 0
        return lab
    }()
    
    override func initView() {
        super.initView()
        failBtn.isHidden = true
        sendingView.isHidden = true
        headerImageView.removeFromSuperview()
        userNameLbl.removeFromSuperview()
        let backView = UIView()
        backView.backgroundColor = FZM_LineColor
        backView.layer.cornerRadius = 5
        backView.clipsToBounds = true
        self.contentView.addSubview(backView)
        self.contentView.addSubview(messageLab)
        messageLab.snp.makeConstraints { (m) in
            m.centerX.equalToSuperview()
            m.top.equalTo(topTimeView.snp.bottom).offset(9)
            m.bottom.equalToSuperview().offset(-24)
            m.width.lessThanOrEqualToSuperview().offset(-84)
            m.height.greaterThanOrEqualTo(17)
        }
        backView.snp.makeConstraints { (m) in
            m.center.equalTo(messageLab)
            m.width.equalTo(messageLab).offset(24)
            m.height.equalTo(messageLab).offset(18)
        }
        
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe {[weak self] (event) in
            guard let strongSelf = self else { return }
            strongSelf.tapGestureClick()
            }.disposed(by: disposeBag)
        self.addGestureRecognizer(tap)
    }
    
    
    override func configure(with data: FZMMessageBaseVM) {
        super.configure(with: data)
        guard let data = data as? FZMNotifyMessageVM else { return }
        guard let event = data.notifyEvent else { return }
        switch event {
        case .receoptSuceess(_ , _, _):
            if !data.logId.isEmpty && !data.recordId.isEmpty && data.content.count >= 2 {
                let att = NSMutableAttributedString.init(string: data.content, attributes: [.foregroundColor:FZM_GrayWordColor, .font: UIFont.regularFont(12)])
                att.addAttributes([.foregroundColor:FZM_TintColor], range: NSRange.init(location: data.content.count - 2, length: 2))
                messageLab.attributedText = att
            }
        case .receiveRedBag(_, _, _, _):
            data.message.getProcessedBodyContent { (content) in
                if !data.owner.isEmpty && !data.oper.isEmpty && !data.packetId.isEmpty && content.contains("红包") {
                    let att = NSMutableAttributedString.init(string: content, attributes: [.foregroundColor:FZM_GrayWordColor, .font: UIFont.regularFont(12)])
                    att.addAttributes([.foregroundColor:FZM_RedColor], range:(content as NSString).range(of: "红包"))
                    self.messageLab.attributedText = att
                }
            }
        default:
            messageLab.text = data.content
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func tapGestureClick() {
        
        if let data = self.vm as? FZMNotifyMessageVM {
            guard let event = data.notifyEvent else { return }
            switch event {
            case .receoptSuceess(_ , _, _):
                if !data.logId.isEmpty && !data.recordId.isEmpty {
                    self.actionDelegate?.clickReceipyNotifyCell(msgId: data.msgId, logId: data.logId, recordId: data.recordId)
                }
            case .receiveRedBag(_, _, _, _):
                if !data.owner.isEmpty && !data.oper.isEmpty && !data.packetId.isEmpty {
                    self.actionDelegate?.clickReceiveRedBagNotifyCell(owner: data.owner, operator: data.oper, packetId: data.packetId)
                }
            default:
                break
            }
        }
    }
    
    
    
    
}
