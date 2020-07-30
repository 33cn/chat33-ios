//
//  FZMDecryptFailedCell.swift
//  IMSDK
//
//  Created by .. on 2019/5/27.
//

import UIKit

class FZMDecryptFailedCell: FZMBaseMessageCell {
   
    lazy var messageLab: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.isUserInteractionEnabled = true
        lbl.preferredMaxLayoutWidth = ScreenWidth - 160
        lbl.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        lbl.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        lbl.textColor = FZM_GrayWordColor
        lbl.enlargeClickEdge(10, 0, 10, 0)
        return lbl
    }()
    
    let lockedView = UIImageView.init(image: GetBundleImage("text_decrypt_failed"))

    
    lazy var bgImageView: UIImageView = {
        let v = UIImageView()
        v.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        v.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let inset = UIEdgeInsets.init(top: 30, left: 30, bottom: 30, right: 30)
        var image = GetBundleImage("message_text")
        image = image?.resizableImage(withCapInsets: inset, resizingMode: .stretch)
        v.image = image
        v.isUserInteractionEnabled = true
        
        v.addSubview(lockedView)
        lockedView.snp.makeConstraints({ (m) in
            m.top.equalToSuperview().offset(10)
            m.right.equalToSuperview()
        })
        
        return v
    }()
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func initView() {
        super.initView()
        self.contentView.addSubview(bgImageView)
        self.contentView.addSubview(messageLab)
        messageLab.snp.makeConstraints { (m) in
            m.top.equalTo(self.userNameLbl.snp.bottom).offset(12)
            m.bottom.equalToSuperview().offset(-25)
            m.left.equalTo(headerImageView.snp.right).offset(30)
            m.right.lessThanOrEqualToSuperview().offset(-80)
            m.height.greaterThanOrEqualTo(20)
        }
        
        bgImageView.snp.makeConstraints { (m) in
            m.centerX.equalTo(messageLab)
            m.centerY.equalTo(messageLab)
            m.width.equalTo(messageLab).offset(50)
            m.height.equalTo(messageLab).offset(40)
        }
        
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.actionDelegate?.decryptFailedCellClick(msgId: strongSelf.vm.msgId)
            }.disposed(by: disposeBag)
        messageLab.addGestureRecognizer(tap)
    }
    
    override func configure(with data: FZMMessageBaseVM) {
        super.configure(with: data)
        guard let data = data as? FZMDecryptFailedVM else { return }
        messageLab.text = data.content
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}

class FZMMineDecryptFailedCell: FZMDecryptFailedCell {
    override func initView() {
        super.initView()
        self.changeMineConstraints()
        
        messageLab.snp.remakeConstraints { (m) in
            m.top.equalTo(self.userNameLbl.snp.bottom).offset(12)
            m.bottom.equalToSuperview().offset(-49)
            m.right.equalTo(headerImageView.snp.left).offset(-30)
            m.left.greaterThanOrEqualToSuperview().offset(80)
            m.height.greaterThanOrEqualTo(20)
        }
        
        bgImageView.snp.remakeConstraints { (m) in
            m.centerX.equalTo(messageLab)
            m.centerY.equalTo(messageLab).offset(3)
            m.width.equalTo(messageLab).offset(50)
            m.height.equalTo(messageLab).offset(40)
        }
        
        lockedView.snp.remakeConstraints({ (m) in
            m.top.equalToSuperview().offset(10)
            m.left.equalToSuperview()
        })
        
        let inset = UIEdgeInsets.init(top: 30, left: 30, bottom: 30, right: 30)
        var image = GetBundleImage("message_text_mine")
        image = image?.resizableImage(withCapInsets: inset, resizingMode: .stretch)
        bgImageView.image = image
    }
    
}
