//
//  FZMPromoteHotGroupCell.swift
//  IMSDK
//
//  Created by .. on 2019/7/4.
//

import UIKit

class FZMPromoteHotGroupCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    
    lazy var bgView : UIView = {
        let v = UIView.init()
        v.makeOriginalShdowShow()
        return v
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
    
    lazy var selectedImageView: UIImageView = {
        let v = UIImageView.init(image: GetBundleImage("tool_disselect"))
        v.highlightedImage = GetBundleImage("tool_select")
        v.isHighlighted = true
        return v
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = FZM_BackgroundColor
        self.contentView.addSubview(bgView)
        bgView.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(2)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
            m.bottom.equalToSuperview().offset(-13)
        }
        
        self.bgView.addSubview(headerImageView)
        headerImageView.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(15)
            m.size.equalTo(CGSize(width: 35, height: 35))
        }
        self.bgView.addSubview(nameLab)
        nameLab.snp.makeConstraints { (m) in
            m.left.equalTo(headerImageView.snp.right).offset(10)
            m.right.equalToSuperview().offset(-59)
            m.centerY.equalToSuperview()
            m.height.equalTo(23)
        }
        self.bgView.addSubview(selectedImageView)
        selectedImageView.snp.makeConstraints { (m) in
            m.right.equalToSuperview().offset(-15)
            m.centerY.equalToSuperview()
            m.size.equalTo(CGSize.init(width: 15, height: 15))
        }
    }
    
    func configure(with data: FZMPromoteHotGroup) {
        nameLab.text = data.name
        headerImageView.loadNetworkImage(with: data.avatar.getDownloadUrlString(width: 35), placeImage: GetBundleImage("chat_normal_head"))
        selectedImageView.isHighlighted = data.isSelected
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

}
