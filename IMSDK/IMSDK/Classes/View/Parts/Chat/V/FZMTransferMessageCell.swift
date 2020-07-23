//
//  FZMTransferCell.swift
//  IMSDK
//
//  Created by .. on 2019/4/17.
//

import UIKit

class FZMTransferMessageCell: FZMBaseMessageCell {

    lazy var contentImageView : UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.layer.cornerRadius = 5
        v.clipsToBounds = true
        v.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        v.isUserInteractionEnabled = true
        v.backgroundColor = FZM_TransferBgColor
        return v
    }()
    
    lazy var transferIconImageView : UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        v.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        v.isUserInteractionEnabled = true
        v.layer.cornerRadius = 5
        v.layer.masksToBounds = true
        v.image = GetBundleImage("input_transfer")
        return v
    }()

    
    let moneyLab = UILabel.getLab(font: UIFont.boldFont(20), textColor: FZM_WhiteColor, textAlignment: .center, text: "")
    let inforLab = UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_WhiteColor, textAlignment: .left, text: "")
    
    override func initView() {
        super.initView()
        moneyLab.textAlignment = .left
        inforLab.textAlignment = .left
        
        self.contentView.addSubview(contentImageView)
        contentImageView.snp.makeConstraints { (m) in
            m.top.equalTo(headerImageView)
            m.left.equalTo(headerImageView.snp.right).offset(15)
            m.size.equalTo(CGSize.init(width: 230, height: 70))
            m.bottom.equalToSuperview().offset(-15)
        }
        self.contentImageView.addSubview(transferIconImageView)
        transferIconImageView.snp.makeConstraints { (m) in
            m.size.equalTo(CGSize.init(width: 30, height: 30))
            m.left.equalToSuperview().offset(15)
            m.centerY.equalToSuperview()
        }

        self.contentImageView.addSubview(moneyLab)
        moneyLab.snp.makeConstraints { (m) in
            m.top.equalTo(self.transferIconImageView).offset(-8)
            m.left.equalTo(self.transferIconImageView.snp.right).offset(10)
            m.right.equalToSuperview()
            m.height.equalTo(28)
        }

        self.contentImageView.addSubview(inforLab)
        inforLab.snp.makeConstraints { (m) in
            m.left.right.equalTo(moneyLab)
            m.bottom.equalTo(self.transferIconImageView).offset(7)
            m.height.equalTo(17);
        }
        
        self.admireView.snp.makeConstraints { (m) in
            m.bottom.equalTo(contentImageView.snp.bottom).offset(-5)
            m.left.equalTo(contentImageView.snp.right).offset(5)
        }

        let longPress = UILongPressGestureRecognizer()
        longPress.rx.event.subscribe {[weak self] (event) in
            guard case .next(let press) = event else { return }
            if press.state == .began {
                guard let view = press.view else { return }
                self?.showMenu(in: view)
            }
            }.disposed(by: disposeBag)
        contentImageView.addGestureRecognizer(longPress)
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe {[weak self] (event) in
            guard let strongSelf = self else { return }
            strongSelf.contentImageViewTap(msgId: strongSelf.vm.msgId)
            }.disposed(by: disposeBag)
        contentImageView.addGestureRecognizer(tap)
        
    }
    
    override func configure(with data: FZMMessageBaseVM) {
        super.configure(with: data)
        guard let data = data as? FZMTransferMessageVM  else { return }
        
        self.moneyLab.text = data.money
        self.inforLab.text = data.infor
        
    }
    
    func contentImageViewTap(msgId: String) {
        guard let vm = self.vm as? FZMTransferMessageVM else { return }
        self.actionDelegate?.openTransfer(msgId: msgId)
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


class FZMMineTransferMessageCell: FZMTransferMessageCell {
    override func initView() {
        super.initView()
        
        moneyLab.textAlignment = .right
        inforLab.textAlignment = .right
        
        self.changeMineConstraints()
        sendingView.snp.remakeConstraints { (m) in
            m.centerY.equalTo(contentImageView)
            m.right.equalTo(contentImageView.snp.left).offset(-5)
            m.size.equalTo(CGSize(width: 15, height: 15))
        }
        
        contentImageView.snp.remakeConstraints { (m) in
            m.top.equalTo(headerImageView)
            m.right.equalTo(headerImageView.snp.left).offset(-10)
            m.size.equalTo(CGSize.init(width: 230, height: 70))
            m.bottom.equalToSuperview().offset(-15)
        }
        
        transferIconImageView.snp.remakeConstraints { (m) in
            m.size.equalTo(CGSize.init(width: 30, height: 30))
            m.right.equalToSuperview().offset(-15)
            m.centerY.equalToSuperview()
        }
        
        moneyLab.snp.remakeConstraints { (m) in
            m.top.equalTo(self.transferIconImageView).offset(-8)
            m.right.equalTo(self.transferIconImageView.snp.left).offset(-10)
            m.left.equalToSuperview()
            m.height.equalTo(28)
        }
        
        self.admireView.snp.remakeConstraints { (m) in
            m.bottom.equalTo(contentImageView.snp.bottom).offset(-5)
            m.right.equalTo(contentImageView.snp.left).offset(-5)
        }
    }
    
    override func configure(with data: FZMMessageBaseVM) {
        super.configure(with: data)
        guard let data = data as? FZMTransferMessageVM else { return }
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
