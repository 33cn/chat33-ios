//
//  FZMMeCenterCell.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/8.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit

class FZMMeCenterCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    lazy var backView : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        return view
    }()
    
    lazy var headImageView : UIImageView = {
        let imV = UIImageView()
        return imV
    }()
    
    lazy var titleLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: nil)
    }()
    
    lazy var desLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .left, text: nil)
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.clear
        self.selectionStyle = .none
        self.contentView.addSubview(backView)
        backView.snp.makeConstraints { (m) in
            m.edges.equalToSuperview().inset(UIEdgeInsets.init(top: 0, left: 15, bottom: 15, right: 15))
        }
        backView.addSubview(headImageView)
        headImageView.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(15)
            m.size.equalTo(CGSize(width: 35, height: 35))
        }
        backView.addSubview(titleLab)
        titleLab.snp.makeConstraints { (m) in
            m.centerY.equalTo(headImageView)
            m.left.equalTo(headImageView.snp.right).offset(16)
            m.height.equalTo(23)
        }
        let moreImageView = UIImageView(image: GetBundleImage("me_more"))
        backView.addSubview(moreImageView)
        moreImageView.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.right.equalToSuperview().offset(-15)
            m.size.equalTo(CGSize(width: 3, height: 15))
        }
        
        backView.addSubview(desLab)
        desLab.snp.makeConstraints { (m) in
            m.centerY.equalTo(headImageView)
            m.right.equalTo(moreImageView.snp.left).offset(-5)
            m.height.equalTo(17)
        }
    }
    
    func configure(with data: [String:String]) {
        self.desLab.text = nil
        self.desLab.textColor = FZM_GrayWordColor
        self.titleLab.text = data["title"]
        self.headImageView.image = GetBundleImage(data["image"]!)
        if data["title"] == "我的收藏" {
            self.desLab.text = "0条"
        }else if data["title"] == "安全管理" {
            self.desLab.text = ""
        }else if data["title"] == "设置中心" {
            self.desLab.text = "好友验证"
        }else if data["title"] == "检测更新" {
            self.desLab.text = "v\(Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String)"
        }else if data["title"] == "分享邀请" {
            self.desLab.text = "APP下载"
        }else if data["title"] == "红包记录" {
            self.desLab.text = ""
        }else if data["title"] == "实名认证" {
            if let isAuth = FZM_UserDefaults.value(forKey: ESCROW_IS_AUTH) {
               self.desLab.text = ((isAuth as? Bool) ?? false) ? "已认证" : "未认证"
            } else {
                self.desLab.text = nil
            }
        }else if data["title"] == "考勤打卡" {
            self.desLab.text = IMLoginUser.shared().currentUser?.workUser?.workStatus.rawValue
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
