//
//  FZMContactApplyCell.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/10/17.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit
import RxSwift

class FZMContactApplyCell: UITableViewCell {

    private var data : FZMContactApplyVM?
    
    private let disposeBag = DisposeBag()
    
    var dealBlock : BoolBlock?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    lazy var infoView : UIView = {
        let view = UIView()
        view.makeOriginalShdowShow()
        view.addSubview(nameLab)
        nameLab.snp.makeConstraints({ (m) in
            m.top.equalToSuperview().offset(16)
            m.left.equalToSuperview().offset(16)
            m.right.equalToSuperview().offset(-114)
            m.height.equalTo(23)
        })
        view.addSubview(applyDesLab)
        applyDesLab.snp.makeConstraints({ (m) in
            m.top.equalTo(nameLab.snp.bottom)
            m.left.equalTo(nameLab)
            m.right.equalToSuperview().offset(-100)
            m.height.lessThanOrEqualTo(40)
            m.height.greaterThanOrEqualTo(20)
        })
        view.addSubview(dealLab)
        dealLab.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.right.equalToSuperview().offset(-15)
            m.height.equalTo(20)
        })
        view.addSubview(agreeBtn)
        agreeBtn.snp.makeConstraints({ (m) in
            m.centerY.equalToSuperview()
            m.right.equalToSuperview().offset(-15)
            m.width.height.equalTo(35)
        })
        view.addSubview(rejectBtn)
        rejectBtn.snp.makeConstraints({ (m) in
            m.top.equalTo(agreeBtn)
            m.right.equalTo(agreeBtn.snp.left).offset(-15)
            m.width.height.equalTo(35)
        })
        view.addSubview(reasonLab)
        reasonLab.snp.makeConstraints({ (m) in
            m.bottom.equalToSuperview().offset(-10)
            m.left.equalToSuperview().offset(16)
            m.right.equalToSuperview().offset(-16)
            m.height.lessThanOrEqualTo(60)
        })
        return view
    }()
    
    lazy var nameLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: nil)
    }()
    
    lazy var applyDesLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: nil)
        lab.numberOfLines = 2
        return lab
    }()
    
    lazy var dealLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_TintColor, textAlignment: .right, text: nil)
    }()
    
    lazy var agreeBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(GetBundleImage("tool_agree"), for: .normal)
        return btn
    }()
    
    lazy var rejectBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(GetBundleImage("tool_reject"), for: .normal)
        return btn
    }()
    
    lazy var headImageView : UIImageView = {
        let view = UIImageView(image: GetBundleImage("chat_normal_head"))
        view.layer.cornerRadius = 5
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    lazy var reasonLab : UILabel = {
        let lab = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: nil)
        lab.numberOfLines = 3
        return lab
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = UIColor.clear
        self.createUI()
    }
    
    private func createUI() {
        self.contentView.addSubview(infoView)
        infoView.snp.makeConstraints { (m) in
            m.left.equalToSuperview().offset(45)
            m.right.equalToSuperview().offset(-15)
            m.centerY.equalToSuperview()
            m.height.equalTo(70)
        }
        let lineView = UIView.getNormalLineView()
        self.contentView.addSubview(lineView)
        lineView.snp.makeConstraints { (m) in
            m.left.equalToSuperview().offset(32)
            m.top.bottom.equalToSuperview()
            m.width.equalTo(1)
        }
        self.contentView.addSubview(headImageView)
        headImageView.snp.makeConstraints { (m) in
            m.top.equalTo(infoView).offset(20)
            m.centerX.equalTo(lineView)
            m.size.equalTo(CGSize(width: 35, height: 35))
        }
        
        rejectBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            self?.dealBlock?(false)
        }.disposed(by: disposeBag)
        agreeBtn.rx.controlEvent(.touchUpInside).subscribe {[weak self] (_) in
            self?.dealBlock?(true)
        }.disposed(by: disposeBag)
    }
    
    func configure(with data: FZMContactApplyVM) {
        self.data = data
        headImageView.loadNetworkImage(with: data.avatar.getDownloadUrlString(width: 35), placeImage: GetBundleImage("chat_normal_head"))
        nameLab.text = data.name
        applyDesLab.text = data.source
        dealLab.text = data.statusStr
        if !data.isSender && data.status == .waiting {
            rejectBtn.isHidden = false
            agreeBtn.isHidden = false
            dealLab.isHidden = true
        }else {
            rejectBtn.isHidden = true
            agreeBtn.isHidden = true
            dealLab.isHidden = false
        }
        reasonLab.text = data.reason
        self.infoView.snp.updateConstraints { (m) in
            m.height.equalTo(data.contentHeight - 15)
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
