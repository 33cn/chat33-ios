//
//  FZMPromoteDetailCell.swift
//  IMSDK
//
//  Created by .. on 2019/7/2.
//

import UIKit

class FZMPromoteDetailCell: UITableViewCell {
    
    let uidLab = UILabel.getLab(font: UIFont.boldSystemFont(ofSize: 16), textColor: FZM_BlackWordColor, textAlignment: .left, text: nil)
    
    let promoteLab = UILabel.getLab(font: UIFont.boldSystemFont(ofSize: 18), textColor: FZM_BlackWordColor, textAlignment: .right, text: nil)
    
    let timeLab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .right, text: nil)
    
    lazy var alreadyRegisterBtn: UIButton = {
       let btn = UIButton.init()
        btn.setTitle(" 已注册", for: .normal)
        btn.titleLabel?.font = UIFont.regularFont(14)
        btn.setTitleColor(FZM_BlackWordColor, for: .disabled)
        btn.setImage(GetBundleImage("me_promote_Reg"), for: .disabled)
        btn.isEnabled = false
        return btn
    }()
    
    lazy var certificationBtn: UIButton = {
        let btn = UIButton.init()
        btn.setTitle(" 未实名", for: .normal)
        btn.setTitle(" 已实名", for: .selected)
        btn.setTitleColor(FZM_GrayWordColor, for: .normal)
        btn.setTitleColor(FZM_BlackWordColor, for: .selected)
        btn.titleLabel?.font = UIFont.regularFont(14)
        btn.setImage(GetBundleImage("me_promote_no_cer"), for: .normal)
        btn.setImage(GetBundleImage("me_promote_cer"), for: .selected)
        return btn
    }()
    
    lazy var bgView: UIView = {
        let v = UIView.init()
        v.makeOriginalShdowShow()
        
        v.addSubview(self.uidLab)
        self.uidLab.snp.makeConstraints({ (m) in
            m.top.equalToSuperview().offset(12)
            m.left.equalToSuperview().offset(15)
            m.height.equalTo(23)
        })
        
        v.addSubview(self.alreadyRegisterBtn)
        self.alreadyRegisterBtn.snp.makeConstraints({ (m) in
            m.top.equalTo(self.uidLab.snp.bottom).offset(7)
            m.left.equalTo(self.uidLab)
            m.height.equalTo(20)
            m.width.equalTo(65)
        })
        
        v.addSubview(self.certificationBtn)
        self.certificationBtn.snp.makeConstraints({ (m) in
            m.left.equalTo(self.alreadyRegisterBtn.snp.right).offset(30)
            m.top.size.equalTo(self.alreadyRegisterBtn)
        })
        
        v.addSubview(self.timeLab)
        self.timeLab.isHidden = true
        self.timeLab.snp.makeConstraints({ (m) in
            m.top.left.equalTo(self.alreadyRegisterBtn)
        })
        
        v.addSubview(self.promoteLab)
        self.promoteLab.snp.makeConstraints({ (m) in
            m.right.equalToSuperview().offset(-17)
            m.centerY.equalToSuperview()
        })
        
        return v
    }()
    
    var isTotalPromote = false {
        didSet {
            if isTotalPromote {
                self.timeLab.isHidden = false
                self.alreadyRegisterBtn.isHidden = true
                self.certificationBtn.isHidden = true
            } else {
                self.timeLab.isHidden = true
                self.alreadyRegisterBtn.isHidden = false
                self.certificationBtn.isHidden = false
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = FZM_BackgroundColor
        self.selectionStyle = .none
        self.crateViews()
    }
    
    func crateViews() {
        self.contentView.addSubview(self.bgView)
        self.bgView.snp.makeConstraints({ (m) in
            m.top.equalToSuperview().offset(2)
            m.bottom.equalToSuperview().offset(-13)
            m.left.equalToSuperview().offset(15)
            m.right.equalToSuperview().offset(-15)
        })
    }
    
    func configure(with data: FZMPromoteDetailVM) {
        self.isTotalPromote = data.isTotalPromote
        self.uidLab.text = data.uidInfo
        self.certificationBtn.isSelected = data.isCertification
        self.promoteLab.text = data.promoteInfo
        self.timeLab.text = data.timeInfo
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
