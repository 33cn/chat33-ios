//
//  FZMContactCell.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/9.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift

enum FZMContactSelectStyle {
    case select
    case disSelect
    case cantSelect
}


class FZMContactCell: UITableViewCell {

    private var refreshBag : DisposeBag?
    
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
        let imgV = UIImageView(image: GetBundleImage("chat_identification"))
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
    
    lazy var desLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .left, text: nil)
    }()
    
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
        self.contentView.addSubview(nameLab)
        nameLab.snp.makeConstraints { (m) in
            m.left.equalTo(headerImageView.snp.right).offset(10)
            m.right.equalToSuperview().offset(-10)
            m.height.equalTo(23)
        }
        self.contentView.addSubview(desLab)
        desLab.snp.makeConstraints { (m) in
            m.left.equalTo(nameLab)
            m.top.equalTo(nameLab.snp.bottom).offset(3)
            m.bottom.equalToSuperview().offset(-5)
            m.height.equalTo(17)
        }
    }
    
    func showSelect() {
        selectBtn.isHidden = false
        headerImageView.snp.updateConstraints { (m) in
            m.left.equalToSuperview().offset(45)
        }
    }
    
    
    
    func configure(with contact: FZMContactViewModel) {
        if refreshBag != nil {
            refreshBag = nil
        }
        refreshBag = DisposeBag()
        self.headerImageView.image = nil
        self.nameLab.attributedText = nil
        self.desLab.attributedText = nil
        self.nameLab.text = nil
        self.desLab.text = nil
        
        self.identificationImageView.image =  GetBundleImage(contact.type == .person ? "chat_identification" : "group_identification" )
        contact.identificationSubject.subscribe {[weak self] (event) in
            guard case .next(let identification) = event else { return }
            self?.identificationImageView.isHidden = !identification
        }.disposed(by: refreshBag!)
        
        let image = GetBundleImage(contact.type == .person ? "chat_normal_head" : "chat_group_head" )
        
        if contact.isBlocked, let user = contact.user {
           self.headerImageView.loadNetworkImage(with: user.avatar.getDownloadUrlString(width: 35), placeImage: image)
            self.nameLab.text = user.name
        } else {
            contact.infoSubject.subscribe {[weak self] (event) in
                guard case .next(let (name,avatar)) = event else { return }
                self?.headerImageView.loadNetworkImage(with: avatar.getDownloadUrlString(width: 35), placeImage: image)
                self?.nameLab.text = name
            }.disposed(by: refreshBag!)
        }
        
        
        
        self.desLab.snp.updateConstraints { (m) in
            m.height.equalTo(5)
        }
        
        if contact.searchString != nil {
            self.dealSearchString(data: contact)
        }
    }
    
    private func dealSearchString(data: FZMContactViewModel) {
        if let searchString = data.searchString, let user = data.user {
            let name = data.name
            if name.lowercased().contains(searchString.lowercased()) {
                let attStr = NSMutableAttributedString.init(string: name, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor : FZM_BlackWordColor])
                attStr.addAttributes([NSAttributedString.Key.foregroundColor : FZM_TitleColor], range:(name.lowercased() as NSString).range(of: searchString.lowercased()))
                self.nameLab.attributedText = attStr
            } else {
                self.nameLab.text = name
                var desString = ""
                if user.name.lowercased().contains(searchString.lowercased()) {
                    desString = "昵称: " + user.name
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
