//
//  FZMGroupUserCell.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/29.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit

class FZMGroupUserCell: UICollectionViewCell {
    
    private(set) var data : FZMGroupDetailUserViewModel?
    
    lazy var identificationImageView: UIImageView = {
        let imgV = UIImageView(image: GetBundleImage("user_identification"))
        imgV.isUserInteractionEnabled = true
        imgV.contentMode = .scaleAspectFill
        imgV.isHidden = true
        return imgV
    }()
    
    lazy var headImageView : UIImageView = {
        let imV = UIImageView(image:GetBundleImage("chat_normal_head"))
        imV.layer.cornerRadius = 5
        imV.clipsToBounds = true
        imV.contentMode = .scaleAspectFill
        imV.addSubview(identificationImageView)
        identificationImageView.snp.makeConstraints({ (m) in
            m.size.equalTo(CGSize.init(width: 15, height: 15))
            m.bottom.right.equalToSuperview()
        })
        return imV
    }()
    
    lazy var nameLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(10), textColor: FZM_GrayWordColor, textAlignment: .center, text: nil)
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(headImageView)
        headImageView.snp.makeConstraints { (m) in
            m.top.centerX.equalToSuperview()
            m.height.width.equalTo(35)
        }
        self.contentView.addSubview(nameLab)
        nameLab.snp.makeConstraints { (m) in
            m.bottom.left.right.equalToSuperview()
            m.height.equalTo(14)
        }
        IMNotifyCenter.shared().addReceiver(receiver: self, type: .groupUser)
    }
    
    deinit {
        IMNotifyCenter.shared().removeReceiver(receiver: self, type: .groupUser)
    }
    
    func setImageSize(_ size: CGFloat) {
        headImageView.snp.updateConstraints { (m) in
            m.height.width.equalTo(size)
        }
    }
    
    func configure(with data: FZMGroupDetailUserViewModel) {
        self.data = data
        self.identificationImageView.isHidden = true
        switch data.type {
        case .person:
            self.identificationImageView.image = GetBundleImage("user_identification")
            self.identificationImageView.isHidden = !data.identification
            self.nameLab.textColor = FZM_GrayWordColor
        case .invite:
            self.nameLab.text = "邀请"
            self.nameLab.textColor = FZM_TintColor
            self.headImageView.image = GetBundleImage("group_add_user")
        case .remove:
            self.nameLab.text = "移除"
            self.nameLab.textColor = FZM_TintColor
            self.headImageView.image = GetBundleImage("group_remove_user")
        }
        self.refreshView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension FZMGroupUserCell: UserGroupInfoChangeDelegate {
    func userGroupInfoChange(groupId: String, userId: String) {
        if let data = data, data.userId == userId, data.groupId == groupId {
            self.refreshView()
        }
    }
    
    private func refreshView() {
        guard let data = self.data else { return }
        switch data.type {
        case .person:
            IMContactManager.shared().getUsernameAndAvatar(with: data.userId, groupId: data.groupId) { (userId, name, avatar) in
                guard let nowData = self.data, nowData.type == .person, nowData.userId == userId else { return }
                self.headImageView.loadNetworkImage(with: avatar.getDownloadUrlString(width: 35), placeImage: GetBundleImage("chat_normal_head"))
                self.nameLab.text = name
                self.nameLab.textColor = FZM_GrayWordColor
            }
        case .invite:
            self.nameLab.text = "邀请"
            self.nameLab.textColor = FZM_TintColor
            self.headImageView.image = GetBundleImage("group_add_user")
        case .remove:
            self.nameLab.text = "移除"
            self.nameLab.textColor = FZM_TintColor
            self.headImageView.image = GetBundleImage("group_remove_user")
        }
    }
}
