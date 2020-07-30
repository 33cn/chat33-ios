//
//  FZMSearchCell.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/22.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit

class FZMSearchCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
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
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = UIColor.clear
        self.contentView.addSubview(headerImageView)
        headerImageView.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(15)
            m.size.equalTo(CGSize(width: 35, height: 35))
        }
        self.contentView.addSubview(nameLab)
        nameLab.snp.makeConstraints { (m) in
            m.left.equalTo(headerImageView.snp.right).offset(10)
            m.right.equalToSuperview().offset(-15)
            m.centerY.equalToSuperview()
            m.height.equalTo(23)
        }
    }
    
    func configure(with data: IMSearchInfoModel) {
        nameLab.text = data.name
        headerImageView.loadNetworkImage(with: data.avatar.getDownloadUrlString(width: 35), placeImage: GetBundleImage("chat_normal_head"))
        identificationImageView.image = data.type == .person ? GetBundleImage("chat_identification") : GetBundleImage("group_identification")
        identificationImageView.isHidden = !data.identification
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
