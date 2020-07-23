//
//  FZMTextRedbagMessageCell.swift
//  IMSDK
//
//  Created by .. on 2019/12/12.
//

import UIKit
import YYText

class FZMTextRedbagMessageCell: FZMBaseMessageCell {
    
    lazy var messageLab: YYLabel = {
        let lbl = YYLabel()
        lbl.numberOfLines = 0
        lbl.isUserInteractionEnabled = true
        lbl.preferredMaxLayoutWidth = ScreenWidth - 160
        lbl.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        lbl.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return lbl
    }()
    
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
    
    lazy var flodImageView: UIImageView = {
        let v = UIImageView()
        var image = GetBundleImage("text_unfold")
        v.image = image
        v.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(flodImageViewTap))
        v.addGestureRecognizer(tap)
        v.enlargeClickEdge(10, 10, 10, 10)
        return v
    }()
    
    lazy var flodLab: YYLabel = {
        let lbl = YYLabel()
        lbl.numberOfLines = 2
        lbl.isUserInteractionEnabled = true
        lbl.isHidden = true
        lbl.preferredMaxLayoutWidth = ScreenWidth - 190
        return lbl
    }()
    
    lazy var iconView: UIImageView = {
        let v = UIImageView.init(image: GetBundleImage("msg_textRedbag"))
        return v
    }()
    
    @objc func flodImageViewTap() {
        self.vm.isNeedFold = !self.vm.isNeedFold
        if let tableView = self.superview as? UITableView, let indexPath = tableView.indexPath(for: self)  {
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func initView() {
        super.initView()
        self.contentView.addSubview(bgImageView)
        self.contentView.addSubview(messageLab)
        messageLab.numberOfLines = 0
        messageLab.snp.makeConstraints { (m) in
            m.top.equalTo(self.userNameLbl.snp.bottom).offset(12)
            m.bottom.equalToSuperview().offset(-25)
            m.left.equalTo(headerImageView.snp.right).offset(30)
            m.right.lessThanOrEqualToSuperview().offset(-80)
            m.height.greaterThanOrEqualTo(20)
        }
        bgImageView.snp.makeConstraints { (m) in
            m.centerX.equalTo(messageLab)
            m.centerY.equalTo(messageLab).offset(3)
            m.width.equalTo(messageLab).offset(50)
            m.height.equalTo(messageLab).offset(40)
        }
        sendingView.snp.makeConstraints { (m) in
            m.centerY.equalTo(bgImageView)
            m.left.equalTo(bgImageView.snp.right).offset(5)
            m.size.equalTo(CGSize(width: 15, height: 15))
        }
        
        self.contentView.addSubview(self.lockView)
        self.lockView.snp.makeConstraints { (m) in
            m.top.equalTo(self.userNameLbl.snp.bottom).offset(-5)
            m.left.equalToSuperview().offset(55)
            m.size.equalTo(CGSize(width: 120, height: 65))
        }
        self.bgImageView.addSubview(self.countDownTimeView)
        self.countDownTimeView.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(10)
            m.centerX.equalTo(self.bgImageView.snp.right).offset(-10)
            m.size.equalTo(CGSize(width: 0, height: 0))
        }
        
        
        
        self.contentView.addSubview(flodImageView)
        flodImageView.snp.makeConstraints { (m) in
            m.bottom.equalTo(self.bgImageView.snp.bottom).offset(-30)
            m.right.equalTo(self.bgImageView).offset(-23)
            m.size.equalTo(CGSize(width: 10, height: 6))
        }
        
        flodLab.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        self.contentView.addSubview(flodLab)
        flodLab.snp.makeConstraints { (m) in
            m.top.left.bottom.equalTo(messageLab)
            m.right.equalTo(messageLab).offset(-20)
        }
        
        self.admireView.snp.makeConstraints { (m) in
            m.bottom.equalTo(bgImageView.snp.bottom).offset(-15)
            m.left.equalTo(bgImageView.snp.right).offset(-5)
        }
        
        self.contentView.addSubview(self.iconView)
        self.iconView.snp.makeConstraints { (m) in
            m.size.equalTo(CGSize.init(width: 20, height: 20))
            m.top.equalTo(self.bgImageView).offset(10)
            m.left.equalTo(self.bgImageView.snp.right).offset(-20)
        }
        
        let longPress = UILongPressGestureRecognizer()
        longPress.rx.event.subscribe {[weak self] (event) in
            guard case .next(let press) = event else { return }
            guard let strongSelf = self else { return }
            if press.state == .began {
                self?.showMenu(in: strongSelf.bgImageView)
            }
        }.disposed(by: disposeBag)
        messageLab.addGestureRecognizer(longPress)
        
        let longPress2 = UILongPressGestureRecognizer()
        longPress2.rx.event.subscribe {[weak self] (event) in
            guard case .next(let press) = event else { return }
            guard let strongSelf = self else { return }
            if press.state == .began {
                self?.showMenu(in: strongSelf.bgImageView)
            }
        }.disposed(by: disposeBag)
        flodLab.addGestureRecognizer(longPress2)
        
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe {[weak self] (_) in
            guard let strongSelf = self, strongSelf.sendingView.isHidden, strongSelf.failBtn.isHidden else { return }
            strongSelf.actionDelegate?.clickLuckyPacket(msgId: strongSelf.vm.msgId)
        }.disposed(by: disposeBag)
        messageLab.addGestureRecognizer(tap)
        
        let tap2 = UITapGestureRecognizer()
        tap2.rx.event.subscribe {[weak self] (_) in
            guard let strongSelf = self, strongSelf.sendingView.isHidden, strongSelf.failBtn.isHidden else { return }
            strongSelf.actionDelegate?.clickLuckyPacket(msgId: strongSelf.vm.msgId)
        }.disposed(by: disposeBag)
        flodLab.addGestureRecognizer(tap2)
        
    }
    
    override func configure(with data: FZMMessageBaseVM) {
        super.configure(with: data)
        messageLab.numberOfLines = 0
        messageLab.isHidden = false
        messageLab.text = nil
        messageLab.attributedText = nil
        flodLab.text = nil
        flodLab.attributedText = nil
        flodImageView.isHidden = true
        flodLab.isHidden = true
        guard data.direction == .receive, let data = data as? FZMTextRedbagMessageVM else { return }
        lockView.isHidden = true
        messageLab.isHidden = false
        bgImageView.isHidden = false
        self.showContentText(with: data.remark)
    }
    
    fileprivate func showContentText(with str: String) {
        let  attStr = self.makeString(with: str, normalColor: FZM_BlackWordColor, linkColor: FZM_TitleColor)
        messageLab.attributedText = attStr
        
        if str.isURL() && str.count > 50  {
            messageLab.isHidden = true
            flodImageView.isHidden = false
            flodLab.isHidden = false
            flodLab.attributedText = attStr
            if self.vm.isNeedFold {
                messageLab.numberOfLines = 2
                flodLab.numberOfLines = 2
                flodImageView.image = GetBundleImage("text_unfold")
            } else {
                messageLab.numberOfLines = 0
                flodLab.numberOfLines = 0
                flodImageView.image = GetBundleImage("text_fold")
            }
        }else if self.vm.isTextNeedFold && messageLab.getLineCount(text: str)>3{
            messageLab.isHidden = true
            flodImageView.isHidden = false
            flodLab.isHidden = false
            flodLab.attributedText = attStr
            if self.vm.isNeedFold {
                messageLab.numberOfLines = 3
                flodLab.numberOfLines = 3
                flodImageView.image = GetBundleImage("text_unfold")
            } else {
                messageLab.numberOfLines = 0
                flodLab.numberOfLines = 0
                flodImageView.image = GetBundleImage("text_fold")
            }
        }
    }
    
    fileprivate func makeString(with str: String, normalColor: UIColor, linkColor: UIColor) -> NSMutableAttributedString?{
        let regularStr = "((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)"
        let reg = try? NSRegularExpression.init(pattern: regularStr, options: .caseInsensitive)
        guard let regex = reg else { return nil }
        let arrayOfAllMatches = regex.matches(in: str, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, str.count))
        var arr = [String]()
        var rangeArr = [NSRange]()
        arrayOfAllMatches.forEach { (match) in
            let substringForMatch = str.substring(with: match.range)
            arr.append(substringForMatch)
        }
        let subStr = str
        arr.forEach { (useStr) in
            rangeArr.append(str.nsRange(from: useStr))
        }
        let mutStr = NSMutableAttributedString(string: subStr)
        mutStr.yy_font = UIFont.regularFont(16)
        mutStr.yy_color = normalColor
        mutStr.yy_alignment = .left
 
        return mutStr
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}

