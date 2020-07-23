//
//  FZMRedbagMessageCell.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/27.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import UIKit

class FZMRedbagMessageCell: FZMBaseMessageCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    lazy var backView : UIView = {
        let view = UIView()
        view.backgroundColor = FZM_RedColor
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }()
    
    lazy var bagImageView : UIImageView = {
        let v = UIImageView()
        v.image = UIImage(text: .luckyPacket, imageSize: CGSize(width: 30, height: 30), imageColor: UIColor(hex: 0xFFF602))
        return v
    }()
    
    lazy var desLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(16), textColor: UIColor.white, textAlignment: .left, text: "恭喜发财，大吉大利")
    }()
    
    lazy var typeLab : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(12), textColor: UIColor.white, textAlignment: .left, text: "查看红包")
    }()
    
    override func initView() {
        super.initView()
        self.contentView.addSubview(backView)
        backView.snp.makeConstraints { (m) in
            m.top.equalTo(self.userNameLbl.snp.bottom).offset(2)
            m.left.equalTo(self.userNameLbl)
            m.size.equalTo(CGSize(width: 230, height: 70))
            m.bottom.equalToSuperview().offset(-15)
        }
        backView.addSubview(bagImageView)
        bagImageView.snp.makeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.left.equalToSuperview().offset(15)
            m.size.equalTo(CGSize(width: 26, height: 30))
        }
        backView.addSubview(desLab)
        desLab.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(13)
            m.left.equalTo(bagImageView.snp.right).offset(10)
            m.size.equalTo(CGSize(width: 165, height: 23))
        }
        backView.addSubview(typeLab)
        typeLab.snp.makeConstraints { (m) in
            m.top.equalTo(desLab.snp.bottom).offset(6)
            m.left.equalTo(desLab)
            m.size.equalTo(CGSize(width: 165, height: 17))
        }
        
        self.admireView.snp.makeConstraints { (m) in
            m.bottom.equalTo(backView.snp.bottom).offset(-5)
            m.left.equalTo(backView.snp.right).offset(5)
        }
        
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe {[weak self] (_) in
            guard let strongSelf = self, strongSelf.sendingView.isHidden, strongSelf.failBtn.isHidden else { return }
            strongSelf.actionDelegate?.clickLuckyPacket(msgId: strongSelf.vm.msgId)
        }.disposed(by: disposeBag)
        backView.addGestureRecognizer(tap)
    }
    
    override func configure(with data: FZMMessageBaseVM) {
        super.configure(with: data)
        guard let data = data as? FZMRedbagMessageVM else { return }
        desLab.text = data.remark
        self.configureBagStatus(data.bagStatus)
        data.updateBagStatusSubject.subscribe {[weak self] (event) in
            guard case .next(let bagStatus) = event else { return }
            self?.configureBagStatus(bagStatus)
        }.disposed(by: disposeBag)
    }
    
    private func configureBagStatus(_ status :SocketLuckyPacketStatus) {
        switch status {
        case .normal:
            typeLab.text = "查看红包"
            backView.backgroundColor = FZM_LuckyPacketColor
            bagImageView.tintColor = UIColor(hex: 0xFFF602)
        case .opened:
            typeLab.text = "已领取"
            backView.backgroundColor = UIColor(hex: 0xF2A4A4)
            bagImageView.tintColor = UIColor(hex: 0xF4DEB8)
        case .receiveAll:
            typeLab.text = "已领完"
            backView.backgroundColor = UIColor(hex: 0xF2A4A4)
            bagImageView.tintColor = UIColor(hex: 0xF4DEB8)
        case .past:
            typeLab.text = "已过期"
            backView.backgroundColor = UIColor(hex: 0xF2A4A4)
            bagImageView.tintColor = UIColor(hex: 0xF4DEB8)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

class FZMMineRedbagMessageCell: FZMRedbagMessageCell {
    override func initView() {
        super.initView()
        self.changeMineConstraints()
        backView.snp.remakeConstraints { (m) in
            m.top.equalTo(self.userNameLbl.snp.bottom).offset(2)
            m.right.equalTo(self.userNameLbl)
            m.size.equalTo(CGSize(width: 230, height: 70))
            m.bottom.equalToSuperview().offset(-15)
        }
        bagImageView.snp.remakeConstraints { (m) in
            m.centerY.equalToSuperview()
            m.right.equalToSuperview().offset(-15)
            m.size.equalTo(CGSize(width: 26, height: 30))
        }
        desLab.textAlignment = .right
        desLab.snp.remakeConstraints { (m) in
            m.top.equalToSuperview().offset(13)
            m.right.equalTo(bagImageView.snp.left).offset(-10)
            m.size.equalTo(CGSize(width: 165, height: 23))
        }
        typeLab.textAlignment = .right
        typeLab.snp.remakeConstraints { (m) in
            m.top.equalTo(desLab.snp.bottom).offset(6)
            m.right.equalTo(desLab)
            m.size.equalTo(CGSize(width: 165, height: 17))
        }
        sendingView.snp.remakeConstraints { (m) in
            m.centerY.equalTo(backView)
            m.right.equalTo(backView.snp.left).offset(-5)
            m.size.equalTo(CGSize(width: 15, height: 15))
        }
        
        self.admireView.snp.remakeConstraints { (m) in
            m.bottom.equalTo(backView.snp.bottom).offset(-5)
            m.right.equalTo(backView.snp.left).offset(-5)
        }
    }
}

