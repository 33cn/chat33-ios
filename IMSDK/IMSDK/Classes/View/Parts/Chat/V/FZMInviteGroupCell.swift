//
//  FZMInviteGroupCell.swift
//  IMSDK
//
//  Created by .. on 2019/7/17.
//

import UIKit

class FZMInviteGroupCell: FZMBaseMessageCell {

    lazy var contentImageView : UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        v.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        v.isUserInteractionEnabled = true
        v.image = GetBundleImage("chat_inviteGroupBg")
        return v
    }()
    
    lazy var groupIdentificationImageView: UIImageView = {
        let imgV = UIImageView(image: GetBundleImage("group_identification"))
        imgV.isUserInteractionEnabled = true
        imgV.contentMode = .scaleAspectFill
        imgV.isHidden = true
        return imgV
    }()
    
    lazy var groupAvatarImageView : UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        v.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        v.isUserInteractionEnabled = true
        v.layer.cornerRadius = 5
        v.layer.masksToBounds = true
        v.addSubview(groupIdentificationImageView)
        groupIdentificationImageView.snp.makeConstraints({ (m) in
            m.size.equalTo(CGSize.init(width: 15, height: 15))
            m.bottom.right.equalToSuperview()
        })
        return v
    }()
    
    let titleLab = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: "")
    let groupNameLab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_BlackWordColor, textAlignment: .left, text: "")
    let identificationLab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: "")
    
    override func initView() {
        super.initView()
        self.contentView.addSubview(contentImageView)
        contentImageView.snp.makeConstraints { (m) in
            m.top.equalTo(userNameLbl.snp.bottom).offset(2)
            m.left.equalTo(headerImageView.snp.right)
            m.size.equalTo(CGSize.init(width: 260, height: 135))
            m.bottom.equalToSuperview().offset(-15)
        }
        self.contentImageView.addSubview(groupAvatarImageView)
        groupAvatarImageView.snp.makeConstraints { (m) in
            m.size.equalTo(CGSize.init(width: 50, height: 50))
            m.left.equalToSuperview().offset(23)
            m.centerY.equalToSuperview().offset(11)
        }
        titleLab.textAlignment = .left
        self.contentImageView.addSubview(titleLab)
        titleLab.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(21)
            m.left.equalTo(self.groupAvatarImageView)
            m.right.equalToSuperview().offset(-20)
        }
        self.contentImageView.addSubview(groupNameLab)
        groupNameLab.lineBreakMode = .byTruncatingTail
        groupNameLab.snp.makeConstraints { (m) in
            m.top.equalTo(self.groupAvatarImageView).offset(2)
            m.left.equalTo(self.groupAvatarImageView.snp.right).offset(10)
            m.right.equalToSuperview().offset(-20)
            m.height.equalTo(20)
        }
        self.contentImageView.addSubview(identificationLab)
        identificationLab.lineBreakMode = .byTruncatingTail
        identificationLab.snp.makeConstraints { (m) in
            m.bottom.equalToSuperview().offset(-2)
            m.left.right.height.equalTo(self.groupNameLab)
        }
        
        self.admireView.snp.makeConstraints { (m) in
            m.bottom.equalTo(contentImageView.snp.bottom).offset(-15)
            m.left.equalTo(contentImageView.snp.right).offset(-5)
        }
        
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe {[weak self] (event) in
            guard let strongSelf = self else { return }
            strongSelf.tapGestureClick()
            }.disposed(by: disposeBag)
        contentImageView.addGestureRecognizer(tap)
        
    }
    
    func tapGestureClick() {
        if let data = self.vm as? FZMInviteGroupVM {
            self.actionDelegate?.inviteGroupCellClick(msgId: data.msgId, inviterId: data.inviterId, inviteGroupId: data.roomId, inviteMarkId: data.markId)
        }
    }
    
    override func configure(with data: FZMMessageBaseVM) {
        super.configure(with: data)
        guard let data = data as? FZMInviteGroupVM  else { return }
        self.groupIdentificationImageView.isHidden = data.identificationInfo.isEmpty
        self.groupAvatarImageView.loadNetworkImage(with: data.groupAvatar.getDownloadUrlString(width: 35), placeImage: GetBundleImage("chat_normal_head"))
        self.titleLab.text = data.title
        self.groupNameLab.text = data.roomName
        if data.identificationInfo.isEmpty {
            self.identificationLab.isHidden = true
            self.groupNameLab.snp.remakeConstraints { (m) in
                m.centerY.equalTo(self.groupAvatarImageView)
                m.left.equalTo(self.groupAvatarImageView.snp.right).offset(10)
                m.right.equalToSuperview().offset(-20)
                m.height.equalTo(20)
            }
        } else {
            self.identificationLab.isHidden = false
            self.identificationLab.text = data.identificationInfo
            groupNameLab.snp.remakeConstraints { (m) in
                m.top.equalTo(self.groupAvatarImageView).offset(2)
                m.left.equalTo(self.groupAvatarImageView.snp.right).offset(10)
                m.right.equalToSuperview().offset(-20)
                m.height.equalTo(20)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

}

class FZMMineInviteGroupCell: FZMInviteGroupCell {
    
    override func initView() {
        super.initView()
        self.changeMineConstraints()
        contentImageView.snp.remakeConstraints { (m) in
            m.top.equalTo(userNameLbl.snp.bottom).offset(2)
            m.right.equalTo(headerImageView.snp.left)
            m.size.equalTo(CGSize.init(width: 260, height: 135))
            m.bottom.equalToSuperview().offset(-15)
        }
        sendingView.snp.remakeConstraints { (m) in
            m.centerY.equalTo(contentImageView)
            m.right.equalTo(contentImageView.snp.left).offset(-5)
            m.size.equalTo(CGSize(width: 15, height: 15))
        }
        
        self.admireView.snp.remakeConstraints { (m) in
            m.bottom.equalTo(contentImageView.snp.bottom).offset(-15)
            m.right.equalTo(contentImageView.snp.left).offset(5)
        }
    }
    
    override func configure(with data: FZMMessageBaseVM) {
        super.configure(with: data)
        self.sendingView.transform = CGAffineTransform.init(scaleX: 0, y: 0)
        guard let data = data as? FZMFileMessageVM else { return }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
