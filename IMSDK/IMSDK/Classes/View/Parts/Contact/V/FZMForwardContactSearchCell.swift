//
//  FZMForwardContactSearchCell.swift
//  IMSDK
//
//  Created by .. on 2019/9/25.
//

import UIKit

class FZMForwardContactSearchCell: UITableViewCell {
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
        return btn
    }()
    
    lazy var headerImageView : UIImageView = {
        let imV = UIImageView(image: GetBundleImage("chat_normal_head"))
        imV.layer.cornerRadius = 5
        imV.clipsToBounds = true
        imV.contentMode = .scaleAspectFill
        return imV
    }()
    
    lazy var nameLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: nil)
    }()
    
    lazy var desLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .left, text: nil)
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
            m.left.equalToSuperview().offset(45)
            m.size.equalTo(CGSize(width: 35, height: 35))
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
    }
    
    func configure(with model: FZMForwardContactSearchModel) {
        self.nameLab.attributedText = nil
        self.desLab.attributedText = nil
        self.nameLab.text = ""
        self.desLab.text = ""
        self.selectStyle = model.isSelected ? FZMContactSelectStyle.select : FZMContactSelectStyle.disSelect
        self.desLab.snp.updateConstraints { (m) in
            m.height.equalTo(5)
        }
        nameLab.snp.updateConstraints { (m) in
            m.left.equalTo(headerImageView.snp.right).offset(10)
        }
        self.headerImageView.loadNetworkImage(with: model.avatar.getDownloadUrlString(width: 35), placeImage: GetBundleImage("chat_normal_head"))
        if self.searchString != nil {
            self.dealSearchString(data: model, name: model.showName)
        } else {
            self.nameLab.text = model.showName
            self.desLab.text = ""
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}



extension FZMForwardContactSearchCell {
    
    private func dealSearchString(data: FZMForwardContactSearchModel, name: String) {
        if let searchString = self.searchString {
            if name.lowercased().contains(searchString.lowercased()) {
                let attStr = NSMutableAttributedString.init(string: name, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor : FZM_BlackWordColor])
                attStr.addAttributes([NSAttributedString.Key.foregroundColor : FZM_TitleColor], range:(name.lowercased() as NSString).range(of: searchString.lowercased()))
                self.nameLab.attributedText = attStr
            } else {
                if data.isFriend {
                    self.nameLab.text = name
                    var desString = ""
                    if data.name.lowercased().contains(searchString.lowercased()) {
                        desString = "昵称: " + data.name
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
}
