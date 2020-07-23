//
//  FZMGroupMemberCell.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/30.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift

class FZMGroupMemberCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    private var member : IMGroupUserInfoModel?
    private let disposeBag = DisposeBag()
    
    var showType = true
    
    var showRightDelete = false {
        didSet{
            deleteBtn.isHidden = !showRightDelete
        }
    }
    
    var showSelect = false {
        didSet{
            if showSelect {
                selectBtn.isHidden = false
                headerImageView.snp.updateConstraints { (m) in
                    m.left.equalToSuperview().offset(45)
                }
            }else {
                selectBtn.isHidden = true
                headerImageView.snp.updateConstraints { (m) in
                    m.left.equalToSuperview().offset(15)
                }
            }
        }
    }
    
    var isSelect = false {
        didSet{
            selectBtn.image = GetBundleImage(isSelect ? "tool_select" : "tool_disselect" )
        }
    }
    
    var deleteBlock: NormalBlock?
    var cleanBlock: NormalBlock?
    
    lazy var selectBtn : UIImageView = {
        let btn = UIImageView(image: GetBundleImage("tool_disselect"))
        btn.isHidden = true
        return btn
    }()
    
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
        imV.contentMode = .scaleAspectFill
        imV.addSubview(identificationImageView)
        identificationImageView.snp.makeConstraints({ (m) in
            m.size.equalTo(CGSize.init(width: 15, height: 15))
            m.bottom.right.equalToSuperview()
        })
        return imV
    }()
    
    lazy var nameLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: nil)
    }()
    
    lazy var desLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .left, text: nil)
    }()
    
    lazy var typeLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(12), textColor: UIColor.white, textAlignment: .center, text: nil)
        lab.layer.cornerRadius = 4
        lab.clipsToBounds = true
        return lab
    }()
    
    lazy var deleteBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(GetBundleImage("tool_delete"), for: .normal)
        btn.enlargeClickEdge(20, 20, 20, 20)
        btn.isHidden = true
        return btn
    }()
    
    lazy var clearBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.layer.cornerRadius = 15
        btn.layer.borderWidth = 1
        btn.layer.borderColor = FZM_TintColor.cgColor
        btn.setAttributedTitle(NSAttributedString(string: "解除", attributes: [.foregroundColor:FZM_TintColor,.font:UIFont.regularFont(14)]), for: .normal)
        btn.isHidden = true
        return btn
    }()
    
    var searchString: String?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = UIColor.clear
        self.contentView.addSubview(selectBtn)
        selectBtn.snp.makeConstraints { (m) in
            m.left.equalToSuperview().offset(15)
            m.centerY.equalToSuperview()
            m.size.equalTo(CGSize(width: 15, height: 15))
        }
        self.contentView.addSubview(headerImageView)
        headerImageView.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(15)
            m.size.equalTo(CGSize(width: 35, height: 35))
        }
        self.contentView.addSubview(typeLab)
        typeLab.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.left.equalTo(headerImageView.snp.right).offset(15)
            m.size.equalTo(CGSize(width: 45, height: 20))
        }
        self.contentView.addSubview(nameLab)
        nameLab.snp.makeConstraints { (m) in
            m.left.equalTo(headerImageView.snp.right).offset(10)
            m.right.equalToSuperview().offset(-90)
            m.height.equalTo(23)
        }
        self.contentView.addSubview(desLab)
        desLab.snp.makeConstraints { (m) in
            m.left.equalTo(nameLab)
            m.top.equalTo(nameLab.snp.bottom).offset(3)
            m.bottom.equalToSuperview().offset(-5)
            m.height.equalTo(17)
        }
        self.contentView.addSubview(deleteBtn)
        deleteBtn.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.right.equalToSuperview().offset(-15)
            m.size.equalTo(CGSize(width: 15, height: 15))
        }
        deleteBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            self?.deleteBlock?()
        }.disposed(by: disposeBag)
        
        self.contentView.addSubview(clearBtn)
        clearBtn.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.right.equalToSuperview().offset(-40)
            m.size.equalTo(CGSize(width: 50, height: 30))
        }
        clearBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            self?.clearBannedMember()
        }.disposed(by: disposeBag)
        
    }
    
    private func clearBannedMember() {
        guard let member = self.member else { return }
        IMConversationManager.shared().bannedGroupUser(groupId: member.groupId, userId: member.userId, deadline: 0) { (response) in
            guard response.success else {
                self.showToast(with: response.message)
                return
            }
            self.cleanBlock?()
            self.clearBannedInfo()
        }
    }
    
    func configure(with member: IMGroupUserInfoModel, showBannedGroup: IMGroupDetailInfoModel? = nil) {
        self.member = member
        self.nameLab.attributedText = nil
        self.desLab.attributedText = nil
        self.nameLab.text = ""
        self.desLab.text = ""
        self.identificationImageView.isHidden = !member.identification
        self.desLab.snp.updateConstraints { (m) in
            m.height.equalTo(5)
        }
        nameLab.snp.updateConstraints { (m) in
            m.left.equalTo(headerImageView.snp.right).offset(10)
        }
        typeLab.isHidden = true
        
        if showType {
            if member.memberLevel == .owner {
                typeLab.isHidden = false
                typeLab.backgroundColor = FZM_TintColor
                typeLab.text = "群主"
                nameLab.snp.updateConstraints { (m) in
                    m.left.equalTo(headerImageView.snp.right).offset(70)
                }
            }else if member.memberLevel == .manager {
                typeLab.isHidden = false
                typeLab.backgroundColor = UIColor(hex: 0xECD13C)
                typeLab.text = "管理员"
                nameLab.snp.updateConstraints { (m) in
                    m.left.equalTo(headerImageView.snp.right).offset(70)
                }
            }
        }
        
        if let group = showBannedGroup {
            FZMAnimationTool.removeCountdown(with: desLab)
            self.clearBtn.isHidden = true
            self.desLab.snp.updateConstraints { (m) in
                m.height.equalTo(5)
            }
            self.desLab.text = ""
            let (isBanned, distance) = IMConversationManager.shared().handleBannedInfo(user: member, group: group)
            if isBanned && distance > 0 {
                self.desLab.snp.updateConstraints { (m) in
                    m.height.equalTo(17)
                }
                self.popAnimation(time: distance)
                self.clearBtn.isHidden = false
            }
        }
        self.headerImageView.loadNetworkImage(with: member.avatar.getDownloadUrlString(width: 35), placeImage: GetBundleImage("chat_normal_head"))

        if self.searchString != nil {
            self.dealSearchString(data: member, name: member.showName)
        } else {
            self.nameLab.text = member.showName
            self.desLab.text = ""
        }
        
    }
    
    private func clearBannedInfo() {
        FZMAnimationTool.removeCountdown(with: desLab)
        self.clearBtn.isHidden = true
        self.desLab.snp.updateConstraints { (m) in
            m.height.equalTo(5)
        }
        desLab.text = ""
        self.member?.deadline = Date.timestamp
    }
    
    private func popAnimation(time:Double){
        if time < OnedaySeconds {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            FZMAnimationTool.countdown(with: desLab, fromValue: time, toValue: 0, block: { [weak self] (useTime) in
                let time = useTime - 8 * 3600
                let date = Date.init(timeIntervalSince1970: TimeInterval(time))
                self?.desLab.text = "已禁言 " + formatter.string(from: date)
            },finishBlock: {[weak self] in
                self?.clearBannedInfo()
            })
        }else{
            self.desLab.text = "永远禁言"
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

extension FZMGroupMemberCell {
    
    private func dealSearchString(data: IMGroupUserInfoModel, name: String) {
        if let searchString = self.searchString {
            if name.lowercased().contains(searchString.lowercased()) {
                let attStr = NSMutableAttributedString.init(string: name, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor : FZM_BlackWordColor])
                attStr.addAttributes([NSAttributedString.Key.foregroundColor : FZM_TitleColor], range:(name.lowercased() as NSString).range(of: searchString.lowercased()))
                self.nameLab.attributedText = attStr
            } else {
                self.nameLab.text = name
                var desString = ""
                if data.nickname.lowercased().contains(searchString.lowercased()) {
                    desString = "昵称: " + data.nickname
                } else if data.groupNickname.contains(searchString) {
                    desString = "群昵称: " + data.groupNickname
                }
                guard desString != "" else { return }
                self.desLab.snp.updateConstraints { (m) in
                    m.height.equalTo(15)
                }
                let attStr = NSMutableAttributedString.init(string: desString, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor : FZM_BlackWordColor])
                attStr.addAttributes([NSAttributedString.Key.foregroundColor : FZM_TitleColor], range:(desString.lowercased() as NSString).range(of: searchString.lowercased()))
                self.desLab.attributedText = attStr
            }
        }
    }
}

