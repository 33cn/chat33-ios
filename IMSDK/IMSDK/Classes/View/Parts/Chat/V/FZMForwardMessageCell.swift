//
//  FZMForwardMessageCell.swift
//  AFNetworking
//
//  Created by 吴文拼 on 2019/1/9.
//

import UIKit

class FZMForwardMessageCell: FZMBaseMessageCell {

    lazy var bgImageView: UIImageView = {
        let v = UIImageView()
        v.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        v.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let inset = UIEdgeInsets.init(top: 30, left: 30, bottom: 30, right: 30)
        var image = GetBundleImage("message_text")
        image = image?.resizableImage(withCapInsets: inset, resizingMode: .stretch)
        v.image = image
        v.isUserInteractionEnabled = true
        return v
    }()
    
    lazy var mergeView : UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.addSubview(titleView)
        titleView.snp.makeConstraints({ (m) in
            m.top.equalToSuperview().offset(16)
            m.left.equalToSuperview().offset(24)
            m.right.equalToSuperview().offset(-24)
            m.height.lessThanOrEqualTo(45)
        })
        view.addSubview(messageListView)
        messageListView.snp.makeConstraints({ (m) in
            m.left.right.equalTo(titleView)
            m.top.equalTo(titleView.snp.bottom).offset(5)
        })
        view.addSubview(lineView)
        lineView.snp.makeConstraints({ (m) in
            m.bottom.equalToSuperview().offset(-40)
            m.left.equalToSuperview().offset(10)
            m.right.equalToSuperview().offset(-10)
            m.height.equalTo(0.5)
        })
        view.addSubview(numberView)
        numberView.snp.makeConstraints({ (m) in
            m.top.equalTo(lineView.snp.bottom)
            m.left.right.equalTo(titleView)
            m.height.equalTo(30)
        })
        return view
    }()
    lazy var titleView : UILabel = {
        let view = UILabel.getLab(font: UIFont.regularFont(16), textColor: FZM_BlackWordColor, textAlignment: .left, text: nil)
        view.numberOfLines = 2
        return view
    }()
    lazy var messageListView : UILabel = {
        let view = UILabel.getLab(font: UIFont.regularFont(14), textColor: FZM_GrayWordColor, textAlignment: .left, text: nil)
        view.numberOfLines = 4
        return view
    }()
    lazy var lineView : UIView = {
        return UIView.getNormalLineView()
    }()
    lazy var numberView : UILabel = {
        return UILabel.getLab(font: UIFont.regularFont(12), textColor: FZM_GrayWordColor, textAlignment: .left, text: nil)
    }()
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func initView() {
        super.initView()
        self.contentView.addSubview(bgImageView)
        self.contentView.addSubview(mergeView)
        mergeView.snp.makeConstraints { (m) in
            m.top.equalTo(self.userNameLbl.snp.bottom).offset(-8)
            m.bottom.equalToSuperview().offset(-5)
            m.left.equalTo(headerImageView.snp.right).offset(5)
            m.right.equalToSuperview().offset(-55)
            m.height.equalTo(100)
        }
        bgImageView.snp.makeConstraints { (m) in
            m.edges.equalTo(mergeView)
        }
        lineView.backgroundColor = UIColor(hex: 0xE6EAEE)
        self.remakeSelectBtnConstraints(with: mergeView)
        
        self.admireView.snp.makeConstraints { (m) in
            m.bottom.equalTo(bgImageView.snp.bottom).offset(-15)
            m.left.equalTo(bgImageView.snp.right).offset(-5)
        }
        
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe {[weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.actionDelegate?.forwardMessageDetail(msgId: strongSelf.vm.msgId)
        }.disposed(by: disposeBag)
        mergeView.addGestureRecognizer(tap)
        let longPress = UILongPressGestureRecognizer()
        longPress.rx.event.subscribe {[weak self] (event) in
            guard case .next(let press) = event else { return }
            guard let strongSelf = self else { return }
            if press.state == .began {
                self?.showMenu(in: strongSelf.bgImageView)
            }
        }.disposed(by: disposeBag)
        mergeView.addGestureRecognizer(longPress)
    }
    
    override func configure(with data: FZMMessageBaseVM) {
        super.configure(with: data)
        guard let data = data as? FZMForwardMessageVM else { return }
        titleView.text = data.title
        numberView.text = data.numberText
        messageListView.text = data.detail
        var height : CGFloat = 71
        let titleHeight = data.title.getContentHeight(width: ScreenWidth - 162, font: UIFont.regularFont(16))
        height += titleHeight > 45 ? 45 : titleHeight
        let detailHeight = data.detail.getContentHeight(width: ScreenWidth - 162, font: UIFont.regularFont(14))
        height += detailHeight > 80 ? 80 : detailHeight
        
        mergeView.snp.updateConstraints { (m) in
            m.height.equalTo(height)
        }
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

class FZMMineForwardMessageCell: FZMForwardMessageCell {
    override func initView() {
        super.initView()
        self.changeMineConstraints()
        mergeView.snp.remakeConstraints { (m) in
            m.top.equalTo(self.userNameLbl.snp.bottom).offset(-8)
            m.bottom.equalToSuperview().offset(-5)
            m.right.equalTo(headerImageView.snp.left).offset(-5)
            m.left.equalToSuperview().offset(55)
            m.height.equalTo(100)
        }
        bgImageView.snp.remakeConstraints { (m) in
            m.edges.equalTo(mergeView)
        }
        
        self.admireView.snp.remakeConstraints { (m) in
            m.bottom.equalTo(bgImageView.snp.bottom).offset(-15)
            m.right.equalTo(bgImageView.snp.left).offset(5)
        }
        
        let inset = UIEdgeInsets.init(top: 30, left: 30, bottom: 30, right: 30)
        var image = GetBundleImage("message_text_mine")
        image = image?.resizableImage(withCapInsets: inset, resizingMode: .stretch)
        bgImageView.image = image
        lineView.backgroundColor = UIColor(hex: 0x9FCAF5)
        messageListView.textColor = UIColor(hex: 0x5B7796)
        numberView.textColor = UIColor(hex: 0x5B7796)
    }
    
}