class FZMMineTextRedbagMessageCell: FZMTextRedbagMessageCell {
    override func initView() {
        super.initView()
        self.changeMineConstraints()
        self.contentView.addSubview(sourceLab)
        sourceLab.snp.makeConstraints { (m) in
            m.right.equalTo(headerImageView.snp.left).offset(-20)
            m.left.greaterThanOrEqualToSuperview().offset(80)
            m.bottom.equalToSuperview().offset(-10)
            m.height.lessThanOrEqualTo(35)
        }
        messageLab.snp.remakeConstraints { (m) in
            m.top.equalTo(self.userNameLbl.snp.bottom).offset(12)
            m.bottom.equalTo(self.sourceLab.snp.top).offset(-12)
            m.right.equalTo(headerImageView.snp.left).offset(-30)
            m.left.greaterThanOrEqualToSuperview().offset(80)
            m.height.greaterThanOrEqualTo(20)
        }
        
        lockView.removeFromSuperview()
        countDownTimeView.removeFromSuperview()
        self.bgImageView.addSubview(lockImg)
        lockImg.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(8)
            m.left.equalToSuperview()
            m.size.equalTo(CGSize(width: 20, height: 20))
        }
        let inset = UIEdgeInsets.init(top: 30, left: 30, bottom: 30, right: 30)
        var image = GetBundleImage("message_text_mine")
        image = image?.resizableImage(withCapInsets: inset, resizingMode: .stretch)
        bgImageView.image = image
        sendingView.snp.remakeConstraints { (m) in
            m.centerY.equalTo(bgImageView)
            m.right.equalTo(bgImageView.snp.left).offset(-5)
            m.size.equalTo(CGSize(width: 15, height: 15))
        }
        
        self.admireView.snp.remakeConstraints { (m) in
            m.bottom.equalTo(bgImageView.snp.bottom).offset(-15)
            m.right.equalTo(bgImageView.snp.left).offset(5)
        }
        
        self.iconView.snp.remakeConstraints { (m) in
            m.size.equalTo(CGSize.init(width: 20, height: 20))
            m.top.equalTo(self.bgImageView).offset(7)
            m.right.equalTo(self.bgImageView.snp.left).offset(20)
        }
        
    }
    
    override func configure(with data: FZMMessageBaseVM) {
        super.configure(with: data)
        guard data.direction == .send, let data = data as? FZMTextRedbagMessageVM else { return }
        self.showContentText(with: data.remark)
        self.lockImg.isHidden = data.snap == .none
        
        sourceLab.text = data.forwardType == .detail ? data.forwardDescriptionText : nil
    }
}
